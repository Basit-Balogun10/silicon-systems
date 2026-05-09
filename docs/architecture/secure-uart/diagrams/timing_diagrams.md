# Secure UART System - Timing Diagrams

Detailed timing waveforms showing signal relationships throughout the Secure UART system, from CPU interface through encryption to serial transmission.

---

## 1. Complete Transaction Timing - Encrypted Transmission

### Scenario: CPU writes 16 bytes, system encrypts and transmits

```
Time Scale: Not to scale (cycles compressed for clarity)
Clock: 70MHz (14.3ns period)

CPU Write Sequence (16 bytes):
═══════════════════════════════

CPU Clock:
  ╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗
  ║ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝ ╚
  
address[5:0]:
  ══════╗                                               ╔══════
   0x08 ╚═══════════════════════════════════════════════╝ (other)
        ↑ TX_DATA register address

data_write_n:
  ══════╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔══
        ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═
        W0  W1  W2  W3  W4  W5  W6  W7  W8  W9  W10 W11 W12 W13 W14 W15
        
data_in[7:0]:
  ══════╗   ╔═══╗   ╔═══╗   ╔═══╗   ╔═══╗   ╔═══╗   ╔═══╗   ╔═══╗   ╔══
   0x48 ╚═══╝0x65╚═══╝0x6C╚═══╝0x6C╚═══╝0x6F╚═══╝0x20╚═══╝0x57╚═══╝0x6F╚══...
   'H'       'e'     'l'     'l'     'o'     ' '     'W'     'o'
        ↑ Byte 0          ↑ Byte 3         ↑ Byte 6
        
cpu_tx_write (internal pulse):
  ══════╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔══
        ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═
        ↑ Triggers byte entry into TX buffer


AES TX Streaming Buffer:
═════════════════════════

tx_buffer_count[4:0]:
  ════╗   ╔═╗   ╔═╗   ╔═╗   ╔═══╗   ╔═══╗   ╔═══╗   ╔═══╗   ╔═══╗   ╔═══╗
   0  ╚═══╝1 ╚═══╝2 ╚═══╝3 ╚═══╝ 4 ╚═══╝ 5 ╚═══╝ 6 ╚═══╝ 7 ╚═══╝ 8 ╚═══╝ 9 ╚══...══╗ 15╔════
                                                                                       ╚════╝ 0
      ↑ Bytes accumulating                                                           ↑ Full → Encrypt
      
tx_state[2:0]:
  ════════════════════════════════════════════════════════════════════════════╗       ╔═══════
   IDLE                                                                        ╚ BUFFER╝ENCRYPT
                                                                               ↑               ↑
                                                                          Start buffering   Start AES


AES Encryption Phase:
═════════════════════

aes_tx_start:
  ═════════════════════════════════════════════════════════════════════════════╗ ╔════════════
                                                                                ╚═╝
                                                                                ↑ Trigger encryption

aes_tx_busy:
  ═════════════════════════════════════════════════════════════════════════════╗           ╔══
                                                                                ╚═══════════╝
                                                                                ↑ 11 cycles ↑
                                                                              Start       Done

aes_tx_block_out[127:0]:
  ═════════════════════════════════════════════════════════════════════════════╗ (plaintext) ╔══
   undefined                                                                    ╚═════════════╝
                                                                                ↑ Ciphertext valid
                                                                                
tx_state[2:0]:
  ═════════════════════════════════════════════════════════════════════════ENCRYPT╗       ╔═══
                                                                                   ╚SERIAL ╝IDLE
                                                                                   ↑           ↑
                                                                              Serialize   Complete


Serialization and UART TX:
═══════════════════════════

tx_serialize_count[4:0]:
  ══════════════════════════════════════════════════════════════════════════════╗ ╔═╗ ╔═╗ ╔═╗...╔════
   0                                                                             ╚═╝1╚═╝2╚═╝3╚══╝ 15╔═
                                                                                 ↑              ↑   ↑
                                                                            Serialize        Last Done
                                                                            starts           byte
                                                                            
tx_byte_out[7:0]:
  ══════════════════════════════════════════════════════════════════════════════╗   ╔═══╗   ╔═══╗
   undefined                                                                     ╚0xA1╝0xB2╚0xC3╚══...
                                                                                 ↑ Ciphertext bytes
                                                                                 (from encrypted block)

uart_tx_start:
  ══════════════════════════════════════════════════════════════════════════════╗ ╔═╗ ╔═╗ ╔═╗...╔═╗ ╔═
                                                                                 ╚═╝ ╚═╝ ╚═╝ ╚═══╝ ╚═
                                                                                 ↑   ↑   ↑         ↑
                                                                                 B0  B1  B2       B15

uart_tx_busy:
  ══════════════════════════════════════════════════════════════════════════════╗               ╔════
                                                                                 ╚═══════════════╝
                                                                                 ↑ Transmitting  ↑
                                                                                                 All bytes
                                                                                                 sent

uart_tx_pin (Serial output - showing first byte 0xA1):
  IDLE═════════════════════════════════════════════════════════════════════════╗S╔══D0══╗D1╔══D2══╗
                                                                                ╚═╝     ╚══╝     ╚══...
                                                                                ↑ ↑ ↑             ↑
                                                                                │ │ └─ Bit 0 (LSB)
                                                                                │ └─── Start bit
                                                                                └───── Was IDLE (high)


Timeline Summary:
═════════════════

  Phase 1: CPU writes (16 bytes)          ~16 cycles  @ 70MHz = 0.23µs
  Phase 2: Buffer accumulation             (during writes)
  Phase 3: AES encryption                  11 cycles   @ 70MHz = 0.16µs
  Phase 4: Serialization starts            1 cycle     @ 70MHz = 0.01µs
  Phase 5: UART transmission (16 bytes)    ~1.39ms     @ 115200 baud
           (Each byte: 10 bits @ 115200 = 86.8µs)
           
  Total latency: ~1.39ms (UART dominates)
  AES overhead: 0.16µs (0.01% of total)
```

