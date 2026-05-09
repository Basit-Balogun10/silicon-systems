# AES-128 ASCII Art Diagrams

Text-based block diagrams for the AES-128 encryption engine. All diagrams use pure ASCII art for maximum compatibility.

---

## 1. AES-128 Top-Level Architecture

```
                           AES-128 ENCRYPTION ENGINE
    ┌─────────────────────────────────────────────────────────────────┐
    │                                                                   │
    │  ┌──────────────┐         ┌─────────────────────────────┐      │
    │  │  Key Input   │         │     Plaintext Input         │      │
    │  │  (128 bits)  │         │      (128 bits)             │      │
    │  └──────┬───────┘         └──────────┬──────────────────┘      │
    │         │                             │                          │
    │         ▼                             ▼                          │
    │  ┌──────────────┐         ┌──────────────────┐                 │
    │  │     Key      │         │     State        │                 │
    │  │  Expansion   │────────▶│    Register      │                 │
    │  │   Module     │ Round   │    (4x4 bytes)   │                 │
    │  │              │  Keys   │                  │                 │
    │  └──────────────┘         └────────┬─────────┘                 │
    │                                     │                            │
    │                           ┌─────────▼──────────┐                │
    │                           │   AddRoundKey      │                │
    │                           │   (Initial XOR)    │                │
    │                           └─────────┬──────────┘                │
    │                                     │                            │
    │                           ┌─────────▼──────────┐                │
    │                           │                    │                │
    │              ╔════════════╧════════════════════╧══════╗         │
    │              ║      ROUND FUNCTION (10 rounds)        ║         │
    │              ║                                         ║         │
    │              ║  ┌──────────────────────────────────┐  ║         │
    │              ║  │  1. SubBytes (S-Box)             │  ║         │
    │              ║  │     - Lookup each byte in S-Box  │  ║         │
    │              ║  │     - Non-linear substitution    │  ║         │
    │              ║  └────────────┬─────────────────────┘  ║         │
    │              ║               ▼                         ║         │
    │              ║  ┌──────────────────────────────────┐  ║         │
    │              ║  │  2. ShiftRows                    │  ║         │
    │              ║  │     - Rotate rows left           │  ║         │
    │              ║  │     - Row 0: no shift            │  ║         │
    │              ║  │     - Row 1: shift 1             │  ║         │
    │              ║  │     - Row 2: shift 2             │  ║         │
    │              ║  │     - Row 3: shift 3             │  ║         │
    │              ║  └────────────┬─────────────────────┘  ║         │
    │              ║               ▼                         ║         │
    │              ║  ┌──────────────────────────────────┐  ║         │
    │              ║  │  3. MixColumns                   │  ║         │
    │              ║  │     - Matrix multiplication      │  ║         │
    │              ║  │     - Galois field GF(2^8)       │  ║         │
    │              ║  │     - Skipped in final round     │  ║         │
    │              ║  └────────────┬─────────────────────┘  ║         │
    │              ║               ▼                         ║         │
    │              ║  ┌──────────────────────────────────┐  ║         │
    │              ║  │  4. AddRoundKey                  │  ║         │
    │              ║  │     - XOR with round key         │  ║         │
    │              ║  └────────────┬─────────────────────┘  ║         │
    │              ║               │                         ║         │
    │              ╚═══════════════╧═════════════════════════╝         │
    │                              │                                   │
    │                   ┌──────────▼──────────┐                        │
    │                   │   Ciphertext Output │                        │
    │                   │     (128 bits)      │                        │
    │                   └─────────────────────┘                        │
    │                                                                   │
    └───────────────────────────────────────────────────────────────────┘
```

---

## 2. State Matrix Organization (4x4 bytes)

```
    Input: 128-bit block (16 bytes)
    
    Byte Order:  b0  b1  b2  b3  b4  b5  b6  b7  b8  b9  b10 b11 b12 b13 b14 b15
    
    Arranged as 4x4 State Matrix (column-major):
    
                Column 0   Column 1   Column 2   Column 3
              ┌─────────┬─────────┬─────────┬─────────┐
    Row 0     │   b0    │   b4    │   b8    │   b12   │
              ├─────────┼─────────┼─────────┼─────────┤
    Row 1     │   b1    │   b5    │   b9    │   b13   │
              ├─────────┼─────────┼─────────┼─────────┤
    Row 2     │   b2    │   b6    │   b10   │   b14   │
              ├─────────┼─────────┼─────────┼─────────┤
    Row 3     │   b3    │   b7    │   b11   │   b15   │
              └─────────┴─────────┴─────────┴─────────┘
    
    All operations work on this state matrix
```

---

## 3. SubBytes Transformation (S-Box Lookup)

