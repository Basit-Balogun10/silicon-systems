# Secure UART Diagrams

Visual documentation for the Secure UART Peripheral system, organized by format for optimal viewing.

---

## 📁 Available Diagram Formats

### [ASCII Diagrams](ascii_diagrams.md) 📝
Text-based diagrams that render perfectly in any editor or terminal.

**Best for:**
- Quick reference during coding
- Offline viewing
- Copy/paste into comments
- Documentation that must work everywhere

**Includes:**
- Complete system architecture with full component detail
- TX and RX data flow paths (5 steps each with timing)
- Bypass mode operation
- Full-duplex operation showing dual AES cores
- State machine diagrams (TX and RX FSMs)
- Signal interface specifications
- Register bit field layouts (all 12 registers)

**Size:** 500+ lines, 8 comprehensive sections

---

### [Mermaid Diagrams](mermaid_diagrams.md) 📊
Interactive, zoomable diagrams using Mermaid syntax.

**Best for:**
- GitHub/GitLab documentation
- VS Code preview (with Mermaid extension)
- Presentations and reports
- Interactive exploration

**Includes:**
- Complete system architecture with color-coded blocks
- AES-UART integration flow showing encryption pipeline
- TX and RX state machines with transitions
- Encryption and decryption data flow
- Bypass mode flow diagrams
- Full-duplex sequence diagram
- Register access flows
- Module hierarchy tree

**Renders automatically on GitHub!**

---

### [Timing Diagrams](timing_diagrams.md) ⏱️
Waveform-style ASCII art showing signal timing relationships.

**Best for:**
- Understanding signal timing
- Debugging protocol issues
- Verifying timing constraints
- Integration testing

**Includes:**
- Complete transaction timing (CPU write → AES → UART TX)
- Single-byte register write/read timing
- AES encryption timing (11-cycle detail)
- UART serial transmission (8N1 format, bit-by-bit)
- Full-duplex operation timing
- Bypass vs encrypted mode comparison
- Interrupt timing diagrams

**Shows exact cycle counts and time delays!**

---

## 🎯 Quick Navigation

