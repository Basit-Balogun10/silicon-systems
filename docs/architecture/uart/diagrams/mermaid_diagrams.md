# UART Peripheral - Mermaid Diagrams

This file contains all Mermaid diagrams for the UART peripheral. These diagrams are interactive and render beautifully in GitHub and VS Code with Mermaid support.

---

## 1. Top-Level System Architecture

```mermaid
%%{init: {'look':'handDrawn'}}%%
graph TB
    subgraph TinyQV["TinyQV RISC-V Core"]
        CPU[CPU Pipeline]
        MEM[Memory Controller]
        BUS[32-bit Register Bus]
        
        CPU --> MEM
        MEM --> BUS
    end
    
    subgraph UART["UART Peripheral"]
        REG[Register Interface]
        CTRL[Control Register]
        STATUS[Status Register]
        TXDATA[TX Data Register]
        RXDATA[RX Data Register]
        BAUD[Baud Rate Generator]
        TX[TX Module]
        RX[RX Module]
        
        REG --> CTRL
        REG --> STATUS
        REG --> TXDATA
        REG --> RXDATA
        CTRL --> BAUD
        CTRL --> TX
        CTRL --> RX
        BAUD --> TX
        BAUD --> RX
        TX --> STATUS
        RX --> STATUS
        TXDATA --> TX
        RX --> RXDATA
    end
    
    BUS -->|address 31:0| REG
    BUS -->|data_in 31:0| REG
    REG -->|data_out 31:0| BUS
    BUS -->|data_write_n| REG
    BUS -->|data_read_n| REG
    
    TX -->|uo_out 0| EXT[External Device]
    EXT -->|ui_in 7| RX
    RX -->|user_interrupt| BUS
    
    style TinyQV fill:#7a9fb8
    style UART fill:#9d8860
    style EXT fill:#7a9d72
```

---

## 2. Baud Rate Generator Module

```mermaid
%%{init: {'look':'handDrawn'}}%%
graph LR
    subgraph Inputs
        CLK[clk<br/>70 MHz]
        RST[rst_n]
        BSEL[baud_sel<br/>3:0]
        EN[enable]
    end
    
    subgraph BaudGen["Baud Rate Generator"]
        LUT[Baud Rate Lookup<br/>9600 → 7291<br/>19200 → 3645<br/>38400 → 1823<br/>115200 → 607]
        DIV[Divisor Register<br/>16-bit]
        CNT[Counter<br/>16-bit]
        CMP[Comparator<br/>counter == divisor?]
        
        BSEL --> LUT
        LUT --> DIV
        DIV --> CMP
        CNT --> CMP
        CLK --> CNT
        EN --> CNT
    end
    
    CMP -->|Yes| TICK[baud_tick<br/>1 cycle pulse]
    CMP -->|Yes| RESET[Reset Counter]
    RESET --> CNT
    
    style BaudGen fill:#9d8860
    style TICK fill:#6e8f70
```

---

## 3. UART Transmitter - State Machine

```mermaid
%%{init: {'look':'handDrawn'}}%%
stateDiagram-v2
    [*] --> IDLE
    IDLE --> START : tx_start = 1
    START --> DATA : baud_tick
    DATA --> DATA : bit_cnt < 8
    DATA --> STOP : bit_cnt = 8
    STOP --> IDLE : baud_tick
    
    note right of IDLE
        tx_out = 1 (idle high)
        tx_busy = 0
    end note
    
    note right of START
        tx_out = 0 (start bit)
        tx_busy = 1
        Load shift register
    end note
    
    note right of DATA
        tx_out = shift_reg[0]
        Shift right each tick
        bit_cnt++
    end note
    
    note right of STOP
        tx_out = 1 (stop bit)
    end note
```

---

## 4. UART Transmitter - Block Diagram

