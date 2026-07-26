/* -----------------------------------------------------------------------------
* Project Name   : Architectures of Processor Systems (APS) lab work
* Organization   : National Research University of Electronic Technology (MIET)
* Department     : Institute of Microdevices and Control Systems
* Author(s)      : Andrei Solodovnikov
* Email(s)       : hepoh@org.miet.ru

See https://github.com/MPSU/APS/blob/master/LICENSE file for licensing details.
* ------------------------------------------------------------------------------
*/
package memory_pkg;

  localparam INSTR_MEM_SIZE_BYTES = 32'h800;
  localparam INSTR_MEM_SIZE_WORDS = INSTR_MEM_SIZE_BYTES / 4;
  localparam INSTR_MEM_FILE_NAME  = "program.hex";
  localparam DATA_MEM_SIZE_BYTES  = 32'h800;
  localparam DATA_MEM_SIZE_WORDS  = DATA_MEM_SIZE_BYTES / 4;
  localparam DATA_MEM_FILE_NAME   = "";
endpackage
