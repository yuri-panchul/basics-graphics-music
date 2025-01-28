The dates for the Verilog Meetup events in Mexico and Armenia are set:

* Friday and Saturday, February 21-22, 2025 in Mexico, Universidad autónoma de baja California in Tijuana.

* Thursday and Friday, March 13-14, 2025 in Armenia, Russian-Armenian University in Yerevan, in cooperation with Institute for Informatics and Automation Problems, National Academy of Sciences of the Republic of Armenia.

Both events will include a program for undergraduate students studying digital design. However, the event in Armenia will also include a program for a more advanced audience since we have worked with colleagues in Armenia longer (since 2023), plus they have a local division of Synopsys and do EDA (Electronic Design Automation) research over there.

The program for the undegraduate students:

* Day 1. ASIC and FPGA design flow. Exercises with combinational logic.

    * Morning

        1. Introduction to digital design flow for FPGA.

        2. Basics of SystemVerilog hardware description language.

        3. [Exercises with combinational logic using buttons, LEDs and 7-segment displays](https://github.com/yuri-panchul/basics-graphics-music/tree/main/labs/9_events/2025_01_21_tijuana/day_1_am_combination_logic_basics).

    * Afternoon

        4. Improving proficiency with SystemVerilog syntax by doing exercises with graphics.

The students will draw static pictures on a color LCD screen or an HDMI
display by changing the SystemVerilog code that computes a color RGB
(red/green/blue) using X and y coordinates provided by an LCD or HDMI
controller.

        5. Moving the students exercises developed on FPGA to Tiny Tapeout infrastructure, the most affordable way to do ASIC design.
We are going to use [a special template that allows to write the same code targeting ASIC and FPGA](https://github.com/yuri-panchul/tt10-verilog-template-for-verilog-meetup).

* Day 2. Sequential logic is what makes circuits smart. More exercises and a hackathon.

    * Morning

        6. Logic meets physics: the propagation delay and the need to synchromize the computations. Introducing clock, state, D-flip-flop, slack and aperture.

        7. The exercises on FPGA board covering sequential blocks and the finite state machines (FSMs).

        8. A hackathon on designing graphical games with moving objects on LCD screen.

The hackathon participants present their games on FPGA board. A game should not use CPU cores, either external or synthesized, and should be synthesizable for ASIC
using Tiny Tapeout infrastructure, fitting into no more than 4 Tiny Tapeout tiles. We plan to order a chip manifactured on Skywater Fab for both student teams in Mexico and Armenia.





In both Mexico and Armenia we are going to use Gowin EDA toolchain for the exercises with a basic setup that consist 



Day 1. Morning. Introduction to digital design flow for FPGA. Exercises with combinational logic using buttons, LEDs and 7-segment displays.






This workshop proposal is prepared by Yuri Panchul and the Verilog Meetup community. It can be tuned to various audiences, including high-school students, college students, educators, or simply people with various backgrounds who want to understand the technology base for digital chip design and FPGA applications. The length of the workshop can vary from three hours to three days or even a week, if we are going into details. A three-hour version would probably include just exercises with Gowin/Tang FPGA boards and graphics on an LCD screen, but a three-day version may include the whole day with a discussion of ASIC implementation using TinyTapeout and eFabless.

You can join a Google group <a href="https://groups.google.com/g/verilog-meetup-maker-faire">Verilog Meetup on Maker Faire</a> to get notifications about the workshop events, as well as a Google group <a href="https://groups.google.com/g/meetsv">SystemVerilog Meetups in Silicon Valley</a> for the <a href="https://www.meetup.com/hackerdojo/events/303889717">weekly meetings</a> at <a href="https://hackerdojo.org/">Hacker Dojo</a> in Mountain View, California.
<h2>Introduction</h2>
“Verilog, ASIC, FPGA” are not exactly household words, but they are at the very heart of the microelectronics revolution that brought us smartphones, fast internet, 3D graphics and AI acceleration. For the last 40 years, the Verilog hardware description language has been used to design the logic of chips. An ASIC (Application Specific Integrated Circuit) is the chip itself, and an FPGA (Field Programmable Gate Array) is a chip used to prototype an ASIC. During the workshop, we are going to expose the students to the following concepts:
<ol>
 	<li>The difference between programming and logic design using hardware description languages.</li>
 	<li>The design flow for the fixed chips made in a semiconductor foundry (RTL-to-GDSII) and the flow used for reconfigurable logic, Field-Programmable Gate Arrays (FPGAs).</li>
 	<li>The concepts of combinational and sequential logic, logic gates and-or-not and the state elements, D-flip-flops. How to express an algorithm using these primitives. The influence of physical delays on the design organization.</li>
 	<li>The idea of CPU: a circuit that runs the programs. The concept of architecture (the instruction set, an interface to software) and microarchitecture (the hardware organization).</li>
 	<li>How the design process in electronic companies is organized: the team, the chip design cycle and the tools.</li>
</ol>
<a href="https://verilog-meetup.com/wp-content/uploads/2024/10/poster.png"><img class="alignleft size-full wp-image-716" src="https://verilog-meetup.com/wp-content/uploads/2024/10/poster.png" alt="" width="1920" height="1080" /></a>
<h2>Setup</h2>
The learning process will be centered around practical exercises with FPGA boards. We can support more than 35 boards with Verilog Meetup examples, however, for the proposed seminar, we plan to use the setup that includes a Tang Nano 9K board with Gowin FPGA, a 4-inch LCD screen, a TM1638-based interface module and five female-female jumper wires. We will use Gowin EDA software running under Windows or Linux. We will provide the boards and bootable SSD drives with Linux. The participants need to bring their laptops or can use computers provided by the hosting university.

The instructions on how to setup Gowin EDA software, assemble a board set and run the examples:

<a href="https://verilog-meetup.com/wp-content/uploads/2024/10/GOWIN-EDA-Quick-Start-Guide-V6.pdf">GOWIN EDA Quick Start Guide V6</a>

<a href="https://verilog-meetup.com/wp-content/uploads/2024/10/TangNano9KBoardSetupV3.pdf">TangNano9KBoardSetupV3</a>

<a href="https://verilog-meetup.com/wp-content/uploads/2024/10/Tang-Nano-9K-Synthesis-and-Configuration-V6.pdf">Tang Nano 9K Synthesis and Configuration V6</a>

&nbsp;

<a href="https://verilog-meetup.com/wp-content/uploads/2024/10/board2000-rotated.jpg"><img class="size-large wp-image-717 alignnone" src="https://verilog-meetup.com/wp-content/uploads/2024/10/board2000-1280x1630.jpg" alt="" width="819" height="1043" /></a>
<h2>Activities</h2>
<ol>
 	<li>Basic exercises with buttons, LEDs and a seven-segment display: and/or/not/xor gates, multiplexors, counters and shift registers. The participants will change the design in SystemVerilog, synthesize the code, upload the FPGA board configuration and see how their changes affect the behavior of the design on the board.</li>
 	<li>Drawing static and moving pictures on a color LCD screen or an HDMI display by changing the SystemVerilog code that computes a color RGB (red/green/blue) using X and y coordinates provided by an LCD or HDMI controller.</li>
 	<li>Watching demos of FPGAs used to recognize music notes, generate sounds and control the ultrasound distance measuring device.</li>
</ol>
https://youtube.com/shorts/duuduEN7s4g?si=Zb-cJFN3_RypHgtZ
<h2>Schedule</h2>
The general schedule for a one-day seminar:

10.00-11.00. A lecture on the concepts of hardware description languages and register transfer design methodology.

11.00-12.00. Exercises with FPGA boards and combinational logic using buttons, LEDs and seven-segment display: logic gates, multiplexor, displaying letters on 7-segment display at different positions.

12.00-13.00. Exercises with FPGA boards and combinational logic using an LCD screen or HDMI monitor to display graphics: rectangles, ellipses, a parabola, a hyperbola, and repetitive patterns.

13.00-14.00. Lunch break

14.00-15.00. Sequential logic. A short lecture following with the exercises with the FPGA boards using buttons, LEDs and a seven-segment display: D-flip-flop, counter and shift register.

15.00-16.00. Creating moving pictures on a graphics screen using sequential logic. We modify the graphical examples with created earlier by adding counters and control with keys. The goal is to create a simple graphical game.

16.00-17.00. Conclusion. Demos of sound recognition, sound generation, discussion of RISC-V processor design and jobs in the electronic industry.

<a href="https://verilog-meetup.com/wp-content/uploads/2024/10/with_kids.jpg"><img class="size-medium wp-image-712 alignnone" src="https://verilog-meetup.com/wp-content/uploads/2024/10/with_kids-900x600.jpg" alt="" width="900" height="600" /></a>
<h2>Extensions</h2>
There are three directions we can extend the seminar:
<ol>
 	<li>Discussing CPU: the idea of architecture and microarchitecture. Computer architecture is the software side of the CPU: the instruction set and assembly programming. Processor microarchitecture is the hardware side: the structure of the CPU pipeline and the computational blocks.</li>
 	<li>Discussing microarchitectural problems the intern candidates get during interviews in electronic companies.</li>
 	<li>A step-by-step instruction on implementing the design in ASIC using TinyTapeout infrastructure and eFabless partnership with Skywater silicon foundry. This is an affordable way for a group of students to put their ideas into working silicon.</li>
</ol>
In addition to this workshop proposal, we are working on a hackathon proposal in which the participants prototype graphical games on Gowin FPGA boards, present them to a panel of judges and gamers, and finally implement the games in ASIC using TinyTapeout and eFabless. The games will be primarily judged on how cool they are; however they must pass all the technical criteria, including the absence of verilator lint warnings and no negative slack in static timing analysis for both FPGA and ASIC implementation. We also intend to restrict the games in size (like up to 4 TinyTapeout tiles) and prohibit the use of CPU cores in the design (otherwise, the competition will be dominated by retrocomputing fans bringing back to life their favorite games from the 1980s). The focus of the competition should be on how much fun you can get from clever hardware design rather than from software (which already has a lot of competitions).

<a href="https://verilog-meetup.com/wp-content/uploads/2024/10/efabless_2000.jpg"><img class="alignleft size-medium wp-image-709" src="https://verilog-meetup.com/wp-content/uploads/2024/10/efabless_2000-900x675.jpg" alt="" width="900" height="675" /></a>