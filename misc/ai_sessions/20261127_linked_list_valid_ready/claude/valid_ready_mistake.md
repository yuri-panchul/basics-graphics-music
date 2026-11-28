basics-graphics-music · lab 5_5_1, linked list controller · 27 November 2026

# How I was wrong to call Yuri's valid/ready non-standard

Written by Claude (Opus 5.5) at Yuri's request · [Русская версия](valid_ready_mistake_ru.md)

*Markdown version of [valid_ready_mistake.html](valid_ready_mistake.html). The waveforms are drawn as text from the same simulation data: `‾` is 1, `_` is 0, `x` is unknown, `|` starts a new bus value, `-` means no value, `#` marks a cycle with valid = ready = 1, and `^` marks a rising edge.*

## In short

In this session I said several times that the handshake between `start_pointer_request_generator` and `linked_list_controller_1_fetching_next_from_constant_array` was not standard valid/ready. I then "fixed" the controller and listed 20 "non-standard" clock edges.

**That was wrong.** Under the AXI handshake rules, a transfer happens on the rising edge where VALID and READY are both 1. Until that edge the source must keep VALID and the data steady, and the destination is free to look at the data early. Yuri's controller reads the start pointer when a list starts and raises READY on the list's last entry, so each pointer is read once and acknowledged once.

My change was a different design choice: acknowledge at the start of the list instead of the end. It didn't fix any protocol problem.

## 1. The design

The lab has a generator that sends start pointers and a controller that follows a linked list stored in constant tables. The controller outputs one table entry per clock. Each list ends with a node whose data is 0 and whose next pointer is 0:

| Start pointer | 1 | 2 | 6 | 7 | 9 |
|---|---|---|---|---|---|
| Nodes | 1 → 5 → 3 → 10 | 2 → 4 | 6 | 7 → 15 → 8 | 9 → 14 → 11 → 13 → 12 |
| Output | A B C 0 | D 0 | 0 | E F 0 | G H I J 0 |

Here is the controller's handshake logic, unchanged in Yuri's commit `709da7c2`:

```systemverilog
    pointer_t current_pointer, next_pointer;
    logic next_pointer_valid;

    always_comb
    begin
        next_pointer = '0;

        if (out_data_valid)
            next_pointer = next_pointers [current_pointer];
        else if (start_pointer_valid)
            next_pointer = start_pointer;

        next_pointer_valid = (next_pointer != '0);
    end

    always_ff @ (posedge clock)
        if (reset)
            out_data_valid <= 1'b0;
        else
            out_data_valid <= next_pointer_valid;

    always_ff @ (posedge clock)
    begin
        current_pointer <= next_pointer;
        out_data        <= constant_data_array [next_pointer];
    end

    assign start_pointer_ready = ~ next_pointer_valid;
```

*`linked_list_controller_1_fetching_next_from_constant_array.sv`, lines 76–103*

Here is the committed generator, which sends eight requests. It advances its counter on `start_pointer_ready`:

```systemverilog
    logic [3:0] n_request;

    always_ff @ (posedge clock)
        if (reset)
            n_request <= '0;
        else if (start_pointer_ready)
            n_request <= n_request + 4'd1;

    assign start_pointer_valid = (n_request != 4'd8);

    always_comb
        case (n_request)
        4'd0:    start_pointer = pointer_t' (7);
        4'd1:    start_pointer = pointer_t' (6);
        4'd2:    start_pointer = pointer_t' (2);
        4'd3:    start_pointer = pointer_t' (1);
        4'd4:    start_pointer = pointer_t' (0);
        default: start_pointer = pointer_t' (9);
        endcase
```

*`start_pointer_request_generator.sv` at commit 709da7c2, lines 12–30*

For the one-list test, Yuri replaced the sequence with a constant request:

```systemverilog
    assign start_pointer_valid = 1'b1;
    assign start_pointer       = pointer_t' (1);
```

*`start_pointer_request_generator.sv` in the working tree (uncommitted)*

## 2. What I said

Here are my exact words, with the prompt each one answered:

**Prompt**

> fix synthax error in …/lab_top.sv

**My reply (excerpt)**

> One thing in the design, which I left alone: `start_pointer_ready = ~ next_pointer_valid` is high in the cycle the controller is *not* taking a pointer. The generator moves on in that cycle. That works for this sequence, but it isn't standard valid/ready.