| I want to understand... | Best diagram | Link |
|------------------------|--------------|------|
| **Overall system architecture** | ASCII or Mermaid | [ASCII #1](ascii_diagrams.md#1-complete-system-architecture---full-detail) or [Mermaid #1](mermaid_diagrams.md#1-complete-system-architecture) |
| **How encryption works end-to-end** | ASCII or Mermaid | [ASCII #2](ascii_diagrams.md#2-data-flow---transmission-path) or [Mermaid #5](mermaid_diagrams.md#5-encryption-data-flow) |
| **How decryption works end-to-end** | ASCII or Mermaid | [ASCII #3](ascii_diagrams.md#3-data-flow---reception-path) or [Mermaid #6](mermaid_diagrams.md#6-decryption-data-flow) |
| **Bypass mode operation** | ASCII or Mermaid | [ASCII #4](ascii_diagrams.md#4-bypass-mode-data-flow) or [Mermaid #7](mermaid_diagrams.md#7-bypass-mode-flow) |
| **Full-duplex simultaneous TX+RX** | ASCII or Mermaid | [ASCII #5](ascii_diagrams.md#5-full-duplex-operation) or [Mermaid #8](mermaid_diagrams.md#8-full-duplex-operation) |
| **TX state machine** | ASCII or Mermaid | [ASCII #6](ascii_diagrams.md#6-aes-streaming-controller-state-machines) or [Mermaid #3](mermaid_diagrams.md#3-tx-path-state-machine) |
| **RX state machine** | ASCII or Mermaid | [ASCII #6](ascii_diagrams.md#6-aes-streaming-controller-state-machines) or [Mermaid #4](mermaid_diagrams.md#4-rx-path-state-machine) |
| **Register map & bit fields** | ASCII | [ASCII #8](ascii_diagrams.md#8-register-bit-field-details) |
| **Signal interfaces (CPU, UART, AES)** | ASCII | [ASCII #7](ascii_diagrams.md#7-signal-interface-details) |
| **Module hierarchy** | Mermaid | [Mermaid #10](mermaid_diagrams.md#10-module-hierarchy) |
| **Complete transaction timing** | Timing | [Timing #1](timing_diagrams.md#1-complete-transaction-timing---encrypted-transmission) |
| **Register write timing** | Timing | [Timing #2](timing_diagrams.md#2-register-interface-timing---single-byte-write) |
| **Register read timing** | Timing | [Timing #3](timing_diagrams.md#3-register-interface-timing---single-byte-read) |
| **AES encryption cycle-by-cycle** | Timing | [Timing #4](timing_diagrams.md#4-aes-encryption-timing---single-128-bit-block) |
| **UART serial transmission** | Timing | [Timing #5](timing_diagrams.md#5-uart-serial-transmission-timing---single-byte) |
| **Interrupt timing** | Timing | [Timing #8](timing_diagrams.md#8-interrupt-timing) |

---

## 🚀 Recommended Learning Path

**For first-time learners:**

1. **System Overview** → [Mermaid System Architecture](mermaid_diagrams.md#1-complete-system-architecture)
   - Get the big picture: CPU ↔ Registers ↔ AES ↔ UART ↔ Serial
   - Color-coded blocks show major subsystems

2. **Data Flow - Encryption** → [ASCII TX Path](ascii_diagrams.md#2-data-flow---transmission-path)
   - Follow a byte from CPU write through encryption to serial output
   - See 5-step process with timing analysis

3. **Data Flow - Decryption** → [ASCII RX Path](ascii_diagrams.md#3-data-flow---reception-path)
   - Follow a byte from serial input through decryption to CPU read
   - See 5-step process with timing analysis

4. **State Machines** → [Mermaid TX FSM](mermaid_diagrams.md#3-tx-path-state-machine) and [RX FSM](mermaid_diagrams.md#4-rx-path-state-machine)
   - Understand the control flow: IDLE → BUFFER → ENCRYPT/DECRYPT → SERIALIZE → IDLE
   - See bypass states for AES_EN=0 mode

5. **Registers** → [ASCII Register Bit Fields](ascii_diagrams.md#8-register-bit-field-details)
   - Learn all 12 registers (0x00-0x34) with bit-level layouts
   - Understand control bits (AES_EN, uart_en, baud_sel, etc.)

6. **Timing** → [Complete Transaction Timing](timing_diagrams.md#1-complete-transaction-timing---encrypted-transmission)
   - See waveforms for full encryption cycle
   - Understand 1.39ms UART bottleneck vs 157ns AES overhead

7. **Advanced** → [Full-Duplex Operation](ascii_diagrams.md#5-full-duplex-operation)
   - Learn how dual AES cores enable simultaneous TX+RX
   - See independence between encryption and decryption paths

---

## 📋 Design Summary

### Key System Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| **System Clock** | 70 MHz | TinyQV core frequency |
| **AES Block Size** | 128 bits (16 bytes) | Standard AES-128 |
| **AES Latency** | 11 cycles = 157ns | Negligible overhead |
| **UART Baud Rate** | 115200 (default) | Configurable: 9600-921600 |
| **UART Frame** | 8N1 | 8 data, no parity, 1 stop |
| **TX Throughput** | ~11.5 KB/s | UART limited (not AES) |
| **RX Throughput** | ~11.5 KB/s | UART limited (not AES) |
| **Byte Latency** | 86.8µs | Per byte @ 115200 baud |
| **Block Latency** | 1.39ms | 16 bytes @ 115200 baud |
| **Full-Duplex** | ✅ Yes | Dual independent AES cores |
| **Bypass Mode** | ✅ Yes | For debugging/plaintext |

### Architecture Highlights

- **Transparent Encryption**: CPU sees simple byte-level TX/RX interface
- **Automatic Buffering**: System accumulates 16 bytes before encrypting
- **Dual AES Cores**: Separate TX (encrypt) and RX (decrypt) for full-duplex
- **Shared Key**: Single 128-bit key used by both cores
- **Bypass Mode**: Direct CPU↔UART path when AES_EN=0
- **Zero Software Overhead**: Hardware handles all buffering and encryption
- **Interrupt Support**: TX done and RX ready interrupts

### Performance Analysis

**Bottleneck:** UART serial transmission (86.8µs per byte @ 115200 baud)

**AES Impact:** 0.01% overhead (157ns encryption vs 1.39ms UART transmission)

**Conclusion:** System throughput is UART-limited, not AES-limited. Increasing AES complexity would have negligible impact on overall performance.

---

## 🛠️ Viewing Tips

### ASCII Diagrams
- Use **monospace font** (Courier New, Consolas, Monaco)
- Set editor to **120+ columns** for best rendering
- Works in: any text editor, terminal, code comments, markdown

### Mermaid Diagrams
- **GitHub/GitLab**: Renders automatically in markdown preview
- **VS Code**: Install "Markdown Preview Mermaid Support" extension
- **Online**: Copy to [mermaid.live](https://mermaid.live) for interactive editing
- **Export**: Render to PNG/SVG using mermaid CLI or online tools

### Timing Diagrams
- Best viewed in **monospace font**
- Set editor to **100+ columns**
- Look for cycle counts and time annotations
- Compare signal transitions vertically (aligned in time)

---

## 📖 Related Documentation

- **[Main README](../README.md)**: System overview and integration guide
- **[SOFTWARE_GUIDE.md](../SOFTWARE_GUIDE.md)**: C driver examples and register definitions
- **[BLOCK_DIAGRAMS.md](../BLOCK_DIAGRAMS.md)**: Detailed module interfaces and signal paths
- **[SECURE_UART_FUNDAMENTALS.md](../SECURE_UART_FUNDAMENTALS.md)**: Theory and encryption concepts

---

## 📝 Contributing

When adding new diagrams:

1. **ASCII**: Keep to 120 columns max, use box-drawing characters consistently
2. **Mermaid**: Test rendering on GitHub before committing
3. **Timing**: Show cycle counts, time delays, and signal annotations
4. **Update this README**: Add navigation links and descriptions

---

## ✅ Diagram Completeness Checklist

- [x] ASCII Diagrams (500+ lines, 8 sections)
- [x] Mermaid Diagrams (10 diagrams covering all aspects)
- [x] Timing Diagrams (8 comprehensive timing scenarios)
- [x] README with navigation (this file)
- [x] All cross-references working
- [x] Consistent terminology across all formats
- [x] Matching detail level with uart/ and aes/ docs

**Status:** Complete and comprehensive, matching existing uart/ and aes/ documentation quality.
