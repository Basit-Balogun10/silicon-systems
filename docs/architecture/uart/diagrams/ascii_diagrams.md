# UART Peripheral - ASCII Art Diagrams

This file contains text-based diagrams that work in any editor or terminal.

---

## 1. Top-Level System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         TinyQV RISC-V Core                          │
│                                                                     │
│  ┌──────────────┐    32-bit Bus Interface                         │
│  │    CPU       │                                                  │
│  │   Pipeline   │───┐                                              │
│  └──────────────┘   │                                              │
│                     │                                              │
│  ┌──────────────┐   │                                              │
│  │   Memory     │   │                                              │
│  │  Controller  │◄──┤                                              │
│  └──────────────┘   │                                              │
│                     │                                              │
└─────────────────────┼──────────────────────────────────────────────┘
                      │
                      │ address[31:0]
                      │ data_in[31:0]
                      │ data_out[31:0]
                      │ data_write_n
                      │ data_read_n
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   UART Peripheral (peripheral.v)                    │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │              Register Interface / Decoder                     │ │
│  │   - Address decode (0x00, 0x04, 0x08, 0x0C)                  │ │
│  │   - Read/Write control                                       │ │
│  │   - Register banking                                         │ │
│  └────────┬────────────────┬────────────────┬────────────────────┘ │
│           │                │                │                      │
│           ▼                ▼                ▼                      │
│  ┌────────────┐   ┌────────────┐   ┌────────────┐   ┌──────────┐ │
│  │   CTRL     │   │  STATUS    │   │  TX_DATA   │   │ RX_DATA  │ │
│  │  Register  │   │  Register  │   │  Register  │   │ Register │ │
│  │            │   │            │   │            │   │          │ │
│  │ [Baud Sel] │   │ [TX Busy]  │   │ [8 bits]   │   │[8 bits]  │ │
│  │ [Enable]   │   │ [RX Ready] │   │            │   │          │ │
│  └─────┬──────┘   └──────▲─────┘   └─────┬──────┘   └────▲─────┘ │
│        │                 │                │               │       │
│        │ baud_sel        │ status         │ tx_data       │ rx_data
│        │ enable          │                │               │       │
│        │                 │                ▼               │       │
│        │         ┌───────┴──────┐   ┌─────────────┐      │       │
│        │         │              │   │             │      │       │
│        ├────────►│ Baud Rate    │◄──┤  TX Module  │      │       │
│        │         │  Generator   │   │             │      │       │
│        │         │              │   └──────┬──────┘      │       │
│        │         │  - Counter   │          │ tx_out      │       │
│        │         │  - Divider   │          │             │       │
│        │         │              │          │             │       │
│        │         └───────┬──────┘          │             │       │
│        │                 │                 │             │       │
│        │                 │ baud_tick       │             │       │
│        │                 │                 │             │       │
│        │                 ▼                 │             │       │
│        │         ┌──────────────┐          │             │       │
│        └────────►│  RX Module   │          │             │       │
│                  │              │          │             │       │
│                  └───────▲──────┘          │             │       │
│                          │                 │             │       │
│                          │ rx_in           │             │       │
│                          │                 │             │       │
└──────────────────────────┼─────────────────┼─────────────┼───────┘
                           │                 │             │
                    ┌──────┴─────┐    ┌──────┴─────┐      │
                    │  ui_in[7]  │    │ uo_out[0]  │      │
                    │    (RX)    │    │    (TX)    │      │
                    └────────────┘    └────────────┘      │
                                                           │
                                                    ┌──────┴──────┐
                                                    │user_interrupt│
                                                    │ (RX Ready)  │
                                                    └─────────────┘