```mermaid
%%{init: {'look':'handDrawn'}}%%
graph TB
    subgraph TX_Inputs["TX Module Inputs"]
        CLK_TX[clk]
        RST_TX[rst_n]
        BTICK_TX[baud_tick]
        TXDATA[tx_data<br/>7:0]
        TXSTART[tx_start]
    end
    
    subgraph TX_Logic["TX Logic"]
        FSM_TX[State Machine<br/>IDLE/START/DATA/STOP]
        SHIFT_TX[Shift Register<br/>8-bit]
        BITCNT_TX[Bit Counter<br/>4-bit: 0-9]
        MUX_TX[Output Mux]
        
        FSM_TX --> SHIFT_TX
        FSM_TX --> BITCNT_TX
        SHIFT_TX --> MUX_TX
        FSM_TX --> MUX_TX
        BTICK_TX --> FSM_TX
        TXDATA --> SHIFT_TX
        TXSTART --> FSM_TX
    end
    
    MUX_TX --> TXOUT[tx_out<br/>Serial Output]
    FSM_TX --> TXBUSY[tx_busy<br/>Status Flag]
    
    style TX_Logic fill:#7a9fb8
    style TXOUT fill:#6e8f70
```

---

## 5. UART Receiver - State Machine

```mermaid
%%{init: {'look':'handDrawn'}}%%
stateDiagram-v2
    [*] --> IDLE
    IDLE --> START : start_detected (1→0)
    START --> DATA : verify_start (sample @ mid-bit)
    START --> IDLE : invalid_start
    DATA --> DATA : bit_cnt < 8
    DATA --> STOP : bit_cnt = 8
    STOP --> IDLE : stop_valid (rx_ready=1)
    STOP --> IDLE : stop_error (rx_error=1)
    
    note right of IDLE
        Monitor for falling edge
        sample_cnt = 0
    end note
    
    note right of START
        Wait to sample @ cnt=7
        Verify still LOW
    end note
    
    note right of DATA
        Sample @ cnt=7
        Shift into register
        bit_cnt++
    end note
    
    note right of STOP
        Verify stop bit = 1
        Set rx_ready or rx_error
    end note
```

---

## 6. UART Receiver - Block Diagram

```mermaid
%%{init: {'look':'handDrawn'}}%%
graph TB
    subgraph RX_Inputs["RX Module Inputs"]
        CLK_RX[clk]
        RST_RX[rst_n]
        BTICK_RX[baud_tick<br/>16x oversampling]
        RXIN[rx_in<br/>Serial Input]
    end
    
    subgraph RX_Sync["Input Synchronization"]
        DFF1[DFF Stage 1]
        DFF2[DFF Stage 2]
        RXIN --> DFF1
        DFF1 --> DFF2
        DFF2 --> RXSYNC[rx_sync]
    end
    
    subgraph RX_Logic["RX Logic"]
        EDGE[Start Bit<br/>Detector]
        SMPCNT[Sample Counter<br/>4-bit: 0-15]
        FSM_RX[State Machine<br/>IDLE/START/DATA/STOP]
        SHIFT_RX[Shift Register<br/>8-bit]
        BITCNT_RX[Bit Counter<br/>4-bit: 0-9]
        MAJ[Majority Voter<br/>3 samples]
        
        RXSYNC --> EDGE
        EDGE --> FSM_RX
        BTICK_RX --> SMPCNT
        SMPCNT --> FSM_RX
        FSM_RX --> SHIFT_RX
        FSM_RX --> BITCNT_RX
        RXSYNC --> MAJ
        MAJ --> SHIFT_RX
    end
    
    SHIFT_RX --> RXDATA[rx_data<br/>7:0<br/>Received Byte]
    FSM_RX --> RXRDY[rx_ready<br/>Data Ready Flag]
    FSM_RX --> RXERR[rx_error<br/>Frame Error Flag]
    
    style RX_Sync fill:#9d8f68
    style RX_Logic fill:#7a9fb8
    style RXDATA fill:#6e8f70
```

---

## 7. Register Interface - Memory Map

