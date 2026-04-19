# Syntax Virtual Machine (SVM)

Syntax VM is a low-level, stack-based runtime environment developed in Pascal. It is designed to execute specialized binary instructions and provides a native bridge for direct interaction with the host operating system's dynamic libraries.

## System Architecture

The VM operates on a custom execution model that mimics physical CPU cycles, consisting of a Fetch-Decode-Execute loop.

* **Stack-Based Execution:** All operations are performed on a Last-In-First-Out (LIFO) stack. This includes arithmetic calculations, logic operations, and function argument passing.
* **Bytecode Engine:** Executes pre-compiled `.syprg` files. These files contain a header, a constant pool for strings/integers, and a code segment containing opcodes.
* **Binary Specification:** The system utilizes a proprietary binary format starting with a fixed 8-byte magic number signature followed by versioning and segment data.

## Features and Capabilities

### Native Bridge (FFI)
The core functionality of SVM is its Foreign Function Interface. It allows the bytecode to load external Windows DLLs (such as `user32.dll` or `kernel32.dll`) and invoke their exported functions using standard calling conventions (stdcall).

### Memory Management
The VM implements a managed memory area including:
* **Global Slots:** Persistent storage slots for holding data handles across different execution blocks.
* **Dynamic Heap:** Support for memory allocation and deallocation during runtime.
* **String Pooling:** Handling of UTF-8 encoded strings stored in a dedicated constant segment.

### Instruction Set
The instruction set includes:
* **Data Flow:** Pushing and popping of immediate integers, strings, and floats.
* **Control Flow:** Conditional and unconditional jump instructions for loop and branch management.
* **FFI Operations:** DLL loading, function handle retrieval, and native call execution.
* **I/O Operations:** Standard console output for debugging and feedback.

## File Structure

| Extension | Type | Description |
| :--- | :--- | :--- |
| `.syasm` | Source | Human-readable assembly source code containing mnemonics. |
| `.syprg` | Binary | Compiled bytecode optimized for SVM execution. |

## Execution Flow

The system consists of two primary components:
1. **The Assembler:** Translates `.syasm` mnemonics into the `.syprg` binary format, resolving labels and constant pool offsets.
2. **The Runtime:** The virtual machine that loads the binary, initializes the stack, and manages the execution pointer and native bridge.