```
    S-Box: 16x16 lookup table (256 entries)
    
    For each byte in state matrix:
    
    Input Byte: 0xAB  (example)
              ────┬────
                  │
                  ▼
         ┌──────────────────┐
         │  S-Box Lookup    │
         │                  │
         │  High nibble (A) │──▶ Row index
         │  Low nibble  (B) │──▶ Column index
         │                  │
         │  S-Box[A][B]     │
         └────────┬─────────┘
                  │
                  ▼
    Output Byte: 0x62
    
    
    S-Box Partial Table (first 4 rows):
    
         0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
      ┌────────────────────────────────────────────────────────────────────────────────┐
    0 │ 63   7C   77   7B   F2   6B   6F   C5   30   01   67   2B   FE   D7   AB   76 │
    1 │ CA   82   C9   7D   FA   59   47   F0   AD   D4   A2   AF   9C   A4   72   C0 │
    2 │ B7   FD   93   26   36   3F   F7   CC   34   A5   E5   F1   71   D8   31   15 │
    3 │ 04   C7   23   C3   18   96   05   9A   07   12   80   E2   EB   27   B2   75 │
      └────────────────────────────────────────────────────────────────────────────────┘
    ... (continues to row F)
    
    Example: SubBytes(0xAB) = S-Box[A][B] = S-Box[10][11] = 0x62
```

---

## 4. ShiftRows Transformation

```
    Before ShiftRows:
                Column 0   Column 1   Column 2   Column 3
              ┌─────────┬─────────┬─────────┬─────────┐
    Row 0     │   a0    │   a1    │   a2    │   a3    │  No shift
              ├─────────┼─────────┼─────────┼─────────┤
    Row 1     │   b0    │   b1    │   b2    │   b3    │  Shift left 1
              ├─────────┼─────────┼─────────┼─────────┤
    Row 2     │   c0    │   c1    │   c2    │   c3    │  Shift left 2
              ├─────────┼─────────┼─────────┼─────────┤
    Row 3     │   d0    │   d1    │   d2    │   d3    │  Shift left 3
              └─────────┴─────────┴─────────┴─────────┘
    
    After ShiftRows:
                Column 0   Column 1   Column 2   Column 3
              ┌─────────┬─────────┬─────────┬─────────┐
    Row 0     │   a0    │   a1    │   a2    │   a3    │  ─────────────▶
              ├─────────┼─────────┼─────────┼─────────┤
    Row 1     │   b1    │   b2    │   b3    │   b0    │  ───────▶──────┐
              ├─────────┼─────────┼─────────┼─────────┤               │
    Row 2     │   c2    │   c3    │   c0    │   c1    │  ─────▶────────┤
              ├─────────┼─────────┼─────────┼─────────┤               │
    Row 3     │   d3    │   d0    │   d1    │   d2    │  ───▶──────────┘
              └─────────┴─────────┴─────────┴─────────┘
    
    Diffusion: Each column now contains bytes from different columns
```

---

## 5. MixColumns Transformation

```
    Process each column independently using matrix multiplication:
    
    Input Column:              Output Column:
    ┌────┐                     ┌────┐
    │ s0 │                     │ s'0│
    │ s1 │  ────MixColumns───▶ │ s'1│
    │ s2 │                     │ s'2│
    │ s3 │                     │ s'3│
    └────┘                     └────┘
    
    Matrix Multiplication (Galois Field GF(2^8)):
    
    ┌────┐   ┌───────────────┐   ┌────┐
    │ s'0│   │ 02  03  01  01│   │ s0 │
    │ s'1│ = │ 01  02  03  01│ ⊗ │ s1 │
    │ s'2│   │ 01  01  02  03│   │ s2 │
    │ s'3│   │ 03  01  01  02│   │ s3 │
    └────┘   └───────────────┘   └────┘
    
    Where ⊗ means Galois field multiplication
    
    Example for s'0:
    s'0 = (02 ⊗ s0) ⊕ (03 ⊗ s1) ⊕ (01 ⊗ s2) ⊕ (01 ⊗ s3)
    
    Galois Field Operations:
    - 01 ⊗ x = x               (identity)
    - 02 ⊗ x = x << 1          (shift left, XOR 0x1B if overflow)
    - 03 ⊗ x = (02 ⊗ x) ⊕ x    (multiply by 2, then XOR with x)
```

---

## 6. AddRoundKey Operation

```
    State Matrix        Round Key           Result
    ┌────────────┐      ┌────────────┐     ┌────────────┐
    │ s0  s4  s8 │      │ k0  k4  k8 │     │ r0  r4  r8 │
    │ s1  s5  s9 │  ⊕   │ k1  k5  k9 │  =  │ r1  r5  r9 │
    │ s2  s6  s10│      │ k2  k6  k10│     │ r2  r6  r10│
    │ s3  s7  s11│      │ k3  k7  k11│     │ r3  r7  r11│
    └────────────┘      └────────────┘     └────────────┘
    
    Byte-wise XOR operation:
    ri = si ⊕ ki  for all bytes i
    
    Example:
    State byte:  0x47
    Round key:   0x2B
               ────────
    XOR Result:  0x6C
```

---

## 7. Key Expansion Architecture