```

---

## 2. Baud Rate Generator Module

```
┌─────────────────────────────────────────────────────────────┐
│               Baud Rate Generator Module                     │
│                                                              │
│  Inputs:                                                     │
│    - clk           : System clock (70 MHz)                  │
│    - rst_n         : Async active-low reset                 │
│    - baud_sel[3:0] : Baud rate selection                    │
│    - enable        : Enable baud generator                  │
│                                                              │
│  Outputs:                                                    │
│    - baud_tick     : Baud rate clock pulse (1 cycle pulse)  │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                 Baud Rate Lookup                       │ │
│  │                                                        │ │
│  │  baud_sel │ Baud Rate │ Divisor (70MHz)               │ │
│  │  ─────────┼───────────┼───────────────                │ │
│  │    0000   │   9600    │    7291                       │ │
│  │    0001   │  19200    │    3645                       │ │
│  │    0010   │  38400    │    1823                       │ │
│  │    0011   │ 115200    │     607                       │ │
│  │    ...    │   ...     │    ...                        │ │
│  └────────────────────────────────────────────────────────┘ │
│                          │                                   │
│                          ▼                                   │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Divisor Register                          │ │
│  │                 divisor[15:0]                          │ │
│  └────────────────────────┬───────────────────────────────┘ │
│                           │                                  │
│                           ▼                                  │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Counter Logic                             │ │
│  │                                                        │ │
│  │   counter[15:0] ────┐                                 │ │
│  │                     │                                 │ │
│  │              ┌──────▼──────┐                          │ │
│  │              │  counter++  │                          │ │
│  │              └──────┬──────┘                          │ │
│  │                     │                                 │ │
│  │              ┌──────▼──────┐                          │ │
│  │              │ == divisor? │─── Yes ──► baud_tick=1  │ │
│  │              └──────┬──────┘                          │ │
│  │                     │                                 │ │
│  │                     No                                │ │
│  │                     │                                 │ │
│  │                     ▼                                 │ │
│  │              baud_tick=0                              │ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘

Example:
  For 9600 baud at 70 MHz:
    - Divisor = 70,000,000 / 9600 = 7291.67 ≈ 7291
    - Counter counts 0→7290, then resets
    - baud_tick pulses once per bit period
```

---

## 3. UART Transmitter (TX) Module

```
┌─────────────────────────────────────────────────────────────────┐
│                    UART TX Module                                │
│                                                                  │
│  Inputs:                                                         │
│    - clk        : System clock                                  │
│    - rst_n      : Reset                                         │
│    - baud_tick  : Baud rate tick from generator                │
│    - tx_data[7:0] : Data byte to transmit                      │
│    - tx_start   : Start transmission pulse                      │
│                                                                  │
│  Outputs:                                                        │
│    - tx_out     : Serial output (to uo_out[0])                 │
│    - tx_busy    : Transmission in progress flag                │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                   TX State Machine                         │ │
│  │                                                            │ │
│  │        ┌─────────┐                                         │ │
│  │        │  IDLE   │◄────────────────┐                      │ │
│  │        └────┬────┘                  │                      │ │
│  │             │ tx_start              │ bit_cnt==10         │ │
│  │             │                       │                      │ │
│  │        ┌────▼────┐                  │                      │ │
│  │        │  START  │                  │                      │ │
│  │        └────┬────┘                  │                      │ │
│  │             │ baud_tick             │                      │ │
│  │             │                       │                      │ │
│  │        ┌────▼────┐                  │                      │ │
│  │        │  DATA   │──────────────────┘                      │ │
│  │        │(8 bits) │                                         │ │
│  │        └────┬────┘                                         │ │
│  │             │ bit_cnt==8                                   │ │
│  │             │                                              │ │
│  │        ┌────▼────┐                                         │ │
│  │        │  STOP   │                                         │ │
│  │        └─────────┘                                         │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                   Shift Register                           │ │
│  │                                                            │ │
│  │   ┌───┬───┬───┬───┬───┬───┬───┬───┐                      │ │
│  │   │ 7 │ 6 │ 5 │ 4 │ 3 │ 2 │ 1 │ 0 │ ◄── tx_data          │ │
│  │   └─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┘                      │ │
│  │     │   │   │   │   │   │   │   │                        │ │
│  │     └───┴───┴───┴───┴───┴───┴───┴──► Shift right         │ │
│  │                                       (LSB first)          │ │
│  │                                          │                 │ │
│  │                                          ▼                 │ │
│  │                                       tx_out               │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                  Bit Counter                               │ │
│  │                                                            │ │
│  │   bit_cnt[3:0] : Counts 0→9                               │ │
│  │     0     : Start bit                                     │ │
│  │     1-8   : Data bits (LSB first)                         │ │
│  │     9     : Stop bit                                      │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  TX Frame Format (8N1):                                         │
│                                                                  │
│   Idle  Start   D0   D1   D2   D3   D4   D5   D6   D7   Stop   │
│    ──┐  ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐     │
│      │  │   │   │   │   │   │   │   │   │   │   │   │   │──   │
│      └──┘   └───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┘     │
│                                                                  │
│   Logic Levels: Idle=1, Start=0, Data=varies, Stop=1           │
└──────────────────────────────────────────────────────────────────┘
```

---

## 4. UART Receiver (RX) Module

```
┌─────────────────────────────────────────────────────────────────┐
│                    UART RX Module                                │
│                                                                  │
│  Inputs:                                                         │
│    - clk        : System clock                                  │
│    - rst_n      : Reset                                         │
│    - baud_tick  : Baud rate tick (16x oversampling)            │
│    - rx_in      : Serial input (from ui_in[7])                 │
│                                                                  │
│  Outputs:                                                        │
│    - rx_data[7:0] : Received data byte                         │
│    - rx_ready   : Data ready flag                              │
│    - rx_error   : Frame error flag                             │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Input Synchronizer                            │ │
│  │              (Metastability Prevention)                    │ │
│  │                                                            │ │
│  │   rx_in ──► [DFF] ──► [DFF] ──► rx_sync                   │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              │                                   │
│                              ▼                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Start Bit Detector                            │ │
│  │                                                            │ │
│  │   Detect falling edge: rx_sync = 1→0                      │ │
│  └────────────────────────┬───────────────────────────────────┘ │
│                           │                                      │
│                           ▼                                      │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │            16x Oversampling Counter                        │ │
│  │                                                            │ │
│  │   sample_cnt[3:0] : Counts 0→15 per bit period            │ │
│  │                                                            │ │
│  │   Sample Point: sample_cnt == 7 (middle of bit)           │ │
│  │                                                            │ │
│  │    Bit Period:                                             │ │
│  │    0   1   2   3   4   5   6   7   8   9  10  11 12 13 14 15│ │
│  │    ├───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┤│ │
│  │                                  ▲                          │ │
│  │                             Sample Here                     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                   RX State Machine                         │ │
│  │                                                            │ │
│  │        ┌─────────┐                                         │ │
│  │        │  IDLE   │◄────────────────┐                      │ │
│  │        └────┬────┘                  │                      │ │
│  │             │ start_detected        │ bit_cnt==9          │ │
│  │             │                       │                      │ │
│  │        ┌────▼────┐                  │                      │ │
│  │        │  START  │                  │                      │ │
│  │        └────┬────┘                  │                      │ │
│  │             │ verify_start          │                      │ │
│  │             │                       │                      │ │
│  │        ┌────▼────┐                  │                      │ │
│  │        │  DATA   │──────────────────┘                      │ │
│  │        │(8 bits) │                                         │ │
│  │        └────┬────┘                                         │ │
│  │             │ bit_cnt==8                                   │ │
│  │             │                                              │ │
│  │        ┌────▼────┐                                         │ │
│  │        │  STOP   │                                         │ │
│  │        └────┬────┘                                         │ │
│  │             │                                              │ │
│  │             ├─ stop_valid ──► rx_ready=1                  │ │
│  │             └─ stop_error ──► rx_error=1                  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                   Shift Register                           │ │
│  │                                                            │ │
│  │   ┌───┬───┬───┬───┬───┬───┬───┬───┐                      │ │
│  │   │ 7 │ 6 │ 5 │ 4 │ 3 │ 2 │ 1 │ 0 │                      │ │
│  │   └───┴───┴───┴───┴───┴───┴───┴─▲─┘                      │ │
│  │                                  │                        │ │
│  │   Shift left ◄───────────────────┘ rx_sync (at sample)   │ │
│  │   (LSB first)                                             │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Majority Voting (Noise Filter)                │ │
│  │                                                            │ │
│  │   Sample at: cnt=6, cnt=7, cnt=8                          │ │
│  │   Majority wins: 2 out of 3                               │ │
│  │   Example: [0,1,1] → Output = 1                           │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

