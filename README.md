# AcceleronOS - A Bare-Metal Command-Line Operating System

## Project Overview

**AcceleronOS** is a minimal, monolithic kernel Operating System designed and implemented entirely in **NASM x86-16 bit Assembly language**. It currently runs as a floppy-disk image on virtual machines (QEMU/VirtualBox) and provides a stable, interactive Command-Line Interface (CLI) environment.

This project was built from scratch, including a custom bootloader and kernel, and serves as a hands-on exploration of low-level systems architecture, memory management, and BIOS/Hardware interaction.

| Core Components | Technology Stack | Status |
| :--- | :--- | :--- |
| **Bootloader** | NASM Assembly, BIOS Interrupts (`INT 13h`) | Stable (Loads Kernel) |
| **Kernel** | NASM Assembly, BIOS Interrupts (`INT 10h`, `INT 16h`) | Stable (CLI Shell) |
| **Toolchain** | NASM, GNU `make`, `dd`, QEMU | Operational |

## Key Technical Features

This system is built without the use of high-level languages (like C) or external libraries, forcing direct interaction with the underlying hardware via BIOS calls.

### 1. Custom Bootloader (`boot.asm`)

The 512-byte boot sector performs all necessary initialization steps:

* **16-bit Real Mode Initialization:** Sets up the essential segment registers (`DS`, `ES`, `SS`) and Stack Pointer (`SP`).
* **Kernel Loading:** Utilizes the BIOS disk services (`INT 13h`) with Cylinder-Head-Sector (CHS) addressing to load **one 512-byte sector** (the kernel) from the floppy image.
* **Target Memory Map:** The kernel is loaded into **physical memory address `0x10000`** (Segment `0x1000`, Offset `0x0000`). 
* **Control Transfer:** Performs a **far jump** to `0x1000:0x0000` to execute the kernel.

### 2. Monolithic Kernel (`kernel.asm`)

The core kernel handles system interaction and the user environment:

* **CLI Implementation:** Provides an interactive shell prompt (`root@acceleron / >`).
* **Keyboard I/O Handling:** Uses the BIOS keyboard service (`INT 16h`) to read key presses without polling.
* **Echo and Backspace Logic:** Implements fundamental text editing features:
    * Prints (echoes) printable characters to the screen immediately using `INT 10h`.
    * Handles the **Backspace (ASCII 8)** character by erasing the character on the screen and correctly moving the input buffer pointer (`DI`).
* **Command Buffer:** Stores typed input in a 128-byte `input_buffer` and terminates it with a `NULL` byte (0x00) upon pressing Enter.

### 3. Build & Run Environment

The included `Makefile` automates the entire development workflow:

* **Assembly:** Uses `nasm` to compile `boot.asm` and `kernel.asm` into raw binaries.
* **Image Creation:** Employs the `dd` utility to construct a standard **1.44MB floppy image (`floppy.img`)**.
    * The 512-byte `boot.bin` is placed in **Sector 1** (`count=1`).
    * The 512-byte `kernel.bin` is placed in **Sector 2** (`seek=1`).
* **Virtualization:** Provides a clean `run` target using `qemu-system-i386` for immediate testing and iteration.

## Getting Started

### Prerequisites

1.  **NASM (Netwide Assembler):** Required for compiling the assembly source code.
2.  **GNU Make:** Required for the build automation.
3.  **QEMU:** Required for virtualization and testing the OS image.
4.  **`dd` utility:** Required for building the disk image (typically pre-installed on Linux/macOS).

### Build & Run

1.  **Clone the Repository:**
    ```bash
    git clone [https://github.com/aritrash/AcceleronOS.git](https://github.com/aritrash/AcceleronOS.git)
    cd AcceleronOS
    ```
    
2. **Install QEMU in terminal:**
   ```bash
   pacman -S mingw-w64-x86_64-qemu
   ```
   or for Debian packages
   ```bash
   sudo apt install qemu-system qemu-utils
   ```

3.  **Compile and Build the Floppy Image:**
    ```bash
    make all
    # This generates boot.bin, kernel.bin, and floppy.img
    ```

4.  **Run the OS in QEMU:**
    ```bash
    make run
    # QEMU will launch, and you will see the AcceleronOS prompt.
    ```

5.  **Clean up binaries:**
    ```bash
    make clean
    ```

## Version History (Releases)

* **v1.0.4 :** Implemented 'ver' for version information and GitHub link and 'help' for help
* **v1.0.3 :** Implemented 'clr' command via BIOS INT 10h. 
* **v1.0.2 :** Implemented stable keyboard input loop, backspace handling, and echo functionality to complete the basic Command Line Interface (CLI).
* **v1.0.1 (Initial Release):** Initial successful boot. Custom bootloader implemented for 16-bit real mode setup and successful kernel jump. Displays initial welcome messages.

## Future Development

* **Command Parsing:** Implement basic command interpretation (e.g., `help`, `clear`).
* **Filesystem Management:** Develop routines for reading and writing data to the disk, starting with a simple FAT12 implementation. 
* **Protected Mode:** Transition the OS from 16-bit Real Mode to 32-bit Protected Mode for access to more memory and advanced features.

---
*(C) Asta Epsilon Group, 2025. This project is provided for educational purposes.*
