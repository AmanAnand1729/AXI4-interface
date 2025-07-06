# AXI4-interface
RTL Design of  AMBA AXI4 Master–Slave interface with burst support and self-verifying testbench

# AXI4 Master–Slave Interface (Verilog)

This repository provides a synthesizable Verilog implementation of a **fully handshake-compliant AMBA AXI4 Master and Slave**, connected through a top-level module and verified by a comprehensive self-checking testbench.  
The design demonstrates the standard **AXI4 protocol** with proper channel handshakes, burst transactions, transaction IDs, and debug visibility for learning and prototyping purposes.

---

## 📌 Overview

**Key features:**
- ✅ Complete **AXI4 5-channel interface**: Write Address (`AW`), Write Data (`W`), Write Response (`B`), Read Address (`AR`), and Read Data (`R`).
- ✅ Master FSM supports single burst write and read operations.
- ✅ Slave module implements an internal RAM with valid AXI read/write behavior.
- ✅ Fully decoupled handshaking (`VALID`/`READY`) for each channel.
- ✅ Configurable burst length (`AWLEN`/`ARLEN`), burst type (`INCR`), transfer size (`AWSIZE`/`ARSIZE`), and transaction IDs.
- ✅ Simulation testbench verifies correct data flow with `$display` outputs for debugging.
- ✅ Synthesizable for FPGA or ASIC integration.

---

## ⚡ FPGA & ASIC Ready

This RTL is written in standard Verilog-2001 and is fully synthesizable for both FPGA and ASIC flows.  
The AXI4 Master can be connected to a processor core or custom user logic, while the Slave module can interface with on-chip or external memory, or be extended as a base for additional AXI4 peripherals.

---

## 📚 Reference

- **Specification:** [ARM AMBA AXI4 Specification (IHI 0022)](https://developer.arm.com/documentation/ihi0022/latest)  
  This implementation adheres to the standard AXI4 channel architecture and handshake protocol, making it suitable for study, verification, and integration in larger SoC designs.