**Prompt**

> what about now?

**My reply (excerpt)**

> The handshake still has the issue I mentioned: the controller takes a start pointer while `start_pointer_ready` is 0, and the generator moves on later, when `ready` is 1. It gives the right sequence here, but it isn't standard valid/ready.

**Prompt**

> fix it for the standard valid/ready

**My reply (excerpt)**

> The controller now uses standard valid/ready: a start pointer moves only in a cycle where `start_pointer_valid` and `start_pointer_ready` are both 1. Only the controller changed; your generator was already correct.

**Prompt**

> in what clock cycles (simulation time) I can see a non-standard valid/ready bahaviour if I stash the changes?

**My reply (excerpt)**

> With both files stashed, 20 rising edges show non-standard valid/ready behaviour, between 45 ns and 505 ns.

## 3. My assumptions

1. **The transfer is the cycle in which the destination starts using the data.** So `start_pointer_ready` should be 1 in exactly the cycle where the controller loads `start_pointer`.
2. **READY = 1 means "I am taking the data now".** So READY = 1 in a cycle where the controller doesn't load the pointer looked like the destination dropping data.
3. **The destination must not use the data before it acknowledges it.** This is a habit from FIFOs and skid buffers, which take data on `valid & ready`. It is a design convention, not a protocol rule.
4. I didn't check any of this against the AXI specification before stating it as fact.

## 4. My line of thought

1. In the `always_comb` block, the branch `else if (start_pointer_valid) next_pointer = start_pointer;` has no `start_pointer_ready` in its condition.
2. `assign start_pointer_ready = ~ next_pointer_valid;` means that in the cycle where the controller loads a non-zero pointer, `next_pointer_valid` is 1, so `ready` is 0.
3. Together with assumption 1, that read as "loads while ready = 0, and raises ready when it doesn't load", which I called non-standard.
4. When asked to fix it, I moved the acknowledgment to the start of the list:

```diff
@@ -76,13 +76,25 @@ import linked_list_controller_configuration_and_types_package::*;
     pointer_t current_pointer, next_pointer;
     logic next_pointer_valid;
 
+    // The controller is busy while it walks a list,
+    // i.e. while the current node has a next node.
+
+    wire list_continues
+        = out_data_valid & (next_pointers [current_pointer] != '0);
+
+    // Standard valid/ready handshake: a start pointer is transferred
+    // in a clock cycle when both start_pointer_valid
+    // and start_pointer_ready are 1.
+
+    assign start_pointer_ready = ~ list_continues;
+
     always_comb
     begin
         next_pointer = '0;
 
-        if (out_data_valid)
+        if (list_continues)
             next_pointer = next_pointers [current_pointer];
-        else if (start_pointer_valid)
+        else if (start_pointer_valid & start_pointer_ready)
             next_pointer = start_pointer;
 
         next_pointer_valid = (next_pointer != '0);
@@ -100,6 +112,4 @@ import linked_list_controller_configuration_and_types_package::*;
         out_data        <= constant_data_array [next_pointer];
     end
 
-    assign start_pointer_ready = ~ next_pointer_valid;
-
 endmodule
```

*My change to the controller, now in `stash@{0}`*

5. When asked for the clock edges, I wrote a checker whose rules were my assumptions:

```systemverilog
// My checker (scratch file vr_check.sv), committed controller

wire taken = v & ! odv;   // controller loads start_pointer at this edge

if (taken & ! r)          // "A": loads while ready = 0
    ...
if (v & r & ! taken)      // "B": valid = ready = 1, but no load
    ...
if (n != prev_n & ! prev_v)  // "C": generator counted a transfer while valid = 0
    ...
```

*The three rules of my checker, shortened*

It reported 20 edges. The check was circular: it encoded my assumption, so its result couldn't test that assumption. Here are the first edges it flagged, in the committed eight-request test:

