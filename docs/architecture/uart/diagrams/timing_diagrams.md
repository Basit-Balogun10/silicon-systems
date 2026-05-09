# UART Peripheral - Timing Diagrams

This file contains detailed timing waveforms showing signal relationships for the UART peripheral.

---

## 1. Complete UART Transaction Timing

### Sending 0x55 (0b01010101) in 8N1 Format

```
Time →

Clock (70MHz):
  ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗
  ║ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═

Baud Tick (115200 bps, every 607 clocks @ 70MHz):
  ╔═════════════════════════════════════╗       ╔═════════════════
  ║ (607 cycles)                        ╚═══════╝
  ║◄─────────── 8.68 µs ────────────────►
  
TX Line (sending 0x55 = 0b01010101):
                 S  D0 D1 D2 D3 D4 D5 D6 D7  P
  Idle ═════════╗  ╔══╗  ╔══╗  ╔══╗  ╔══╗  ╔════════  Idle
                ╚══╝  ╚══╝  ╚══╝  ╚══╝  ╚══╝
                |  |  |  |  |  |  |  |  |  |  |
                0  1  0  1  0  1  0  1  0  1  1
             Start  LSB                 MSB Stop

Bit Breakdown:
  - IDLE state: Line = 1 (HIGH)
  - START bit:  Line = 0 (LOW) for 1 bit period
  - D0 (bit 0): Line = 1 (LSB of 0x55)
  - D1 (bit 1): Line = 0
  - D2 (bit 2): Line = 1
  - D3 (bit 3): Line = 0
  - D4 (bit 4): Line = 1
  - D5 (bit 5): Line = 0
  - D6 (bit 6): Line = 1
  - D7 (bit 7): Line = 0 (MSB of 0x55)
  - STOP bit:   Line = 1 (HIGH) for 1 bit period
  - Back to IDLE: Line = 1

TX_BUSY Flag:
  ════════╗                                              ╔════════
          ╚══════════════════════════════════════════════╝
          ↑ Start TX                                     ↑ TX Complete
          (tx_start=1)                                   (bit_cnt==10)

Total Frame Time (10 bits):
  At 115200 bps: 10 bits × 8.68 µs/bit = 86.8 µs per byte
  At 9600 bps:   10 bits × 104.17 µs/bit = 1.04 ms per byte
```

---

## 2. Receiving 0xAA (0b10101010) with 16x Oversampling

```
Time →

RX Line (receiving 0xAA = 0b10101010):
                 S  D0 D1 D2 D3 D4 D5 D6 D7  P
  Idle ═════════╗  ╔══╗  ╔══╗  ╔══╗  ╔══╗  ╔════════  Idle
                ╚══╝  ╚══╝  ╚══╝  ╚══╝  ╚══╝
                |  |  |  |  |  |  |  |  |  |  |
                0  0  1  0  1  0  1  0  1  1  1
             Start  LSB                 MSB Stop

16x Oversample Clock (tick every 607/16 ≈ 38 system clocks):
  ╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗╔═╗...
  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15  0  1 ...
                       ▲
                  Sample Point (cnt=7, middle of bit)

Oversample Counter:
  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15│ 0  1  2  3 ...
                       ▲  ▲  ▲
               Majority vote: sample @ 6,7,8

RX State Machine:
  IDLE ─────┐
            │ START detected (1→0 edge)
            ▼
         START ──┐
                 │ Verify start bit @ cnt=7 (should be 0)
                 ▼
         DATA[0] ──► DATA[1] ──► ... ──► DATA[7] ──┐
                                                     │
                                                     ▼
                                                  STOP ──┐
                                                         │ Verify stop=1
                                                         ▼
                                                       IDLE

RX_READY Flag:
  ════════════════════════════════════════════════╗
                                                   ╚═══════
                                                   ▲ Data ready
                                                   (stop bit verified)

user_interrupt:
  ════════════════════════════════════════════════╗
                                                   ╚═══════
                                                   ▲ Interrupt fired
                                                   (cleared on read)
```

---

## 3. Baud Rate Generator Timing (9600 bps @ 70MHz)

