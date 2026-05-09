# UART Peripheral Diagrams

This folder contains all block diagrams for the UART peripheral implementation, organized by format for easier viewing and maintenance.

## Diagram Files

### Mermaid Diagrams
**File**: [mermaid_diagrams.md](mermaid_diagrams.md)
- Interactive, zoomable diagrams that render beautifully in GitHub and VS Code
- Best for: Understanding high-level architecture and dataflow
- Requires: Mermaid preview extension or GitHub rendering

**Contents**:
1. Top-Level System Architecture
2. Baud Rate Generator Block Diagram
3. TX Module State Machine & Block Diagram  
4. RX Module State Machine & Block Diagram
5. Register Interface Memory Map
6. Transaction Sequence Diagrams (Write/Read)
7. Module Hierarchy Tree

### ASCII Art Diagrams
**File**: [ascii_diagrams.md](ascii_diagrams.md)
- Text-based diagrams that work in any text editor
- Best for: Quick reference, offline viewing, printing
- Requires: Nothing - pure text!

**Contents**:
1. Top-Level System Architecture
2. Baud Rate Generator with detailed logic
3. TX Module with state machine and shift register
4. RX Module with oversampling details
5. Register Interface with complete memory map
6. Signal Flow for CPU transactions
7. Timing Diagrams for UART frames
8. Module Hierarchy Tree

### Timing Diagrams
**File**: [timing_diagrams.md](timing_diagrams.md)
- Waveform representations showing signal transitions
- Best for: Understanding timing relationships and protocol details
- Includes both ASCII waveforms and descriptions

**Contents**:
1. Complete UART transmission timing (8N1 format)
2. Baud rate clock generation
3. TX state transitions
4. RX oversampling and bit detection
5. CPU read/write transaction timing
6. Interrupt timing

## Quick Reference

| Need to understand... | Use this diagram |
|-----------------------|------------------|
| Overall system connection | Top-Level Architecture (both formats) |
| How baud rate is generated | Baud Rate Generator |
| How data is transmitted | TX Module diagrams |
| How data is received | RX Module diagrams |
| Register addresses and fields | Register Interface diagrams |
| Timing between signals | Timing Diagrams |
| Module organization | Module Hierarchy |
| Transaction flow | Sequence Diagrams (Mermaid) |

## Usage Tips

1. **For Initial Learning**: Start with Mermaid diagrams for visual clarity
2. **For Implementation**: Use ASCII diagrams as reference while coding
3. **For Debugging Timing**: Check timing diagrams for expected waveforms
4. **For Register Programming**: Refer to Register Interface memory map

## Design Decisions Summary

- **Baud Rate**: Configurable (9600, 19200, 38400, 115200 bps)
- **Frame Format**: Fixed 8N1 (8 data bits, no parity, 1 stop bit)
- **Oversampling**: 16x for RX (robust noise immunity)
- **FIFO**: None (future enhancement)
- **Flow Control**: None (simple design)
- **Interrupt**: Single RX data ready interrupt
- **System Clock**: 70 MHz (TinyQV core frequency)
- **Interface**: 32-bit register-based (TinyQV peripheral bus)

---

Return to [main documentation](../BLOCK_DIAGRAMS.md) for index of all diagrams.
