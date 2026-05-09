# Secure UART System - Mermaid Diagrams

Interactive visual diagrams for the Secure UART system showing architecture, data flow, and state machines using Mermaid syntax.

## Table of Contents
1. [Complete System Architecture](#1-complete-system-architecture)
2. [AES-UART Integration Flow](#2-aes-uart-integration-flow)
3. [TX Path State Machine](#3-tx-path-state-machine)
4. [RX Path State Machine](#4-rx-path-state-machine)
5. [Encryption Data Flow](#5-encryption-data-flow)
6. [Decryption Data Flow](#6-decryption-data-flow)
7. [Bypass Mode Flow](#7-bypass-mode-flow)
8. [Full-Duplex Operation](#8-full-duplex-operation)
9. [Register Access Flow](#9-register-access-flow)
10. [Module Hierarchy](#10-module-hierarchy)

---

## 1. Complete System Architecture

```mermaid
%%{init: {'look':'handDrawn'}}%%
graph TB
    subgraph TinyQV["TinyQV RISC-V CPU"]
        CPU[CPU Pipeline]
        MEM[Memory Controller]
        BUS[32-bit System Bus<br/>address, data_in, data_out<br/>data_write_n, data_read_n]
        
        CPU --> MEM
        MEM --> BUS
    end
    
    subgraph SecureUART["Secure UART Peripheral @ 0x80000000"]
        REG[Register Interface<br/>12 registers<br/>0x00-0x34]
        
        subgraph Registers["Configuration Registers"]
            UART_CTRL[UART_CTRL 0x00<br/>enable, baud, flow]
            STATUS[STATUS 0x04<br/>busy, ready, err]
            TX_DATA[TX_DATA 0x08<br/>write byte]
            RX_DATA[RX_DATA 0x0C<br/>read byte]
            INT_EN[INT_EN 0x10]
            INT_CLR[INT_CLR 0x14]
            AES_CTRL[AES_CTRL 0x20<br/>AES enable]
            AES_STATUS[AES_STATUS 0x24<br/>AES busy, ready]
            KEY0[AES_KEY0 0x28]
            KEY1[AES_KEY1 0x2C]
            KEY2[AES_KEY2 0x30]
            KEY3[AES_KEY3 0x34]
        end
        
        subgraph AES_UART["AES-UART Controller"]
            STREAM[AES Streaming Controller<br/>TX/RX byte buffering<br/>AES block control<br/>Bypass logic]
            
            subgraph TX_Path["TX Encryption Path"]
                TX_BUF[TX Buffer<br/>16 bytes]
                TX_AES[AES-128 Core TX<br/>11 cycles]
                TX_SER[TX Serializer<br/>128-bit → bytes]
            end
            
            subgraph RX_Path["RX Decryption Path"]
                RX_BUF[RX Buffer<br/>16 bytes]
                RX_AES[AES-128 Core RX<br/>11 cycles]
                RX_SER[RX Serializer<br/>128-bit → bytes]
            end
            
            TX_BUF --> TX_AES
            TX_AES --> TX_SER
            
            RX_BUF --> RX_AES
            RX_AES --> RX_SER
        end
        
        subgraph UART_Module["UART Module"]
            BAUD[Baud Generator<br/>607 divisor<br/>@ 115200]
            TX_UART[TX Shift Reg<br/>Serial out]
            RX_UART[RX Shift Reg<br/>Serial in]
            FLOW[RTS/CTS<br/>Flow Control]
        end
        
        REG --> UART_CTRL
        REG --> STATUS
        REG --> TX_DATA
        REG --> RX_DATA
        REG --> AES_CTRL
        REG --> KEY0
        REG --> KEY1
        REG --> KEY2
        REG --> KEY3
        
        TX_DATA --> STREAM
        STREAM --> RX_DATA
        
        STREAM --> TX_SER
        TX_SER --> TX_UART
        
        RX_UART --> STREAM
        STREAM --> RX_SER
        
        BAUD --> TX_UART
        BAUD --> RX_UART
        
        TX_UART --> STATUS
        RX_UART --> STATUS
    end
    
    BUS <-->|Register Access| REG
    
    TX_UART -->|uart_tx pin| EXT[External Device<br/>Terminal/MCU]
    EXT -->|uart_rx pin| RX_UART
    TX_UART <-->|rts/cts| FLOW
    FLOW <-->|rts/cts| EXT
    
    STATUS -->|interrupt| BUS
    
    style TinyQV fill:#7a9fb8
    style SecureUART fill:#9d8860
    style TX_Path fill:#e1f5e1
    style RX_Path fill:#ffe1e1
    style UART_Module fill:#d1ecf1
    style EXT fill:#7a9d72
    style AES_CTRL fill:#fff3cd
```

---

## 2. AES-UART Integration Flow

```mermaid
%%{init: {'look':'handDrawn'}}%%
graph LR
    subgraph CPU_Side["CPU Interface"]
        APP[Application Code]
        DRV[UART Driver]
        
        APP -->|uart_putc 'H'| DRV
        DRV -->|Write 0x48| TX_REG[TX_DATA<br/>0x08]
    end
    
    subgraph AES_Pipeline["AES Encryption Pipeline"]
        TX_REG -->|byte| BUF[TX Buffer<br/>Accumulate 16]
        
        BUF -->|16 bytes full| TRIG[Trigger<br/>AES Encrypt]
        
        TRIG -->|plaintext block| ENC[AES-128<br/>Encrypt<br/>11 cycles]
        
        ENC -->|ciphertext block| SER[Serialize<br/>128-bit → 16 bytes]
        
        SER -->|byte stream| UART_TX[UART TX<br/>8N1 Serial]
    end
    
    UART_TX -->|serial bits| WIRE[uart_tx pin]
    
    WIRE -->|serial bits| UART_RX[UART RX<br/>8N1 Serial]
    
    subgraph AES_RX_Pipeline["AES Decryption Pipeline"]
        UART_RX -->|byte| RX_BUF[RX Buffer<br/>Accumulate 16]
        
        RX_BUF -->|16 bytes full| RX_TRIG[Trigger<br/>AES Decrypt]
        
        RX_TRIG -->|ciphertext block| DEC[AES-128<br/>Decrypt<br/>11 cycles]
        
        DEC -->|plaintext block| RX_SER[Serialize<br/>128-bit → 16 bytes]
        
        RX_SER -->|byte stream| RX_REG[RX_DATA<br/>0x0C]
    end
    
    subgraph CPU_RX["CPU Receive"]
        RX_REG -->|Read 0x48| RX_DRV[UART Driver]
        RX_DRV -->|uart_getc| RX_APP[Application]
    end
    
    style CPU_Side fill:#7a9fb8
    style AES_Pipeline fill:#e1f5e1
    style AES_RX_Pipeline fill:#ffe1e1
    style CPU_RX fill:#7a9fb8
    style WIRE fill:#ffeaa7
```

---

## 3. TX Path State Machine

```mermaid
%%{init: {'look':'handDrawn'}}%%
stateDiagram-v2
    [*] --> IDLE
    
    IDLE --> BUFFER : CPU writes byte<br/>AES_EN=1
    IDLE --> BYPASS : CPU writes byte<br/>AES_EN=0
    
    BUFFER --> BUFFER : byte_count < 16
    BUFFER --> ENCRYPT : byte_count = 16
    
    ENCRYPT --> ENCRYPT : AES busy<br/>(11 cycles)
    ENCRYPT --> SERIALIZE : AES done
    
    SERIALIZE --> SERIALIZE : serialize_count < 16
    SERIALIZE --> IDLE : serialize_count = 16
    
    BYPASS --> IDLE : UART TX start
    
    note right of IDLE
        tx_busy = 0
        Waiting for CPU write
    end note
    
    note right of BUFFER
        Accumulating bytes
        into 128-bit buffer
        Count: 0-15
    end note
    
    note right of ENCRYPT
        AES encryption active
        11 clock cycles
        aes_tx_busy = 1
    end note
    
    note right of SERIALIZE
        Output ciphertext
        bytes to UART TX
        One per UART TX ready
    end note
    
    note right of BYPASS
        Direct pass-through
        No buffering
        No encryption
    end note
```

---

## 4. RX Path State Machine

```mermaid
%%{init: {'look':'handDrawn'}}%%
stateDiagram-v2
    [*] --> IDLE
    
    IDLE --> BUFFER : UART RX ready<br/>AES_EN=1
    IDLE --> BYPASS : UART RX ready<br/>AES_EN=0
    
    BUFFER --> BUFFER : byte_count < 16
    BUFFER --> DECRYPT : byte_count = 16
    
    DECRYPT --> DECRYPT : AES busy<br/>(11 cycles)
    DECRYPT --> SERIALIZE : AES done
    
    SERIALIZE --> SERIALIZE : serialize_count < 16
    SERIALIZE --> IDLE : serialize_count = 16
    
    BYPASS --> IDLE : Byte to RX_DATA
    
    note right of IDLE
        rx_ready = 0
        Waiting for serial data
    end note
    
    note right of BUFFER
        Accumulating bytes
        from UART RX
        Count: 0-15
    end note
    
    note right of DECRYPT
        AES decryption active
        11 clock cycles
        aes_rx_busy = 1
    end note
    
    note right of SERIALIZE
        Output plaintext
        bytes to CPU
        One per CPU read
    end note
    
    note right of BYPASS
        Direct pass-through
        UART → CPU
        No buffering
    end note
```

---

## 5. Encryption Data Flow

```mermaid
%%{init: {'look':'handDrawn'}}%%
flowchart TD
    Start([CPU writes byte]) --> WriteReg[Write to TX_DATA 0x08]
    
    WriteReg --> CheckAES{AES_EN<br/>enabled?}
    
    CheckAES -->|Yes| Buffer[Add to TX Buffer<br/>tx_buffer byte_count]
    CheckAES -->|No| DirectUART[Direct to UART TX]
    
    Buffer --> CheckFull{Buffer<br/>count = 16?}
    
    CheckFull -->|No| WaitMore[Wait for more bytes]
    WaitMore --> End1([Ready for next write])
    
    CheckFull -->|Yes| LoadAES[Load 128-bit block<br/>into AES TX core]
    
    LoadAES --> StartEnc[Start encryption<br/>aes_tx_start = 1]
    
    StartEnc --> EncWait[Wait 11 cycles<br/>aes_tx_busy = 1]
    
    EncWait --> EncDone{Encryption<br/>complete?}
    
    EncDone -->|No| EncWait
    EncDone -->|Yes| GetCipher[Get ciphertext block<br/>aes_tx_block_out]
    
    GetCipher --> Serialize[Serialize to bytes<br/>byte 0-15]
    
    Serialize --> SendUART[Send to UART TX]
    
    SendUART --> CheckMore{More bytes<br/>to send?}
    
    CheckMore -->|Yes| Serialize
    CheckMore -->|No| ResetBuf[Reset buffer count]
    
    DirectUART --> End2([UART transmits])
    ResetBuf --> End3([Ready for next block])
    
    style Start fill:#e1f5e1
    style LoadAES fill:#fff3cd
    style StartEnc fill:#ffeaa7
    style GetCipher fill:#fdcb6e
    style SendUART fill:#d1ecf1
```

---

## 6. Decryption Data Flow

```mermaid
%%{init: {'look':'handDrawn'}}%%
flowchart TD
    Start([UART RX byte received]) --> CheckAES{AES_EN<br/>enabled?}
    
    CheckAES -->|Yes| Buffer[Add to RX Buffer<br/>rx_buffer byte_count]
    CheckAES -->|No| DirectCPU[Direct to RX_DATA]
    
    Buffer --> CheckFull{Buffer<br/>count = 16?}
    
    CheckFull -->|No| WaitMore[Wait for more bytes]
    WaitMore --> End1([Continue receiving])
    
    CheckFull -->|Yes| LoadAES[Load 128-bit block<br/>into AES RX core]
    
    LoadAES --> StartDec[Start decryption<br/>aes_rx_start = 1]
    
    StartDec --> DecWait[Wait 11 cycles<br/>aes_rx_busy = 1]
    
    DecWait --> DecDone{Decryption<br/>complete?}
    
    DecDone -->|No| DecWait
    DecDone -->|Yes| GetPlain[Get plaintext block<br/>aes_rx_block_out]
    
    GetPlain --> Serialize[Serialize to bytes<br/>byte 0-15]
    
    Serialize --> ToFIFO[Store in output FIFO<br/>or direct register]
    
    ToFIFO --> CPURead[CPU reads RX_DATA<br/>0x0C]
    
    CPURead --> CheckMore{More bytes<br/>available?}
    
    CheckMore -->|Yes| ToFIFO
    CheckMore -->|No| ResetBuf[Reset buffer count]
    
    DirectCPU --> End2([CPU reads byte])
    ResetBuf --> End3([Ready for next block])
    
    style Start fill:#ffe1e1
    style LoadAES fill:#fff3cd
    style StartDec fill:#ffeaa7
    style GetPlain fill:#fdcb6e
    style CPURead fill:#7a9fb8
```

---

## 7. Bypass Mode Flow

```mermaid
%%{init: {'look':'handDrawn'}}%%
graph TB
    subgraph TX_Bypass["TX Bypass Mode AES_EN=0"]
        TX_Start[CPU writes TX_DATA]
        TX_Start -->|byte| TX_Direct[Direct to UART TX]
        TX_Direct -->|no buffer| TX_UART[UART Transmit]
        TX_UART -->|serial| TX_Pin[uart_tx pin]
    end
    
    subgraph RX_Bypass["RX Bypass Mode AES_EN=0"]
        RX_Pin[uart_rx pin]
        RX_Pin -->|serial| RX_UART[UART Receive]
        RX_UART -->|no buffer| RX_Direct[Direct to RX_DATA]
        RX_Direct -->|byte| RX_Read[CPU reads RX_DATA]
    end
    
    Note1[No buffering<br/>No encryption<br/>Single byte latency<br/>~86.8µs @ 115200]
    Note2[Normal UART operation<br/>Compatible with standard devices<br/>Debug/testing mode]
    
    TX_Bypass -.->|Characteristics| Note1
    RX_Bypass -.->|Use Cases| Note2
    
    style TX_Bypass fill:#e1f5e1
    style RX_Bypass fill:#ffe1e1
    style Note1 fill:#fff3cd
    style Note2 fill:#d1ecf1
```

---

## 8. Full-Duplex Operation

```mermaid
%%{init: {'look':'handDrawn'}}%%
sequenceDiagram
    participant CPU
    participant TX_AES as TX AES Core
    participant UART
    participant RX_AES as RX AES Core
    participant Remote as Remote Device
    
    Note over CPU,Remote: Simultaneous TX Encryption + RX Decryption
    
    CPU->>TX_AES: Write 16 bytes "Hello World....."
    activate TX_AES
    TX_AES->>TX_AES: Encrypt (11 cycles)
    
    Remote->>UART: Serial data arrives
    UART->>RX_AES: Accumulate RX bytes
    activate RX_AES
    
    TX_AES->>UART: Ciphertext bytes
    deactivate TX_AES
    UART->>Remote: Transmit encrypted data
    
    RX_AES->>RX_AES: Decrypt (11 cycles)
    RX_AES->>CPU: Plaintext available
    deactivate RX_AES
    CPU->>RX_AES: Read plaintext
    
    Note over TX_AES,RX_AES: Independent AES cores<br/>No conflicts<br/>Shared key only
```

---

## 9. Register Access Flow

```mermaid
%%{init: {'look':'handDrawn'}}%%
flowchart LR
    subgraph CPU_Write["CPU Write Sequence"]
        W1[CPU sets address<br/>data_in, data_write_n]
        W1 --> W2[Register decode<br/>address = 0x08?]
        W2 --> W3[Write to TX_DATA]
        W3 --> W4[Trigger tx_write pulse]
        W4 --> W5[data_ready = 1]
    end
    
    subgraph CPU_Read["CPU Read Sequence"]
        R1[CPU sets address<br/>data_read_n]
        R1 --> R2[Register decode<br/>address = 0x0C?]
        R2 --> R3[Read from RX_DATA]
        R3 --> R4[data_out = rx_data]
        R4 --> R5[data_ready = 1]
    end
    
    subgraph Key_Program["AES Key Programming"]
        K1[Write AES_KEY0 0x28]
        K1 --> K2[Write AES_KEY1 0x2C]
        K2 --> K3[Write AES_KEY2 0x30]
        K3 --> K4[Write AES_KEY3 0x34]
        K4 --> K5[128-bit key assembled]
        K5 --> K6[AES_STATUS.key_ready = 1]
    end
    
    style CPU_Write fill:#e1f5e1
    style CPU_Read fill:#ffe1e1
    style Key_Program fill:#fff3cd
```

---

## 10. Module Hierarchy

```mermaid
%%{init: {'look':'handDrawn'}}%%
graph TD
    Root[secure_uart_peripheral.v<br/>Top-level integration]
    
    Root --> RegIf[Register Interface<br/>address decode<br/>12 registers]
    
    Root --> AES_UART[aes_uart_controller.v<br/>AES-UART bridge]
    
    AES_UART --> Stream[aes_uart_streaming.v<br/>Byte buffering & control]
    
    Stream --> TX_AES[aes_core.v TX instance<br/>Encryption mode]
    Stream --> RX_AES[aes_core.v RX instance<br/>Decryption mode]
    
    Root --> UART[uart_peripheral.v<br/>Basic UART]
    
    UART --> Baud[baud_rate_gen.v<br/>70MHz → 115200 baud]
    UART --> TX_Mod[uart_tx.v<br/>Parallel → Serial]
    UART --> RX_Mod[uart_rx.v<br/>Serial → Parallel]
    
    TX_AES --> Sub[aes_sub_bytes.v<br/>S-Box lookup]
    TX_AES --> Shift[aes_shift_rows.v<br/>Byte rotation]
    TX_AES --> Mix[aes_mix_columns.v<br/>Matrix multiply]
    TX_AES --> Key[aes_key_expansion.v<br/>Round key generation]
    
    RX_AES --> InvSub[aes_inv_sub_bytes.v<br/>Inverse S-Box]
    RX_AES --> InvShift[aes_inv_shift_rows.v<br/>Inverse rotation]
    RX_AES --> InvMix[aes_inv_mix_columns.v<br/>Inverse matrix]
    RX_AES --> Key
    
    style Root fill:#7a9fb8
    style AES_UART fill:#9d8860
    style Stream fill:#ffeaa7
    style TX_AES fill:#e1f5e1
    style RX_AES fill:#ffe1e1
    style UART fill:#d1ecf1
```

---

## Usage Notes

These Mermaid diagrams render in:
- **GitHub**: Automatically rendered in Markdown preview
- **VS Code**: Install "Markdown Preview Mermaid Support" extension
- **Online**: Copy to https://mermaid.live for interactive editing

All diagrams use the `handDrawn` theme for a sketch-like appearance. Remove `%%{init: {'look':'handDrawn'}}%%` for standard styling.