```
System Clock (70 MHz):
  ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗  ... (7291 clocks) ...  ╔═╗ ╔═╗ ╔═╗
  ║ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝                         ║ ╚═╝ ╚═╝ ╚═
  
Counter[15:0]:
  0000 0001 0002 0003 0004 ... 7289 7290 7291 0000 0001 0002
  
Comparator (counter == divisor?):
  ═══════════════════════════════════════╗       ╔═══════════
                                         ╚═══════╝
                                         ↑ Match! (counter == 7291)
                                         
baud_tick Output (1 cycle pulse):
  ════════════════════════════════════════╗╔══════════════════
                                          ╚╝
                                          ↑ 1 tick every 7291 clocks
                                          = 9600 Hz
                                          = 104.17 µs period

Calculation:
  Divisor = System_Clock / Baud_Rate
          = 70,000,000 / 9600
          = 7291.67 ≈ 7291

  Actual Baud Rate = 70,000,000 / 7291
                   = 9599.78 bps
                   ≈ 9600 bps (0.002% error - excellent!)
```

---

## 4. CPU Write Transaction Timing (Send Byte)

```
Time →

clk:
  ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗
  ║ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═

address[31:0]:
  ═══════════════╗   ╔═══════════════════════════════════
         0x00... ╚═══╝ 0x08
                 │
  (CTRL reg)     └──► (TX_DATA reg address)

data_in[31:0]:
  ═══════════════════╗   ╔═══════════════════════════════
         0x0031...   ╚═══╝ 0x55
  (BAUD=3, EN=1)     └──► (data byte to transmit)

data_write_n:
  ═══════════════╗       ╔╗       ╔═══════════════════════
                 ╚═══════╝╚═══════╝
                 ↑       ↑        ↑
           Setup  │Write│  Hold    No write
                 
tx_start (internal pulse):
  ════════════════════════╗╔══════════════════════════════
                          ╚╝
                          ↑ 1-cycle pulse to start TX

tx_busy:
  ════════════════════════╗                       ╔═══════
                          ╚═══════════════════════╝
                          ↑ Busy                  ↑ Done
                          (transmitting)          (86.8 µs later)

STATUS Register Read:
  CPU can poll bit[3] of STATUS (0x04) to check if TX_BUSY
  Before writing new data, should wait for tx_busy=0
```

---

## 5. CPU Read Transaction Timing (Receive Byte)

```
Time →

clk:
  ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗
  ║ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═

RX byte arrives:
  External UART transmission completes
  ↓
rx_ready:
  ════════════════════════╗               ╔═══════════════
                          ╚═══════════════╝
                          ↑ Data ready    ↑ Read clears flag

user_interrupt:
  ════════════════════════╗               ╔═══════════════
                          ╚═══════════════╝
                          ↑ Interrupt     ↑ Cleared on read

CPU Polling Sequence:

1. Read STATUS (0x04):
   address[31:0]:
     ═══════════════╗   ╔═══════════════════════════════════
                    ╚═══╝ 0x04
   
   data_read_n:
     ═══════════════╗   ╔╗   ╔═════════════════════════════
                    ╚═══╝╚═══╝
   
   data_out[31:0]:
     ═══════════════════╗   ╔═══════════════════════════════
            0x0000...   ╚═══╝ 0x04
                        └──► bit[2]=1 (RX_READY)

2. Read RX_DATA (0x0C) if RX_READY=1:
   address[31:0]:
     ═══════════════════════╗   ╔═══════════════════════════
                            ╚═══╝ 0x0C
   
   data_read_n:
     ═══════════════════════╗   ╔╗   ╔═════════════════════
                            ╚═══╝╚═══╝
   
   data_out[31:0]:
     ═══════════════════════════╗   ╔═══════════════════════
                0x00...         ╚═══╝ 0xAA
                                └──► Received byte

   rx_ready (auto-cleared):
     ═══════════════════════════════╗╔══════════════════════
                                    ╚╝
                                    ↑ Cleared on read

   user_interrupt (auto-cleared):
     ═══════════════════════════════╗╔══════════════════════
                                    ╚╝
                                    ↑ Interrupt dismissed
```

---

## 6. TX State Machine Timing

