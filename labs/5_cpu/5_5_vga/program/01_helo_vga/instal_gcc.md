# Installing GCC Compiler for RISC-V Cross Compilation

In order to properly configure the build environment, it is important to install the GCC compiler in specific locations based on the operating system being used.
# Toolchain - xPack GNU RISC-V Embedded GCC is:
https://xpack-dev-tools.github.io/riscv-none-elf-gcc-xpack/

# You can download latest release from direct url:
https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases

## Windows (MinGW or MSYS2 Environment)

When working within a Windows-based development environment like MinGW or MSYS2, install the GCC compiler to the following path:
```/c/opt/riscv/bin/```

The full paths to executable files would then look like this:

- **Linker**: `/c/opt/riscv/bin/riscv-none-elf-gcc`
- **Compiler**: `/c/opt/riscv/bin/riscv-none-elf-gcc`
- **Object Copy Tool**: `/c/opt/riscv/bin/riscv-none-elf-objcopy`

## Linux/MacOS (Unix-Like Operating Systems)

For Linux or MacOS environments, install the GCC compiler to the following location:
```/opt/riscv/bin/```
Thus, the complete paths are:

- **Linker**: `/opt/riscv/bin/riscv-none-elf-gcc`
- **Compiler**: `/opt/riscv/bin/riscv-none-elf-gcc`
- **Object Copy Tool**: `/opt/riscv/bin/riscv-none-elf-objcopy`

Following these recommendations ensures proper functioning of cross-compilation tools regardless of the operating system used.


# Installation of the GCC Compiler for RISC-V Architecture in Windows

## Requirements
Operating System: Windows
Archive file with compiler tools (xpack-riscv-none-elf-gcc-15.2.0-1-win32-x64.zip)

# Installation Instructions
Follow these steps to install the GCC toolchain for the RISC-V architecture in Windows OS:

## Step 1: Create Target Directory
Open a command prompt window (cmd) and run this command to check if the directory C:\opt exists. If it doesn't exist, it will be created automatically:

**CMD**
```if not exist "C:\opt\" mkdir "C:\opt"```

## Step 2: Extract Archive Contents
Use PowerShell to extract the contents of the archive **(xpack-riscv-none-elf-gcc-15.2.0-1-win32-x64.zip)** into the target directory **C:\opt:**

**CMD**
```powershell Expand-Archive -Path 'xpack-riscv-none-elf-gcc-15.2.0-1-win32-x64.zip' -DestinationPath 'C:\opt'```
Or use 7zip or another archiver from your computer

Rename destination directory to riscv  - full path shoul be **/c/opt/riscv**

## Step 3: Set Environment Variables (Optional)
To make the compiler accessible from any location, you can add its binary path to your system's PATH environment variable:

Open Control Panel ? System ? Advanced System Settings ? Environment Variables.
Edit the value of the PATH variable by adding the following path:
```C:\opt\riscv\bin```

## Conclusion
Your GCC toolchain for RISC-V is now installed and ready to use!