```mermaid
%%{init: {'look':'handDrawn'}}%%
graph TB
    subgraph CPU_IF["CPU Interface"]
        ADDR[address<br/>31:0]
        DIN[data_in<br/>31:0]
        DOUT[data_out<br/>31:0]
        WRN[data_write_n]
        RDN[data_read_n]
    end
    
    ADDR --> DEC[Address Decoder]
    
    DEC -->|0x00| CTRL_REG["CTRL 0x00<br/>┌─────────┬──────┬─────┬────┐<br/>│Reserved │BAUD  │Rsvd │EN  │<br/>│ 31-8    │ 7-4  │ 3-1 │ 0  │<br/>└─────────┴──────┴─────┴────┘<br/>Write Only"]
    
    DEC -->|0x04| STAT_REG["STATUS 0x04<br/>┌─────────┬──────┬────┬────┬────┬────┐<br/>│Reserved │ Rsvd │ TB │ RR │ RO │ RE │<br/>│ 31-8    │ 7-4  │ 3  │ 2  │ 1  │ 0  │<br/>└─────────┴──────┴────┴────┴────┴────┘<br/>TB=TX_BUSY RR=RX_READY<br/>RO=RX_OVERRUN RE=RX_ERROR<br/>Read Only"]
    
    DEC -->|0x08| TXDAT_REG["TX_DATA 0x08<br/>┌─────────┬──────────────┐<br/>│Reserved │ TX Data      │<br/>│ 31-8    │ 7-0          │<br/>└─────────┴──────────────┘<br/>Write triggers TX<br/>Write Only"]
    
    DEC -->|0x0C| RXDAT_REG["RX_DATA 0x0C<br/>┌─────────┬──────────────┐<br/>│Reserved │ RX Data      │<br/>│ 31-8    │ 7-0          │<br/>└─────────┴──────────────┘<br/>Read clears RX_READY<br/>Read Only"]
    
    CTRL_REG -->|baud_sel| BAUD_OUT[To Baud Generator]
    CTRL_REG -->|enable| EN_OUT[To TX/RX Modules]
    
    TXDAT_REG -->|tx_data<br/>tx_start| TX_OUT[To TX Module]
    
    RX_IN[From RX Module] -->|rx_data<br/>rx_ready| RXDAT_REG
    TX_IN[From TX Module] -->|tx_busy| STAT_REG
    RX_IN2[From RX Module] -->|rx_ready<br/>rx_error| STAT_REG
    
    STAT_REG --> MUX[Read Data Mux]
    RXDAT_REG --> MUX
    MUX --> DOUT
    
    style CTRL_REG fill:#7a9fb8
    style STAT_REG fill:#9d8f68
    style TXDAT_REG fill:#9d8aa8
    style RXDAT_REG fill:#7a9d72
```

---

## 8. Transaction Sequence - Write (Send Data)

```mermaid
%%{init: {'look':'handDrawn'}}%%
sequenceDiagram
    participant CPU
    participant RegIF as Register Interface
    participant TXReg as TX_DATA Register
    participant TXMod as TX Module
    participant Wire as TX Wire
    
    Note over CPU,Wire: CPU wants to send 0x55
    
    CPU->>RegIF: address = 0x08<br/>data_in = 0x55<br/>data_write_n = 0
    RegIF->>TXReg: Decode address 0x08
    TXReg->>TXMod: tx_data = 0x55<br/>tx_start = 1 (pulse)
    
    Note over TXMod: State: IDLE → START
    TXMod->>Wire: tx_out = 0 (start bit)
    TXMod->>RegIF: tx_busy = 1
    
    Note over TXMod: State: START → DATA
    TXMod->>Wire: Shift out bits 0-7<br/>LSB first
    
    Note over TXMod: State: DATA → STOP
    TXMod->>Wire: tx_out = 1 (stop bit)
    
    Note over TXMod: State: STOP → IDLE
    TXMod->>RegIF: tx_busy = 0
    
    Note over CPU,Wire: Transmission complete
```

---

## 9. Transaction Sequence - Read (Receive Data)

