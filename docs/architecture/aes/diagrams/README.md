# AES-128 Encryption Engine Diagrams

This folder contains all block diagrams for the AES-128 encryption engine implementation, organized by format for easier viewing and maintenance.

## Diagram Files

### Mermaid Diagrams
**File**: [mermaid_diagrams.md](mermaid_diagrams.md)
- Interactive, zoomable diagrams that render beautifully in GitHub and VS Code
- Best for: Understanding high-level architecture and transformation flow
- Requires: Mermaid preview extension or GitHub rendering

**Contents**:
1. AES-128 Top-Level Architecture
2. Encryption Round Function Flowchart
3. Key Expansion Block Diagram
4. SubBytes (S-Box) Transformation
5. ShiftRows Transformation
6. MixColumns Transformation
7. AddRoundKey Operation
8. Integration with UART TX/RX
9. Control FSM State Machine

### ASCII Art Diagrams
**File**: [ascii_diagrams.md](ascii_diagrams.md)
- Text-based diagrams that work in any text editor
- Best for: Quick reference, offline viewing, printing
- Requires: Nothing - pure text!

**Contents**:
1. AES-128 Top-Level Block Diagram
2. Encryption Round Function Detail
3. Key Expansion Logic
4. S-Box Lookup Table Structure
5. ShiftRows Byte Positions
6. MixColumns Matrix Multiplication
7. AddRoundKey XOR Operation
8. State Matrix Organization (4x4 bytes)
9. Integration with TX FIFO
10. Control Signals and FSM States

### Timing Diagrams
**File**: [timing_diagrams.md](timing_diagrams.md)
- Waveform representations showing signal transitions
- Best for: Understanding timing relationships and encryption cycles
- Includes both ASCII waveforms and descriptions

**Contents**:
1. Complete encryption cycle timing (~24 clock cycles)
2. Round function execution timing
3. Key expansion timing
4. Integration with UART TX timing
5. CPU register write/read timing
6. Encryption trigger and completion signals

## Quick Reference

| Need to understand... | Use this diagram |
|-----------------------|------------------|
| Overall AES architecture | Top-Level Architecture (both formats) |
| How each round works | Round Function diagrams |
| How keys are generated | Key Expansion |
| SubBytes transformation | S-Box diagrams |
| ShiftRows transformation | Byte Position diagrams |
| MixColumns transformation | Matrix Multiplication diagrams |
| How AES integrates with UART | Integration diagrams |
| Timing for encryption | Timing Diagrams |
| Control flow | FSM State Machine |

## Usage Tips

1. **For Initial Learning**: Start with Mermaid diagrams for visual clarity
2. **For Implementation**: Use ASCII diagrams as reference while coding
3. **For Debugging**: Check timing diagrams for expected cycle counts
4. **For Integration**: Refer to UART integration diagrams

## Design Decisions Summary

- **Algorithm**: AES-128 (10 rounds)
- **Key Size**: 128 bits (16 bytes)
- **Block Size**: 128 bits (16 bytes)
- **Architecture**: Iterative (reuses hardware across rounds)
- **Cycles/Block**: ~24 cycles (key expansion + rounds + overhead)
- **S-Box**: ROM lookup table (256 bytes)
- **Integration**: Automatic encryption of 16-byte blocks from TX FIFO
- **Trigger**: Hardware-controlled when FIFO accumulates 16 bytes
- **System Clock**: 70 MHz (TinyQV core frequency)
- **Throughput**: ~2.9 Mbps encrypted data (@70MHz, 24 cycles/block)

## Performance Characteristics

- **Area**: ~2000 cells estimated (S-Box ROM, state registers, control logic)
- **Latency**: 24 clock cycles per 128-bit block
- **Throughput**: 367 MB/s @ 70 MHz
- **Power**: Low (mostly combinational logic, minimal toggling)

---

Return to [main documentation](../AES_FUNDAMENTALS.md) for algorithm details.
