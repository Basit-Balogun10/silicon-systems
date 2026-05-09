# AES-128 Timing Diagrams

Waveform representations showing signal transitions and cycle-by-cycle operation of the AES-128 encryption engine.

## Table of Contents
1. [Complete 128-bit Block Encryption Timing](#1-complete-128-bit-block-encryption-timing)
2. [Single Round Cycle Breakdown](#2-single-round-cycle-breakdown)
3. [Key Expansion Timing](#3-key-expansion-timing)
4. [SubBytes Pipeline Timing](#4-subbytes-pipeline-timing)
5. [Integration with UART TX FIFO](#5-integration-with-uart-tx-fifo)
6. [Control Signal Timing](#6-control-signal-timing)

---

## 1. Complete 128-bit Block Encryption Timing

### Full Encryption Cycle (~26 clock cycles)

```
Clock Cycle:  0    1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26
              ────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────
clk           ────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────

                  ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
aes_enable  ──────┘                                                                                                                      └─────────
              
              ────┐                                                                                                                      ┌─────────
aes_busy    ──────┘──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘─────────

aes_done    ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐    ┌──
                                                                                                                                           └────┘

                  ╔══════╦═════════╦═════════╦═════════╦═════════╦═════════╦═════════╦═════════╦═════════╦═════════╦═════════╦═════════╦═══════╗
fsm_state   ══════╣ LOAD ╠ INIT_RK ╠ ROUND_1 ╠ ROUND_2 ╠ ROUND_3 ╠ ROUND_4 ╠ ROUND_5 ╠ ROUND_6 ╠ ROUND_7 ╠ ROUND_8 ╠ ROUND_9 ╠ROUND_10 ╠ STORE ╠═══
                  ╚══════╩═════════╩═════════╩═════════╩═════════╩═════════╩═════════╩═════════╩═════════╩═════════╩═════════╩═════════╩═══════╝

                  ╔══════╗                   ╔═════════╗         ╔═════════╗         ╔═════════╗         ╔═════════╗         ╔═════════╗
round_count ══════╣  0   ╠═══════════════════╣    1    ╠═════════╣    2    ╠═════════╣    3    ╠═════════╣   ...   ╠═════════╣   10    ╠═════════════
                  ╚══════╝                   ╚═════════╝         ╚═════════╝         ╚═════════╝         ╚═════════╝         ╚═════════╝

                         ┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
plaintext_valid ─────────┘                                                                                                 └──────────────

                                                                                                                                  ┌─────────────
ciphertext_valid ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

tx_fifo_rd  ──────┐                                                                                                                              ┌────
              ────┘──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘────
                  ↑                                                                                                                              ↑
              Read 16 bytes                                                                                                                Write 16 bytes
              from TX FIFO                                                                                                                   to TX path
```

**Timing Breakdown**:
- **Cycle 0**: Trigger encryption (TX FIFO has 16 bytes)
- **Cycle 1**: Load 128-bit plaintext from FIFO to state matrix, assert `aes_busy`
- **Cycle 2**: Initial AddRoundKey with K0 (round 0)
- **Cycles 3-22**: Execute 10 rounds (~2 cycles each)
  - Rounds 1-9: SubBytes → ShiftRows → MixColumns → AddRoundKey
  - Round 10: SubBytes → ShiftRows → AddRoundKey (no MixColumns)
- **Cycle 23**: Store 128-bit ciphertext to output buffer
- **Cycle 24**: Transfer ciphertext to TX path, pulse `aes_done`, deassert `aes_busy`
- **Cycle 25+**: Ready for next block

**Total Latency**: ~26 cycles per 128-bit block
**Throughput**: At 25 MHz → ~960 kbps encrypted data rate

---

## 2. Single Round Cycle Breakdown

### Detailed Timing for One Encryption Round (Rounds 1-9)

```
Clock:        0         1         2         3
          ────┐    ┌────┐    ┌────┐    ┌────┐    ┌─
clk       ────┘────┘────┘────┘────┘────┘────┘────┘

              ╔════════════╦═══════════╦═══════════╦═══════════╗
fsm_state ════╣  SUB_BYTES ╠ SHIFT_ROWS╠MIX_COLUMNS╠ADD_RND_KEY╠══
              ╚════════════╩═══════════╩═══════════╩═══════════╝

              ╔════════════╗           ║           ║           ║
state_in  ════╣  Original  ╠═══════════╬═══════════╬═══════════╬══
              ╚════════════╝           ║           ║           ║
                                       ║           ║           ║
                           ╔═══════════╗           ║           ║
sbox_out  ═════════════════╣ S-Boxed   ╠═══════════╬═══════════╬══
                           ╚═══════════╝           ║           ║
                                                   ║           ║
                                       ╔═══════════╗           ║
shifted_out ═══════════════════════════╣  Shifted  ╠═══════════╬══
                                       ╚═══════════╝           ║
                                                               ║
                                                   ╔═══════════╗
mixed_out ═════════════════════════════════════════╣   Mixed   ╠══
                                                   ╚═══════════╝

                                                               ║
round_key ═════════════════════════════════════════════════════╬══
                                                               ║
                                                               ╔═══════════╗
state_out ═════════════════════════════════════════════════════╣  New State╠══
                                                               ╚═══════════╝
```

**Stage Details**:

1. **SUB_BYTES (Cycle 0)**:
   - Load state matrix
   - Perform 16 parallel S-Box lookups (combinational ROM)
   - All bytes substituted in same cycle

2. **SHIFT_ROWS (Cycle 1)**:
   - Take S-Boxed output
   - Circular shift rows (wire routing, combinational)
   - Row 0: no shift, Row 1: <<1, Row 2: <<2, Row 3: <<3

3. **MIX_COLUMNS (Cycle 2)**:
   - Take shifted output
   - Apply GF(2^8) matrix multiplication to 4 columns in parallel
   - Each column: 4 multiplications + XORs

4. **ADD_ROUND_KEY (Cycle 3)**:
   - XOR mixed state with round key
   - Combinational: 128-bit XOR operation
   - Output becomes input for next round

**Note**: Some operations can overlap if pipelined, reducing round time to ~2 cycles total.

### Round 10 Timing (Final Round - No MixColumns)

```
Clock:        0         1         2
          ────┐    ┌────┐    ┌────┐    ┌─
clk       ────┘────┘────┘────┘────┘────┘

              ╔════════════╦═══════════╦═══════════╗
fsm_state ════╣  SUB_BYTES ╠ SHIFT_ROWS╠ADD_RND_KEY╠══
              ╚════════════╩═══════════╩═══════════╝

              ╔════════════╗           ║           ║
state_in  ════╣  Round 9   ╠═══════════╬═══════════╬══
              ╚════════════╝           ║           ║
                                       ║           ║
                           ╔═══════════╗           ║
sbox_out  ═════════════════╣ S-Boxed   ╠═══════════╬══
                           ╚═══════════╝           ║
                                                   ║
                                       ╔═══════════╗
shifted_out ═══════════════════════════╣  Shifted  ╠══
                                       ╚═══════════╝

round_key_10 ══════════════════════════════════════╬══
                                                   ║
                                                   ╔═══════════╗
ciphertext ═════════════════════════════════════════╣Final Output╠═
                                                   ╚═══════════╝
```

**Difference from Rounds 1-9**:
- MixColumns stage **omitted** (AES-128 standard)
- Only 2 cycles instead of 3
- Direct path: SubBytes → ShiftRows → AddRoundKey → Done

---

## 3. Key Expansion Timing

### Pre-Computed Key Expansion (Design Choice A)

```
Clock:        0         1         2         3         4         5     ...    174       175
          ────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐          ┐    ┌────┐    ┌─
clk       ────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘──────────┘────┘────┘────┘

                  ┌────────────────────────────────────────────────────────────────────────┐
key_write ────────┘                                                                        └─────────

              ╔═══════╦═══════╦═══════╦═══════╦═══════╦═══════╦═══════╦═══════╦═══════╦═════════╗
master_key ═══╣ Byte0 ╠ Byte1 ╠ Byte2 ╠ Byte3 ╠  ...  ╠Byte12 ╠Byte13 ╠Byte14 ╠Byte15 ╠  HOLD   ╠═
              ╚═══════╩═══════╩═══════╩═══════╩═══════╩═══════╩═══════╩═══════╩═══════╩═════════╝

                      ╔═══════╦═══════╦═══════╦═══════╗       ╔═══════╦═══════╦═══════╦═══════╗
round_key[0] ═════════╣  W0   ╠  W1   ╠  W2   ╠  W3   ╠═══════╬═══════╬═══════╬═══════╬═══════╬═
                      ╚═══════╩═══════╩═══════╩═══════╝       ╚═══════╩═══════╩═══════╩═══════╝

                                      (176 cycles of key expansion logic)

                                                              ╔═══════╦═══════╦═══════╦═══════╗
round_key[10] ═════════════════════════════════════════════╣ W40   ╠ W41   ╠ W42   ╠ W43   ╠═
                                                              ╚═══════╩═══════╩═══════╩═══════╝

                                                                                             ┌──────
keys_ready ───────────────────────────────────────────────────────────────────────────────────┘
```

**Pre-Computation Approach**:
- Write 128-bit master key over 16 cycles (byte-by-byte via register interface)
- Automatically trigger key expansion FSM
- Generate all 11 round keys (44 words = 176 bytes) in ~176 cycles
- Store in dedicated key memory
- **Pro**: Fast encryption (no per-round key overhead)
- **Con**: Larger memory footprint (176 bytes)
- **Use case**: When key changes infrequently

### On-the-Fly Key Expansion (Alternative Design Choice B)

```
Clock:        0    1    2    3    4    5    6    7    8    9   10   11   12   13   14   15
          ────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌─
clk       ────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘

              ╔═══════════╦═════════╦═════════╦═════════╦═══════════╦═════════╗
fsm_state ════╣   IDLE    ╠GEN_KEY_1╠ ROUND_1 ╠GEN_KEY_2╠  ROUND_2  ╠   ...   ╠══
              ╚═══════════╩═════════╩═════════╩═════════╩═══════════╩═════════╝

                          ┌─────────┐         ┌─────────┐
key_expand_en ────────────┘         └─────────┘         └─────────────────────────────

                          ╔═════════╗         ╔═════════╗         ╔═════════╗
current_round_key ════════╣  Key 1  ╠═════════╣  Key 2  ╠═════════╣  Key 3  ╠══
                          ╚═════════╝         ╚═════════╝         ╚═════════╝
```

**On-the-Fly Approach**:
- Generate each round key just before needed
- Add 2 cycles per round for key expansion logic
- **Pro**: No key storage (only 128 bits for master key)
- **Con**: Slower encryption (~46 cycles instead of ~26)
- **Use case**: Very area-constrained designs

**Recommended**: Pre-computed approach for this project (faster encryption prioritized).

---

## 4. SubBytes Pipeline Timing

### Parallel S-Box Lookups (All 16 Bytes Simultaneously)

```
Clock:        0              1              2
          ────┐         ┌────┐         ┌────┐         ┌─
clk       ────┘─────────┘────┘─────────┘────┘─────────┘

                        ╔═══════════════════════════════╗
state_in  ══════════════╣ 128-bit State (16 bytes)     ╠═══════
                        ╚═══════════════════════════════╝

              ╔═════════╗
sbox_in[0] ═══╣  0x53   ╠═════════════════════════════════════
              ╚═════════╝
                        ╔═════════╗
sbox_out[0] ════════════╣  0xED   ╠═════════════════════════════
                        ╚═════════╝

              ╔═════════╗
sbox_in[1] ═══╣  0x00   ╠═════════════════════════════════════
              ╚═════════╝
                        ╔═════════╗
sbox_out[1] ════════════╣  0x63   ╠═════════════════════════════
                        ╚═════════╝

                  ...  (14 more parallel S-Box lookups)  ...

              ╔═════════╗
sbox_in[15] ══╣  0xA5   ╠═════════════════════════════════════
              ╚═════════╝
                        ╔═════════╗
sbox_out[15] ═══════════╣  0xC9   ╠═════════════════════════════
                        ╚═════════╝

                        ╔═══════════════════════════════╗
state_out ══════════════╣ Substituted State (16 bytes) ╠═══════
                        ╚═══════════════════════════════╝
```

**S-Box Implementation Details**:
- **Type**: 256-entry × 8-bit ROM (combinational lookup table)
- **Latency**: Combinational (output available same cycle as input stable)
- **Area**: ~512 cells (256 bytes + decode logic)
- **Parallelism**: 16 S-Box instances (one per byte) → 16 simultaneous lookups
- **Total S-Box area**: 16 × 512 = ~8192 cells (largest component)

**S-Box Table Sample**:
```
Input  → Output
0x00   → 0x63
0x01   → 0x7C
0x02   → 0x77
...
0x53   → 0xED
...
0xFF   → 0x16
```

**Alternative**: Composite field implementation (smaller but slower).

---

## 5. Integration with UART TX FIFO

### Encryption Trigger from TX FIFO Watermark

```
Clock:    0    1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20
      ────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌─
clk   ────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘

                                                  ┌─────────────────────────────────────────────────────────────────────
cpu_write ─────────────────────────────────────────┘

tx_data ════╬════╬════╬════╬════╬════╬════╬════╬════╬════╬════╬════╬════╬════╬════╬════╬════════════════════════════
           Byte0 Byte1 Byte2 Byte3 Byte4 Byte5 Byte6 Byte7 Byte8 Byte9 ...Byte13Byte14Byte15

          ╔════╦════╦════╦════╦════╦════╦════╦════╦════╦════╦════╦════╦════╦════╦════╦════╗
fifo_count══╣ 0  ╠ 1  ╠ 2  ╠ 3  ╠ 4  ╠ 5  ╠ 6  ╠ 7  ╠ 8  ╠ 9  ╠ 10 ╠ 11 ╠ 12 ╠ 13 ╠ 14 ╠ 15 ╠══════════════════════════
          ╚════╩════╩════╩════╩════╩════╩════╩════╩════╩════╩════╩════╩════╩════╩════╩════╝

                                                                                             ┌────
fifo_watermark ───────────────────────────────────────────────────────────────────────────────┘

                                                                                                  ┌───────────────────
aes_trigger ──────────────────────────────────────────────────────────────────────────────────────┘

                                                                                                  ╔═══════════════════
aes_busy ═════════════════════════════════════════════════════════════════════════════════════════╣   Encrypting...
                                                                                                  ╚═══════════════════

                                                                                                        (24 cycles)

aes_done ─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐  ┌─
                                                                                                                       └──┘

                                                                                                                            ┌
uart_tx_start ────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Integration Flow**:
1. **Cycles 0-15**: CPU writes 16 bytes to TX_DATA register
2. Each write increments `fifo_count`
3. **Cycle 15**: `fifo_count` reaches 16, assert `fifo_watermark`
4. **Cycle 16**: Trigger AES encryption (`aes_enable` must be set)
5. **Cycles 16-40**: AES encrypts 128-bit block (24 cycles)
6. **Cycle 41**: `aes_done` pulse, ciphertext ready
7. **Cycle 42+**: UART TX starts sending encrypted bytes (with flow control)

**Control Register Interaction**:
- `AES_CTRL[0]`: `aes_enable` - must be set to trigger encryption
- `AES_CTRL[1]`: `bypass_mode` - if set, skip encryption (plaintext mode)
- `AES_STATUS[0]`: `aes_busy` - read-only, indicates encryption in progress
- `AES_STATUS[1]`: `aes_done` - read-only, pulsed when block complete

---

## 6. Control Signal Timing

### AES Control and Status Signals

```
Clock:    0    1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16
      ────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌─
clk   ────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘────┘

            ┌──────────────────────────────────────────────────────────────────────────────────
aes_enable ─┘

                  ┌───────────────────────────────────────────────────────────────────┐
aes_start ────────┘                                                                   └──────────

                  ╔═══════════════════════════════════════════════════════════════════╗
aes_busy ═════════╣                       Encryption Active                           ╠═══════════
                  ╚═══════════════════════════════════════════════════════════════════╝

aes_done ─────────────────────────────────────────────────────────────────────────────────────┐  ┌─
                                                                                               └──┘

                  ╔═══════════╦═══════╦═══════╦═══════╦═══════╦═════════╦═════════╦═══════╗
aes_state ════════╣   IDLE    ╠ LOAD  ╠INIT_RK╠ROUND_1╠ROUND_2╠  ...   ╠ ROUND_10╠ STORE ╠═══════
                  ╚═══════════╩═══════╩═══════╩═══════╩═══════╩═════════╩═════════╩═══════╝

                  ╔═══════════╦═══════════════════════════════════════════════════════════╗
plaintext ════════╣  Invalid  ╠                     Valid 128-bit Block                   ╠═══════
                  ╚═══════════╩═══════════════════════════════════════════════════════════╝

ciphertext ═══════════════════════════════════════════════════════════════════════╔═══════════════
                                                                                   ╠Valid 128-bit
                                                                                   ╚═══════════════

              ────┐                                                               ┌─────────────────
fifo_rd_en    ────┘───────────────────────────────────────────────────────────────┘

              ────┐                                                                                 ┌─
tx_wr_en      ────┘─────────────────────────────────────────────────────────────────────────────────┘
```

**Signal Descriptions**:

- **aes_enable** (input, CPU register bit):
  - Master enable for AES encryption
  - Must be asserted before encryption can start
  - Can be disabled to bypass encryption (plaintext mode)

- **aes_start** (input, internal trigger):
  - Pulse to start encryption (from TX FIFO watermark)
  - Only triggers if `aes_enable` is high
  - Latched internally to start FSM

- **aes_busy** (output, status):
  - Asserted during encryption (LOAD → STORE states)
  - CPU can poll this bit to check if encryption ongoing
  - Blocks new encryption starts while high

- **aes_done** (output, 1-cycle pulse):
  - Pulsed for 1 clock cycle when encryption completes
  - Can trigger interrupt to notify CPU
  - Clears automatically next cycle

- **aes_state** (internal FSM):
  - Current state of encryption engine
  - Not directly visible to CPU (use `aes_busy` instead)
  - Debug signal for verification

- **plaintext** (input, 128-bit):
  - Valid when loaded from TX FIFO
  - Held stable during encryption

- **ciphertext** (output, 128-bit):
  - Valid when `aes_done` pulses
  - Transferred to TX path immediately

- **fifo_rd_en** (internal control):
  - Pulse to read 16 bytes from TX FIFO
  - Asserted in LOAD state

- **tx_wr_en** (internal control):
  - Pulse to write ciphertext to TX path
  - Asserted in STORE state

---

## Timing Constraints

### Critical Paths

1. **S-Box Lookup**:
   - Input byte stabilization → ROM access → Output valid
   - Estimated: ~3 ns at typical process corner
   - Max frequency: ~333 MHz (well within 25 MHz target)

2. **MixColumns GF Multiplication**:
   - xtime operations + XOR tree depth
   - Estimated: ~5 ns
   - Max frequency: ~200 MHz

3. **Round Control Logic**:
   - FSM state decode + mux select + datapath routing
   - Estimated: ~4 ns
   - Max frequency: ~250 MHz

**Overall Design Max Frequency**: ~200 MHz (limited by MixColumns)
**Target Frequency**: 25 MHz (8× margin, very comfortable)

### Setup and Hold Times

```
Clock:              ┌────┐    ┌────┐    ┌────┐
clk             ────┘    └────┘    └────┘    └────

                ────────────╨═════════════════════
data_in                    └─┬─┘
                             │tsetup (1ns)
                             ↓
                             ├─ Sample Point
                             ↑
                             │thold (0.5ns)
                           ┌─┴─┐
data_out                   ╞═══╡──────────────────
                           └───┘
                             │tcq (clock-to-q, 2ns)
                             ↓
```

**Timing Parameters** (typical values for target process):
- **tsetup**: 1 ns (data must be stable before clock edge)
- **thold**: 0.5 ns (data must remain stable after clock edge)
- **tcq**: 2 ns (clock-to-output delay for flip-flops)
- **tperiod**: 40 ns @ 25 MHz (ample margin for all paths)

---

## Performance Summary

| Metric | Value | Notes |
|--------|-------|-------|
| **Cycles per block** | 26 | 128-bit block (16 bytes) |
| **Clock frequency** | 25 MHz | Target for TinyTapeout |
| **Time per block** | 1.04 µs | 26 cycles ÷ 25 MHz |
| **Throughput (encrypted)** | ~1.23 Mbps | 128 bits ÷ 1.04 µs |
| **Throughput (UART baud)** | 115.2 kbps | Bottleneck (UART slower) |
| **Effective throughput** | 115.2 kbps | UART-limited |
| **Latency (first byte out)** | ~1.2 µs | Encryption + TX start |
| **Area estimate** | ~2000 cells | S-Box + datapath + control |
| **Power estimate** | ~0.5 mW @ 25 MHz | Dynamic switching power |

**Conclusion**: AES engine has sufficient throughput to keep up with 115.2 kbps UART. Encryption is not the bottleneck; UART transmission rate limits overall performance.

---

## Verification Timing Checks

### Testbench Assertions

Key timing checks in verification:
1. `aes_done` pulses exactly 1 cycle
2. `aes_busy` asserted for 24-26 cycles
3. Output ciphertext matches expected (NIST test vectors)
4. No intermediate state corruption
5. Back-to-back block encryption (pipeline refill)

### Example Test Sequence

```
// Test: Single block encryption timing
initial begin
    // Load key
    write_aes_key(128'h2b7e151628aed2a6abf7158809cf4f3c);
    #100;
    
    // Enable AES
    write_aes_ctrl(8'h01);
    #10;
    
    // Write 16 bytes to TX FIFO
    for (int i = 0; i < 16; i++) begin
        write_tx_data(plaintext_block[i]);
        #40; // 1 clock cycle @ 25 MHz
    end
    
    // Wait for encryption
    @(posedge aes_done);
    check_timing: assert ($time - start_time == 26 * 40) 
        else $error("Encryption took unexpected number of cycles");
    
    // Verify ciphertext
    check_output: assert (ciphertext == expected_cipher)
        else $error("Ciphertext mismatch");
end
```

---

Return to [main diagrams README](README.md) for overview and navigation.