---

## 2. Register Interface Timing - Single Byte Write

### CPU writes one byte to TX_DATA register

```
Clock Period: 14.3ns @ 70MHz

    ╔═╗   ╔═╗   ╔═╗   ╔═╗   ╔═╗   ╔═╗
clk ║ ╚═══╝ ╚═══╝ ╚═══╝ ╚═══╝ ╚═══╝ ╚═══
    0   1   2   3   4   5   6   7   8

address[5:0]:
    ════╗           ╔═══════════════════
   (old)╚═══0x08════╝ (next)
        ↑ Setup     ↑ Hold
        T-1         T+2

data_in[31:0]:
    ════╗           ╔═══════════════════
   (old)╚═══0x48════╝ (next)
        ↑ Setup     ↑ Hold
        
data_write_n[1:0]:
    ════╗   ╔═══════╗═══════════════════
   0b11 ╚0b00╝  0b11 ╚ (inactive)
        ↑   ↑       ↑
        │   │       └─ Write pulse ends
        │   └───────── Active (write occurs)
        └───────────── Asserted

data_ready:
    ════════╗   ╔═══╗═══════════════════
       0    ╚ 1 ╝ 0 ╚ 
            ↑   ↑
            │   └─ Deasserted after 1 cycle
            └───── Asserted when write completes

cpu_tx_write (internal):
    ════════╗ ╔═════╗═══════════════════
       0    ╚1╝  0  ╚
            ↑ One clock pulse
            
tx_data_reg[7:0]:
    ════════╗       ╔═══════════════════
   (old)    ╚ 0x48  ╚ (holds)
            ↑ Captured on rising edge


Timing Requirements:
════════════════════

Setup time (address, data_in):  1 cycle before data_write_n assertion
Hold time (address, data_in):   1 cycle after data_write_n deassertion
Write pulse width:               Minimum 1 cycle
data_ready assertion:            1 cycle after write
Transaction complete:            2 cycles total
```

---

## 3. Register Interface Timing - Single Byte Read

### CPU reads one byte from RX_DATA register

