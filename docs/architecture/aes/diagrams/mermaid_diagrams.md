# AES-128 Mermaid Diagrams

Interactive block diagrams for the AES-128 encryption engine implementation.

## Table of Contents
1. [AES-128 Top-Level Architecture](#1-aes-128-top-level-architecture)
2. [Encryption Round Function Flowchart](#2-encryption-round-function-flowchart)
3. [Key Expansion Block Diagram](#3-key-expansion-block-diagram)
4. [SubBytes Transformation](#4-subbytes-transformation)
5. [ShiftRows Transformation](#5-shiftrows-transformation)
6. [MixColumns Transformation](#6-mixcolumns-transformation)
7. [AddRoundKey Operation](#7-addroundkey-operation)
8. [Integration with UART TX/RX](#8-integration-with-uart-txrx)
9. [Control FSM State Machine](#9-control-fsm-state-machine)

---

## 1. AES-128 Top-Level Architecture

```mermaid
graph TB
    subgraph "AES-128 Encryption Engine"
        Input[128-bit Plaintext Block]
        Key[128-bit Master Key]
        
        Input --> AddRK0[AddRoundKey Initial]
        Key --> KeyExp[Key Expansion Module]
        
        AddRK0 --> Round1-9[Rounds 1-9]
        KeyExp --> Round1-9
        
        subgraph "Rounds 1-9 (Iterative)"
            SubBytes1[SubBytes]
            ShiftRows1[ShiftRows]
            MixColumns1[MixColumns]
            AddRK1[AddRoundKey]
            
            SubBytes1 --> ShiftRows1
            ShiftRows1 --> MixColumns1
            MixColumns1 --> AddRK1
        end
        
        Round1-9 --> Round10[Round 10 Final]
        KeyExp --> Round10
        
        subgraph "Round 10 (Final)"
            SubBytes2[SubBytes]
            ShiftRows2[ShiftRows]
            AddRK2[AddRoundKey]
            
            SubBytes2 --> ShiftRows2
            ShiftRows2 --> AddRK2
        end
        
        Round10 --> Output[128-bit Ciphertext Block]
    end
    
    FIFO[TX FIFO 16 bytes] --> Input
    Output --> UART[UART TX]
    
    style Input fill:#e1f5e1
    style Output fill:#ffe1e1
    style Key fill:#fff3cd
    style FIFO fill:#d1ecf1
    style UART fill:#d1ecf1
```

**Notes**:
- Total: 10 rounds (9 full rounds + 1 final round without MixColumns)
- Each round operates on 128-bit (16-byte) state matrix
- Key expansion generates 11 round keys (initial + 10 rounds)
- Iterative architecture reuses hardware for all rounds

---

## 2. Encryption Round Function Flowchart

```mermaid
flowchart TD
    Start([Start Encryption]) --> LoadState[Load 128-bit Plaintext into State]
    LoadState --> InitKey[AddRoundKey with K0]
    
    InitKey --> LoopStart{Round Counter\n< 10?}
    
    LoopStart -->|Yes| SubBytes[SubBytes: S-Box Substitution]
    SubBytes --> ShiftRows[ShiftRows: Circular Byte Shift]
    ShiftRows --> CheckRound{Round\n== 10?}
    
    CheckRound -->|No Rounds 1-9| MixColumns[MixColumns: Matrix Multiply]
    CheckRound -->|Yes Round 10| SkipMix[Skip MixColumns]
    
    MixColumns --> AddRoundKey[AddRoundKey: XOR with Round Key]
    SkipMix --> AddRoundKey
    
    AddRoundKey --> Increment[Increment Round Counter]
    Increment --> LoopStart
    
    LoopStart -->|No Done| OutputCipher[Output 128-bit Ciphertext]
    OutputCipher --> End([End Encryption])
    
    style Start fill:#e1f5e1
    style End fill:#ffe1e1
    style SubBytes fill:#fff3cd
    style ShiftRows fill:#ffeaa7
    style MixColumns fill:#fdcb6e
    style AddRoundKey fill:#e17055
```

**Key Points**:
- 10 total rounds executed
- Round 10 omits MixColumns (AES-128 standard)
- Each transformation modifies state in-place
- Round counter increments 0→10

---

## 3. Key Expansion Block Diagram

```mermaid
graph LR
    subgraph "Key Expansion (10 Rounds)"
        MasterKey[128-bit Master Key] --> W0-3[Words W0-W3]
        
        W0-3 --> Expand[Expansion Logic]
        
        subgraph "Per-Round Expansion"
            Expand --> RotWord[RotWord: Rotate Left 8 bits]
            RotWord --> SubWord[SubWord: S-Box on Each Byte]
            SubWord --> Rcon[XOR with Rcon]
            Rcon --> XOR[XOR with Previous Word]
        end
        
        XOR --> W4-43[Words W4-W43\n 10 Round Keys]
    end
    
    W0-3 --> RK0[Round Key 0]
    W4-43 --> RK1-10[Round Keys 1-10]
    
    RK0 --> AddRoundKey0[AddRoundKey Initial]
    RK1-10 --> AddRoundKey1-10[AddRoundKey Rounds 1-10]
    
    style MasterKey fill:#fff3cd
    style W0-3 fill:#dfe6e9
    style W4-43 fill:#dfe6e9
    style Rcon fill:#74b9ff
```

**Key Expansion Details**:
- Master key → 4 words (W0, W1, W2, W3) = 128 bits
- Generate 40 more words (W4-W43) for 10 rounds
- Each round key = 4 words = 128 bits
- Total: 11 round keys (176 bytes stored)

**Rcon Values** (Round Constants):
- Round 1: 0x01, Round 2: 0x02, Round 3: 0x04, Round 4: 0x08
- Round 5: 0x10, Round 6: 0x20, Round 7: 0x40, Round 8: 0x80
- Round 9: 0x1B, Round 10: 0x36

---

## 4. SubBytes Transformation

```mermaid
graph TB
    subgraph "SubBytes S-Box Substitution"
        State[State Matrix\n16 bytes] --> Split[Split into 16 Bytes]
        
        Split --> B0[Byte 0]
        Split --> B1[Byte 1]
        Split --> B15[Byte 15]
        Split --> Dots[...]
        
        B0 --> SBox0[S-Box Lookup]
        B1 --> SBox1[S-Box Lookup]
        B15 --> SBox15[S-Box Lookup]
        Dots --> SBoxN[S-Box Lookup]
        
        SBox0 --> B0Out[S Byte 0']
        SBox1 --> B1Out[S Byte 1']
        SBox15 --> B15Out[S Byte 15']
        SBoxN --> DotsOut[...]
        
        B0Out --> Merge[Merge into State Matrix]
        B1Out --> Merge
        B15Out --> Merge
        DotsOut --> Merge
        
        Merge --> StateOut[Transformed State\n16 bytes]
    end
    
    subgraph "S-Box Implementation"
        Input[8-bit Input] --> ROM[256-entry ROM\nPrecomputed S-Box]
        ROM --> Output[8-bit Output]
    end
    
    style State fill:#e1f5e1
    style StateOut fill:#ffe1e1
    style ROM fill:#a29bfe
```

**S-Box Properties**:
- Non-linear transformation (confusion)
- Implemented as 256-byte lookup table (ROM)
- Same S-Box used for all 16 bytes
- Combinational logic: 1 cycle latency
- Area: ~512 cells (256×8-bit entries)

---

## 5. ShiftRows Transformation

```mermaid
graph TB
    subgraph "ShiftRows Byte Position Mapping"
        subgraph "Input State Matrix"
            I00[0] --> I01[1] --> I02[2] --> I03[3]
            I10[4] --> I11[5] --> I12[6] --> I13[7]
            I20[8] --> I21[9] --> I22[10] --> I23[11]
            I30[12] --> I31[13] --> I32[14] --> I33[15]
        end
        
        Arrow[Shift Rows]
        
        subgraph "Output State Matrix"
            O00[0] --> O01[1] --> O02[2] --> O03[3]
            O10[5] --> O11[6] --> O12[7] --> O13[4]
            O20[10] --> O21[11] --> O22[8] --> O23[9]
            O30[15] --> O31[12] --> O32[13] --> O33[14]
        end
    end
    
    I00 -.Row 0: No Shift.-> O00
    I01 -.-> O01
    I02 -.-> O02
    I03 -.-> O03
    
    I10 -.Row 1: Shift Left 1.-> O13
    I11 -.-> O10
    I12 -.-> O11
    I13 -.-> O12
    
    I20 -.Row 2: Shift Left 2.-> O22
    I21 -.-> O23
    I22 -.-> O20
    I23 -.-> O21
    
    I30 -.Row 3: Shift Left 3.-> O31
    I31 -.-> O32
    I32 -.-> O33
    I33 -.-> O30
    
    style Arrow fill:#74b9ff
```

**ShiftRows Operation**:
- Row 0: No shift
- Row 1: Circular left shift by 1 byte
- Row 2: Circular left shift by 2 bytes
- Row 3: Circular left shift by 3 bytes
- Pure combinational logic (wire routing only)
- Zero area cost (just wire connections)

---

## 6. MixColumns Transformation

```mermaid
graph TB
    subgraph "MixColumns Matrix Multiplication"
        State[State Matrix\n4 columns] --> C0[Column 0\n4 bytes]
        State --> C1[Column 1\n4 bytes]
        State --> C2[Column 2\n4 bytes]
        State --> C3[Column 3\n4 bytes]
        
        C0 --> GF0[GF 2^8 Multiply\nby Fixed Matrix]
        C1 --> GF1[GF 2^8 Multiply\nby Fixed Matrix]
        C2 --> GF2[GF 2^8 Multiply\nby Fixed Matrix]
        C3 --> GF3[GF 2^8 Multiply\nby Fixed Matrix]
        
        GF0 --> C0Out[Column 0'\n4 bytes]
        GF1 --> C1Out[Column 1'\n4 bytes]
        GF2 --> C2Out[Column 2'\n4 bytes]
        GF3 --> C3Out[Column 3'\n4 bytes]
        
        C0Out --> Merge[Merge Columns]
        C1Out --> Merge
        C2Out --> Merge
        C3Out --> Merge
        
        Merge --> StateOut[Transformed State]
    end
    
    subgraph "Matrix Operation Per Column"
        Matrix["[2 3 1 1]\n[1 2 3 1]\n[1 1 2 3]\n[3 1 1 2]"]
        InputCol[Input Column\n s0, s1, s2, s3]
        
        Matrix -.Multiply.-> InputCol
        InputCol --> OutputCol[Output Column\n s0', s1', s2', s3']
    end
    
    style State fill:#e1f5e1
    style StateOut fill:#ffe1e1
    style Matrix fill:#fdcb6e
    style GF0 fill:#ffeaa7
    style GF1 fill:#ffeaa7
    style GF2 fill:#ffeaa7
    style GF3 fill:#ffeaa7
```

**MixColumns Details**:
- Operates independently on each of 4 columns
- Galois Field GF(2^8) arithmetic
- Fixed transformation matrix (invertible)
- Each output byte = XOR of 4 multiplications
- Area: ~400 cells (xtime operations + XOR trees)

**GF(2^8) Multiplication**:
- `{02} • x` = xtime(x) = left shift with conditional XOR 0x1B
- `{03} • x` = xtime(x) ⊕ x

---

## 7. AddRoundKey Operation

```mermaid
graph LR
    subgraph "AddRoundKey XOR Operation"
        State[State Matrix\n128 bits] --> XOR((⊕))
        RoundKey[Round Key\n128 bits] --> XOR
        
        XOR --> StateOut[Output State\n128 bits]
    end
    
    subgraph "Byte-Level View"
        S0[State Byte 0] --> X0((⊕))
        K0[Key Byte 0] --> X0
        X0 --> O0[Out Byte 0]
        
        Dots[... 14 more bytes ...]
        
        S15[State Byte 15] --> X15((⊕))
        K15[Key Byte 15] --> X15
        X15 --> O15[Out Byte 15]
    end
    
    style State fill:#e1f5e1
    style RoundKey fill:#fff3cd
    style StateOut fill:#ffe1e1
    style XOR fill:#74b9ff
    style X0 fill:#74b9ff
    style X15 fill:#74b9ff
```

**AddRoundKey Properties**:
- Simple bitwise XOR: `state[i] = state[i] ⊕ roundKey[i]`
- Performs 16 byte-wise XORs in parallel
- Combinational logic: ~32 cells (16×2-input XOR)
- Used at start (round 0) and after every round (rounds 1-10)
- Provides key-dependent transformation

---

## 8. Integration with UART TX/RX

```mermaid
graph TB
    subgraph "Secure UART with AES-128 Encryption"
        CPU[CPU / Register Interface] -->|Write TX_DATA| TxReg[TX Register Interface]
        
        TxReg -->|8-bit Writes| TxFIFO[TX FIFO\n16-byte Buffer]
        
        TxFIFO -->|Watermark = 16| Trigger{16 Bytes\nAccumulated?}
        
        Trigger -->|Yes| AES[AES-128 Engine]
        Trigger -->|No Bypass Mode| TxFlow[TX Flow Control]
        
        subgraph "AES-128 Encryption"
            AES --> Load[Load 128-bit Block]
            Load --> Encrypt[10 Rounds Encryption\n ~24 cycles]
            Encrypt --> Store[Store 128-bit Ciphertext]
        end
        
        Store --> TxFlow
        TxFlow -->|CTS Check| UartTx[UART TX]
        UartTx --> TxPin[TX Pin]
        
        RxPin[RX Pin] --> UartRx[UART RX]
        UartRx --> RxFIFO[RX FIFO\n16-byte Buffer]
        RxFIFO -->|Watermark Check| RTS[RTS Generator]
        RxFIFO -->|Read RX_DATA| RxReg[RX Register Interface]
        RxReg --> CPU
    end
    
    Key[128-bit AES Key\nRegister 0x20-0x2F] --> AES
    Control[Control Register\nAES_EN bit] --> Trigger
    
    style TxFIFO fill:#d1ecf1
    style RxFIFO fill:#d1ecf1
    style AES fill:#a29bfe
    style Key fill:#fff3cd
    style CPU fill:#dfe6e9
```

**Integration Flow**:
1. CPU writes 16 bytes to TX_DATA register
2. Bytes accumulate in TX FIFO
3. When FIFO has 16 bytes, trigger AES encryption (if enabled)
4. AES encrypts 128-bit block (~24 cycles)
5. Ciphertext feeds to UART TX with flow control
6. RX path has FIFO with RTS generation (decryption future)

**Control Registers**:
- `AES_KEY[0:15]` (0x20-0x2F): 128-bit encryption key
- `AES_CTRL` (0x30): Enable/disable encryption
- `AES_STATUS` (0x31): Busy/done flags

---

## 9. Control FSM State Machine

```mermaid
stateDiagram-v2
    [*] --> IDLE
    
    IDLE --> LOAD_KEY : aes_key_write
    LOAD_KEY --> IDLE : key_loaded
    
    IDLE --> WAIT_DATA : aes_enable
    WAIT_DATA --> IDLE : !aes_enable
    
    WAIT_DATA --> LOAD_STATE : tx_fifo_count == 16
    LOAD_STATE --> INIT_ROUND : state_loaded
    
    INIT_ROUND --> ROUND_1_9 : add_round_key_done
    
    ROUND_1_9 --> SUB_BYTES : round_start
    SUB_BYTES --> SHIFT_ROWS : sub_bytes_done
    SHIFT_ROWS --> MIX_COLUMNS : shift_rows_done
    MIX_COLUMNS --> ADD_RND_KEY : mix_columns_done
    ADD_RND_KEY --> CHECK_ROUND : add_round_key_done
    
    CHECK_ROUND --> ROUND_1_9 : round < 9
    CHECK_ROUND --> ROUND_10 : round == 9
    
    ROUND_10 --> SUB_BYTES_10 : round_start
    SUB_BYTES_10 --> SHIFT_ROWS_10 : sub_bytes_done
    SHIFT_ROWS_10 --> ADD_RND_KEY_10 : shift_rows_done
    ADD_RND_KEY_10 --> STORE_OUTPUT : add_round_key_done
    
    STORE_OUTPUT --> WAIT_DATA : output_stored
    
    note right of IDLE
        Reset state
        aes_busy = 0
        aes_done = 0
    end note
    
    note right of WAIT_DATA
        Waiting for 16 bytes
        in TX FIFO
    end note
    
    note right of ROUND_1_9
        Rounds 1-9:
        SubBytes → ShiftRows
        → MixColumns → AddRoundKey
    end note
    
    note right of ROUND_10
        Round 10:
        SubBytes → ShiftRows
        → AddRoundKey (no MixColumns)
    end note
```

**FSM States**:
- **IDLE**: Waiting for key load or data
- **LOAD_KEY**: Loading 128-bit master key
- **WAIT_DATA**: Monitoring TX FIFO for 16 bytes
- **LOAD_STATE**: Transfer FIFO → state matrix
- **INIT_ROUND**: AddRoundKey with K0
- **ROUND_1_9**: Execute rounds 1-9 (with MixColumns)
- **SUB_BYTES**: S-Box substitution (1-2 cycles)
- **SHIFT_ROWS**: Row shifting (combinational)
- **MIX_COLUMNS**: Column mixing (1-2 cycles)
- **ADD_RND_KEY**: XOR round key (combinational)
- **CHECK_ROUND**: Test round counter
- **ROUND_10**: Execute final round (no MixColumns)
- **STORE_OUTPUT**: Transfer ciphertext to TX path
- **Output**: Return to WAIT_DATA for next block

**Control Signals**:
- `aes_enable`: Master enable
- `aes_busy`: Encryption in progress
- `aes_done`: Block complete (1-cycle pulse)
- `round_counter`: 0-10 round tracking

---

## Implementation Notes

### Hardware Architecture Choices

1. **Iterative Design**: Single round hardware reused 10 times
   - Pro: Smaller area (~2000 cells vs ~8000 for pipelined)
   - Con: Lower throughput (24 cycles vs 1 cycle per block)
   - Justification: Area-constrained design, moderate throughput OK

2. **S-Box Implementation**: 256-entry ROM (combinational lookup)
   - Pro: Fast (1 cycle), simple
   - Con: Larger than composite field (512 cells vs ~300)
   - Justification: Speed prioritized over area

3. **Key Expansion**: Pre-compute and store all round keys
   - Pro: Faster encryption (no key schedule overhead)
   - Con: More storage (176 bytes for 11 round keys)
   - Alternative: On-the-fly expansion (saves storage, adds ~2 cycles/round)

4. **MixColumns**: Combinational xtime logic
   - Pro: No clock cycles added
   - Con: ~400 cells for Galois field multipliers
   - Justification: Critical path acceptable

### Timing Budget

Estimated cycle counts per operation:
- **AddRoundKey**: Combinational (part of FSM state)
- **SubBytes**: 1 cycle (ROM lookup)
- **ShiftRows**: Combinational (wire routing)
- **MixColumns**: 1 cycle (if pipelined) or combinational
- **Round overhead**: 1 cycle (state transitions)

**Total per round**: ~2-3 cycles
**Total for 10 rounds**: ~24 cycles
**Plus load/store**: ~2 cycles
**Total per 128-bit block**: ~26 cycles

At 25 MHz clock: ~1 µs per block = 1 Mbps encrypted throughput

---

Return to [main diagrams README](README.md) for overview and navigation.
