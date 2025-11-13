# AcceleronOS - A Bare-Metal Monolithic Kernel OS

## Project Status: v1.0.4 (Stable Release)

AcceleronOS is a hobbyist Operating System project built entirely from the ground up in **NASM x86-16 bit Assembly language**. It functions as a minimal, monolithic kernel running in **Real Mode** on a virtualized floppy disk.

This project serves as a low-level educational exploration into custom bootloaders, kernel command processing, and BIOS-level hardware interaction.

| Component | Architecture | Toolchain | State |
| :--- | :--- | :--- | :--- |
| **Kernel Type** | Monolithic (16-bit) | NASM | Stable |
| **Boot Standard** | BIOS/Floppy Disk Boot Sector | `dd` Utility | Stable (Loads 2 sectors) |
| **Primary I/O** | BIOS Interrupts (`INT 10h`, `INT 16h`) | QEMU | Operational |
| **Filesystem** | Custom FAT16/32 Driver | Planned for v1.0.5 | In Development |

---

## Key Technical Features

### 1. Custom Bootloader (`boot.asm`)

The boot sector resides at `0x7C00` and executes the following core tasks:

* **Mode Initialization:** Sets up the 16-bit Real Mode environment by initializing segment registers (`DS`, `ES`, `SS`) and the Stack Pointer (`SP`).
* **Kernel Loading:** Uses the BIOS disk service **`INT 13h, AH=02h`** with CHS addressing to load the kernel.
    * **Sector Count:** The bootloader is configured to read **2 sectors (1024 bytes)** to accommodate the growing kernel size.
    * **Target Address:** The kernel is loaded into physical memory starting at **`0x10000`** (Segment `0x1000`, Offset `0x0000`). 
* **Control Transfer:** Performs a **far jump** to the kernel entry point (`0x1000:0x0000`).

### 2. Kernel Command-Line Interface (CLI) (`kernel.asm`)

The kernel's primary function is to provide an interactive shell environment via direct BIOS interaction.

* **Input Handling:** Uses `INT 16h` for keyboard input, featuring robust **Echo** and **Backspace** logic that manages the screen and the input buffer.
* **Command Parsing:** Implemented a core string comparison utility (`strequ`) to match user input against defined commands upon pressing Enter.

| Command | Description | Implementation Detail |
| :--- | :--- | :--- |
| **`clr`** | Clears the entire terminal screen. | Uses `INT 10h, AH=06h` (Scroll Window Up) for fast screen clearing. |
| **`ver`** | Displays the current kernel version and build source. | Prints a predefined multi-line string. |
| **`help`**| Displays a formatted list of all available commands. | Uses `CR` (13) and `LF` (10) control characters for multi-line output. |

---

## Build and Execution

The project uses a standard, automated development workflow via a GNU `Makefile`.

### Prerequisites Installation

* **NASM**, **GNU Make**, and **`dd`** are required for compilation.
* **QEMU** is required for the simplest virtualization environment.

| System | Command to Install QEMU |
| :--- | :--- |
| **Debian/Ubuntu (Debian-based)** | `sudo apt update && sudo apt install qemu-system-x86` |
| **Arch/Manjaro (Arch-based)** | `sudo pacman -S qemu` |

### Workflow Commands

1.  **Clone the Repository:**
    ```bash
    git clone [https://github.com/aritrash/AcceleronOS.git](https://github.com/aritrash/AcceleronOS.git)
    cd AcceleronOS
    ```

2.  **Build the Disk Image (`floppy.img`):**
    ```bash
    make all
    # Compiles boot.bin and kernel.bin, then stitches them into the floppy.img.
    ```

3.  **Run in QEMU (Recommended):**
    ```bash
    make run
    # Executes: qemu-system-i386 -fda floppy.img -boot a
    ```

### Running on Other VMs (VirtualBox / VMware)

You can run the generated `floppy.img` on other virtualization software by attaching it as a virtual floppy drive:

1.  **Build the image** using `make all`.
2.  **Create a new VM** (select "Other" or "MS-DOS" as the operating system type).
3.  **Configure Storage:** In the VM settings, find the Floppy Disk Controller/Drive option.
4.  **Attach Image:** Select "Choose/Create a Virtual Floppy Disk" and point it to your locally generated **`floppy.img`** file.
5.  **Start the VM** and ensure the boot order prioritizes the Floppy Drive.

### Clean up binaries

```bash
make clean
```

## Version History (Releases)

* **v1.0.4 (Current Release):** Implemented 'ver' for version information and GitHub link and 'help' for help
* **v1.0.3 :** Implemented 'clr' command via BIOS INT 10h. 
* **v1.0.2 :** Implemented stable keyboard input loop, backspace handling, and echo functionality to complete the basic Command Line Interface (CLI).
* **v1.0.1 (Initial Release):** Initial successful boot. Custom bootloader implemented for 16-bit real mode setup and successful kernel jump. Displays initial welcome messages.

## Future Development

* **Filesystem Management:** Develop routines for reading and writing data to the disk, starting with a simple FAT12 implementation. 
* **Protected Mode:** Transition the OS from 16-bit Real Mode to 32-bit Protected Mode for access to more memory and advanced features.

---
*(C) Asta Epsilon Group, 2025. This project is provided for educational purposes.*
