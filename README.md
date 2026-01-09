# I2C Master for M24C32 EEPROM (Verilog)

## Overview
This project implements a fully synthesizable **I2C Master controller** in Verilog to interface with the **M24C32 EEPROM** (4KB, 16-bit addressing).  
The design supports **single-byte read and write operations**, includes **proper I2C protocol sequencing**, and exposes **internal debug signals for ILA-based verification** on FPGA.

The module is designed for FPGA implementation (Vivado) with clean separation between control, data path, and physical I/O buffering.

---

## EEPROM Details
- Device: **M24C32**
- Memory Size: **4 KB**
- Addressing: **16-bit memory address (0x0000 – 0x0FFF)**
- I2C Address: `0x50` (7-bit, configurable)

---

## Features
- I2C Master compliant with standard I2C timing
- Supports:
  - EEPROM byte write
  - EEPROM random read (write address → repeated START → read)
- 16-bit memory address handling
- ACK/NACK detection with error flag
- Clean START, RESTART, and STOP generation
- Configurable clock divider for I2C speed (~400 kHz)
- **ILA-friendly debug signals**
- SDA implemented using **IOBUF (tri-state control)**

---

## Block Diagram
The following diagram shows the top-level architecture, including:
- I2C Master FSM
- Clock divider
- SDA IOBUF
- EEPROM interface

![Block Diagram](Docs/block_diagram.png)

---

## I2C Timing & Waveforms
Below is the simulated waveform showing a complete EEPROM transaction:
- START condition
- Slave address + R/W bit
- ACK cycles
- 16-bit memory address transfer
- Data phase
- STOP condition

![I2C Waveform](Docs/i2c_waveform.png)

---

## Top-Level Interface

### Clock & Reset
- `clk` : 100 MHz system clock
- `rst_n` : Active-low synchronous reset

### Control Signals
- `start_write` : Pulse to initiate EEPROM write
- `start_read`  : Pulse to initiate EEPROM read
- `slave_addr`  : 7-bit EEPROM I2C address
- `mem_addr`    : 16-bit EEPROM memory address
- `data_in`     : Data byte to write
- `data_out`    : Data byte read from EEPROM
- `busy`        : High during active I2C transaction
- `done`        : Pulsed when transaction completes
- `error`       : Set if NACK is detected

### I2C Physical Interface
- `scl` : I2C clock output
- `sda` : Bidirectional data line (connected via IOBUF)

---

## Internal Architecture

### Clock Generation
- System clock: **100 MHz**
- Target I2C clock: **~400 kHz**
- 4-phase timing per I2C bit (setup, sample, hold, transition)
- Clock divider parameterized using `CLKDIV`

---

### FSM States
The controller uses a **16-state FSM**, including:
- IDLE
- START
- SEND ADDRESS (Write / Read)
- ACK phases
- SEND MEMORY ADDRESS (High & Low)
- DATA WRITE / DATA READ
- RESTART (for read operation)
- STOP

This ensures strict compliance with EEPROM read/write timing requirements.

---

## Debug & ILA Signals
To enable on-chip debugging, key internal signals are exported:

- `debug_sda_out` – SDA driven by master
- `debug_sda_in`  – SDA sampled from bus
- `debug_sda_en`  – SDA direction control
- `debug_state`   – FSM state
- `debug_bit_cnt` – Bit counter
- `debug_shift_reg` – Shift register contents

These signals can be connected directly to **Vivado ILA** for real-time protocol analysis.

---

## Toolchain
- Language: **Verilog HDL**
- FPGA Tool: **Xilinx Vivado**
- Debug: **Integrated Logic Analyzer (ILA)**
- Target Clock: **100 MHz**

---

## How to Use
1. Instantiate the module in your top-level design
2. Connect `scl` and `sda` to external pins via **IOBUF**
3. Provide memory address and data
4. Pulse `start_write` or `start_read`
5. Monitor `busy`, `done`, and `error`

---

## Author
**Ramiksha C. Shetty**  
Electronics & Communication Engineering  
RTL / Digital Design Enthusiast