```
Clock Period: 14.3ns @ 70MHz

    ╔═╗   ╔═╗   ╔═╗   ╔═╗   ╔═╗   ╔═╗
clk ║ ╚═══╝ ╚═══╝ ╚═══╝ ╚═══╝ ╚═══╝ ╚═══
    0   1   2   3   4   5   6   7   8

address[5:0]:
    ════╗           ╔═══════════════════
   (old)╚═══0x0C════╝ (next)
        ↑ Setup     ↑ Hold
        T-1         T+2

data_read_n[1:0]:
    ════╗   ╔═══════╗═══════════════════
   0b11 ╚0b00╝  0b11 ╚ (inactive)
        ↑   ↑       ↑
        │   │       └─ Read pulse ends
        │   └───────── Active (read occurs)
        └───────────── Asserted

data_out[31:0]:
    ════════╗       ╔═══════════════════
   (old/Z)  ╚ 0x57  ╝ (Z/next)
            ↑       ↑
            │       └─ Data released (high-Z)
            └───────── Data driven

data_ready:
    ════════╗   ╔═══╗═══════════════════
       0    ╚ 1 ╝ 0 ╚ 
            ↑   ↑
            │   └─ Deasserted after 1 cycle
            └───── Asserted when read completes

cpu_rx_read (internal):
    ════════╗ ╔═════╗═══════════════════
       0    ╚1╝  0  ╚
            ↑ One clock pulse
            
rx_data_available:
    ════╗           ╔═══════════════════
     1  ╚═══════0═══╝ 1 (if more data)
        ↑           ↑
        │           └─ Cleared after read
        └───────────── Was available


Timing Requirements:
════════════════════

Setup time (address):           1 cycle before data_read_n assertion
Read pulse width:                Minimum 1 cycle
Data valid time:                 Available same cycle as data_read_n
data_ready assertion:            1 cycle after read
Transaction complete:            2 cycles total
Data hold after read_n high:     1 cycle minimum
```

---

## 4. AES Encryption Timing - Single 128-bit Block

### Detailed timing of AES core encryption operation

```
Clock: 70MHz (14.3ns period)
Total AES latency: 11 cycles = 157ns

Cycle:  0     1     2     3     4     5     6     7     8     9    10    11    12
        ╔═╗   ╔═╗   ╔═╗   ╔═╗   ╔═╗   ╔═╗   ╔═╗   ╔═╗   ╔═╗   ╔═╗   ╔═╗   ╔═╗   ╔═╗
clk     ║ ╚═══╝ ╚═══╝ ╚═══╝ ╚═══╝ ╚═══╝ ╚═══╝ ╚═══╝ ╚═══╝ ╚═══╝ ╚═══╝ ╚═══╝ ╚═══╝ ╚══

aes_start:
        ╗ ╔═══════════════════════════════════════════════════════════════════════════
        ╚═╝
        ↑ Trigger encryption

aes_state:
        ════╗     ╔═══╗     ╔═══════════════════════════════════════╗           ╔═════
       IDLE ╚LOAD ╝KEY╚═R0══R1══R2══R3══R4══R5══R6══R7══R8══R9══R10═╝   DONE    ╚IDLE
        ↑   ↑     ↑   ↑                                              ↑           ↑
        │   │     │   └─ Round 0 (initial AddRoundKey)               │           │
        │   │     └───── Key expansion (compute round keys)           │           │
        │   └─────────── Load plaintext into state                    │           │
        └─────────────── Waiting for start                            │           └─ Ready for next
                                                                       └─────────── Output valid

plaintext_in[127:0]:
        ════╗                                                                           ╔═════
       (old)╚═ 0x00112233445566778899AABBCCDDEEFF ═════════════════════════════════════╝(next)
            ↑ Must be stable during operation

key_in[127:0]:
        ════╗                                                                           ╔═════
       (old)╚═ 0x000102030405060708090A0B0C0D0E0F ═════════════════════════════════════╝(same)
            ↑ Must be stable during operation

round_number[3:0]:
        ════════════╗   ╔═══╗   ╔═══╗   ╔═══╗   ╔═══╗   ╔═══╗   ╔═══╗   ╔═══╗   ╔═══╗
           0        ╚ 0 ╝ 1 ╚ 2 ╝ 3 ╚ 4 ╝ 5 ╚ 6 ╝ 7 ╚ 8 ╝ 9 ╚10 ╝ 0 ╚ 0
                    ↑                                                   ↑   ↑
                    └─ Initial round                                   │   └─ Reset
                                                                        └───── Final round

aes_done:
        ═════════════════════════════════════════════════════════════════════════╗ ╔═══════
           0                                                                      ╚═╝ 0
                                                                                  ↑ Output ready

ciphertext_out[127:0]:
        ═════════════════════════════════════════════════════════════════════════╗       ╔═══
       (undefined)                                                                ╚ Result╝(holds)
                                                                                  ↑
                                                                           0x69C4E0D86A7B0430D8CDB78070B4C55A
                                                                           (NIST test vector result)

AES Round Operations (per cycle):
═════════════════════════════════

Cycle 0:  IDLE state
Cycle 1:  Load plaintext into state register
Cycle 2:  Key expansion (generate K0-K10)
Cycle 3:  Round 0: AddRoundKey (initial)
Cycle 4:  Round 1: SubBytes → ShiftRows → MixColumns → AddRoundKey
Cycle 5:  Round 2: SubBytes → ShiftRows → MixColumns → AddRoundKey
Cycle 6:  Round 3: SubBytes → ShiftRows → MixColumns → AddRoundKey
Cycle 7:  Round 4: SubBytes → ShiftRows → MixColumns → AddRoundKey
Cycle 8:  Round 5: SubBytes → ShiftRows → MixColumns → AddRoundKey
Cycle 9:  Round 6: SubBytes → ShiftRows → MixColumns → AddRoundKey
Cycle 10: Round 7: SubBytes → ShiftRows → MixColumns → AddRoundKey
Cycle 11: Round 8: SubBytes → ShiftRows → MixColumns → AddRoundKey
Cycle 12: Round 9: SubBytes → ShiftRows → MixColumns → AddRoundKey
Cycle 13: Round 10: SubBytes → ShiftRows → AddRoundKey (no MixColumns)
Cycle 14: DONE state, output valid

Total: 11 cycles from start to done
Processing time: 11 × 14.3ns = 157ns @ 70MHz
Throughput: 128 bits / 157ns = 815 Mbps
           or 101.9 MB/s
```

