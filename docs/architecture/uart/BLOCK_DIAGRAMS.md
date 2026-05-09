# UART Peripheral Block Diagrams

This document serves as the index for all UART peripheral diagrams, organized by format for easy navigation and better viewing experience.

---

## 📁 Diagram Organization

All diagrams have been organized into the [diagrams/](diagrams/) folder, separated by format to avoid rendering conflicts and provide the best viewing experience for each type.

### Available Diagram Formats

1. **[Mermaid Diagrams](diagrams/mermaid_diagrams.md)** 📊
   - Interactive, zoomable diagrams  
   - Best viewed in: GitHub, VS Code (with Mermaid extension), GitLab
   - Includes: Architecture, state machines, sequence diagrams, block diagrams

2. **[ASCII Art Diagrams](diagrams/ascii_diagrams.md)** 📝
   - Text-based, works in any editor
   - Best for: Quick reference, offline viewing, printing
   - Includes: All major modules with detailed annotations

3. **[Timing Diagrams](diagrams/timing_diagrams.md)** ⏱️
   - Waveform representations
   - Best for: Understanding signal timing, debugging protocol issues
   - Includes: Complete transaction timing, baud rate generation, oversampling

4. **[Diagrams README](diagrams/README.md)** 📖
   - Quick reference guide
   - Usage tips and design decisions summary

---

## 🎯 Quick Navigation by Topic

