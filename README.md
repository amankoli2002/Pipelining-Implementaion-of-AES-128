# Pipelined AES-128 Encryption on FPGA

## Overview
This project presents the design and implementation of a **fully pipelined AES-128 encryption** using **Verilog HDL**, for deployment on a **PYNQ FPGA board**. The design achieves **high throughput and timing closure at 200 MHz** by introducing round-level pipelining and a sequential key expansion.

The work was carried out as part of the **CS666: Hardware Security for IoT** course at **IIT Kanpur**.

---

## Objectives
- Implement a correct **AES-128 encryption code** in hardware  
- Eliminate long combinational paths present in baseline AES designs  
- Achieve **one 128-bit ciphertext output per clock cycle** after pipeline fill  
- Optimize for **high frequency, low latency, and efficient FPGA resource usage**

---

## Architecture Overview
- **Round-based pipelined architecture** (10 pipeline stages)
- Each pipeline stage corresponds to **one AES round**
- Operations per round:
  - SubBytes
  - ShiftRows
  - MixColumns (skipped in final round)
  - AddRoundKey
- **Key expansion is pipelined** and overlaps with encryption
- Initial AddRoundKey performed before pipeline entry

After an initial latency of 10 cycles, the design outputs **one encrypted block per clock cycle**.

---

## Module Description

### 1. AES_Encrypt_Pipelined (Top Module)
- Manages pipeline registers:
  - `state_reg[0:10]`
  - `round_key_reg[0:10]`
  - `valid_reg[0:10]`
- Performs initial AddRoundKey
- Instantiates 10 AES round modules using a generate block
- Outputs ciphertext and done signal

### 2. AES_Round
- Combinational logic between pipeline stages
- Implements:
  - SubBytes
  - ShiftRows
  - MixColumns (conditionally bypassed)
  - AddRoundKey

### 3. AddRoundKey
- Performs XOR of state with expanded key
- Triggers key expansion for it own round

### 4. PipelinedKeyExpansionRound
- Generates one round key per clock cycle
- Converts combinational key expansion into a sequential process
- Reduces critical path delay significantly

### 5. AES Primitives
- SubBytes (S-box using SubTable)
- ShiftRows
- MixColumns

---

## Pipeline Operation (Cycle-Level Summary)

- **Cycle 0**: Input loaded, initial AddRoundKey performed
- **Cycles 1–9**: AES rounds 1 to 9 executed in pipeline
- **Cycle 10**: Final AES round (MixColumns skipped)
- **Cycle 11**: Ciphertext output becomes valid

---

## Experimental Setup
- Toolchain: **Xilinx Vivado**
- Target platform: **PYNQ FPGA**

### Baseline Design
- Fully combinational AES
- Operated at **10 MHz**
- Long critical path due to key expansion

### Pipelined Design
- Fully pipelined AES rounds
- Sequential key expansion
- Meets timing at **200 MHz**

---

## Results

| Metric | Baseline AES | Pipelined AES |
|------|-------------|---------------|
| Frequency | 10 MHz | 200 MHz |
| Throughput | 0.11 Gbps | **25.6 Gbps** |
| Latency (cycles) | 11 | 11 |
| Slice LUTs | 3217 | 8495 |
| Speedup | – | **20×** |