---

## 5. UART Serial Transmission Timing - Single Byte

### 8N1 format at 115200 baud

```
Baud Rate: 115200 bps
Bit Period: 8.68 µs
Total byte time: 10 bits × 8.68µs = 86.8µs

Time (µs):  0      8.68   17.36  26.04  34.72  43.40  52.08  60.76  69.44  78.12  86.80
            │      │      │      │      │      │      │      │      │      │      │
uart_tx_pin:│      │      │      │      │      │      │      │      │      │      │
            │      │      │      │      │      │      │      │      │      │      │
IDLE ═══════╗      │      │      │      │      │      │      │      │      │      ╔══════ IDLE
            ║      │      │      │      │      │      │      │      │      │      ║
            ╚══════╗      ╔══════╗      ╔══════╗      ╔══════╗      ╔══════╗      ║
         START     ╚══════╝      ╚══════╝      ╚══════╝      ╚══════╝    STOP    ║
            ║   D0     D1     D2     D3     D4     D5     D6     D7     ║        ║
            ║  (LSB)                                         (MSB)       ║        ║
            
Example: Transmitting 0x55 (01010101 binary):
═════════════════════════════════════════════

Bit Sequence (LSB first):
  START D0 D1 D2 D3 D4 D5 D6 D7 STOP
    0   1  0  1  0  1  0  1  0   1
    
uart_tx_pin waveform:
IDLE ═══╗   ╔══╗  ╔══╗  ╔══╗  ╔══╗  ╔═══════ IDLE
        ╚═══╝  ╚══╝  ╚══╝  ╚══╝  ╚══╝
        S   D0 D1 D2 D3 D4 D5 D6 D7 P
        
Bit positions:
  S  = START bit  (0)
  D0 = Bit 0 (LSB) (1)
  D1 = Bit 1       (0)
  D2 = Bit 2       (1)
  D3 = Bit 3       (0)
  D4 = Bit 4       (1)
  D5 = Bit 5       (0)
  D6 = Bit 6       (1)
  D7 = Bit 7 (MSB) (0)
  P  = STOP bit   (1)


Internal UART TX Signals:
═════════════════════════

System Clock (70MHz):
  ╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗...╔═╗╔═╗ (607 clocks per bit)
  ║ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝   ╚╝ ╚

baud_tick (115200 Hz):
  ╔═══════════════════════════════════════════════╗       ╔════════════════...
  ║ (607 system clocks @ 70MHz = 8.67µs)          ╚═══════╝
  ║◄───────────── One bit period ─────────────────►
  
uart_tx_start:
  ═══╗ ╔═════════════════════════════════════════════════════════════════════
     ╚═╝
     ↑ CPU writes byte, triggers TX
     
uart_tx_busy:
  ═══╗                                                                   ╔═════
     ╚═══════════════════════════════════════════════════════════════════╝
     ↑ Set when byte loaded                                              ↑ Clear when STOP bit sent
     
tx_shift_reg[9:0]:
  ═══╗       ╔═══════════════════════════════════════════════════════════════
     ╚ 1_0101_0101_0 ╚ (shifts right each baud_tick)
     ↑ [STOP D7-D0 START]
     
bit_count[3:0]:
  ═══╗   ╔═══╗   ╔═══╗   ╔═══╗   ╔═══╗   ╔═══╗   ╔═══╗   ╔═══╗   ╔═══╗
   0 ╚ 0 ╝ 1 ╚ 2 ╝ 3 ╚ 4 ╝ 5 ╚ 6 ╝ 7 ╚ 8 ╝ 9 ╚10 ╝ 0 ╚
     ↑   ↑                                               ↑   ↑
     │   └─ START                                        │   └─ Reset, ready for next
     └───── IDLE                                         └───── STOP done
```

