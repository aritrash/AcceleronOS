# AcceleronOS

## A 16-bit x86 Operating System Kernel

AcceleronOS is a simple, command-line interface (CLI) based operating system kernel built from scratch in Assembly (NASM) for the 16-bit x86 architecture. This project serves as a foundational layer for understanding low-level computing, boot processes, and basic disk I/O.

---

## Version v1.0: CLI Foundation Release

This milestone establishes the stable command-line interface and the foundational routines necessary for future filesystem integration.

### Features

* **Core CLI Interface:** A robust command loop that accepts user input, handles backspace, and executes commands.
* **Essential Commands:** Implemented commands for system information and interaction:
    * `clr`: Clears the terminal screen.
    * `ver`: Displays the kernel version and repository information.
    * `help`: Displays available commands.
* **16-bit Kernel:** The entire kernel is built to run in the $0x1000$ memory segment, utilizing BIOS interrupts for I/O and disk access.
* **Disk I/O Foundation:** Includes the `read_sector` utility with LBA-to-CHS translation, ready for data retrieval.
* **FAT Initialization Stub:** Contains the complete structure and variable definitions for parsing the FAT Boot Sector (LBA 0).

### Build Requirements

To build and run AcceleronOS, you need the following tools installed on your system:

1.  **NASM (Netwide Assembler):** Version 2.xx or later.
2.  **GNU Make:** For automated building of the floppy image.
3.  **dd:** A utility for low-level data conversion and copying (standard on most Unix-like systems, available via MSYS/Cygwin on Windows).
4.  **QEMU (Quick EMUlator):** For running and testing the kernel.

### Building and Running

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/aritrash/AcceleronOS
    cd AcceleronOS
    ```

2.  **Build the floppy image:**
    The `Makefile` compiles the `boot.asm` (512 bytes) and `kernel.asm` (2048 bytes / 4 sectors) and combines them into `floppy.img`.
    ```bash
    make
    ```

3.  **Run in QEMU:**
    The `make run` command launches QEMU, booting from the generated floppy image.
    ```bash
    make run
    ```
    To stop QEMU, press `Ctrl+A` then `X`.

---

## Architecture and Memory Layout 

The kernel uses a standard floppy boot sequence:

| Component | Location (Physical Address) | Size (Sectors) | Purpose |
| :--- | :--- | :--- | :--- |
| **BIOS** | > 0xF0000 | N/A | Provides `INT 10h` (Video) and `INT 13h` (Disk) services. |
| **Boot Sector** | 0x7C00 | 1 | Loads the kernel, sets up initial segments, and jumps to 0x1000:0x0000. |
| **Kernel Code/Data** | 0x10000 ($0x1000:0x0000$) | 4 | Executes the main CLI logic and low-level routines. |

The kernel uses the $0x1000$ segment for code, data, and its stack ($0x1000:0xFFFE$).

---

## Copyright and Licensing

AcceleronOS is provided under the terms of the **MIT License**.

**Copyright (C) Asta Epsilon Group, 2025**

See the `LICENSE` file for more details.
