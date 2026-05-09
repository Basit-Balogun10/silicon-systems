# Secure UART Peripheral - Block Diagrams

Comprehensive block-level documentation showing the architecture, module interfaces, signal connections, and data paths of the Secure UART system.

---

## Table of Contents

1. [Complete System Architecture](#1-complete-system-architecture)
2. [AES-UART Controller Architecture](#2-aes-uart-controller-architecture)
3. [TX Encryption Path - Detailed](#3-tx-encryption-path---detailed)
4. [RX Decryption Path - Detailed](#4-rx-decryption-path---detailed)
5. [Register Interface Architecture](#5-register-interface-architecture)
6. [Signal Connectivity Diagram](#6-signal-connectivity-diagram)
7. [Bypass Mode Architecture](#7-bypass-mode-architecture)
8. [Module Interface Specifications](#8-module-interface-specifications)

---

## 1. Complete System Architecture

### Top-Level System Integration

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                         Secure UART Peripheral @ 0x80000000                   │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                         Register Interface Block                        │ │
│  │                                                                          │ │
│  │   Address      Register         Access     Description                  │ │
│  │   ───────      ────────         ──────     ───────────                  │ │
│  │   0x00    →   UART_CTRL           R/W      UART enable, baud, flow     │ │
│  │   0x04    →   STATUS               R       TX busy, RX ready, errors   │ │
│  │   0x08    →   TX_DATA             W        Write byte to transmit      │ │
│  │   0x0C    →   RX_DATA              R       Read received byte           │ │
│  │   0x10    →   INT_EN              R/W      Interrupt enable mask        │ │
│  │   0x14    →   INT_CLR             W        Interrupt clear              │ │
│  │   0x20    →   AES_CTRL            R/W      AES enable control           │ │
│  │   0x24    →   AES_STATUS           R       AES busy, key status         │ │
│  │   0x28    →   AES_KEY0            R/W      Key bits [31:0]              │ │
│  │   0x2C    →   AES_KEY1            R/W      Key bits [63:32]             │ │
│  │   0x30    →   AES_KEY2            R/W      Key bits [95:64]             │ │
│  │   0x34    →   AES_KEY3            R/W      Key bits [127:96]            │ │
│  │                                                                          │ │
│  └─────────────────────────┬────────────────────────────────────────────────┘ │
│                            │                                                  │
│              ┌─────────────┴────────────┬────────────────┐                   │
│              ▼                          ▼                ▼                   │
│  ┌───────────────────────┐  ┌──────────────────┐  ┌──────────────────────┐  │
│  │                       │  │                  │  │                      │  │
│  │  UART Core Module     │  │  AES-UART        │  │  Control & Status    │  │
│  │  ─────────────────    │  │  Controller      │  │  Logic               │  │
│  │                       │  │                  │  │                      │  │
│  │  ┌─────────────────┐ │  │  ┌────────────┐  │  │  ┌────────────────┐  │  │
│  │  │ Baud Generator  │ │  │  │ TX AES     │  │  │  │ Interrupt Gen  │  │  │
│  │  │  607 @ 115200   │ │  │  │ Streaming  │  │  │  │ - TX done      │  │  │
│  │  │  70MHz → baud   │ │  │  │ Controller │  │  │  │ - RX ready     │  │  │
│  │  └────────┬────────┘ │  │  │            │  │  │  └────────────────┘  │  │
│  │           │          │  │  │  ┌──────┐  │  │  │                      │  │
│  │           ▼          │  │  │  │ TX   │  │  │  │  ┌────────────────┐  │  │
│  │  ┌─────────────────┐ │  │  │  │Buffer│  │  │  │  │ Status Bits    │  │  │
│  │  │ UART TX         │◄┼──┼──┼──┤16 Byte│ │  │  │  │ - tx_busy      │  │  │
│  │  │ Serial Shift Reg│ │  │  │  │      │  │  │  │  │ - rx_ready     │  │  │
│  │  │ 8N1 Format      │ │  │  │  └──┬───┘  │  │  │  │ - aes_busy     │  │  │
│  │  └────────┬────────┘ │  │  │     │      │  │  │  └────────────────┘  │  │
│  │           │          │  │  │     ▼      │  │  │                      │  │
│  │           ▼          │  │  │  ┌──────┐  │  │  │                      │  │
│  │        uart_tx ──────┼──┼──┼─►│ AES  │  │  │  │                      │  │
│  │         (pin)        │  │  │  │ TX   │  │  │  │                      │  │
│  │                      │  │  │  │ Core │  │  │  │                      │  │
│  │        uart_rx ──────┼──┼──┼──┤11 cyc│  │  │  │                      │  │
│  │         (pin)        │  │  │  │      │  │  │  │                      │  │
│  │           │          │  │  │  └──┬───┘  │  │  │                      │  │
│  │           ▼          │  │  │     │      │  │  │                      │  │
│  │  ┌─────────────────┐ │  │  │     ▼      │  │  │                      │  │
│  │  │ UART RX         │ │  │  │  ┌──────┐  │  │  │                      │  │
│  │  │ Serial → Byte   │─┼──┼──┼─►│ AES  │  │  │  │                      │  │
│  │  │ 16x Oversample  │ │  │  │  │ RX   │  │  │  │                      │  │
│  │  └─────────────────┘ │  │  │  │ Core │  │  │  │                      │  │
│  │                      │  │  │  │11 cyc│  │  │  │                      │  │
│  │  ┌─────────────────┐ │  │  │  │      │  │  │  │                      │  │
│  │  │ Flow Control    │ │  │  │  └──┬───┘  │  │  │                      │  │
│  │  │ RTS/CTS         │ │  │  │     │      │  │  │                      │  │
│  │  │ (Optional)      │ │  │  │     ▼      │  │  │                      │  │
│  │  └─────────────────┘ │  │  │  ┌──────┐  │  │  │                      │  │
│  │                      │  │  │  │ RX   │  │  │  │                      │  │
│  └──────────────────────┘  │  │  │Buffer│  │  │  │                      │  │
│                            │  │  │16 Byte│ │  │  │                      │  │
│                            │  │  └──────┘  │  │  │                      │  │
│                            │  │            │  │  │                      │  │
│                            │  └────────────┘  │  └──────────────────────┘  │
│                            │                  │                            │
│                            └──────────────────┘                            │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                        AES Key Storage                                │  │
│  │                                                                        │  │
│  │   aes_key_reg[127:0] = {AES_KEY3, AES_KEY2, AES_KEY1, AES_KEY0}      │  │
│  │                                                                        │  │
│  │   Shared by TX and RX AES cores (same encryption key)                │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
         ▲                                                        │
         │ CPU Bus Interface                                     │
         │ (address, data_in, data_out,                         │
         │  data_write_n, data_read_n, data_ready)              ▼
         │                                                  Serial Interface
    TinyQV CPU                                             (uart_tx, uart_rx,
                                                            rts_n, cts_n)
```

---

## 2. AES-UART Controller Architecture

### `aes_uart_controller.v` - Block-Level View

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        AES-UART Controller Module                            │
│                        (aes_uart_controller.v)                               │
│                                                                               │
│  Inputs:                                                                      │
│    clk, rst_n                     - System clock and reset                   │
│    aes_enable                     - AES mode enable (from AES_CTRL register) │
│    aes_key[127:0]                 - 128-bit encryption key                   │
│    cpu_tx_write, tx_data_in[7:0]  - CPU writes to TX_DATA                   │
│    cpu_rx_read                    - CPU reads from RX_DATA                   │
│    uart_rx_ready, uart_rx_data[7:0] - UART received byte                    │
│                                                                               │
│  Outputs:                                                                     │
│    uart_tx_start, uart_tx_data[7:0] - Send byte to UART TX                  │
│    rx_data_out[7:0], rx_data_available - Decrypted byte to CPU              │
│    tx_busy, rx_busy               - AES processing status                    │
│    aes_key_ready                  - Key configured and ready                 │
│                                                                               │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                  AES-UART Streaming Controller                        │  │
│  │                  (aes_uart_streaming.v instance)                      │  │
│  │                                                                        │  │
│  │  ┌──────────────────────────────────────────────────────────────────┐ │  │
│  │  │                   TX Encryption Path                             │ │  │
│  │  │                                                                   │ │  │
│  │  │  cpu_tx_write ──► [Input Logic] ──► tx_buffer[127:0]            │ │  │
│  │  │                        │              (16 bytes)                  │ │  │
│  │  │                        │                    │                     │ │  │
│  │  │                  [Buffer Counter]           │                     │ │  │
│  │  │                   tx_byte_count[4:0]        │                     │ │  │
│  │  │                        │                    │                     │ │  │
│  │  │                        ▼                    ▼                     │ │  │
│  │  │                  count == 16?      [AES TX Core Instance]        │ │  │
│  │  │                        │             aes_core tx_aes              │ │  │
│  │  │                        ├──Yes──►  .plaintext_in(tx_buffer)       │ │  │
│  │  │                        │           .key_in(aes_key)              │ │  │
│  │  │                        │           .encrypt_mode(1'b1)           │ │  │
│  │  │                        │           .start(aes_tx_start)          │ │  │
│  │  │                        │                    │                     │ │  │
│  │  │                        │                    ▼                     │ │  │
│  │  │                        │           [11 cycle latency]            │ │  │
│  │  │                        │                    │                     │ │  │
│  │  │                        │                    ▼                     │ │  │
│  │  │                        │           .ciphertext_out[127:0]        │ │  │
│  │  │                        │           .done(aes_tx_done)            │ │  │
│  │  │                        │                    │                     │ │  │
│  │  │                        │                    ▼                     │ │  │
│  │  │                        │         [TX Serializer Logic]           │ │  │
│  │  │                        │          Extract bytes 0-15             │ │  │
│  │  │                        │                    │                     │ │  │
│  │  │                        │                    ▼                     │ │  │
│  │  │                        │           uart_tx_start                 │ │  │
│  │  │                        │           uart_tx_data[7:0]             │ │  │
│  │  │                        │                                          │ │  │
│  │  └──────────────────────────────────────────────────────────────────┘ │  │
│  │                                                                        │  │
│  │  ┌──────────────────────────────────────────────────────────────────┐ │  │
│  │  │                   RX Decryption Path                             │ │  │
│  │  │                                                                   │ │  │
│  │  │  uart_rx_ready ──► [Input Logic] ──► rx_buffer[127:0]           │ │  │
│  │  │                         │              (16 bytes)                 │ │  │
│  │  │                         │                    │                    │ │  │
│  │  │                   [Buffer Counter]           │                    │ │  │
│  │  │                    rx_byte_count[4:0]        │                    │ │  │
│  │  │                         │                    │                    │ │  │
│  │  │                         ▼                    ▼                    │ │  │
│  │  │                   count == 16?      [AES RX Core Instance]       │ │  │
│  │  │                         │             aes_core rx_aes             │ │  │
│  │  │                         ├──Yes──►  .plaintext_in(rx_buffer)      │ │  │
│  │  │                         │           .key_in(aes_key)             │ │  │
│  │  │                         │           .encrypt_mode(1'b0)          │ │  │
│  │  │                         │           .start(aes_rx_start)         │ │  │
│  │  │                         │                    │                    │ │  │
│  │  │                         │                    ▼                    │ │  │
│  │  │                         │           [11 cycle latency]           │ │  │
│  │  │                         │                    │                    │ │  │
│  │  │                         │                    ▼                    │ │  │
│  │  │                         │           .ciphertext_out[127:0]       │ │  │
│  │  │                         │           .done(aes_rx_done)           │ │  │
│  │  │                         │                    │                    │ │  │
│  │  │                         │                    ▼                    │ │  │
│  │  │                         │         [RX Serializer Logic]          │ │  │
│  │  │                         │          Extract bytes 0-15            │ │  │
│  │  │                         │                    │                    │ │  │
│  │  │                         │                    ▼                    │ │  │
│  │  │                         │           rx_data_out[7:0]             │ │  │
│  │  │                         │           rx_data_available            │ │  │
│  │  │                         │                                         │ │  │
│  │  └──────────────────────────────────────────────────────────────────┘ │  │
│  │                                                                        │  │
│  │  Control FSMs:                                                         │  │
│  │    tx_state: IDLE → BUFFER → ENCRYPT → SERIALIZE → IDLE              │  │
│  │    rx_state: IDLE → BUFFER → DECRYPT → SERIALIZE → IDLE              │  │
│  │                                                                        │  │
│  │  Bypass Mode (aes_enable = 0):                                        │  │
│  │    TX: cpu_tx_write → uart_tx_start (direct passthrough)             │  │
│  │    RX: uart_rx_ready → rx_data_out (direct passthrough)              │  │
│  │                                                                        │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│                                                                               │
└───────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. TX Encryption Path - Detailed

### Signal Flow from CPU Write to Serial Transmission

```
CPU Interface                Buffering              Encryption           Serialization       UART TX
─────────────                ─────────              ──────────           ─────────────       ───────

   CPU                         
writes 0x48               ┌──────────┐                                                    
  ('H')         ─────────►│ tx_buf[0]│                                                    
    │                     ├──────────┤                                                    
    ▼                     │ tx_buf[1]│                                                    
cpu_tx_write = 1          ├──────────┤                                                    
tx_data_in = 0x48         │ tx_buf[2]│                                                    
    │                     ├──────────┤                                                    
    │                     │   ...    │                                                    
    ▼                     ├──────────┤                                                    
[Register Interface]      │tx_buf[15]│                                                    
    │                     └────┬─────┘                                                    
    │                          │                                                          
    │                     tx_byte_count++                                                 
    │                          │                                                          
    ▼                          ▼                                                          
                          count == 16?                                                    
                               │                                                          
                               │ Yes                                                      
                               ▼                                                          
                         ┌─────────────┐                                                  
                         │ Concatenate │                                                  
                         │ 16 bytes to │                                                  
                         │  128 bits   │                                                  
                         └──────┬──────┘                                                  
                                │                                                         
                                │ tx_buffer[127:0]                                        
                                ▼                                                         
                          ┌──────────────┐                                                
                          │   AES TX     │                                                
                          │   Core       │                                                
                          │              │                                                
                          │ plaintext_in │◄────── tx_buffer[127:0]                        
                          │ key_in       │◄────── aes_key[127:0]                          
                          │ start        │◄────── aes_tx_start = 1                        
                          │              │                                                
                          │ [11 cycles]  │                                                
                          │              │                                                
                          │ciphertext_out│────────►┌────────────────┐                    
                          │ done         │         │ Ciphertext     │                    
                          └──────────────┘         │  128 bits      │                    
                                                   │  [127:0]       │                    
                                                   └────────┬───────┘                    
                                                            │                            
                                                       Split into                         
                                                       16 bytes                           
                                                            │                            
                               ┌────────────────────────────┴───────────────┐            
                               ▼                                            ▼            
                         cipher_byte[0]                             cipher_byte[15]      
                               │                                            │            
                               │ serialize_count = 0                        │            
                               ▼                                            ▼            
                         ┌──────────┐                                 ┌──────────┐       
                         │ TX Ser.  │ ──► uart_tx_start               │   ...    │       
                         │ FSM      │ ──► uart_tx_data[7:0]           │          │       
                         └──────────┘                                 └──────────┘       
                               │                                            │            
                               │ Wait for uart_tx_done                      │            
                               │                                            │            
                               ▼                                            ▼            
                         serialize_count++                            (16 bytes)         
                               │                                                         
                               │ count < 16? Loop                                        
                               │                                                         
                               ▼                                                         
                         count == 16                                                     
                               │                                                         
                               ▼                                                         
                         Reset buffer                                                    
                         Back to IDLE                      ┌─────────────┐              
                                                            │  UART TX    │              
                                                            │  Module     │              
                                                            │             │              
                                                            │ uart_tx_data│◄─── 0xA1 (ciphertext byte)
                                                            │ uart_tx_start│◄── 1       
                                                            │             │              
                                                            │ [Shift Reg] │              
                                                            │  8N1 Serial │              
                                                            │             │              
                                                            │  uart_tx    │──────►      
                                                            │   (pin)     │  Serial     
                                                            └─────────────┘  Output     
                                                                   │                    
                                                                   ▼                    
                                                            Start(0) D0 D1 ... D7 Stop(1)
                                                            └──── 86.8µs @ 115200 ────┘ 

Timing:
  CPU write:           ~14ns (1 cycle @ 70MHz)
  Buffering:           ~229ns (16 cycles for 16 bytes)
  AES encryption:      157ns (11 cycles @ 70MHz)
  Serialization setup: ~14ns (1 cycle)
  UART TX:             1.39ms (16 bytes × 86.8µs)
  ────────────────────────────────────────────
  Total:               ~1.39ms (UART limited)
```

---

## 4. RX Decryption Path - Detailed

### Signal Flow from Serial Reception to CPU Read

```
Serial Input          UART RX           Buffering            Decryption         Serialization     CPU Interface
────────────          ───────           ─────────            ──────────         ─────────────     ─────────────

uart_rx pin                                                                                    
    │                                                                                          
    │ Start(0) D0 D1 D2...D7 Stop(1)                                                          
    ▼                                                                                          
┌─────────────┐                                                                                
│  UART RX    │                                                                                
│  Module     │                                                                                
│             │                                                                                
│ 16x Sample  │                                                                                
│ Majority    │                                                                                
│ Vote        │                                                                                
│             │                                                                                
│ uart_rx_data│──────► 0xA1 (ciphertext byte)                                                
│ uart_rx_ready│─────► 1                                                                      
└─────────────┘                                                                                
       │                                                                                       
       │ 86.8µs per byte @ 115200                                                             
       ▼                                                                                       
  ┌──────────┐                                                                                 
  │ rx_buf[0]│◄────── uart_rx_data[7:0]                                                       
  ├──────────┤                                                                                 
  │ rx_buf[1]│                                                                                 
  ├──────────┤                                                                                 
  │ rx_buf[2]│                                                                                 
  ├──────────┤                                                                                 
  │   ...    │                                                                                 
  ├──────────┤                                                                                 
  │rx_buf[15]│                                                                                 
  └────┬─────┘                                                                                 
       │                                                                                       
  rx_byte_count++                                                                              
       │                                                                                       
       ▼                                                                                       
  count == 16?                                                                                 
       │                                                                                       
       │ Yes                                                                                   
       ▼                                                                                       
 ┌─────────────┐                                                                               
 │ Concatenate │                                                                               
 │ 16 bytes to │                                                                               
 │  128 bits   │                                                                               
 └──────┬──────┘                                                                               
        │                                                                                      
        │ rx_buffer[127:0]                                                                     
        ▼                                                                                      
  ┌──────────────┐                                                                             
  │   AES RX     │                                                                             
  │   Core       │                                                                             
  │              │                                                                             
  │ plaintext_in │◄────── rx_buffer[127:0] (ciphertext for decrypt mode)                      
  │ key_in       │◄────── aes_key[127:0]                                                       
  │ encrypt_mode │◄────── 1'b0 (decrypt)                                                       
  │ start        │◄────── aes_rx_start = 1                                                     
  │              │                                                                             
  │ [11 cycles]  │                                                                             
  │              │                                                                             
  │ciphertext_out│────────►┌────────────────┐                                                 
  │ done         │         │  Plaintext     │                                                 
  └──────────────┘         │   128 bits     │                                                 
                           │   [127:0]      │                                                 
                           └────────┬───────┘                                                 
                                    │                                                         
                               Split into                                                     
                               16 bytes                                                       
                                    │                                                         
       ┌────────────────────────────┴───────────────┐                                         
       ▼                                            ▼                                         
 plain_byte[0]                               plain_byte[15]                                   
       │                                            │                                         
       │ rx_serialize_count = 0                     │                                         
       ▼                                            ▼                                         
 ┌──────────┐                                 ┌──────────┐                                    
 │ RX Ser.  │                                 │   ...    │                                    
 │ FSM      │──► rx_data_out[7:0] = 0x48      │          │                                    
 └──────────┘──► rx_data_available = 1        └──────────┘                                    
       │                                            │                                         
       │ Wait for cpu_rx_read                       │                                         
       │                                            │                                         
       ▼                                            ▼                                         
 rx_serialize_count++                         (16 bytes)                                      
       │                                                                                      
       │ count < 16? Loop                                                                     
       │                                                                                      
       ▼                                                                                      
 count == 16                                                                                  
       │                                                                                      
       ▼                                                                                      
 Reset buffer                                      ┌─────────────┐                            
 Back to IDLE                                      │  CPU Read   │                            
                                                   │  Interface  │                            
                                                   │             │                            
                                                   │ address =   │                            
                                                   │  0x0C       │                            
                                                   │             │                            
                                                   │ data_read_n │                            
                                                   │   asserted  │                            
                                                   │             │                            
                                                   │ data_out =  │◄──── rx_data_out[7:0] = 0x48
                                                   │  0x48       │                            
                                                   │             │                            
                                                   │ data_ready  │                            
                                                   │   = 1       │                            
                                                   └─────────────┘                            
                                                          │                                   
                                                          ▼                                   
                                                    CPU gets 'H'                              
                                                    (decrypted plaintext)                     

Timing:
  UART RX:             1.39ms (16 bytes × 86.8µs)
  Buffering:           ~229ns (16 cycles)
  AES decryption:      157ns (11 cycles @ 70MHz)
  Serialization:       Depends on CPU read rate
  CPU read:            ~28ns per byte (2 cycles)
  ────────────────────────────────────────────────
  Total latency:       ~1.39ms (UART limited)
```

---

## 5. Register Interface Architecture

### Address Decoder and Register Bank

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        Register Interface Logic                              │
│                                                                               │
│  CPU Bus ────────────────────────────────────────────────────────────────┐   │
│   ▲ │                                                                     │   │
│   │ ▼                                                                     │   │
│  data_out[31:0]    address[5:0]                                          │   │
│  data_ready         │                                                     │   │
│                     ▼                                                     │   │
│                ┌─────────────┐                                            │   │
│                │  Address    │                                            │   │
│                │  Decoder    │                                            │   │
│                │  (6-bit)    │                                            │   │
│                └──────┬──────┘                                            │   │
│                       │                                                   │   │
│         ┌─────────────┼─────────────┬─────────────┬───────── ... ────┐   │   │
│         ▼             ▼             ▼             ▼                  ▼   │   │
│     address ==    address ==    address ==    address ==        address == │   │
│       0x00          0x04          0x08          0x0C ...            0x34  │   │
│         │             │             │             │                  │   │   │
│         ▼             ▼             ▼             ▼                  ▼   │   │
│    ┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐        ┌────────┐   │
│    │ UART_  │    │ STATUS │    │ TX_    │    │ RX_    │   ...  │ AES_   │   │
│    │ CTRL   │    │ [R]    │    │ DATA   │    │ DATA   │        │ KEY3   │   │
│    │ [R/W]  │    │        │    │ [W]    │    │ [R]    │        │ [R/W]  │   │
│    └───┬────┘    └───┬────┘    └───┬────┘    └───┬────┘        └───┬────┘   │
│        │             │             │             │                  │        │
│  ┌─────┴─────────────┴─────────────┴─────────────┴──────────────────┴──────┐ │
│  │                      Register Write Logic                               │ │
│  │                                                                          │ │
│  │   if (data_write_n != 2'b11) begin  // Write access                     │ │
│  │     case (address)                                                       │ │
│  │       6'h00: uart_ctrl_reg  <= data_in[31:0];                           │ │
│  │       6'h08: begin                                                       │ │
│  │                tx_data_reg  <= data_in[7:0];                            │ │
│  │                cpu_tx_write <= 1'b1;  // Trigger TX                     │ │
│  │              end                                                         │ │
│  │       6'h20: aes_ctrl_reg   <= data_in[31:0];                           │ │
│  │       6'h28: aes_key_reg[31:0]   <= data_in[31:0];                      │ │
│  │       6'h2C: aes_key_reg[63:32]  <= data_in[31:0];                      │ │
│  │       6'h30: aes_key_reg[95:64]  <= data_in[31:0];                      │ │
│  │       6'h34: aes_key_reg[127:96] <= data_in[31:0];                      │ │
│  │     endcase                                                              │ │
│  │   end                                                                    │ │
│  └──────────────────────────────────────────────────────────────────────────┘ │
│                                                                               │
│  ┌──────────────────────────────────────────────────────────────────────────┐ │
│  │                       Register Read Logic                                │ │
│  │                                                                           │ │
│  │   if (data_read_n != 2'b11) begin  // Read access                        │ │
│  │     case (address)                                                        │ │
│  │       6'h00: data_out <= uart_ctrl_reg;                                  │ │
│  │       6'h04: data_out <= {29'b0, err_flag, rx_ready, tx_busy};           │ │
│  │       6'h0C: begin                                                        │ │
│  │                data_out    <= {24'b0, rx_data_reg};                      │ │
│  │                cpu_rx_read <= 1'b1;  // Trigger RX FIFO pop              │ │
│  │              end                                                          │ │
│  │       6'h24: data_out <= {29'b0, key_ready, rx_busy, tx_busy};           │ │
│  │       6'h28: data_out <= aes_key_reg[31:0];                              │ │
│  │       6'h2C: data_out <= aes_key_reg[63:32];                             │ │
│  │       6'h30: data_out <= aes_key_reg[95:64];                             │ │
│  │       6'h34: data_out <= aes_key_reg[127:96];                            │ │
│  │     endcase                                                               │ │
│  │   end                                                                     │ │
│  └───────────────────────────────────────────────────────────────────────────┘ │
│                                                                               │
└───────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Signal Connectivity Diagram

### All Signal Paths Between Modules

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                            Complete Signal Connectivity                                │
└────────────────────────────────────────────────────────────────────────────────────────┘

 TinyQV CPU                  Register Interface          AES-UART Controller         UART Module
 ──────────                  ──────────────────          ───────────────────         ───────────

   address[31:0] ──────────►│ address[5:0]     │
   data_in[31:0] ──────────►│ data_in[31:0]    │
   data_out[31:0]◄──────────│ data_out[31:0]   │
   data_write_n[1:0]────────►│ data_write_n[1:0]│
   data_read_n[1:0] ────────►│ data_read_n[1:0] │
   data_ready ◄─────────────│ data_ready       │
                             │                  │
                             │  tx_data[7:0]    │──────────────────►│ tx_data_in[7:0]     │
                             │  cpu_tx_write    │──────────────────►│ cpu_tx_write        │
                             │  rx_data[7:0]    │◄──────────────────│ rx_data_out[7:0]    │
                             │  cpu_rx_read     │──────────────────►│ cpu_rx_read         │
                             │                  │                    │                     │
                             │  aes_enable      │──────────────────►│ aes_enable          │
                             │  aes_key[127:0]  │──────────────────►│ aes_key[127:0]      │
                             │                  │                    │                     │
                             │  tx_busy         │◄──────────────────│ tx_busy             │
                             │  rx_busy         │◄──────────────────│ rx_busy             │
                             │  rx_data_avail   │◄──────────────────│ rx_data_available   │
                             │  aes_key_ready   │◄──────────────────│ aes_key_ready       │
                             │                  │                    │                     │
                             │  uart_ctrl[31:0] │────────────────────────────────────────►│ uart_enable      │
                             │                  │                                          │ baud_sel[3:0]    │
                             │                  │                                          │ flow_ctrl_en     │
                             │                  │                                          │                  │
                             │  uart_tx_data    │◄─────────────────│ uart_tx_data[7:0]   │──────────────────►│ tx_data[7:0]     │
                             │  uart_tx_start   │◄─────────────────│ uart_tx_start       │──────────────────►│ tx_start         │
                             │  uart_tx_done    │──────────────────►│ uart_tx_done        │◄──────────────────│ tx_done          │
                             │  uart_tx_busy    │──────────────────►│ uart_tx_busy        │◄──────────────────│ tx_busy          │
                             │                  │                    │                     │                  │                  │
                             │  uart_rx_data    │──────────────────►│ uart_rx_data[7:0]   │◄──────────────────│ rx_data[7:0]     │
                             │  uart_rx_ready   │──────────────────►│ uart_rx_ready       │◄──────────────────│ rx_ready         │
                             │                  │                    │                     │                  │                  │
                             │                  │                    │                     │                  │  uart_tx (pin) ──►
                             │                  │                    │                     │                  │  uart_rx (pin) ◄──
                             │                  │                    │                     │                  │  rts_n (pin) ────►
                             │                  │                    │                     │                  │  cts_n (pin) ◄────
                             │                  │                    │                     │                  │                  │
                             └──────────────────┘                    └─────────────────────┘                  └──────────────────┘

Common Signals (all modules):
  clk         ───────────────────────────────────────────────────────────────────────────────────────────────►
  rst_n       ───────────────────────────────────────────────────────────────────────────────────────────────►
```

---

## 7. Bypass Mode Architecture

### Direct Passthrough When AES_EN = 0

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        Bypass Mode (aes_enable = 0)                          │
│                        Direct CPU ↔ UART Communication                       │
└──────────────────────────────────────────────────────────────────────────────┘

TX Path - Bypass:
─────────────────

  CPU writes byte               AES Controller              UART TX
  ───────────────               ──────────────              ───────

  cpu_tx_write ────────────►┌───────────────┐
  tx_data_in[7:0]───────────►│ aes_enable==0?│
                             │      │        │
                             │      ▼        │
                             │     Yes       │
                             │      │        │
                             │      ▼        │
                             │  [Bypass Mux] │
                             │      │        │
                             │      ▼        │
                             │ uart_tx_data  │────────────►  tx_data[7:0]
                             │ uart_tx_start │────────────►  tx_start
                             └───────────────┘
                                    No buffering
                                    No encryption
                                    Single byte latency


RX Path - Bypass:
─────────────────

  UART RX               AES Controller              CPU reads byte
  ───────               ──────────────              ──────────────

  rx_data[7:0]──────────►┌───────────────┐
  rx_ready──────────────►│ aes_enable==0?│
                         │      │        │
                         │      ▼        │
                         │     Yes       │
                         │      │        │
                         │      ▼        │
                         │  [Bypass Mux] │
                         │      │        │
                         │      ▼        │
                         │ rx_data_out   │────────────►  data_out[7:0]
                         │ rx_data_avail │────────────►  rx_ready status
                         └───────────────┘
                                No buffering
                                No decryption
                                Immediate availability


Use Cases for Bypass Mode:
───────────────────────────
  • Debugging/testing UART functionality independently
  • Communicating with non-encrypted devices
  • Firmware bootloader or initial setup
  • Emergency fallback mode
  • Performance testing (no AES overhead)
```

---

## 8. Module Interface Specifications

### Port Definitions for Key Modules

#### **secure_uart_peripheral.v** (Top Level)

```
module secure_uart_peripheral (
    // System
    input  wire        clk,              // 70 MHz system clock
    input  wire        rst_n,            // Active-low reset
    
    // CPU Register Bus
    input  wire [5:0]  address,          // Register address (0x00-0x34)
    input  wire [31:0] data_in,          // Write data
    output wire [31:0] data_out,         // Read data
    input  wire [1:0]  data_write_n,     // Active-low write strobe
    input  wire [1:0]  data_read_n,      // Active-low read strobe
    output wire        data_ready,       // Transaction complete
    
    // UART Serial Interface
    output wire        uart_tx,          // Serial transmit pin
    input  wire        uart_rx,          // Serial receive pin
    output wire        rts_n,            // Request to send (flow control)
    input  wire        cts_n,            // Clear to send (flow control)
    
    // Interrupt
    output wire        interrupt         // Interrupt to CPU
);
```

#### **aes_uart_controller.v**

```
module aes_uart_controller (
    // System
    input  wire         clk,
    input  wire         rst_n,
    
    // Configuration
    input  wire         aes_enable,      // 1 = encrypt/decrypt, 0 = bypass
    input  wire [127:0] aes_key,         // 128-bit AES key
    
    // CPU TX Interface
    input  wire         cpu_tx_write,    // CPU writes to TX_DATA
    input  wire [7:0]   tx_data_in,      // Byte to transmit
    
    // CPU RX Interface
    input  wire         cpu_rx_read,     // CPU reads RX_DATA
    output wire [7:0]   rx_data_out,     // Received byte
    output wire         rx_data_available, // RX data ready
    
    // UART TX Interface
    output wire         uart_tx_start,   // Start UART transmission
    output wire [7:0]   uart_tx_data,    // Byte to UART TX
    input  wire         uart_tx_done,    // UART TX complete
    input  wire         uart_tx_busy,    // UART TX busy
    
    // UART RX Interface
    input  wire         uart_rx_ready,   // UART RX has byte
    input  wire [7:0]   uart_rx_data,    // Byte from UART RX
    
    // Status
    output wire         tx_busy,         // TX path busy (buffering/encrypting)
    output wire         rx_busy,         // RX path busy (buffering/decrypting)
    output wire         aes_key_ready    // Key is configured
);
```

#### **aes_uart_streaming.v**

```
module aes_uart_streaming (
    // System
    input  wire         clk,
    input  wire         rst_n,
    
    // Configuration
    input  wire         bypass_mode,     // 1 = bypass AES
    input  wire [127:0] aes_key,
    
    // TX Path
    input  wire         tx_byte_valid,   // New byte to transmit
    input  wire [7:0]   tx_byte_in,
    output wire         tx_byte_ready,   // Ready for next byte
    output wire         tx_cipher_valid, // Encrypted byte ready
    output wire [7:0]   tx_cipher_out,
    
    // RX Path
    input  wire         rx_cipher_valid, // Encrypted byte received
    input  wire [7:0]   rx_cipher_in,
    output wire         rx_byte_valid,   // Plaintext byte ready
    output wire [7:0]   rx_byte_out,
    input  wire         rx_byte_read,    // CPU reads byte
    
    // Status
    output wire         tx_aes_busy,
    output wire         rx_aes_busy
);
```

#### **uart_peripheral.v**

```
module uart_peripheral (
    // System
    input  wire       clk,
    input  wire       rst_n,
    
    // Configuration
    input  wire       uart_enable,
    input  wire [3:0] baud_sel,          // 0-6 = 9600 to 921600
    input  wire       flow_ctrl_en,
    
    // TX Interface
    input  wire [7:0] tx_data,
    input  wire       tx_start,
    output wire       tx_done,
    output wire       tx_busy,
    
    // RX Interface
    output wire [7:0] rx_data,
    output wire       rx_ready,
    output wire       rx_error,
    
    // Serial Interface
    output wire       uart_tx,
    input  wire       uart_rx,
    output wire       rts_n,
    input  wire       cts_n
);
```

---

## Summary

This document provides complete block-level views of the Secure UART system architecture. Key takeaways:

- **Modular Design**: Clear separation between register interface, AES controller, and UART module
- **Dual AES Cores**: Independent TX/RX encryption engines for full-duplex operation
- **Bypass Mode**: Direct CPU↔UART path when encryption is disabled
- **128-bit Buffering**: Accumulates 16 bytes before triggering AES block encryption
- **Transparent Operation**: CPU sees simple byte-level TX/RX interface regardless of encryption
- **11-cycle AES Latency**: Negligible compared to UART transmission time (86.8µs per byte)

All diagrams show signal-level connectivity for RTL implementation and verification.