```
State Progression for sending 0x55:

State:
  IDLE ═╗
        ╚══════════► START ═╗
                            ╚════► DATA[0] ═╗
                                            ╚══► DATA[1] ═╗
                                                          ╚══► ... ═╗
                                                                    ╚══► DATA[7] ═╗
                                                                                  ╚══► STOP ═╗
                                                                                            ╚══► IDLE

baud_tick events (one per state transition):
  ════╗   ╔════╗   ╔════╗   ╔════╗   ╔════╗   ╔════╗   ╔════╗   ╔════╗   ╔════╗   ╔═══
      ╚═══╝    ╚═══╝    ╚═══╝    ╚═══╝    ╚═══╝    ╚═══╝    ╚═══╝    ╚═══╝    ╚═══╝
      ↑        ↑        ↑        ↑        ↑        ↑        ↑        ↑        ↑        ↑
   tx_start  S→D0     D0→D1    D1→D2    D2→D3    D3→D4    D4→D5    D5→D6    D6→D7    D7→STOP

tx_out values:
  ══1══╗0══╗1══╗0══╗1══╗0══╗1══╗0══╗1══╗0══╗1══╔════════
       ╚═══╝   ╚═══╝   ╚═══╝   ╚═══╝   ╚═══╝   ╚═══╝
       S   D0  D1  D2  D3  D4  D5  D6  D7  STOP  IDLE
       0   1   0   1   0   1   0   1   0   1     1

bit_cnt[3:0]:
  0000 ──► 0001 ──► 0010 ──► 0011 ──► 0100 ──► 0101 ──► 0110 ──► 0111 ──► 1000 ──► 1001 ──► 0000
  IDLE     START    D0       D1       D2       D3       D4       D5       D6       D7       IDLE
                    
tx_busy:
  ════════╗                                                                          ╔═══════════
          ╚══════════════════════════════════════════════════════════════════════════╝
          ↑ Set on tx_start                                                          ↑ Clear when STOP→IDLE
```

---

## 7. RX Oversampling Detail (Zoomed into 1 bit period)

```
One Bit Period (e.g., D0 bit receiving '0'):

RX Line (stable for entire bit):
  ════════════════════════════════════════════════════════════════
           LOW (0)
  ════════════════════════════════════════════════════════════════

Oversample Ticks (16 per bit):
  ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗ ╔═╗
  0   1   2   3   4   5   6   7   8   9   10  11  12  13  14  15
                          ▲   ▲   ▲
                      Sample @ 6,7,8 for majority vote

sample_cnt[3:0]:
  0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 11 → 12 → 13 → 14 → 15 → 0 (next bit)

Majority Voter:
  At cnt=6: rx_sync = 0 ──┐
  At cnt=7: rx_sync = 0   ├──► Majority = 0 (2 or 3 out of 3)
  At cnt=8: rx_sync = 0 ──┘

Sampled Bit Value:
  ════════════════════════════════════════════════════════════════
                                0
  ════════════════════════════════════════════════════════════════
                                ↑ Sampled value goes into shift register

Why sample 3 times?
  - Noise immunity: Even if one sample is corrupted, majority wins
  - Example with noise:
    cnt=6: 0 (clean)
    cnt=7: 1 (noise glitch!)
    cnt=8: 0 (clean)
    → Majority = 0 (correct!)
```

---

## 8. Timing Constraints Summary

### Setup/Hold Times (Example - Actual values depend on PDK)

```
CPU Interface Timing:

clk ────────╗    ╔────────╗    ╔────────
            ╚════╝        ╚════╝

address ═════╗   valid    ╔════════
             ╚════════════╝
             ↑            ↑
           Tsetup       Thold
           (e.g., 2ns)  (e.g., 1ns)

data_write_n ═════╗╔═════════
                  ╚╝
                  ↑ Must be stable before clock edge
```

### Baud Rate Accuracy

```
Required Accuracy: ±2% for reliable communication

Example Calculations:
  Target: 9600 bps
  System Clock: 70 MHz
  
  Divisor = 70,000,000 / 9600 = 7291.67
  Rounded = 7291
  
  Actual Baud = 70,000,000 / 7291 = 9599.78 bps
  Error = (9599.78 - 9600) / 9600 = -0.002%
  
  ✓ Well within ±2% tolerance!
```

---

## Key Timing Relationships

1. **Baud Period** = System_Clock / Divisor
2. **Frame Time** = 10 × Baud_Period (for 8N1)
3. **Oversample Period** = Baud_Period / 16
4. **Sample Point** = Middle of bit (count = 7)
5. **TX Latency** = Time from tx_start to first bit on wire ≈ 1 baud period
6. **RX Latency** = Time from last bit to rx_ready ≈ 0.5 baud period

---

Return to [diagrams README](README.md) for more diagram formats.
