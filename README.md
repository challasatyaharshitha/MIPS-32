# MIPS-32
# 32-bit Multi-cycle MIPS Processor in Verilog HDL

## Overview

This project implements a **32-bit Multi-cycle MIPS Processor** using **Verilog HDL**. The processor executes instructions over multiple clock cycles using a five-stage datapath consisting of Instruction Fetch, Instruction Decode, Execute, Memory Access, and Write Back. A testbench is included to verify the functionality through simulation.

---

## Features

- 32-bit MIPS Processor
- Multi-cycle datapath architecture
- Verilog HDL implementation
- Five-stage execution flow
- Register File and ALU
- Instruction and Data Memory
- Branch instruction support
- Load and Store instructions
- Arithmetic and Logical operations
- Simulation using Icarus Verilog and GTKWave

---

## Supported Instructions

| Category | Instructions |
|----------|--------------|
| Arithmetic | ADD, SUB, MUL |
| Logical | AND, OR |
| Comparison | SLT |
| Immediate | ADDI, SUBI, SLTI |
| Memory | LW, SW |
| Branch | BEQZ, BNEQZ |
| Control | HLT |

---

## Processor Architecture

The processor follows a multi-cycle execution model with the following stages:

1. Instruction Fetch (IF)
2. Instruction Decode (ID)
3. Execute (EX)
4. Memory Access (MEM)
5. Write Back (WB)

---