---

## 6. Full-Duplex Operation Timing

### Simultaneous TX encryption and RX decryption

```
Scenario: TX encrypting "Hello" while RX decrypting "World"

Time:       0µs    0.5µs   1.0µs   1.5µs   2.0µs   2.5µs
            │      │       │       │       │       │

TX Path:
━━━━━━━━
TX Buffer:
            ┌──────┐
            │Accum │
            │bytes │
            └──┬───┘
               ▼
TX AES:     ┌──────┐
            │IDLE  │───►┌──────┐
            └──────┘    │ENCR  │◄─── 11 cycles
                        └──┬───┘
                           ▼
TX Serialize:           ┌──────┐
                        │Output│───►┌──────┐
                        └──────┘    │UART  │
                                    └──┬───┘
                                       ▼
uart_tx_pin:                        ═══╗   ╔══...
                                       ╚═══╝
                                       Transmitting

RX Path (simultaneous, independent):
━━━━━━━━
uart_rx_pin:            ═══╗   ╔══...
                           ╚═══╝
                           ▼
RX UART:                ┌──────┐
                        │Sample│───►┌──────┐
                        └──────┘    │Shift │
                                    └──┬───┘
                                       ▼
RX Buffer:                          ┌──────┐
                                    │Accum │
                                    │bytes │
                                    └──┬───┘
                                       ▼
RX AES:                             ┌──────┐
                                    │DECR  │◄─── 11 cycles
                                    └──┬───┘
                                       ▼
RX Output:                          ┌──────┐
                                    │Ready │
                                    │ for  │
                                    │ CPU  │
                                    └──────┘

Independence Demonstrated:
═══════════════════════════

TX AES State:
  IDLE ════╗     ╔═════════════════════════════════════════
           ╚ ENCR╝ SERIALIZE ═════════════════════════
           ↑
           └─ TX processing "Hello"

RX AES State:
  ══════════════════════════════════IDLE ════╗     ╔═══════
                                             ╚ DECR ╝ SERIALIZE
                                             ↑
                                             └─ RX processing "World"

No Conflicts:
━━━━━━━━━━━━
- Separate AES cores (tx_aes_core, rx_aes_core)
- Separate buffers (tx_buffer[127:0], rx_buffer[127:0])
- Separate state machines (tx_state, rx_state)
- Same shared key (aes_key_reg[127:0])
- Independent operation confirmed by test_full_duplex_encryption (PASS ✓)
```

---

## 7. Bypass Mode vs Encrypted Mode Timing Comparison

