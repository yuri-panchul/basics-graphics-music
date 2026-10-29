After the main text about the universities and programs like the Synthesis School, create a follow-up chapter. Invent a title with the meaning "Beyond MIT 6.111: Not all HDL+FPGA cirriculums are the same".

Explain that having a single introductory FPGA class is not enough. For example, many countries and universities have only classes that covers material from simple gates to FSMs and interfacing with sequential protocols like SPI. If they cover pipelining, this is usually only in the context of a classic 5-stage MIPS/RISC-V static pipeline. However when students graduate and start working in electronic companies, they discover that many designs in industry (such as networking chips, video processing blocks, GPU fixed functions) have data pipelining outside of CPU scope. Students know about FIFOs but don't know how to use them together with pipelines. Not many graduate students demonstrate the knowledge of such techniques as credit-based flow control during job interviews.

Equally problematic is the fact that many graduate students are not familiar with modern verification techniques and write primitive testbenches in style of early 1990s. Many don't know how to use self-checking against a transactional model, constraint randomization in SystemVerilog and functional coverage. Very few have any experience with formal verification and concurrent assertions, despite many claim them in their AI-generated resumes. As a result, the microarchitectural complexity of their designs is limited because they cannot verify the corner cases in their designs.

Another cluster of problems is that FPGA labs are not connected to ASIC design labs. Some schools have no access to Synopsys Fusion or Cadence Genus / Innovus toolchains, and at the same time do not have expertise in open-source EDA toolchains such as OpenROAD and LibreLane. AS a result,

* Most students do not develop the intuition about the static timing analysis.

* Do not know how to solve negative slack problem.

* Are frequently confused about power savings techniques, such as clock gating.

You can refer to the presentation at EDA, slides 14-17:

https://docs.google.com/presentation/d/14WxUKOwsAo6Yn8X19WpGPNV5fk2H3XappceqGRlxqdM/edit?usp=sharing

Now you need to research and rank the above-mentioned universities using an additional set of criteria. For the purpose of ranking and comparison, you need to add to the group approximately 20 put-of-state and international universities, including:

1. Top US: MIT, Princeton, Univ Michigan.

2. Univ I am familiar with: North Carolina Univ, Portland State, Georgia Institute of Technology.

3. Top (in a sense of these topics) universities in Japan, China, South Korea, India and other Asian countries that educate many Verilog, microarchitectrure, FPGA and ASIC engineers.

4. Representative Europeans - make sure to add ETH Zurich, UCL, Cambridge.

Here how we are going to rank them. We add a point for each item in the following list. This item can be either a part of their introductory HDL+FPGA class (similar to MIT 6.111), or a part of some closely related class (such a separate advanced Verilog, verification or physical design class).

Area 1. Microarchitecture using single clock, gates and D-flip-flops.

1.1. Data pipelining, such as pipelined floating point arithmetic units.

1.2. FIFO queues.

1.3. Combinations of data pipelines and FIFOs for the purpose of flow control.

1.4. Ready/Valid protocols.

1.5. Credit-based flow control.

1.6. Systolic arrays.

1.7. Arbiters, such as round robin arbiters.

1.8. Reorder buffers.

1.9. AXI and the related protocols.

Area 2. Microarchitecture with multiple clocks, memories and power gating.

2.1. Memory banking of embedded into ASIC SRAM memories.

2.2. Linked list hardware controllers working with memories.

2.3. Clock Domain Crossing (CDC).

2.4. CDC using CDC FIFO.

2.5. Clock gating on fine level using enables.

2.6. Mid-range clock gating using latch-and-gate clock gaters.

Area 3. Verification.

3.1. RTL simulation with self-checking testbenches.

3.2. RTL simulation with self-checking against a transaction model.

3.3. Bus functional models (BFMs).

3.4. Passive monitors and scoreboards.

3.5. SystemVerilog constraint random stimuli generation.

3.6. SystemVerilog functional coverage.

3.7. Formal verification using SVA concurrent assertions, assumptions and cover statements.

3.8. Using emulators such as Mentor Veloce,  Synopsys Zebu or Cadence Palladium.

3.9. Verifying a pipelined CPU RTL against an instruction-level-simulator-based model.

Area 4. Timing and other PD topics for ASIC and FPGA

4.1. Simple push-button ASIC design flow using Tiny Tapeout

4.2. Simple push-button ASIC design flow using open-source LibreLane and OpenROAD.

4.3. Commercial tools such as Synopsys and Cadence.

4.4. Labs with ASIC static timing analysis (STA) reports.

4.5. Labs with power analysis tools such as Synopsys PTPX or Cadence Joule.

4.6. Labs with floorplanning tools.

Area 5. CPU specific.

5.1. Labs and exercises (simulation and FPGA) with an RTL CPU core with static pipeline.

5.2. Same with a dynamic out of order pipeline (a students designs his own CPU pipeline back-end).

5.3. Same with hardware supported multithreading.

5.4. Same with caches.

5.5. Same with a cluster of RTL CPU cores without cache coherency, like a mesh interconnect.

5.6. Same with coherent caches with MESI protocols.

5.7. Same with branch predictor (a students designs his own branch predictor).

Area 6. Application-specific

6.1. RTL projects in camera video processing.

6.2. RTL projects in computer graphics.

6.3. RTL projects in networking chips.

6.4. RTL projects in DSP: filters.

6.5. RTL projects in DSP: FFT.

6.6. RTL projects in sound processing.

6.7. ML accelerators.

Area 7. EDA algorithms. Students doing practical labs where they create or modify software EDA tools, specifically.

7.1. RTL simulation.

7.2. Logic synthesis.

7.3. Placement & routing.

Assess each university and Synthesis School in the combined list (California - former USSR - out of state of CA - representative international) in those items, create 7 tables with anything you can find, then create university ranking and tentative country/region ranking.

Put a combined report (MIT 6.111 + follow-ups and related) into new HTML files: English and Russian versions.

Then create English and Russian versions of the texts for the following:

1. LinkedIn post.

2. Facebook post.

3. Telegram post.

4. verilog-meetup.com wordpress post.

5. silicon-russia.com post.

6. ddvca.com post.

Put every post in a different HTML file.