```
    Initial Key (128 bits = 16 bytes):
    ┌─────┬─────┬─────┬─────┐
    │ w0  │ w1  │ w2  │ w3  │  (4 words × 32 bits)
    └──┬──┴──┬──┴──┬──┴──┬──┘
       │     │     │     │
       ▼     ▼     ▼     ▼
    ┌─────────────────────────────────────────┐
    │      Key Expansion Algorithm            │
    │                                          │
    │  For i = 4 to 43:  (44 total words)     │
    │                                          │
    │  if (i mod 4 == 0):                     │
    │    temp = RotWord(w[i-1])               │
    │    temp = SubWord(temp)                 │
    │    temp = temp ⊕ Rcon[i/4]              │
    │    w[i] = w[i-4] ⊕ temp                 │
    │  else:                                   │
    │    w[i] = w[i-4] ⊕ w[i-1]               │
    │                                          │
    └─────────────────────────────────────────┘
       │     │     │           │
       ▼     ▼     ▼           ▼
    ┌─────┬─────┬─────┬ ... ┬─────┐
    │ w4  │ w5  │ w6  │ ... │ w43 │  (11 round keys)
    └─────┴─────┴─────┴─────┴─────┘
    
    Round Keys:
    Round 0:  w0  w1  w2  w3
    Round 1:  w4  w5  w6  w7
    Round 2:  w8  w9  w10 w11
    ...
    Round 10: w40 w41 w42 w43
```

---

## 8. Integration with UART TX FIFO

```
                     SECURE UART TX PATH
    
    CPU Writes     ┌──────────────┐
    (via regs) ───▶│   TX FIFO    │
                   │   (16 bytes) │
                   └──────┬───────┘
                          │
                          │ Full (16 bytes accumulated)
                          ▼
                   ┌──────────────┐
                   │ AES Engine   │
                   │   Trigger    │
                   └──────┬───────┘
                          │
                          ▼
                   ┌──────────────┐       ┌─────────────┐
    Plaintext ────▶│   AES-128    │──────▶│ Encrypted   │
    (16 bytes)     │  Encryption  │       │  Block      │
                   └──────────────┘       │ (16 bytes)  │
                                          └──────┬──────┘
                                                 │
                                                 ▼
                                          ┌──────────────┐
                                          │  UART TX     │
                                          │  Serializer  │
                                          └──────┬───────┘
                                                 │
                                                 ▼
                                          Physical TX Pin
    
    Timing:
    - CPU writes accumulate in TX FIFO (no encryption yet)
    - When 16th byte written, trigger AES encryption
    - AES encrypts block in ~24 cycles (~343 ns @ 70MHz)
    - Encrypted bytes feed to UART TX serializer
    - UART transmits at configured baud rate
```

---

## 9. Control FSM States

```
    AES Encryption FSM
    
    ┌─────────┐
    │  IDLE   │  Waiting for plaintext input
    └────┬────┘
         │ Start signal (16 bytes ready)
         ▼
    ┌─────────┐
    │KEY_EXPN │  Expand 128-bit key to 11 round keys
    └────┬────┘  (~16 cycles)
         │
         ▼
    ┌─────────┐
    │INIT_XOR │  AddRoundKey with round key 0
    └────┬────┘  (1 cycle)
         │
         ▼
    ┌─────────┐
    │ ROUND   │  Execute round function:
    │  1-9    │  - SubBytes
    └────┬────┘  - ShiftRows
         │        - MixColumns
         │        - AddRoundKey
         │        (~1 cycle per round)
         ▼
    ┌─────────┐
    │ ROUND   │  Final round:
    │   10    │  - SubBytes
    └────┬────┘  - ShiftRows
         │        - AddRoundKey (no MixColumns)
         │        (1 cycle)
         ▼
    ┌─────────┐
    │  DONE   │  Ciphertext ready, assert done signal
    └────┬────┘  (1 cycle)
         │
         └─────▶ Return to IDLE
    
    Total: ~24 cycles per 128-bit block
```

---

## 10. Module Hierarchy

```
                        uart_peripheral
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
        ▼                      ▼                      ▼
    uart_baud_gen      uart_register_if      uart_tx_flow
                                                     │
                                                     ├─▶ uart_tx
                                                     │
                                                     └─▶ cts_handler
        
        ▼                      ▼                      ▼
    uart_rx            TX FIFO (uart_fifo)    RX FIFO (uart_fifo)
                              │                      │
                              ▼                      ▼
                       ┌──────────────┐      ┌─────────────┐
                       │  AES Engine  │      │  uart_rts   │
                       │              │      │  generator  │
                       │ ┌──────────┐ │      └─────────────┘
                       │ │ SubBytes │ │
                       │ │ ShiftRows│ │
                       │ │MixColumns│ │
                       │ │ AddKey   │ │
                       │ │Key Expan │ │
                       │ └──────────┘ │
                       └──────────────┘
```

---

Return to [diagrams README](README.md) or [AES fundamentals](../AES_FUNDAMENTALS.md).