| I want to understand... | Go to | File |
|-------------------------|-------|------|
| **Overall system architecture** | System overview showing CPU ↔ UART ↔ External | [Mermaid #1](diagrams/mermaid_diagrams.md#1-top-level-system-architecture) or [ASCII #1](diagrams/ascii_diagrams.md#1-top-level-system-architecture) |
| **How baud rate is generated** | Baud rate generator with counter logic | [Mermaid #2](diagrams/mermaid_diagrams.md#2-baud-rate-generator-module) or [ASCII #2](diagrams/ascii_diagrams.md#2-baud-rate-generator-module) |
| **TX state machine flow** | Transmitter state diagram (IDLE→START→DATA→STOP) | [Mermaid #3](diagrams/mermaid_diagrams.md#3-uart-transmitter---state-machine) or [ASCII #3](diagrams/ascii_diagrams.md#3-uart-transmitter-tx-module) |
| **TX internal logic** | Transmitter block diagram with shift register | [Mermaid #4](diagrams/mermaid_diagrams.md#4-uart-transmitter---block-diagram) or [ASCII #3](diagrams/ascii_diagrams.md#3-uart-transmitter-tx-module) |
| **RX state machine flow** | Receiver state diagram with oversampling | [Mermaid #5](diagrams/mermaid_diagrams.md#5-uart-receiver---state-machine) or [ASCII #4](diagrams/ascii_diagrams.md#4-uart-receiver-rx-module) |
| **RX internal logic** | Receiver block diagram with synchronizer | [Mermaid #6](diagrams/mermaid_diagrams.md#6-uart-receiver---block-diagram) or [ASCII #4](diagrams/ascii_diagrams.md#4-uart-receiver-rx-module) |
| **Register addresses & bit fields** | Complete memory map with all registers | [Mermaid #7](diagrams/mermaid_diagrams.md#7-register-interface---memory-map) or [ASCII #5](diagrams/ascii_diagrams.md#5-register-interface--memory-map) |
| **CPU write transaction flow** | Sequence diagram for sending data | [Mermaid #8](diagrams/mermaid_diagrams.md#8-transaction-sequence---write-send-data) or [Timing #4](diagrams/timing_diagrams.md#4-cpu-write-transaction-timing-send-byte) |
| **CPU read transaction flow** | Sequence diagram for receiving data | [Mermaid #9](diagrams/mermaid_diagrams.md#9-transaction-sequence---read-receive-data) or [Timing #5](diagrams/timing_diagrams.md#5-cpu-read-transaction-timing-receive-byte) |
| **Module hierarchy** | Tree showing all submodules | [Mermaid #10](diagrams/mermaid_diagrams.md#10-module-hierarchy) or [ASCII #6](diagrams/ascii_diagrams.md#6-module-hierarchy) |
| **Signal timing & waveforms** | Complete timing diagrams | [Timing Diagrams](diagrams/timing_diagrams.md) |
| **Frame format (8N1)** | Bit-by-bit transmission timing | [Timing #1](diagrams/timing_diagrams.md#1-complete-uart-transaction-timing) |
| **Oversampling details** | 16x oversampling with majority voting | [Timing #7](diagrams/timing_diagrams.md#7-rx-oversampling-detail-zoomed-into-1-bit-period) |

---

## 🚀 Recommended Learning Path

For first-time learners, we recommend viewing diagrams in this order:

1. **Start Here**: [Top-Level System Architecture](diagrams/mermaid_diagrams.md#1-top-level-system-architecture)
   - Understand how UART peripheral connects to TinyQV CPU
   - See the big picture before diving into details

2. **Baud Rate**: [Baud Rate Generator](diagrams/mermaid_diagrams.md#2-baud-rate-generator-module)
   - Learn how clock division creates baud rate timing
   - See lookup table for different speeds

3. **Transmitter**: [TX State Machine](diagrams/mermaid_diagrams.md#3-uart-transmitter---state-machine) → [TX Block Diagram](diagrams/mermaid_diagrams.md#4-uart-transmitter---block-diagram)
   - Understand the TX flow: IDLE → START → DATA → STOP
   - See how shift register serializes data

4. **Receiver**: [RX State Machine](diagrams/mermaid_diagrams.md#5-uart-receiver---state-machine) → [RX Block Diagram](diagrams/mermaid_diagrams.md#6-uart-receiver---block-diagram)  
   - Understand RX with oversampling
   - See synchronizer and majority voting

5. **Registers**: [Register Interface Memory Map](diagrams/mermaid_diagrams.md#7-register-interface---memory-map)
   - Learn the register addresses (0x00, 0x04, 0x08, 0x0C)
   - Understand bit fields in each register

6. **Transactions**: [Write Sequence](diagrams/mermaid_diagrams.md#8-transaction-sequence---write-send-data) → [Read Sequence](diagrams/mermaid_diagrams.md#9-transaction-sequence---read-receive-data)
   - See how CPU sends and receives bytes
   - Understand polling vs interrupts

7. **Timing**: [Complete Transaction Timing](diagrams/timing_diagrams.md#1-complete-uart-transaction-timing)
   - See actual waveforms for sending/receiving
   - Understand bit timing at different baud rates

---

## 📋 Design Summary

### Key Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| **System Clock** | 70 MHz | TinyQV core frequency |
| **Baud Rates** | 9600, 19200, 38400, 115200 | Configurable via register |
| **Frame Format** | 8N1 | 8 data bits, no parity, 1 stop bit (fixed) |
| **Oversampling** | 16x | For RX only (better noise immunity) |
| **TX FIFO** | None | Direct transmission (future enhancement) |
| **RX FIFO** | None | Direct receive (future enhancement) |
| **Flow Control** | None | Simple design |
| **Interrupts** | user_interrupt | RX data ready signal |

### Register Map

| Address | Register | Access | Description |
|---------|----------|--------|-------------|
| 0x00 | CTRL | Write | Control: baud rate select [7:4], enable [0] |
| 0x04 | STATUS | Read | Status: TX_BUSY [3], RX_READY [2], RX_OVERRUN [1], RX_ERROR [0] |
| 0x08 | TX_DATA | Write | Transmit data [7:0], writing triggers TX |
| 0x0C | RX_DATA | Read | Receive data [7:0], reading clears RX_READY |

### Pin Connections

| Signal | Direction | Description |
|--------|-----------|-------------|
| ui_in[7] | Input | UART RX (serial input from external device) |
| uo_out[0] | Output | UART TX (serial output to external device) |
| user_interrupt | Output | Interrupt signal (RX data ready) |

---

## 🎨 Viewing Tips

### For Mermaid Diagrams

- **GitHub**: Diagrams render automatically (just click the link!)
- **VS Code**: Install "Markdown Preview Mermaid Support" extension
- **Export**: Use [mermaid.live](https://mermaid.live) to export to PNG/SVG

### For ASCII Diagrams

- **Best in**: Monospaced fonts (Courier, Consolas, Monaco)
- **VS Code**: Already perfect!
- **Terminal**: `cat diagrams/ascii_diagrams.md | less`
- **Print**: ASCII diagrams print beautifully on paper

### For Timing Diagrams

- **Zoom In**: Use Ctrl/Cmd + Plus to see waveform details
- **Compare**: Open side-by-side with code for debugging
- **Reference**: Great for verifying GTKWave waveforms

---

## 📚 Related Documentation

- **[UART Fundamentals](UART_FUNDAMENTALS.md)**: Complete beginner's guide with analogies
- **[Project Plan](PROJECT_PLAN.md)**: 9-phase implementation roadmap (Jan 19-28)
- **[Diagrams README](diagrams/README.md)**: Detailed guide for each diagram type

---

## 🔗 External Resources

- **Mermaid Documentation**: https://mermaid.js.org/
- **UART Tutorial**: http://www.ti.com/lit/an/spma038/spma038.pdf
- **Serial Communication**: https://learn.sparkfun.com/tutorials/serial-communication

---

**Happy Learning!** 🎓