```
Scenario: Transmitting single byte 'A' (0x41)

BYPASS MODE (AES_EN=0):
═══════════════════════

Time:  0    14ns   28ns   ...   86.8µs
       │    │      │             │
       
CPU writes 'A':
  ═══╗ ╔══════════════════════════
   Old╚0x41 ══════════════════════
     ↑ TX_DATA write

Direct path (no buffering):
  ═══╗ ╔══════════════════════════
     ╚═╝
     ↑ Immediate pass-through

UART TX:
       ╗ ╔════════════════════════
       ╚═╝ UART TX busy
       ↑ Starts immediately

uart_tx_pin:
       ════════╗   ╔══...═══╗  ╔══
        IDLE   ╚ S ╝ D0-D7  ╚P ╝ IDLE
               ↑ Transmits 'A' as plaintext

Total delay: 1 cycle to UART start
             + UART transmission time (86.8µs)


ENCRYPTED MODE (AES_EN=1):
══════════════════════════

Time:  0    14ns   ...   157ns  ...   86.8µs  ...   1.39ms
       │    │            │            │             │
       
CPU writes 'A':
  ═══╗ ╔══════════════════════════════════════════════
   Old╚0x41 ═════════════════════════════════════════
     ↑ TX_DATA write

Buffering (needs 16 bytes):
  ═══╗                     ╔══════════════════════════
   0 ╚ 1 ══════...══════15 ╝ 16 (full) ══════════════
     ↑ Accumulating       ↑ Buffer full
     
AES Encryption:
                           ╗     ╔════════════════════
                           ╚ AES ╝ Done
                           ↑ 11 cycles = 157ns

Serialization:
                                 ╗         ╔══════════
                                 ╚ Byte 0  ╝ Byte 1...
                                 ↑ Output encrypted bytes

UART TX:
                                 ╗   ╔══════════════...
                                 ╚TX ╝ busy
                                 ↑ Transmits ciphertext

uart_tx_pin:
                                 ════╗   ╔══...═══╗  ╔══
                                 IDLE╚ S ╝ D0-D7  ╚P ╝
                                 ↑ Encrypted byte

Total delay: Buffering wait (depends on message rate)
             + 11 cycles AES (157ns)
             + UART transmission time (1.39ms for 16 bytes)


COMPARISON:
═══════════

Metric                  | Bypass Mode | Encrypted Mode
──────────────────────────────────────────────────────
First byte latency      | ~14ns       | 16-byte buffer + 157ns
CPU overhead            | None        | None (hardware handles it)
UART transmission       | Same        | Same (limited by baud rate)
Throughput              | ~11.5 KB/s  | ~11.5 KB/s (UART limited)
AES processing          | N/A         | 157ns per 128-bit block
Performance penalty     | N/A         | 0.01% (negligible)

Conclusion: AES adds negligible latency. UART baud rate is the bottleneck.
```

---

## 8. Interrupt Timing

```
Scenario: TX done interrupt generation

System Clock (70MHz):
  ╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗
  ║ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝ ╚╝ ╚
  0  1  2  3  4  5  6  7  8  9

uart_tx_done (internal):
  ════════════╗ ╔═════════════════
        0     ╚═╝ 0
              ↑ Pulse when TX completes
              
tx_done_pending:
  ════════════╗           ╔═══════
        0     ╚═══════════╝ 0
              ↑ Set       ↑ Cleared
              
int_en_reg[0] (TX interrupt enable):
  ════════════╗═══════════════════
        1     ╚ 1
        ↑ Enabled by CPU

interrupt (output to CPU):
  ════════════╗           ╔═══════
        0     ╚═══════════╝ 0
              ↑ Asserted  ↑ Cleared
              
CPU writes INT_CLR[0]:
                        ╗ ╔═══════
                  0     ╚═╝ 0
                        ↑ Clear command
                        
Interrupt cleared:
                          ╗═══════
                          ╚ 0
                          ↑ Pending bit cleared


RX Ready Interrupt:
═══════════════════

uart_rx_ready (internal):
  ═════════════════════╗ ╔════════
           0            ╚═╝ 0
                        ↑ Pulse when RX byte ready
                        
rx_ready_pending:
  ═════════════════════╗      ╔═══
           0            ╚══════╝ 0
                        ↑      ↑
                     Set   CPU reads RX_DATA (auto-clear)
                     
int_en_reg[1] (RX interrupt enable):
  ═════════════════════╗══════════
           1            ╚ 1
           
interrupt (output to CPU):
  ═════════════════════╗      ╔═══
           0            ╚══════╝ 0
                        ↑ Interrupt fired


Timing Summary:
═══════════════

Interrupt latency:    1 cycle from event to interrupt assertion
Interrupt duration:   Until cleared by CPU (TX) or auto-clear (RX read)
CPU response time:    Depends on interrupt controller
Total overhead:       Minimal (hardware handles buffering/encryption)
```

This completes the comprehensive timing diagrams showing all signal relationships throughout the Secure UART system.
