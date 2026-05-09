# AES Encryption Fundamentals - Complete Guide for Beginners

> **🎯 Quick Start**: If you're brand new to encryption, start with the [Simple Lock and Key Analogy](#the-simple-analogy-lock-and-key) below, then explore [How AES Works Step-by-Step](#how-aes-works-step-by-step)!

---

## What is AES? (The Basics)

**AES** = Advanced Encryption Standard

**In Plain English**: AES is a mathematical recipe for scrambling data so thoroughly that only someone with the secret key can unscramble it. It's like a super-secure digital lock!

### The Simple Analogy: Lock and Key

Think of AES like a high-security safe:

-   **Plaintext** = Your valuables (readable data)
-   **Encryption** = Locking the valuables in the safe
-   **Ciphertext** = Locked safe (scrambled, unreadable data)
-   **Key** = The secret combination (only you know it)
-   **Decryption** = Unlocking the safe with your combination
-   **Key Size** = How complex the combination is (128-bit = VERY complex!)

**Important**: Even if someone sees the locked safe (ciphertext), they can't access the valuables without the key!

### Key Characteristics

1. **Symmetric** - Same key for encryption AND decryption (like a house key)
2. **Block Cipher** - Encrypts data in fixed 128-bit chunks (16 bytes at a time)
3. **Secure** - Used by governments and military (approved by NSA!)
4. **Fast** - Designed for hardware efficiency (perfect for our FPGA!)
5. **Standard** - Adopted worldwide in 2001, replacing older DES

### Real-World Applications

**You use AES encryption every single day!** Here are common examples:

1. **HTTPS Websites** 🔒
    - Your bank's website uses AES to protect your password
    - E-commerce sites encrypt credit card numbers with AES
2. **Mobile Phones** 📱
    - iPhone/Android encrypt your photos, messages, passwords
    - WhatsApp uses AES for end-to-end encryption
3. **WiFi Networks** 📡
    - WPA2/WPA3 use AES to secure your wireless connection
    - Prevents neighbors from snooping on your traffic
4. **USB Flash Drives** 💾
    - Encrypted USB drives use AES to protect files
    - BitLocker (Windows) and FileVault (Mac) use AES
5. **Video Streaming** 📺
    - Netflix, Amazon Prime use AES to protect content
    - Prevents unauthorized copying
6. **VPN Connections** 🌐
    - Corporate VPNs encrypt all traffic with AES
    - Protects sensitive business data

---

## Why AES? (Compared to Other Options)

### The Secret Message Analogy

Imagine different ways to send secret messages:

1. **Caesar Cipher** = Shift each letter by 3 (A→D, B→E, C→F)
    - Simple, but easily broken (a child can crack it!)
    - Historical curiosity, not secure
2. **DES** = 1970s military encryption standard
    - Was secure for decades
    - Now broken (modern computers crack it in hours)
    - Replaced by AES
3. **3DES** = Triple DES (apply DES three times)
    - More secure than DES
    - Slow and inefficient
    - Being phased out
4. **AES** = Modern, fast, unbreakable (with current technology)
    - Battle-tested for 23+ years
    - No known practical attacks
    - Fast in both hardware and software

**AES wins because**: It's the perfect balance of security, speed, and hardware efficiency!

### Advantages