---

## 5. Register Interface & Memory Map

```
┌─────────────────────────────────────────────────────────────────┐
│                  Register Interface Module                       │
│                                                                  │
│  Inputs:                                                         │
│    - clk              : System clock                            │
│    - rst_n            : Reset                                   │
│    - address[31:0]    : Register address from CPU              │
│    - data_in[31:0]    : Write data from CPU                    │
│    - data_write_n     : Write enable (active low)              │
│    - data_read_n      : Read enable (active low)               │
│                                                                  │
│  Outputs:                                                        │
│    - data_out[31:0]   : Read data to CPU                       │
│    - baud_sel[3:0]    : Baud rate select to TX/RX             │
│    - enable           : UART enable to TX/RX                   │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │             Address Decoder                                │ │
│  │                                                            │ │
│  │   address[31:0] ──┬──► == 0x00 ? ──► ctrl_sel             │ │
│  │                   ├──► == 0x04 ? ──► status_sel           │ │
│  │                   ├──► == 0x08 ? ──► tx_data_sel          │ │
│  │                   └──► == 0x0C ? ──► rx_data_sel          │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │    Register Map                                            │ │
│  │                                                            │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │  CTRL (0x00) - Control Register                      │ │ │
│  │  │                                                       │ │ │
│  │  │  31          8  7   4  3     1  0                    │ │ │
│  │  │  ┌────────────┬──────┬────────┬──┐                   │ │ │
│  │  │  │  Reserved  │ BAUD │Reserved│EN│                   │ │ │
│  │  │  └────────────┴──────┴────────┴──┘                   │ │ │
│  │  │                                                       │ │ │
│  │  │  Write Only                                           │ │ │
│  │  │  [7:4] BAUD_SEL: 0=9600, 1=19200, 2=38400, 3=115200 │ │ │
│  │  │  [0]   ENABLE:   1=enabled, 0=disabled               │ │ │
│  │  └───────────────────────────────────────────────────────┘ │ │
│  │                                                            │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │  STATUS (0x04) - Status Register                     │ │ │
│  │  │                                                       │ │ │
│  │  │  31          8  7   4  3  2  1  0                    │ │ │
│  │  │  ┌────────────┬──────┬──┬──┬──┬──┐                   │ │ │
│  │  │  │  Reserved  │ RES  │TB│RR│RO│RE│                   │ │ │
│  │  │  └────────────┴──────┴──┴──┴──┴──┘                   │ │ │
│  │  │                                                       │ │ │
│  │  │  Read Only                                            │ │ │
│  │  │  [3] TX_BUSY:     1=TX in progress                   │ │ │
│  │  │  [2] RX_READY:    1=RX data available                │ │ │
│  │  │  [1] RX_OVERRUN:  1=RX overrun error                 │ │ │
│  │  │  [0] RX_ERROR:    1=RX frame error                   │ │ │
│  │  └───────────────────────────────────────────────────────┘ │ │
│  │                                                            │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │  TX_DATA (0x08) - Transmit Data Register             │ │ │
│  │  │                                                       │ │ │
│  │  │  31          8  7           0                         │ │ │
│  │  │  ┌────────────┬──────────────┐                       │ │ │
│  │  │  │  Reserved  │   TX Data    │                       │ │ │
│  │  │  └────────────┴──────────────┘                       │ │ │
│  │  │                                                       │ │ │
│  │  │  Write Only                                           │ │ │
│  │  │  [7:0] Data byte to transmit                         │ │ │
│  │  │  Writing triggers transmission                        │ │ │
│  │  └───────────────────────────────────────────────────────┘ │ │
│  │                                                            │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │  RX_DATA (0x0C) - Receive Data Register              │ │ │
│  │  │                                                       │ │ │
│  │  │  31          8  7           0                         │ │ │
│  │  │  ┌────────────┬──────────────┐                       │ │ │
│  │  │  │  Reserved  │   RX Data    │                       │ │ │
│  │  │  └────────────┴──────────────┘                       │ │ │
│  │  │                                                       │ │ │
│  │  │  Read Only                                            │ │ │
│  │  │  [7:0] Received data byte                            │ │ │
│  │  │  Reading clears RX_READY flag                        │ │ │
│  │  └───────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Read Data Multiplexer                         │ │
│  │                                                            │ │
│  │   data_out = ctrl_sel    ? ctrl_reg    :                  │ │
│  │              status_sel  ? status_reg  :                  │ │
│  │              tx_data_sel ? 32'h0       :  // Write-only   │ │
│  │              rx_data_sel ? rx_data_reg :                  │ │
│  │              32'h0;                                        │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

---

## 6. Module Hierarchy

```
tt_um_tqv_peripheral_harness (Top)
│
├── tqvp_uart (UART Peripheral Instance)
│   │
│   ├── uart_register_interface
│   │   ├── address_decoder
│   │   ├── ctrl_register
│   │   ├── status_register
│   │   ├── tx_data_register
│   │   └── rx_data_register
│   │
│   ├── uart_baud_generator
│   │   ├── divisor_lookup
│   │   ├── counter [15:0]
│   │   └── tick_generator
│   │
│   ├── uart_tx
│   │   ├── tx_state_machine (IDLE/START/DATA/STOP)
│   │   ├── shift_register [7:0]
│   │   ├── bit_counter [3:0]
│   │   └── tx_output_driver
│   │
│   └── uart_rx
│       ├── input_synchronizer (2 DFFs)
│       ├── start_detector
│       ├── oversample_counter [3:0]
│       ├── rx_state_machine (IDLE/START/DATA/STOP)
│       ├── shift_register [7:0]
│       ├── bit_counter [3:0]
│       ├── majority_voter
│       └── frame_checker
│
└── test_harness (SPI + synchronizers - unchanged)
    ├── spi_reg
    ├── rising_edge_detector
    ├── falling_edge_detector
    ├── synchronizer
    └── reclocking
```

---

Return to [diagrams README](README.md) for more diagram formats.