```mermaid
%%{init: {'look':'handDrawn'}}%%
sequenceDiagram
    participant Wire as RX Wire
    participant RXMod as RX Module
    participant RXReg as RX_DATA Register
    participant RegIF as Register Interface
    participant CPU
    participant INT as Interrupt
    
    Note over Wire,INT: External device sends 0xAA
    
    Wire->>RXMod: rx_in: 1→0 (start detected)
    
    Note over RXMod: State: IDLE → START
    RXMod->>RXMod: Verify start bit @ mid-sample
    
    Note over RXMod: State: START → DATA
    RXMod->>RXMod: Sample bits 0-7 with oversampling
    
    Note over RXMod: State: DATA → STOP
    RXMod->>RXMod: Verify stop bit = 1
    RXMod->>RXReg: rx_data = 0xAA<br/>rx_ready = 1
    RXMod->>INT: user_interrupt = 1
    
    INT->>CPU: Interrupt signal
    
    Note over CPU: Poll STATUS or handle interrupt
    CPU->>RegIF: address = 0x04<br/>data_read_n = 0
    RegIF->>CPU: data_out = 0x04<br/>(RX_READY=1)
    
    Note over CPU: RX_READY is set read data
    CPU->>RegIF: address = 0x0C<br/>data_read_n = 0
    RegIF->>RXReg: Read RX_DATA
    RXReg->>CPU: data_out = 0xAA
    RXReg->>RXMod: Clear rx_ready flag
    RXMod->>INT: user_interrupt = 0
    
    Note over Wire,INT: Receive complete
```

---

## 10. Module Hierarchy

```mermaid
%%{init: {'look':'handDrawn'}}%%
graph TD
    TOP[tt_um_tqv_peripheral_harness<br/>Top-Level Wrapper]
    
    TOP --> PERIPH[tqvp_uart<br/>UART Peripheral Instance]
    TOP --> HARNESS[test_harness<br/>SPI Interface]
    
    PERIPH --> REGIF[uart_register_interface<br/>Register Decoder & Control]
    PERIPH --> BAUD[uart_baud_generator<br/>Baud Rate Timing]
    PERIPH --> TX[uart_tx<br/>Transmitter]
    PERIPH --> RX[uart_rx<br/>Receiver]
    
    REGIF --> ADDEC[address_decoder]
    REGIF --> CTRLREG[ctrl_register]
    REGIF --> STATREG[status_register]
    REGIF --> TXDREG[tx_data_register]
    REGIF --> RXDREG[rx_data_register]
    
    BAUD --> LUT[divisor_lookup]
    BAUD --> CNT[counter 15:0]
    BAUD --> TICK[tick_generator]
    
    TX --> TXFSM[tx_state_machine<br/>IDLE/START/DATA/STOP]
    TX --> TXSHIFT[shift_register 7:0]
    TX --> TXCNT[bit_counter 3:0]
    TX --> TXDRV[tx_output_driver]
    
    RX --> SYNC[input_synchronizer<br/>2 DFFs]
    RX --> SDET[start_detector]
    RX --> OSCNT[oversample_counter 3:0]
    RX --> RXFSM[rx_state_machine<br/>IDLE/START/DATA/STOP]
    RX --> RXSHIFT[shift_register 7:0]
    RX --> RXCNT[bit_counter 3:0]
    RX --> MAJ[majority_voter]
    RX --> CHECK[frame_checker]
    
    HARNESS --> SPIR[spi_reg]
    HARNESS --> REDET[rising_edge_detector]
    HARNESS --> FEDET[falling_edge_detector]
    HARNESS --> SYNC2[synchronizer]
    HARNESS --> RECLK[reclocking]
    
    style TOP fill:#7a9fb8
    style PERIPH fill:#9d8860
    style HARNESS fill:#9d8aa8
    style REGIF fill:#7a9d72
    style BAUD fill:#9d8f68
    style TX fill:#7a9fb8
    style RX fill:#b08599
```

---

## Usage Notes

1. **Viewing**: These diagrams render automatically in:
   - GitHub (native support)
   - VS Code (with Mermaid extension)
   - GitLab, BitBucket (native support)

2. **Editing**: Mermaid syntax is sensitive to:
   - Indentation (use consistent spacing)
   - Special characters (avoid in node IDs)
   - Quote marks in labels (use `<br/>` for line breaks)

3. **Exporting**: Can be exported to PNG/SVG using:
   - Mermaid CLI
   - Online editors (mermaid.live)
   - VS Code extensions

4. **Legend**:
   - Blue boxes: CPU/Core modules
   - Yellow boxes: UART peripheral modules
   - Green boxes: External interfaces/outputs
   - Purple boxes: Test infrastructure

---

Return to [diagrams README](README.md) for more diagram formats.