```text
slow_clk               /‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/
rst                    ‾‾‾‾\____________________________________________________________________
start_pointer_valid    ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
start_pointer_ready    ________________/‾‾‾\___/‾‾‾\_______/‾‾‾\_______________/‾‾‾‾‾‾‾\________
valid & ready                          ####    ####        ####                ########
start_pointer          |7                  |6      |2          |1                  |0  |9      |
i_spr.n_request        |0                  |1      |2          |3                  |4  |5      |
i_llc.current_pointer  --------|7  |15 |8  ----|6  ----|2  |4  ----|1  |5  |3  |10 --------|9  |
out_data_valid         ________/‾‾‾‾‾‾‾‾‾‾‾\___/‾‾‾\___/‾‾‾‾‾‾‾\___/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______/‾‾‾‾
out_data               --------|E  |F  |0  ----|0  ----|D  |0  ----|A  |B  |C  |0  --------|G  |
A                              ^               ^       ^           ^                       ^
B                                          ^       ^           ^                   ^
ns                     25  35  45  55  65  75  85  95  105 115 125 135 145 155 165 175 185 195 205
```

*Committed controller and generator. Every four characters across are one clock cycle, and the `^` markers sit on the rising edge where the event happens. Cycles marked `####` in the `valid & ready` row have valid = ready = 1, so a transfer happens at the edge that ends them.*

- **A** (45, 85, 105, 135, 195 ns): what I called "takes the pointer while ready = 0". In fact the controller reads a pointer that the source must keep steady anyway, which the rules allow.
- **B** (75, 95, 125, 175 ns): what I called "valid = ready = 1, but the pointer is ignored". In fact this is the handshake that completes the transfer of the pointer read earlier.

## 5. What was incorrect

The handshake rules in the AMBA AXI Protocol Specification (Arm IHI 0022, "Handshake process"), paraphrased:

1. The source asserts VALID when the information is available. It must not wait for READY before asserting VALID.
2. Once VALID is asserted, the source keeps VALID asserted and the information unchanged until the rising clock edge where VALID and READY are both high. That edge is the transfer.
3. The destination may assert READY before VALID, or wait for VALID before asserting READY. It may also deassert READY before VALID arrives.
4. The rules don't say what the destination does with the information before the transfer. Because the source must hold it steady, reading it early is safe.

Checked against these rules:

- **"A" edges:** the controller reads a pointer that rule 2 guarantees will stay put. Nothing requires READY to be 1 when the destination first looks at the data.
- **"B" edges:** these are the transfers. The source moves on, and the controller, having already used the pointer, doesn't use it again.
- **"C" edge (375 ns):** the committed generator counted a transfer on `ready` alone while `valid` was 0, so `valid` came back for an extra request. That is a counting bug inside the generator; on the wire it is just a new VALID, not a protocol violation. Yuri had already changed the generator to `start_pointer_valid & start_pointer_ready`.
- **READY depending on VALID:** `ready = ~ next_pointer_valid` depends on `start_pointer_valid`. Rule 3 allows this. The forbidden dependency is the other way round, VALID waiting for READY, and here VALID never depends on READY.

So my "fix" didn't repair a protocol problem. It only moved the acknowledgment from the end of the list to its start.

## 6. Yuri's correction

> look at the current test with only 1 list. valid is accepted only after all the list is fetched. I do not see anything non-standard in it. if valid is not acknowledged by ready it is supposed to stay high and input valid pointer is supposed to be stable. This is the rules of AXI protocol.

This is the AXI rule set, and the one-list test shows it directly. `start_pointer_valid` stays 1 and the pointer stays 1 until `start_pointer_ready` rises on the last entry of each `ABC` list:

```text
slow_clk               /‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/
rst                    ‾‾‾‾\____________________________________________________________________
start_pointer_valid    ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
start_pointer_ready    ____________________/‾‾‾\_______________/‾‾‾\_______________/‾‾‾\________
valid & ready                              ####                ####                ####
start_pointer          |1                                                                      |
i_llc.current_pointer  --------|1  |5  |3  |10 ----|1  |5  |3  |10 ----|1  |5  |3  |10 ----|1  |
out_data_valid         ________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\___/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\___/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\___/‾‾‾‾
out_data               --------|A  |B  |C  |0  ----|A  |B  |C  |0  ----|A  |B  |C  |0  ----|A  |
transfer                                       ^                   ^                   ^
load                           ^                   ^                   ^                   ^
ns                     25  35  45  55  65  75  85  95  105 115 125 135 145 155 165 175 185 195 205
```

*The one-list test with Yuri's controller. **load**: the controller reads the pointer (45, 95, 145, 195 ns). **transfer**: valid = ready = 1 (85, 135, 185 ns). Each load is followed by exactly one transfer, and the source holds the pointer in between.*

## 7. Checking after the correction