-   **Extremely Secure** - No known practical attacks
-   **Fast in Hardware** - Designed for efficient circuit implementation
-   **Flexible Key Sizes** - 128, 192, or 256 bits (we'll use 128)
-   **Widely Supported** - Every modern chip has AES instructions
-   **Government Approved** - NSA uses AES-256 for TOP SECRET data!
-   **Patent-Free** - Royalty-free, open standard

---

## AES Basics: Blocks, Keys, and Rounds

### The Building Blocks

**1. Block Size** (Always 128 bits = 16 bytes):

```
Plaintext Block (16 bytes):
┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
│48│65│6C│6C│6F│20│57│6F│72│6C│64│21│00│00│00│00│
└──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘
 "H  e  l  l  o     W  o  r  l  d  !  \0 \0 \0 \0"

↓ AES-128 Encryption with Key ↓

Ciphertext Block (16 bytes):
┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
│A7│3B│9F│2C│E8│14│D6│5A│81│F3│4E│C2│97│0B│6D│45│
└──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘
 (Looks like random gibberish - unreadable!)
```

**2. Key Size** (We'll use 128-bit = 16 bytes):

```
128-bit Key:
┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
│2B│7E│15│16│28│AE│D2│A6│AB│F7│15│88│09│CF│4F│3C│
└──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘
 (Secret key - keep this safe!)

Longer keys = more security:
- AES-128: 10 rounds, very secure (our choice)
- AES-192: 12 rounds, more secure
- AES-256: 14 rounds, maximum security (government/military)
```

**3. Rounds** (How many times we scramble):

-   **AES-128**: 10 rounds
-   **AES-192**: 12 rounds
-   **AES-256**: 14 rounds

Each round applies 4 mathematical transformations to scramble the data further.

### The State Array (Core Data Structure)

AES organizes the 16-byte block as a **4×4 matrix** called the "State":

```
Input bytes (linear):
[00][01][02][03][04][05][06][07][08][09][10][11][12][13][14][15]

Arranged as State (4×4 matrix, COLUMN-major order):
     Col0  Col1  Col2  Col3
    ┌────┬────┬────┬────┐
Row0│ 00 │ 04 │ 08 │ 12 │
    ├────┼────┼────┼────┤
Row1│ 01 │ 05 │ 09 │ 13 │
    ├────┼────┼────┼────┤
Row2│ 02 │ 06 │ 10 │ 14 │
    ├────┼────┼────┼────┤
Row3│ 03 │ 07 │ 11 │ 15 │
    └────┴────┴────┴────┘

Note: Filled column-by-column (not row-by-row)!
This is important for ShiftRows operation.
```

---

## How AES Works: Step-by-Step

### The High-Level Process

```
┌────────────┐
│  Plaintext │  "Hello World!..."
│  (16 bytes)│
└──────┬─────┘
       │
       ▼
┌─────────────────────────────┐
│   Initial Round (Round 0)   │
│  AddRoundKey (with Key)     │
└──────┬──────────────────────┘
       │
       ▼
┌─────────────────────────────┐
│  Main Rounds (Rounds 1-9)   │  ← Repeat 9 times
│  1. SubBytes                │
│  2. ShiftRows               │
│  3. MixColumns              │
│  4. AddRoundKey             │
└──────┬──────────────────────┘
       │
       ▼
┌─────────────────────────────┐
│  Final Round (Round 10)     │
│  1. SubBytes                │
│  2. ShiftRows               │
│  3. AddRoundKey (no MixCols)│
└──────┬──────────────────────┘
       │
       ▼
┌────────────┐
│ Ciphertext │  (Scrambled gibberish)
│ (16 bytes) │
└────────────┘
```

**Why 10 rounds?** Security! Each round makes it exponentially harder to crack. After 10 rounds, there's no known way to reverse without the key.

---

## The Four Transformations (The Magic Happens Here!)

### 1. SubBytes: Substitution (Confusion)

**Analogy**: Replace each word in a sentence with a code word from a secret dictionary.

**How it works:**

-   Look up each byte in a special table called "S-Box" (Substitution Box)
-   Replace original byte with S-Box value
-   **Purpose**: Create confusion (hide relationships between input and output)

**Example:**

```
Before SubBytes:
    ┌────┬────┬────┬────┐
    │ 00 │ 04 │ 08 │ 12 │
    ├────┼────┼────┼────┤
    │ 01 │ 05 │ 09 │ 13 │
    ├────┼────┼────┼────┤
    │ 02 │ 06 │ 10 │ 14 │
    ├────┼────┼────┼────┤
    │ 03 │ 07 │ 11 │ 15 │
    └────┴────┴────┴────┘

S-Box Lookup:
0x00 → 0x63
0x01 → 0x7C
0x02 → 0x77
... (256 entries total)

After SubBytes:
    ┌────┬────┬────┬────┐
    │ 63 │ F2 │ 30 │ C8 │
    ├────┼────┼────┼────┤
    │ 7C │ 6F │ 83 │ 5B │
    ├────┼────┼────┼────┤
    │ 77 │ 7B │ CA │ 81 │
    ├────┼────┼────┼────┤
    │ 7B │ F2 │ AB │ 4C │
    └────┴────┴────┴────┘
```

**The S-Box** is a 256-entry lookup table designed mathematically to resist cryptanalysis. It's fixed (same for all AES implementations) and pre-computed.

**Hardware Implementation:**

-   Option 1: 256-byte ROM (fast, larger area)
-   Option 2: Compute on-the-fly using GF(2⁸) math (slower, smaller area)
-   **We'll use ROM**: Faster, acceptable area cost

---

### 2. ShiftRows: Permutation (Diffusion)

**Analogy**: Shuffle rows of a deck of cards by different amounts.

**How it works:**

-   Row 0: No shift
-   Row 1: Shift left by 1 position
-   Row 2: Shift left by 2 positions
-   Row 3: Shift left by 3 positions
-   **Purpose**: Create diffusion (spread information across columns)

**Example:**

```
Before ShiftRows:
       Col0  Col1  Col2  Col3
      ┌────┬────┬────┬────┐
Row 0 │ 63 │ F2 │ 30 │ C8 │  ← No shift
      ├────┼────┼────┼────┤
Row 1 │ 7C │ 6F │ 83 │ 5B │  ← Shift left 1
      ├────┼────┼────┼────┤
Row 2 │ 77 │ 7B │ CA │ 81 │  ← Shift left 2
      ├────┼────┼────┼────┤
Row 3 │ 7B │ F2 │ AB │ 4C │  ← Shift left 3
      └────┴────┴────┴────┘

After ShiftRows:
       Col0  Col1  Col2  Col3
      ┌────┬────┬────┬────┐
Row 0 │ 63 │ F2 │ 30 │ C8 │  (unchanged)
      ├────┼────┼────┼────┤
Row 1 │ 6F │ 83 │ 5B │ 7C │  (rotated left)
      ├────┼────┼────┼────┤
Row 2 │ CA │ 81 │ 77 │ 7B │  (rotated left x2)
      ├────┼────┼────┼────┤
Row 3 │ 4C │ 7B │ F2 │ AB │  (rotated left x3)
      └────┴────┴────┴────┘
```

**Why shift?** Bytes from different columns are now mixed within each column. This spreads information across the entire state!

**Hardware Implementation:**

-   Simple wire remapping (zero logic gates!)
-   Just rearrange connections
-   **Cost**: Essentially free!

---

### 3. MixColumns: Matrix Multiplication (Diffusion++)

**Analogy**: Stir ingredients in a cake mix - each spoonful now contains bits of everything.

**How it works:**

-   Multiply each column by a fixed 4×4 matrix
-   Uses special Galois Field GF(2⁸) arithmetic (not regular math!)
-   **Purpose**: Maximum diffusion within each column

**Example (Simplified):**

```
Before MixColumns:
    ┌────┬────┬────┬────┐
    │ 63 │ ... Column 0 only ...
    ├────┤
    │ 6F │
    ├────┤
    │ CA │
    ├────┤
    │ 4C │
    └────┘

Multiply by fixed matrix:
┌────┐   ┌──────────────────┐   ┌────┐
│ 02 │   │ 02 03 01 01      │   │ 63 │
│ 01 │ = │ 01 02 03 01      │ × │ 6F │
│ 01 │   │ 01 01 02 03      │   │ CA │
│ 03 │   │ 03 01 01 02      │   │ 4C │
└────┘   └──────────────────┘   └────┘

After MixColumns:
    ┌────┐
    │ 5F │  (each output byte is mix of all 4 input bytes!)
    ├────┤
    │ 72 │
    ├────┤
    │ 64 │
    ├────┤
    │ 15 │
    └────┘

Repeat for columns 1, 2, 3...
```

**Galois Field Math** is special "wrap-around" arithmetic used in cryptography:

-   Addition: XOR (exclusive OR)
-   Multiplication: Special algorithm with polynomial reduction

**Why this matters:** Changing 1 input bit affects ALL 4 output bytes!

**Hardware Implementation:**

-   Lookup tables + XOR operations
-   Or: Dedicated GF(2⁸) multipliers
-   **Cost**: ~100-200 gates per column (manageable)

**Note**: MixColumns is SKIPPED in the final round (Round 10).

---

### 4. AddRoundKey: XOR with Round Key

**Analogy**: Add a secret ingredient to each layer of the cake.

**How it works:**

-   XOR the state with the round key (derived from main key)
-   **Purpose**: Incorporate the secret key into the encryption

**Example:**

```
State (after MixColumns):
    ┌────┬────┬────┬────┐
    │ 5F │ 9C │ 2A │ E7 │
    ├────┼────┼────┼────┤
    │ 72 │ 4B │ D8 │ 1F │
    ├────┼────┼────┼────┤
    │ 64 │ 3E │ C9 │ A2 │
    ├────┼────┼────┼────┤
    │ 15 │ 87 │ F0 │ 53 │
    └────┴────┴────┴────┘

XOR (⊕) Round Key:
    ┌────┬────┬────┬────┐
    │ 2B │ 7E │ 15 │ 16 │
    ├────┼────┼────┼────┤
    │ 28 │ AE │ D2 │ A6 │
    ├────┼────┼────┼────┤
    │ AB │ F7 │ 15 │ 88 │
    ├────┼────┼────┼────┤
    │ 09 │ CF │ 4F │ 3C │
    └────┴────┴────┴────┘

Result (after AddRoundKey):
    ┌────┬────┬────┬────┐
    │ 74 │ E2 │ 3F │ F1 │  (5F ⊕ 2B = 74, etc.)
    ├────┼────┼────┼────┤
    │ 5A │ E5 │ 0A │ B9 │
    ├────┼────┼────┼────┤
    │ CF │ C9 │ DC │ 2A │
    ├────┼────┼────┼────┤
    │ 1C │ 48 │ BF │ 6F │
    └────┴────┴────┴────┘
```

**XOR (Exclusive OR) Properties:**

-   A ⊕ B ⊕ B = A (self-inverting!)
-   This is why the same key can decrypt: just XOR again!

**Hardware Implementation:**

-   128 XOR gates (one per bit)
-   **Cost**: Trivial! (~128 gates)

---

## Key Expansion: Generating Round Keys

### The Challenge

We have ONE 128-bit key, but need ELEVEN 128-bit round keys (one for initial round + one per round 1-10).

**Solution:** Key Expansion Algorithm (generates 11 round keys from 1 master key)

### Key Expansion Overview

```
Original Key (128 bits = 4 words):
┌─────────┬─────────┬─────────┬─────────┐
│ Word 0  │ Word 1  │ Word 2  │ Word 3  │
│(4 bytes)│(4 bytes)│(4 bytes)│(4 bytes)│
└─────────┴─────────┴─────────┴─────────┘

Expand to 44 words (11 rounds × 4 words):
┌───────┬───────┬───────┬───────┐
│ W[0]  │ W[1]  │ W[2]  │ W[3]  │ ← Round 0 Key
├───────┼───────┼───────┼───────┤
│ W[4]  │ W[5]  │ W[6]  │ W[7]  │ ← Round 1 Key
├───────┼───────┼───────┼───────┤
│ W[8]  │ W[9]  │ W[10] │ W[11] │ ← Round 2 Key
├───────┼───────┼───────┼───────┤
   ...  (continues to W[43])
├───────┼───────┼───────┼───────┤
│W[40]  │W[41]  │W[42]  │W[43]  │ ← Round 10 Key
└───────┴───────┴───────┴───────┘
```

### Key Expansion Algorithm

**For each new word W[i]:**

```
if (i % 4 == 0):  // Every 4th word (start of new round key)
    temp = RotWord(W[i-1])      // Rotate bytes left
    temp = SubWord(temp)         // S-Box substitution
    temp = temp ⊕ Rcon[i/4]     // XOR with round constant
    W[i] = W[i-4] ⊕ temp
else:
    W[i] = W[i-4] ⊕ W[i-1]      // Simple XOR
```

**Helper Functions:**

1. **RotWord**: Rotate 4-byte word left by 1 byte

    ```
    [A0, A1, A2, A3] → [A1, A2, A3, A0]
    ```

2. **SubWord**: Apply S-Box to each byte

    ```
    [A0, A1, A2, A3] → [S(A0), S(A1), S(A2), S(A3)]
    ```

3. **Rcon** (Round Constant): Prevents symmetry attacks
    ```
    Rcon[1] = 0x01000000
    Rcon[2] = 0x02000000
    Rcon[3] = 0x04000000
    ... (powers of 2 in GF(2⁸))
    ```

**Example (First Round Key Generation):**

```
Given:
W[0] = 2B7E1516
W[1] = 28AED2A6
W[2] = ABF71588
W[3] = 09CF4F3C

Generate W[4]:
  temp = RotWord(W[3]) = RotWord(09CF4F3C) = CF4F3C09
  temp = SubWord(temp) = 8A84EB01  (S-Box lookup)
  temp = temp ⊕ Rcon[1] = 8A84EB01 ⊕ 01000000 = 8B84EB01
  W[4] = W[0] ⊕ temp = 2B7E1516 ⊕ 8B84EB01 = A0FAFE17

Generate W[5]:
  W[5] = W[1] ⊕ W[4] = 28AED2A6 ⊕ A0FAFE17 = 88542CB1

... continue for W[6], W[7], then repeat for all rounds
```

**Hardware Considerations:**

-   Can be pre-computed offline (store all 11 keys in registers)
-   Or compute on-the-fly (saves storage, adds latency)
-   **Our choice**: Pre-compute during initialization (faster encryption/decryption)

---

## AES Decryption: The Reverse Process

Good news! Decryption is just encryption in reverse with inverse operations:

```
Encryption Operations      Decryption Operations
────────────────────      ─────────────────────
SubBytes              →   InvSubBytes (inverse S-Box)
ShiftRows             →   InvShiftRows (shift right instead)
MixColumns            →   InvMixColumns (inverse matrix)
AddRoundKey           →   AddRoundKey (XOR is self-inverse!)
```

**Decryption Process:**

```
Round 0:  AddRoundKey (Round 10 key)
          ↓
Rounds 1-9: InvShiftRows
           InvSubBytes
           AddRoundKey (Round 9-1 keys, reverse order)
           InvMixColumns
          ↓
Round 10: InvShiftRows
          InvSubBytes
          AddRoundKey (Round 0 key)
          ↓
      Plaintext Recovered!
```

**Implementation Approaches:**

1. **Separate Encrypt/Decrypt Modules** (Our approach)
    - ✅ Simpler logic
    - ✅ Easier to test
    - ❌ ~2× area (two datapaths)
2. **Combined Encrypt/Decrypt Module**
    - ✅ Smaller area (shared datapath)
    - ❌ More complex control
    - ❌ Multiplexers add delay

**For this project**: We'll implement both, allowing encrypt/decrypt operations.

---

## AES-128 Complete Example Walkthrough

Let's encrypt "Hello World!!!" with AES-128:

### Setup

```
Plaintext: "Hello World!!!\0" (16 bytes)
  Hex: 48 65 6C 6C 6F 20 57 6F 72 6C 64 21 21 21 00

Key: "YELLOW SUBMARINE" (16 bytes)
  Hex: 59 45 4C 4C 4F 57 20 53 55 42 4D 41 52 49 4E 45

Block Size: 128 bits (16 bytes)
Rounds: 10
```

### Step-by-Step (Round 1 only, for brevity)

**Initial State (Plaintext as 4×4 matrix):**

```
    ┌────┬────┬────┬────┐
    │ 48 │ 20 │ 21 │ 00 │  "H  W  !  \0"
    ├────┼────┼────┼────┤
    │ 65 │ 57 │ 21 │ ?? │  "e  W  !  ??"
    ├────┼────┼────┼────┤
    │ 6C │ 6F │ 21 │ ?? │  "l  o  !  ??"
    ├────┼────┼────┼────┤
    │ 6C │ 72 │ ?? │ ?? │  "l  r  ?? ??"
    └────┴────┴────┴────┘
```

**Round 0: AddRoundKey (Initial Whitening)**

```
State ⊕ Key[0]:
Result omitted for brevity (XOR with first round key)
```

**Round 1: SubBytes**

```
Each byte → S-Box lookup
0x48 → 0x52
0x65 → 0xFB
... (all 16 bytes substituted)
```

**Round 1: ShiftRows**

```
Row shifts as described earlier
```

**Round 1: MixColumns**

```
Each column multiplied by fixed matrix
```

**Round 1: AddRoundKey**

```
XOR with Round 1 key
```

**... Rounds 2-10 continue similarly ...**

**Final Ciphertext (after Round 10):**

```
Hex: 3A D7 7B B4 0D 7A 36 60 A8 9E CA F3 24 66 EF 97

Looks random! No visible pattern to "Hello World!!!"
```

**To Decrypt:**

```
Apply inverse operations with same key:
  3A D7 ... → (InvSubBytes, InvShiftRows, etc.) → 48 65 ... "Hello World!!!"
```

---

## Hardware Implementation Considerations

### Area Estimates (AES-128 Core)

**Component Breakdown:**

```
S-Box ROM (SubBytes):         ~400-600 cells
Inverse S-Box (InvSubBytes):  ~400-600 cells
ShiftRows:                    0 cells (wiring only!)
InvShiftRows:                 0 cells (wiring only!)
MixColumns logic:             ~300-400 cells
InvMixColumns logic:          ~300-400 cells
AddRoundKey (XOR):            ~150 cells
State registers:              ~200 cells
Key registers:                ~200 cells
Control FSM:                  ~100-150 cells
────────────────────────────────────────────
Total (Encrypt + Decrypt):    ~2000-2500 cells
```

**Optimization Options:**

1. **ROM-based S-Box** (our choice)
    - Fast: 1 cycle lookup
    - Area: Moderate
2. **Calculated S-Box**
    - Smaller area
    - Slower: Multiple cycles per byte
3. **Pipeline Stages**
    - Can pipeline each transformation
    - Trades area for throughput

### Timing Analysis

**Encryption/Decryption Latency** (assuming 70MHz clock):

```
Non-pipelined (our approach):
  - 1 cycle: Initial AddRoundKey
  - 10 cycles × 10 rounds: Main rounds (1 cycle per round)
  - 1 cycle: Final round
  ────────────────
  Total: ~12 cycles = 171ns @ 70MHz

Throughput:
  128 bits / 12 cycles = 10.67 bits/cycle
  At 70 MHz: 746 Mbps
```

**Pipelined (advanced):**

```
10-stage pipeline:
  Throughput: 1 block per cycle
  At 70 MHz: 8.96 Gbps! (but much larger area)
```

### Integration with UART

**Secure UART Data Path:**

```
TX Path (Encryption):
  CPU → TX_DATA Register → Plaintext Buffer
      ↓
  AES Encrypt (12 cycles) → Ciphertext
      ↓
  TX FIFO → UART TX → Serial Output (encrypted!)

RX Path (Decryption):
  Serial Input → UART RX → RX FIFO
      ↓
  Ciphertext Buffer → AES Decrypt (12 cycles)
      ↓
  Plaintext → RX_DATA Register → CPU

Key Management:
  CPU writes 128-bit key to KEY registers (4×32-bit writes)
  Key expansion happens automatically
  Keys stored securely in registers
```

**Control Flow:**

```
1. CPU configures encryption key (one-time setup)
2. CPU writes plaintext byte to TX_DATA
3. When 16 bytes accumulated → trigger AES encrypt
4. Encrypted block goes to TX FIFO
5. UART transmits encrypted bytes
6. Remote receiver does reverse process
```

---

## Security Considerations

### AES-128 Strength

**How secure is AES-128?**

```
Key space: 2^128 possible keys
         = 340,282,366,920,938,463,463,374,607,431,768,211,456 keys

Brute force attack:
  Trying 1 trillion keys/second
  Would take: 10,790,000,000,000,000,000,000 years

  (Universe is only 13,800,000,000 years old!)

Conclusion: Brute force is impossible.
```

**Known Attacks:**

-   **Brute Force**: Computationally infeasible
-   **Differential Cryptanalysis**: Doesn't work on AES
-   **Linear Cryptanalysis**: Doesn't work on AES
-   **Side-Channel Attacks**: Possible but very difficult

### Implementation Security

**Potential Vulnerabilities:**

1. **Weak Keys** ❌

    - DON'T use: "0000000000000000" or predictable keys
    - DO use: Cryptographically random keys

2. **Key Reuse with Same Data** ❌

    - Encrypting same plaintext with same key → same ciphertext (pattern leak!)
    - Solution: Use modes like CBC, CTR (add randomness)

3. **Side-Channel Attacks** ⚠️

    - Power analysis: Measure power consumption to extract key
    - Timing attacks: Measure encryption time
    - Mitigation: Constant-time implementation, power masking

4. **Padding Oracle Attacks** ⚠️
    - Exploits error messages about padding
    - Mitigation: Authenticated encryption (add HMAC)

**For Our Implementation:**

-   ✅ Use strong random keys
-   ✅ Implement constant-time operations where possible
-   ⚠️ Add message authentication (future enhancement)
-   ⚠️ Use encryption modes (ECB is okay for demo, but CBC/CTR better for production)

---

## Common AES Mistakes and How to Avoid Them

### ❌ Mistake 1: Using ECB Mode for Large Data

**Problem**: Same plaintext block → same ciphertext block (pattern leak)

```
Plaintext:  "HELLO HELLO HELLO"
Ciphertext: [X5$2] [X5$2] [X5$2]  ← Repeated pattern visible!
```

**Solution**: Use CBC, CTR, or GCM modes (add randomness/IV)

### ❌ Mistake 2: Hardcoding Keys

**Problem**: Key embedded in code → anyone can extract it
**Solution**: Load keys at runtime from secure storage

### ❌ Mistake 3: Not Authenticating Ciphertext

**Problem**: Attacker can modify ciphertext without detection
**Solution**: Add HMAC or use authenticated encryption (AES-GCM)

### ❌ Mistake 4: Column-Major vs Row-Major Confusion

**Problem**: State array filled incorrectly → wrong results
**Solution**: Remember AES uses COLUMN-major ordering!

### ❌ Mistake 5: Galois Field Math Errors

**Problem**: Using regular multiplication instead of GF(2⁸) → corruption
**Solution**: Use GF(2⁸) libraries or lookup tables

---

## Implementation Checklist

### AES Core Module

📋 S-Box ROM (256 bytes)  
📋 Inverse S-Box ROM (256 bytes)  
📋 SubBytes transformation  
📋 ShiftRows transformation  
📋 MixColumns transformation (with GF multiplication)  
📋 AddRoundKey (128-bit XOR)  
📋 Key expansion logic  
📋 Round counter FSM  
📋 State registers (128 bits)  
📋 Round key registers (11 × 128 bits or on-the-fly generation)

### Decryption Support

📋 InvSubBytes (inverse S-Box)  
📋 InvShiftRows  
📋 InvMixColumns  
📋 Reverse round key order

### Integration with UART

📋 Plaintext input buffer (16 bytes)  
📋 Ciphertext output buffer (16 bytes)  
📋 Encryption trigger logic  
📋 Busy/ready status flags  
📋 Key configuration registers  
📋 Mode select (encrypt/decrypt)

### Testing

📋 Test vectors from NIST (official AES test suite)  
📋 Known plaintext/ciphertext pairs  
📋 Key expansion verification  
📋 Each transformation individually  
📋 Full encrypt/decrypt loopback  
📋 Integration with UART TX/RX

---

## Resources and References

### Official Standards

-   **NIST FIPS 197**: The official AES specification
    -   https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.197.pdf

### Test Vectors

-   **NIST AES Test Vectors**: For verification
    -   https://csrc.nist.gov/projects/cryptographic-algorithm-validation-program

### Learning Resources

-   **Computerphile AES Video**: Visual explanation
-   **The Design of Rijndael** (book): Deep dive by AES creators

---

## Next Steps

1. ✅ Review fundamentals (you just did!)
2. 📊 Study [BLOCK_DIAGRAMS.md](BLOCK_DIAGRAMS.md) for architecture details
3. 💻 Start coding SubBytes (S-Box lookup)
4. 💻 Implement ShiftRows (wiring only!)
5. 💻 Implement MixColumns (GF multiplication)
6. 💻 Implement AddRoundKey (XOR)
7. 💻 Build key expansion
8. 🧪 Test each component with NIST vectors
9. 🔗 Integrate with UART
10. 🎯 Run synthesis and optimize for PPA

---

**You're now ready to implement AES-128 encryption!** 🔒

AES is the gold standard of encryption - trusted by governments, banks, and tech giants worldwide. By implementing it in hardware, you're building real-world security infrastructure. Good luck with your implementation!
