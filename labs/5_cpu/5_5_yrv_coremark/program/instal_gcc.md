#Installation of the GCC Compiler for RISC-V Architecture

Requirements
Operating System: Windows
Archive file with compiler tools (xpack-riscv-none-elf-gcc-15.2.0-1-win32-x64.zip)
Installation Instructions
Follow these steps to install the GCC toolchain for the RISC-V architecture:

Step 1: Create Target Directory
Open a command prompt window (cmd) and run this command to check if the directory C:\opt exists. If it doesn't exist, it will be created automatically:

CMD
if not exist "C:\opt\" mkdir "C:\opt"

Step 2: Extract Archive Contents
Use PowerShell to extract the contents of the archive xpack-riscv-none-elf-gcc-15.2.0-1-win32-x64.zip into the target directory C:\opt:

CMD
powershell Expand-Archive -Path 'xpack-riscv-none-elf-gcc-15.2.0-1-win32-x64.zip' -DestinationPath 'C:\opt'

Rename destination directory to riscv (full path shoul be /c/opt/riscv

Step 3: Set Environment Variables (Optional)
To make the compiler accessible from any location, you can add its binary path to your system's PATH environment variable:

Open Control Panel ? System ? Advanced System Settings ? Environment Variables.
Edit the value of the PATH variable by adding the following path:
C:\opt\riscv\bin

Conclusion
Your GCC toolchain for RISC-V is now installed and ready to use!