Over the whole 535 ns one-list run (Icarus Verilog 12.0, the lab's `tb.sv`):

- 10 transfers and 10 loads, with every load followed by exactly one transfer before the next load.
- 0 violations of the source rule: whenever `valid` is 1 and `ready` is 0, the next cycle still has `valid` = 1 and the same pointer.

```systemverilog
// Source-side AXI rule, checked on every rising edge (scratch file axi_trace.sv)

if (prev_v & ! prev_r & (! v | p != prev_p))
    source_errors ++;   // valid dropped or pointer changed before the handshake
```

*The source-side rule, as checked here*

## 8. Final conclusion

**Yuri's controller is a standard valid/ready (AXI-style) destination.** It reads the start pointer early and acknowledges it on the last entry of the list. My variant acknowledges at the start instead. Both follow the rules; they differ in timing:

|  | Yuri's controller (commit 709da7c2) | My variant (in stash@{0}) |
|---|---|---|
| When `start_pointer_ready` is 1 | on the list's last entry | whenever no list is in progress |
| When the transfer happens | at the end of the list | when the list starts |
| How long the source waits | the whole list | nothing extra |
| Cycles per `ABC` list | 5 (one idle cycle between lists) | 4 (lists back to back) |
| Transfers in the 535 ns test | 10 | 13 |
| Source-rule violations | 0 | 0 |

```text
slow_clk               /‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/
rst                    ‾‾‾‾\____________________________________________________________________
start_pointer_valid    ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
start_pointer_ready    ‾‾‾‾‾‾‾‾\___________/‾‾‾\___________/‾‾‾\___________/‾‾‾\___________/‾‾‾‾
valid & ready              ####            ####            ####            ####            ####
start_pointer          |1                                                                      |
i_llc.current_pointer  --------|1  |5  |3  |10 |1  |5  |3  |10 |1  |5  |3  |10 |1  |5  |3  |10 |
out_data_valid         ________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
out_data               --------|A  |B  |C  |0  |A  |B  |C  |0  |A  |B  |C  |0  |A  |B  |C  |0  |
transfer + load                ^               ^               ^               ^               ^
ns                     25  35  45  55  65  75  85  95  105 115 125 135 145 155 165 175 185 195 205
```

*My variant on the same one-list test. The transfer and the load happen on the same edge (45, 85, 125, 165, 205 ns), and lists follow each other without an idle cycle.*

Which one the lab should use is a teaching decision, not a correctness question. Acknowledging at the end is simpler and shows that READY can come long after VALID. Acknowledging at the start frees the source earlier and removes the idle cycle.

## 9. What I take from this

- Check a protocol claim against the protocol's rules, not against a design habit.
- A checker has to encode the specification. Mine encoded my assumption, so its 20 "violations" proved nothing.
- Keep "breaks the protocol" separate from "is a different microarchitecture".
- When a claim is challenged, run the smallest case. One list settled this question.

## 10. Repository state

- Working tree: the controller is Yuri's, as committed in `709da7c2`. The generator has the uncommitted one-list test.
- `stash@{0}`: my controller variant together with Yuri's generator fix, `start_pointer_valid & start_pointer_ready`.
- This report: `misc/ai_sessions/20261127_linked_list_valid_ready/claude/`, untracked.
- The waveforms are drawn from the simulation, sampled in the middle of each clock cycle, with `tb.sv` driving `slow_clk` from `clk` (10 ns period).

## Appendix A. Prompts, verbatim

1. > fix synthax error in /home/verilog/projects/basics-graphics-music/labs/4_microarchitecture/5_5_linked_list_controller/5_5_1_linked_list_controller_fetching_next_from_constant_array/lab_top.sv
2. > what about now?
3. > fix it for the standard valid/ready
4. > in what clock cycles (simulation time) I can see a non-standard valid/ready bahaviour if I stash the changes?
5. > look at the current test with only 1 list. valid is accepted only after all the list is fetched. I do not see anything non-standard in it. if valid is not acknowledged by ready it is supposed to stay high and input valid pointer is supposed to be stable. This is the rules of AXI protocol.
6. > create a report in a separate HTML file "how I was wrong to call Yuri's valid/ready non-standard". Describe your assumptions, line of thought, what was incorrect, my correction and your final conclusion. Make two versions - English and Russian. Illustrate with waveforms and code.
