# UART Fundamentals - Complete Guide for Beginners

> **🎯 Quick Start**: If you're brand new to UART, start with the [Simple Telephone Analogy](#the-simple-analogy-a-telephone-conversation) below, then check out [Common Mistakes](#-common-uart-mistakes-and-how-to-avoid-them) at the end!

---

## What is UART? (The Basics)

**UART** = Universal Asynchronous Receiver/Transmitter

**In Plain English**: UART is a way for two electronic devices to talk to each other by sending data one bit at a time over a single wire, like having a conversation over a phone!

### The Simple Analogy: A Telephone Conversation

Think of UART like two people having a phone conversation:

-   **Serial communication** = Speaking one word at a time (not shouting many words simultaneously)
-   **TX (Transmit)** = Your mouth speaking into the phone
-   **RX (Receive)** = Your ear listening to the phone
-   **Full-Duplex** = Both people can talk and listen at the same time (modern phones)
-   **Baud Rate** = How fast you speak (words per minute)

Just like phones need to be connected correctly (mouthpiece to earpiece), UART connects:

-   Device A's TX → Device B's RX
-   Device A's RX → Device B's TX

### Key Characteristics

1. **Asynchronous** - No shared clock signal between devices (like phone calls - no synchronized timing needed)
2. **Point-to-Point** - Connects two devices directly (one-on-one conversation)
3. **Full-Duplex** - Can send and receive simultaneously (both people can talk at once)
4. **Simple** - Only needs 2 wires (TX and RX) plus ground (minimal hardware)

### Real-World Applications

**You use UART every day!** Here are common examples:

1. **GPS Navigation** 🛰️
    - Your car's GPS module sends location data via UART to the dashboard display
    - Baud rate: Usually 9600 bps
2. **Bluetooth Headphones** 🎧
    - Bluetooth chips communicate with microcontrollers via UART
    - The music commands flow through UART internally
3. **Arduino Projects** 🤖
    - Arduino Serial Monitor uses UART over USB
    - "Serial.println()" sends data via UART
    - Common for debugging: "Hello World" printing
4. **Point-of-Sale Terminals** 💳
    - Credit card readers communicate via UART
    - Barcode scanners send data to registers via UART
5. **Industrial Sensors** 🏭
    - Temperature sensors, pressure sensors send readings via UART
    - Simple, reliable, works over moderate distances
6. **Computer Mice (older models)** 🖱️
    - Serial port mice used UART
    - Modern USB mice emulate UART internally

---

## Why UART? (Compared to Other Options)

### The Restaurant Analogy

Imagine different ways to communicate orders in a restaurant:

1. **UART (Serial)** = A waiter taking orders one table at a time
    - Simple, reliable, but takes more time for many orders
    - Only needs one waiter (one wire)
2. **Parallel Communication** = Multiple waiters taking orders simultaneously
    - Faster for large batches
    - Needs many waiters (many wires), expensive!
3. **SPI** = A manager coordinating multiple waiters with a whistle (clock signal)
    - Very organized, very fast
    - Needs coordination signal (clock wire)
4. **I2C** = Shared walkie-talkie system (shared bus)
    - Many devices on same channel
    - Can get crowded (slower)

**UART wins when**: You need simple, reliable, point-to-point communication without extra wires!

### Advantages

-   **Simple hardware** - Easy to implement (no complex protocols)
-   **Widely supported** - Nearly every chip has UART built-in
-   **Low pin count** - Only 2 signal wires needed (cheap!)
-   **Flexible** - Configurable baud rate and data format
-   **Long distance** - Works over several meters (with proper drivers)
-   **No clock signal needed** - Saves a wire!

---

## UART Hardware Basics

### Physical Connections

```
Device A              Device B
┌─────┐              ┌─────┐
│ TX  │──────────────│ RX  │  (Device A sends to Device B)
│     │              │     │
│ RX  │──────────────│ TX  │  (Device B sends to Device A)
│     │              │     │
│ GND │──────────────│ GND │  (Common ground)
└─────┘              └─────┘
```

**Important**: TX (transmit) of one device connects to RX (receive) of the other!

### Signal Levels

-   **Idle state**: Logic HIGH (1)
-   **Active transmission**: Starts with Logic LOW (0)
-   Voltage levels: Typically 3.3V or 5V (TTL levels)

---

## UART Data Frame Structure

UART sends data in **frames**. Each frame contains:

```
┌────┬─────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┬────────┬──────┐
│IDLE│START│ D0   │ D1   │ D2   │ D3   │ D4   │ D5   │ D6   │ D7     │STOP  │
│ 1  │  0  │      │      │      │ DATA BITS (5-9 bits)       │ PARITY │ 1/2  │
└────┴─────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┴────────┴──────┘
     ↑                                                                  ↑
   Signals                                                          Back to
   start of                                                          idle
transmission
```

### Frame Components

1. **IDLE** (High state)

    - Default state when not transmitting
    - Line stays HIGH

2. **START BIT** (Always 0)

    - Signals beginning of a frame
    - Line goes from HIGH → LOW
    - Receiver detects this transition and starts reading

3. **DATA BITS** (5-9 bits, usually 8)

    - The actual data being sent
    - Sent LSB (Least Significant Bit) first
    - Example: To send 0xA5 (10100101):
        - Bit order: 1, 0, 1, 0, 0, 1, 0, 1

4. **PARITY BIT** (Optional)

    - Error checking bit
    - **Even parity**: Makes total number of 1s even
    - **Odd parity**: Makes total number of 1s odd
    - **No parity**: Skip this bit (most common)

5. **STOP BIT(S)** (1, 1.5, or 2 bits of HIGH)
    - Signals end of frame
    - Line returns to HIGH
    - Allows receiver time to process

---

## Timing: Baud Rate (Speed of Communication)

**Baud Rate** = Number of bits per second (bps)

### The Highway Analogy 🚗

Think of baud rate like speed limits on a highway:

-   **9600 bps** = School zone (slow, safe, works with old equipment)
-   **115200 bps** = Highway speed (fast, requires good "road conditions")

Both cars reach the destination, but faster speeds need:

-   Better timing precision (like good brakes at high speed)
-   Shorter cable distances (like highway vs bumpy road)
-   Higher quality hardware (like sports car vs old truck)

### Common Baud Rates

-   **9600 bps** - Most common for sensors, GPS modules (very reliable)
-   **19200 bps** - Faster sensors
-   **38400 bps** - Moderate speed
-   **57600 bps** - Higher speed applications
-   **115200 bps** - Common for PC communication, Arduino default

### Example Timing Calculation

For **9600 baud**:

-   9600 bits/second
-   Each bit duration = 1/9600 ≈ **104.17 microseconds**

For a **8N1 frame** (8 data, No parity, 1 stop):

-   Total bits = 1 start + 8 data + 1 stop = 10 bits
-   Frame time = 10 × 104.17µs ≈ **1.04 milliseconds**

### Baud Rate Generation

To generate timing, you need a clock divider:

```
Bit period = System_Clock / (Baud_Rate × Oversampling)
```

Common oversampling: 16× (sample 16 times per bit for accuracy)

Example: For 9600 baud with 70MHz system clock:

```
Divider = 70,000,000 / (9600 × 16) = 456.6 ≈ 457
```

---

## UART Configuration: "8N1"

You'll see UART configs like **8N1**, **8E1**, **7O1**, etc.

**Format**: `[Data bits][Parity][Stop bits]`

### Common Configurations

| Config | Data Bits | Parity | Stop Bits |
| ------ | --------- | ------ | --------- | ------------- |
| 8N1    | 8         | None   | 1         | ← Most common |
| 8E1    | 8         | Even   | 1         |
| 8O1    | 8         | Odd    | 1         |
| 7E1    | 7         | Even   | 1         |

**8N1** is the de facto standard: 8 data bits, no parity, 1 stop bit.

---

## How UART Transmission Works

### Transmitter (TX) Side

1. **Wait for data** to send (byte in TX buffer/FIFO)
2. **Pull line LOW** (send start bit)
3. **Send 8 data bits** LSB first, at baud rate intervals
4. **Pull line HIGH** (send stop bit)
5. **Return to idle** (line stays HIGH)
6. **Repeat** for next byte

### Receiver (RX) Side

1. **Monitor RX line** for HIGH → LOW transition (start bit)
2. **Wait half a bit period** to align to center of bits
3. **Sample bit** at each bit interval (using baud rate timer)
4. **Read 8 data bits** LSB first
5. **Check stop bit** is HIGH (frame error if not)
6. **Store byte** in RX buffer/FIFO
7. **Generate interrupt** (optional) to notify CPU

### Clock Recovery

Since UART is asynchronous (no shared clock), the receiver must:

-   Use a local clock running at the same baud rate
-   **Oversample** (typically 16×) to find bit centers accurately
-   **Resynchronize** on each start bit

---

## Real Example: Sending 'A' (ASCII 0x41)

ASCII 'A' = 0x41 = 0b01000001

### The Train Analogy 🚂

Imagine sending a letter 'A' like a train carrying cargo:

1. **IDLE** = Empty track (train station quiet)
2. **START bit** = Train whistle (announcement: "train arriving!")
3. **DATA bits** = 8 cargo cars carrying 0s and 1s
4. **STOP bit** = Caboose (end of train signal)

**Important**: Cargo cars loaded from back to front (LSB first)!

**Transmission sequence** (LSB first):

```
Time →
┌─────────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬─────────
│  IDLE   │    │    │    │    │    │    │    │    │    │  IDLE
│   (1)   │ 0  │ 1  │ 0  │ 0  │ 0  │ 0  │ 0  │ 1  │ 0  │  (1)
└─────────┴────┴────┴────┴────┴────┴────┴────┴────┴────┴─────────
           START  D0   D1   D2   D3   D4   D5   D6   D7  STOP
          🚂     🚃   🚃   🚃   🚃   🚃   🚃   🚃   🚃   🚋
                  ↑                                   ↑
                 LSB                                 MSB
                (Sent first)                   (Sent last)
```

Actual bit values on wire: **1 → 0 → 1 → 0 → 0 → 0 → 0 → 0 → 1 → 0 → 1**

**Breaking it down step-by-step:**

-   0x41 in binary: 0b**01000001** (reading left-to-right: bit7-bit6-bit5-bit4-bit3-bit2-bit1-bit0)
-   **Bit positions**: D7=**0**, D6=**1**, D5=**0**, D4=**0**, D3=**0**, D2=**0**, D1=**0**, D0=**1**
-   **LSB first** means we transmit D0 first, then D1, D2... up to D7 last
-   **Wire sequence**: START(0) → D0(**1**) → D1(**0**) → D2(**0**) → D3(**0**) → D4(**0**) → D5(**0**) → D6(**1**) → D7(**0**) → STOP(1)

### Why LSB First?

Historical reason: Old hardware could start processing the least significant bits while still receiving the rest. Like unloading train cars from the back while front cars are still arriving!

---

## Error Detection (When Things Go Wrong)

### The Package Delivery Analogy 📦

Think of UART errors like package delivery problems:

### Common Errors

1. **Framing Error** = Package arrives without proper wrapping

    - Stop bit is not HIGH when expected
    - **Usually means baud rate mismatch** (sender and receiver talking at different speeds!)
    - Like: You're speaking fast but listener expects slow speech
    - **Fix**: Make sure both devices use same baud rate setting!

2. **Parity Error** = Package checksum doesn't match

    - Parity bit doesn't match calculated parity
    - Indicates bit corruption (noise on the wire)
    - Like: Counting items in a box and finding one missing
    - **Fix**: Use shielded cables, shorter distances, or add error correction

3. **Overrun Error** = Mailbox is full, new package dropped

    - New data arrives before previous data was read
    - RX buffer/FIFO full
    - Like: Mail piling up because you don't check mailbox
    - **Fix**: Read data faster, use larger FIFO buffer

4. **Break Condition** = Special "emergency" signal
    - RX line held LOW for longer than a frame
    - Can be used for special signaling (like "RESET" command)
    - Like: Holding down a phone button to hang up

### Debugging Tips 🔧

**Most common UART problem: Baud rate mismatch!**

Symptoms:

-   Receiving garbage data (random characters)
-   Missing characters
-   Framing errors

Solution checklist:

-   ✅ Check both devices use same baud rate (9600 = 9600)
-   ✅ Check both devices use same config (8N1 = 8N1)
-   ✅ Verify TX of device A connects to RX of device B (and vice versa)
-   ✅ Ensure common ground connection
-   ✅ Check cable length (keep under 15 meters for high baud rates)

---

## UART Registers (How to Actually Use Them!)

### ⚠️ Wait... What KIND of "Register"?

The word **"register"** has **3 different meanings** in hardware. Let's clear this up:

#### 1️⃣ Memory-Mapped Registers (What we're talking about HERE!)

-   **What**: Special memory addresses the CPU uses to talk to peripherals
-   **Where**: They live at specific addresses like `0x00`, `0x04`, `0x08`
-   **How**: CPU reads/writes to these addresses to control UART
-   **Think**: Like mailboxes - CPU puts letters in (writes) or checks for mail (reads)
-   **In Verilog**: Declared as `reg [31:0] ctrl_register;` but used as storage

**Example**:

```verilog
// If CPU writes to address 0x00, store in ctrl_register
if (address == 32'h0000_0000 && !data_write_n)
    ctrl_register <= data_in;  // This is a memory-mapped register!
```

#### 2️⃣ Shift Registers (Used INSIDE the UART)

-   **What**: Sequential circuits that shift bits left/right
-   **Where**: Inside TX/RX modules to serialize/deserialize data
-   **How**: Takes parallel byte (8 bits), outputs 1 bit at a time (or vice versa)
-   **Think**: Like a conveyor belt moving bits one position at a time
-   **In Verilog**: `reg [7:0] shift_reg;` with shift operations `<< 1` or `>> 1`

**Example**:

```verilog
// TX shift register - outputs bits one-by-one
always @(posedge clk) begin
    if (load)
        shift_reg <= tx_data;      // Load 8 bits
    else if (shift)
        shift_reg <= {1'b0, shift_reg[7:1]};  // Shift right, output bit 0
end
assign tx_out = shift_reg[0];  // Serial output!
```

#### 3️⃣ Verilog `reg` Keyword (Just a language thing!)

-   **What**: Verilog syntax for variables assigned in `always` blocks
-   **Where**: Anywhere in your Verilog code
-   **How**: Just means "this holds a value" - might be a flip-flop, might be combinational
-   **Think**: Like declaring `int x;` in C - just a variable type
-   **Confusing**: Name is historical - doesn't always mean physical register/flip-flop!

**Example**:

```verilog
reg [7:0] counter;        // Probably becomes flip-flops (sequential)
reg [3:0] temp_value;     // Might be just wires (combinational)
reg tx_busy;              // Status bit (probably a flip-flop)
```

---

### 🎯 For This Section: We Mean **Memory-Mapped Registers** (#1)

These are the "control panel" the CPU uses to operate the UART peripheral.

---

### 💡 Deep Dive: What is Memory Mapping?

#### The Big Picture: CPU's View of the World

Your TinyQV CPU sees **everything** as memory addresses. It doesn't care if it's reading/writing to:

-   Actual RAM (data storage)
-   ROM (program code)
-   Peripherals like UART (special hardware)

**To the CPU, it's all just addresses!**

```
CPU's Address Space (Simplified):

0x0000_0000 ─────────┐
             ...     │  ← RAM (normal memory)
0x0FFF_FFFF ─────────┤
                     │
0x1000_0000 ─────────┤
  UART CTRL          │  ← UART Registers (memory-mapped peripheral!)
  UART STATUS        │     NOT actual memory - it's hardware!
  UART TX_DATA       │
  UART RX_DATA       │
0x1000_000F ─────────┤
                     │
0x2000_0000 ─────────┤
             ...     │  ← More peripherals (SPI, I2C, etc.)
0xFFFF_FFFF ─────────┘
```

#### What Happens When CPU Writes to 0x1000_0000?

Let's trace a write operation step-by-step:

**CPU Code (in C)**:

```c
// CPU wants to enable UART at 115200 baud
*((volatile uint32_t *)0x10000000) = 0xC1;  // Write to address 0x10000000
```

**What the CPU does**:

```
1. CPU puts 0x10000000 on address bus
2. CPU puts 0x000000C1 on data bus
3. CPU asserts data_write_n = 0 (active low write signal)
```

**What the UART hardware does** (this is YOUR Verilog code!):

```verilog
always @(posedge clk) begin
    // Address decoder: Is CPU talking to ME?
    if (address == 32'h1000_0000 && !data_write_n) begin
        // YES! CPU is writing to my CTRL register
        ctrl_register <= data_in[7:0];  // Grab bottom 8 bits

        // Now extract the configuration
        baud_sel <= data_in[7:4];   // Bits 7-4 → baud rate
        enable   <= data_in[0];     // Bit 0 → enable
    end
end
```

**Result**: Your UART's `ctrl_register` now holds `0xC1`, and `enable` bit goes HIGH!

---

#### Memory-Mapped vs Regular Memory

| Aspect             | Regular Memory (RAM)   | Memory-Mapped Register                    |
| ------------------ | ---------------------- | ----------------------------------------- |
| **What it is**     | Array of storage cells | Hardware control interface                |
| **When you read**  | Returns stored data    | Returns current hardware status           |
| **When you write** | Stores data for later  | **Triggers hardware action!**             |
| **Predictable?**   | Yes - write 5, read 5  | No - write 5, might read something else!  |
| **Example**        | `array[10] = 42;`      | `UART_TX = 'A';` (triggers transmission!) |

**Key difference**: Writing to memory-mapped registers **DOES SOMETHING** in hardware!

---

#### Your UART: The Complete Picture

**Hardware Block Diagram**:

```
     TinyQV CPU
         │
         ├─── address[31:0] ────────┐
         ├─── data_in[31:0] ────────┤
         ├─── data_out[31:0] ───────┤
         ├─── data_write_n ─────────┤
         └─── data_read_n ──────────┤
                                    │
                            ┌───────▼────────┐
                            │ Register       │
                            │ Interface      │
                            │ (Address       │
                            │  Decoder)      │
                            └───────┬────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
            ┌───────▼──────┐ ┌─────▼──────┐ ┌─────▼──────┐
            │ CTRL Register│ │STATUS Reg  │ │TX_DATA Reg │ ...
            │  0x00        │ │  0x04      │ │  0x08      │
            └───────┬──────┘ └─────┬──────┘ └─────┬──────┘
                    │               │               │
                    │               │               │
                ┌───▼───┐       ┌───▼───┐       ┌───▼───┐
                │ Baud  │       │ TX    │       │ RX    │
                │  Gen  │       │ FSM   │       │ FSM   │
                └───────┘       └───┬───┘       └───────┘
                                    │
                                    └────── tx_out (serial wire!)
```

**The flow**:

1. CPU writes to address `0x08` (TX_DATA)
2. Address decoder sees `0x08` and routes to TX_DATA register
3. TX_DATA register captures the byte
4. TX_DATA register asserts `tx_start` signal
5. TX FSM wakes up and starts transmitting bit-by-bit!

**This is the magic**: CPU just writes to a memory address, but hardware converts it to serial transmission!

---

#### Implementing Memory-Mapped Registers in Verilog

Here's simplified code for YOUR UART register interface:

```verilog
module uart_register_interface (
    input clk,
    input rst_n,

    // CPU Bus Interface
    input  [31:0] address,
    input  [31:0] data_in,
    output [31:0] data_out,
    input         data_write_n,  // 0 = write
    input         data_read_n,   // 0 = read

    // To UART modules
    output [3:0]  baud_sel,
    output        enable,
    output [7:0]  tx_data,
    output        tx_start,
    input  [7:0]  rx_data,
    input         rx_ready,
    input         tx_busy
);

// The actual register storage (flip-flops)
reg [7:0] ctrl_register;
reg [7:0] tx_data_reg;
reg       tx_start_pulse;

// Base address for this UART
localparam BASE_ADDR = 32'h1000_0000;

// Address offsets
localparam CTRL_OFFSET   = 4'h0;  // 0x10000000
localparam STATUS_OFFSET = 4'h4;  // 0x10000004
localparam TXDATA_OFFSET = 4'h8;  // 0x10000008
localparam RXDATA_OFFSET = 4'hC;  // 0x1000000C

// ============= WRITE OPERATIONS =============
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ctrl_register <= 8'h00;
        tx_data_reg   <= 8'h00;
        tx_start_pulse <= 1'b0;
    end
    else begin
        tx_start_pulse <= 1'b0;  // Default: no transmit

        // Is CPU writing to us?
        if (!data_write_n && address[31:4] == BASE_ADDR[31:4]) begin
            case (address[3:0])
                CTRL_OFFSET: begin
                    // Write to CTRL register
                    ctrl_register <= data_in[7:0];
                end

                TXDATA_OFFSET: begin
                    // Write to TX_DATA triggers transmission!
                    tx_data_reg <= data_in[7:0];
                    tx_start_pulse <= 1'b1;  // Pulse to start TX
                end

                // STATUS and RXDATA are read-only, ignore writes
            endcase
        end
    end
end

// Extract control signals from ctrl_register
assign baud_sel = ctrl_register[7:4];
assign enable   = ctrl_register[0];
assign tx_data  = tx_data_reg;
assign tx_start = tx_start_pulse;

// ============= READ OPERATIONS =============
reg [31:0] data_out_reg;

always @(*) begin
    // Default: return 0
    data_out_reg = 32'h0000_0000;

    // Is CPU reading from us?
    if (!data_read_n && address[31:4] == BASE_ADDR[31:4]) begin
        case (address[3:0])
            STATUS_OFFSET: begin
                // Build status word
                data_out_reg = {28'h0, tx_busy, rx_ready, 2'b00};
            end

            RXDATA_OFFSET: begin
                // Return received data
                data_out_reg = {24'h000000, rx_data};
            end

            // CTRL and TXDATA are write-only, return 0
        endcase
    end
end

assign data_out = data_out_reg;

endmodule
```

**Key insights**:

1. **Address decoder**: `if (address == 0x10000000)` decides which register
2. **Write logic**: Stores value when `data_write_n = 0`
3. **Read logic**: Returns status/data when `data_read_n = 0`
4. **Side effects**: Writing to TX_DATA creates `tx_start` pulse!

---

### 🤔 Wait... When Does CPU Decide to Read or Write?

**Short answer**: The SOFTWARE (your program) tells the CPU what to do!

#### The CPU Instruction Flow

The CPU executes **instructions** from your program. When it sees certain instructions, it generates read/write signals:

**Example C Program**:

```c
void send_hello() {
    char *uart_tx = (char *)0x10000008;  // TX_DATA address
    char *uart_status = (char *)0x10000004;  // STATUS address

    // This instruction causes a READ
    while (*uart_status & 0x08);  // Read STATUS, check TX_BUSY bit

    // This instruction causes a WRITE
    *uart_tx = 'H';  // Write 'H' to TX_DATA
}
```

**What the CPU does (simplified)**:

**1. Read Operation** (`while (*uart_status & 0x08)`):

```
CPU sees: "Load byte from address 0x10000004"

CPU Actions:
├─ Put 0x10000004 on address bus
├─ Assert data_read_n = 0  ← CPU says "I'm reading!"
├─ Wait for device to respond
├─ Capture data from data_out bus
└─ Use the value (check bit 3)
```

**2. Write Operation** (`*uart_tx = 'H'`):

```
CPU sees: "Store byte 'H' to address 0x10000008"

CPU Actions:
├─ Put 0x10000008 on address bus
├─ Put 0x48 ('H') on data_in bus
├─ Assert data_write_n = 0  ← CPU says "I'm writing!"
├─ Wait one clock cycle
└─ De-assert data_write_n = 1 (done)
```

**Assembly code that generates these signals**:

```assembly
# Read STATUS register
LW   t0, 0x10000004(zero)   # Load Word → data_read_n = 0
ANDI t1, t0, 0x08           # Check bit 3

# Write to TX_DATA register
LI   t2, 0x48               # Load immediate 'H'
SW   t2, 0x10000008(zero)   # Store Word → data_write_n = 0
```

**The key**: `data_write_n` and `data_read_n` are **outputs from the CPU**, controlled by what instructions it's executing!

---

### 🔌 Where Are "Device A" and "Device B"?

**Great question!** Let me show you the COMPLETE physical system:

#### The Full Picture: Two Devices Talking

```
┌─────────────────────────────────────────┐         ┌─────────────────────────┐
│          DEVICE A                       │         │      DEVICE B           │
│         (Your TinyQV System)            │         │   (External Device)     │
│                                         │         │                         │
│  ┌──────────────┐   ┌───────────────┐  │         │  ┌───────────────┐      │
│  │              │   │               │  │         │  │               │      │
│  │  TinyQV CPU  │   │  UART         │  │         │  │   Their       │      │
│  │   (RISC-V)   │   │  Peripheral   │  │         │  │   UART        │      │
│  │              │   │               │  │         │  │               │      │
│  │  - Runs code │   │  - TX Module──┼──┼────TX───┼─►│ RX ───────────┼──┐   │
│  │  - Reads/    │   │  - RX Module◄─┼──┼────RX───┼──│ TX            │  │   │
│  │    Writes    │   │  - Registers  │  │         │  │               │  │   │
│  │    registers │◄──┤  - Baud Gen   │  │         │  │               │  │   │
│  │              │   │               │  │         │  │               │  │   │
│  └──────────────┘   └───────────────┘  │         │  └───────────────┘  │   │
│         ▲                    ▲          │         │           │          │   │
│         │                    │          │         │           ▼          │   │
│         │            (Internal bus)     │         │    ┌──────────────┐  │   │
│         │                    │          │         │    │ Their CPU or │  │   │
│         └────────────────────┘          │         │    │ Microcontrol │  │   │
│                                         │         │    └──────────────┘  │   │
└─────────────────────────────────────────┘         └─────────────────────────┘
              ▲                                                    ▲
              │                                                    │
         Your FPGA board                                   External hardware
      (Ice40 or similar)                              (Arduino, PC, GPS, etc.)

         GND ─────────────── GND ─────────────────────── GND
         (Common ground required!)
```

**Breaking it down**:

1. **Device A = Your Entire TinyQV System**

    - TinyQV CPU (runs your program)
    - UART peripheral (your Verilog code)
    - Both live on the same FPGA chip
    - Connected internally via register bus

2. **Device B = External Device** (could be many things!)
    - Another microcontroller (Arduino, ESP32, etc.)
    - A PC running terminal software (PuTTY, screen, etc.)
    - A GPS module
    - A Bluetooth chip
    - ANY device with a UART interface

#### What Your CPU Does

Your CPU is like a person operating a telegraph machine:

```
CPU's job:
┌─────────────────────────────────────────┐
│ 1. Decides "I want to send 'A'"         │
│ 2. Writes 'A' to UART TX_DATA register  │ ← Software decision
│ 3. UART hardware takes over             │ ← Your Verilog!
│ 4. UART sends bits on TX wire           │
│ 5. External device receives on RX wire  │
└─────────────────────────────────────────┘
```

**The CPU is NOT the sender/receiver!** The CPU is the **BRAIN** that controls the UART peripheral, which is the actual sender/receiver.

#### Real Hardware Example

Let's say you're building a weather station:

```
┌────────────────────────────────┐          ┌──────────────────────┐
│  Ice40 FPGA Board              │          │   GPS Module         │
│  (Your TinyQV + UART)          │          │   (NEO-6M)           │
│                                │          │                      │
│  Pin 15 (TX) ──────────────────┼─────────►│ RX pin               │
│  Pin 16 (RX) ◄─────────────────┼──────────│ TX pin               │
│  GND ──────────────────────────┼──────────│ GND                  │
│                                │          │                      │
│  CPU runs:                     │          │  Sends GPS data:     │
│  while(1) {                    │          │  "$GPGGA,123456,..." │
│    if (rx_ready)               │          │  at 9600 baud        │
│      data = read_uart();       │          │                      │
│  }                             │          │                      │
└────────────────────────────────┘          └──────────────────────┘
```

#### Physical Wires

The TX and RX signals are **actual physical pins on your FPGA**:

```verilog
module top (
    // ... other signals ...
    output wire uart_tx,  // → Goes to external pin (e.g., GPIO 15)
    input  wire uart_rx   // ← Comes from external pin (e.g., GPIO 16)
);

// Your UART module
uart_peripheral my_uart (
    .tx_out(uart_tx),  // This becomes a voltage on the physical pin!
    .rx_in(uart_rx),   // This reads voltage from the physical pin!
    // ...
);
```

**The signal journey**:

```
Inside FPGA:                   Outside FPGA:
tx_out (wire) → Pin driver → Physical pin voltage (3.3V or 0V) → Travels on wire → External device RX pin
```

---

### 🔁 What About Loopback Testing?

Loopback testing is when you **connect Device A to itself** for testing purposes:

#### Loopback Configuration

**Instead of this** (normal):

```
TinyQV TX ──────► External Device RX
TinyQV RX ◄────── External Device TX
```

**You do this** (loopback):

```
TinyQV TX ──┐
            ├──► Short wire
TinyQV RX ◄─┘
```

**In testbench** (simulation):

```verilog
// Connect TX directly to RX
assign uart_rx = uart_tx;  // Whatever I send, I immediately receive
```

**Why loopback?**

-   ✅ Test your TX module (does it transmit correctly?)
-   ✅ Test your RX module (does it receive correctly?)
-   ✅ Don't need external hardware
-   ✅ Easy to debug (you control both ends)

**Example loopback test**:

```c
// Send 'A', should receive 'A' back
uart_send('A');
char received = uart_receive();
if (received == 'A') {
    printf("Success! Loopback works!\n");
}
```

---

### Summary: Devices A & B

| Component           | What It Is            | Role                                                 |
| ------------------- | --------------------- | ---------------------------------------------------- |
| **TinyQV CPU**      | Your RISC-V processor | Runs software, controls UART via registers           |
| **UART Peripheral** | Your Verilog module   | Converts bytes to serial (TX), serial to bytes (RX)  |
| **Device A**        | CPU + UART together   | The complete sender/receiver system                  |
| **Device B**        | External hardware     | The thing you're talking to (GPS, PC, Arduino, etc.) |
| **TX Wire**         | Physical connection   | Carries serial data from A to B                      |
| **RX Wire**         | Physical connection   | Carries serial data from B to A                      |
| **Loopback**        | Test configuration    | A talks to itself (TX→RX on same device)             |

**The key insight**: Your UART peripheral is the **interface** between the digital world inside the CPU and the physical serial communication world outside!

---

### The Control Panel Analogy 🎛️

Think of UART **memory-mapped registers** like the dashboard in your car:

-   **Control Register** = Gear shift, turn signals (what you want to DO)
-   **Status Register** = Dashboard lights, fuel gauge (what's HAPPENING)
-   **Data Register** = The cargo you're carrying
-   **Baud Rate Register** = Speed limiter setting

**Key concept**: CPU doesn't directly control the UART wires. Instead, it writes to special memory addresses (registers), and the UART hardware reads those values to know what to do!

---

### Register #1: CONTROL Register (CTRL) - "The Settings Knob"

**What it does**: You tell the UART HOW to operate

**Typical bits**:

```
Bit 7-4: Baud rate selection (0000=9600, 0001=19200, etc.)
Bit 3-1: Reserved
Bit 0:   UART Enable (1=ON, 0=OFF)
```

**Real example - Starting your UART**:

```c
// I want 115200 baud rate, UART enabled
UART_CTRL = 0x0C1;  // Binary: 00001100 0001
                    // Bits 7-4 = 0xC (115200 baud)
                    // Bit 0 = 1 (Enable)
```

**Think of it like**: Setting your car's cruise control to 115 mph and turning the engine ON.
V

---

### Register #2: STATUS Register (STATUS) - "The Dashboard"

**What it does**: UART tells YOU what's happening (READ-ONLY!)

**Typical bits**:

```
Bit 7-4: Reserved
Bit 3:   TX_BUSY (1=transmitter busy, 0=ready for new data)
Bit 2:   RX_READY (1=data received and ready to read, 0=nothing yet)
Bit 1:   RX_OVERRUN (1=missed data because CPU was too slow!)
Bit 0:   RX_ERROR (1=framing error, 0=no error)
```

**Real example - Checking before sending**:

```c
// Before sending data, check if TX is ready
while (UART_STATUS & 0x08) {  // Bit 3: TX_BUSY
    // Wait... transmitter still busy
}
// Now TX_BUSY=0, safe to send!
UART_TX_DATA = 'A';  // Send the letter 'A'
```

**Think of it like**: Checking your car's fuel gauge before starting a trip. You don't CONTROL the fuel level by looking at the gauge, you just READ it!

---

### Register #3: TX_DATA Register - "The Outbox"

**What it does**: Write a byte here to SEND it

**Real example - Sending "Hi"**:

```c
// Step 1: Wait for TX to be ready
while (UART_STATUS & 0x08);  // Wait while TX_BUSY=1

// Step 2: Write 'H'
UART_TX_DATA = 'H';  // Writing triggers transmission!

// Step 3: Wait again (TX becomes busy)
while (UART_STATUS & 0x08);  // Wait for 'H' to finish

// Step 4: Write 'i'
UART_TX_DATA = 'i';
```

**Think of it like**: Dropping letters in a mailbox. Once you drop it in (write to register), the mail carrier (UART hardware) picks it up and delivers it.

---

### Register #4: RX_DATA Register - "The Inbox"

**What it does**: Read a byte from here after receiving it

**Real example - Receiving data**:

```c
// Step 1: Check if data has arrived
if (UART_STATUS & 0x04) {  // Bit 2: RX_READY=1?

    // Step 2: Read the received byte
    char received = UART_RX_DATA;

    // Reading automatically clears RX_READY flag!
    // UART is now ready to receive next byte

    printf("Got: %c\n", received);
}
```

**Think of it like**: Checking your mailbox. When the flag is up (RX_READY=1), you have mail. Reading it (loading RX_DATA) automatically lowers the flag.

---

### Complete Example: Echo Program (Read & Send Back)

```c
void uart_echo() {
    // Setup: Enable UART at 115200 baud
    UART_CTRL = 0xC1;  // 115200 baud, enabled

    while (1) {
        // 1. Wait for incoming data
        if (UART_STATUS & 0x04) {  // RX_READY?

            // 2. Read what was received
            char data = UART_RX_DATA;

            // 3. Wait until TX is ready
            while (UART_STATUS & 0x08);  // TX_BUSY?

            // 4. Echo it back
            UART_TX_DATA = data;
        }
    }
}
```

**What this does**: Whatever you type gets sent right back to you (like shouting into a canyon).

---

### Your TinyQV Register Map

```
Address | Register  | Read/Write | What it does
--------|-----------|------------|----------------------------------------
0x00    | CTRL      | Write Only | Configure: baud rate, enable
0x04    | STATUS    | Read Only  | Check: TX busy? RX ready? Errors?
0x08    | TX_DATA   | Write Only | Write byte here to transmit
0x0C    | RX_DATA   | Read Only  | Read received byte from here
```

**Remember**:

-   **Write-only registers**: You SET them (like turning a knob)
-   **Read-only registers**: You CHECK them (like reading a gauge)
-   **Never** try to write to STATUS or read from CTRL!

---

## FIFO Buffers (The Waiting Line) 🎢

### The Amusement Park Analogy

**Without FIFO** = No queue line at a rollercoaster

-   Each person must get on the ride immediately
-   If ride operator is busy, people are turned away (OVERRUN!)
-   Very inefficient

**With FIFO** = Proper queue line (First In, First Out)

-   **TX FIFO**: People waiting to board the ride
-   **RX FIFO**: People exiting the ride into exit queue
-   Ride operator can handle them in batches
-   Much smoother operation!

### Benefits

Without FIFO:

-   ❌ CPU must read each byte immediately (stressful!)
-   ❌ Risk of overrun if CPU is busy with other tasks
-   ❌ Inefficient (CPU constantly interrupted)

With FIFO (First In, First Out):

-   ✅ **TX FIFO**: Stores multiple bytes to send (buffer outgoing data)
-   ✅ **RX FIFO**: Stores multiple received bytes (buffer incoming data)
-   ✅ CPU can read/write in bursts (more efficient)
-   ✅ Reduces overrun errors dramatically
-   ✅ Better CPU performance (fewer interrupts)

**Typical FIFO depths**: 8, 16, 32, 64 bytes

**Rule of thumb**: Deeper FIFO = more tolerance for CPU being busy with other tasks!

---

## For Your TinyQV Project

### What You Need to Implement

1. **TX Module**

    - Shift register for serial output
    - Baud rate generator
    - State machine (IDLE → START → DATA → STOP)

2. **RX Module**

    - Oversampling (16×)
    - Bit detection and framing
    - State machine (IDLE → START → DATA → STOP)

3. **Register Interface**

    - Connect to TinyQV's 32-bit register bus
    - Implement DR, SR, CR, BRR registers

4. **FIFOs** (highly recommended)

    - At least 8-16 byte depth
    - Simplifies CPU interaction

5. **Interrupt Generation**
    - RX data ready
    - TX buffer empty
    - Error conditions

### Pin Mapping (from tt_wrapper.v)

```verilog
ui_in[7]         → UART RX input
uo_out[0]        → UART TX output
user_interrupt   → Interrupt to CPU (RX ready, etc.)
```

### Register Interface (from CPU)

```verilog
address          → Select which register
data_in          → Data to write
data_out         → Data to read
data_write_n     → Write enable (active low)
data_read_n      → Read enable (active low)
```

---

## Next Steps for Implementation

1. **Review block diagrams** (we'll create these next)
2. **Design register map** for your specific needs
3. **Implement TX path** first (simpler)
4. **Implement RX path** with oversampling
5. **Add FIFOs** for efficiency
6. **Test with cocotb** using known baud rates
7. **Verify timing** with waveforms

---

## 🚨 Common UART Mistakes (and How to Avoid Them)

### Mistake #1: Mismatched Baud Rates

**Problem**: Device A talks at 9600 bps, Device B listens at 115200 bps  
**Symptom**: Receiving complete garbage data or random characters  
**The Analogy**: Like one person speaking slowly while the other expects fast speech - complete confusion!

**Fix**:

```
✓ Always verify BOTH devices use the SAME baud rate
✓ Check datasheets for default baud rates
✓ Use a logic analyzer to measure actual baud rate
```

### Mistake #2: Swapped TX/RX Connections

**Problem**: Connected TX→TX and RX→RX instead of TX→RX crossover  
**Symptom**: No data received at all, complete silence  
**The Analogy**: Like two people both speaking into microphones with no ears - nobody listening!

**Fix**:

```
Device A TX ──────► Device B RX  ← Correct!
Device A RX ◄────── Device B TX  ← Correct!

Device A GND ──────── Device B GND  ← Always connect ground!
```

### Mistake #3: Forgetting Ground Connection

**Problem**: Only connected TX and RX, forgot common GND  
**Symptom**: Intermittent errors, data corruption, weird random glitches  
**The Analogy**: Like two phones with bad connection - static and dropouts!

**Fix**:

```
✓ ALWAYS connect GND between devices
✓ Ground is the voltage reference - without it, signals are meaningless!
```

### Mistake #4: Wrong Frame Configuration

**Problem**: One device uses 8N1, other uses 8E1 (different parity)  
**Symptom**: Frame errors, missing bytes, data corruption

**Fix**:

```
✓ Both devices must use SAME config: 8N1, 8E1, etc.
✓ 8N1 (8 data, No parity, 1 stop) is industry standard - use it!
```

### Mistake #5: Cable Too Long for Baud Rate

**Problem**: Using 20-meter cable at 115200 bps  
**Symptom**: Works sometimes, fails randomly, errors increase with distance  
**The Analogy**: Like shouting across a football field - works if close, fails if too far!

**Fix**:

```
Maximum Cable Length Guidelines:
- 115200 bps → 15 meters (50 feet) max
- 57600 bps  → 30 meters (100 feet) max
- 9600 bps   → 150 meters (500 feet) max

For longer distances, use RS-232 or RS-485 drivers!
```

### Mistake #6: Not Reading RX Fast Enough (Overrun Errors)

**Problem**: CPU too slow to read data, FIFO overflows  
**Symptom**: Missing bytes, overrun error flags set  
**The Analogy**: Like voicemail box getting full - new messages get rejected!

**Fix**:

```
✓ Use deeper FIFOs (16, 32, 64 bytes)
✓ Enable interrupts instead of polling
✓ Process data immediately when RX interrupt fires
✓ Use DMA for high-speed continuous data streams
```

### Mistake #7: Ignoring Voltage Level Compatibility

**Problem**: Connecting 5V UART to 3.3V UART directly  
**Symptom**: Damaged chips, erratic behavior, or device not working

**Fix**:

```
✓ Check voltage levels in datasheets
✓ Use level shifters for voltage mismatch (5V ↔ 3.3V)
✓ Many modern chips tolerate 5V on inputs, but check first!
```

### Mistake #8: Not Testing with Loopback First

**Problem**: Jumping straight to full system, can't tell which side is broken  
**Symptom**: Nothing works, hours of debugging, frustration!

**Fix**:

```
Loopback Test (connect TX to RX on SAME device):

Device TX ──┐
            ├── (Short wire or jumper)
Device RX ──┘

✓ Send "Hello" → Should receive "Hello"
✓ Tests TX, RX, and baud rate generation in one go
✓ If loopback fails, problem is YOUR device
✓ If loopback works, problem is cable or other device
```

---

## Key Takeaways (TL;DR - The Essentials)

### 🎯 Quick Summary

**What is UART?**

-   Simple serial communication protocol (one bit at a time)
-   Like a phone conversation: TX = mouth, RX = ear
-   Only 2 wires needed: TX and RX (plus ground)

**How fast?**

-   Baud rate = bits per second
-   Common: 9600 (slow/reliable) to 115200 (fast)
-   Both devices MUST use same speed!

**Data Format (8N1 - most common):**

```
IDLE → START(0) → 8 DATA BITS (LSB first) → STOP(1) → IDLE
```

**Where's it used?**

-   🛰️ GPS modules
-   🎧 Bluetooth chips
-   🤖 Arduino Serial Monitor
-   💳 Card readers
-   🏭 Industrial sensors

**Common Problems:**

1. **Garbage data** → Check baud rate matches on both sides!
2. **Missing data** → Add FIFO buffers
3. **Wrong connections** → TX connects to RX (crossover!)

### 📋 Implementation Checklist

✅ Baud rate generator (clock divider)  
✅ TX state machine (IDLE → START → DATA → STOP)  
✅ RX with 16x oversampling (noise immunity)  
✅ Register interface (CTRL, STATUS, TX_DATA, RX_DATA)  
✅ FIFO buffers (highly recommended!)  
✅ Interrupt generation (RX data ready)  
✅ Error detection (framing, overrun)

### 🎓 Remember These Rules!

1. **TX of Device A connects to RX of Device B** (and vice versa)
2. **Both devices must use SAME baud rate** (most common mistake!)
3. **Both devices must use SAME config** (8N1 is standard)
4. **LSB is transmitted first** (historical design choice)
5. **IDLE state is HIGH** (1), START bit is LOW (0)
6. **FIFO buffers prevent data loss** when CPU is busy
7. **Keep cables short at high speeds** (< 15m recommended)

### 🔗 Real-World Connection Example

```
Arduino ←→ GPS Module

Arduino Side:        GPS Module Side:
  TX (Pin 1) ─────────→ RX
  RX (Pin 0) ←───────── TX
  GND ────────────────── GND

Configuration on BOTH devices:
  Baud Rate: 9600
  Format: 8N1 (8 data, no parity, 1 stop)
  Voltage: 3.3V or 5V (check compatibility!)
```

### 🚀 Next Steps

1. ✅ Review fundamentals (you just did!)
2. 📋 Read [PROJECT_PLAN.md](PROJECT_PLAN.md) for implementation roadmap
3. 📊 Study [BLOCK_DIAGRAMS.md](BLOCK_DIAGRAMS.md) for architecture details
4. 💻 Start coding the baud rate generator (Phase 2)
5. 🧪 Test each module with cocotb testbenches
6. 🎯 Run synthesis and optimize for PPA

---

---

## Advanced Features: FIFOs and Flow Control

The basic UART we've discussed works, but has limitations in real-world applications. Let's explore two critical enhancements that make UART production-ready.

---

## FIFO Buffers: Preventing Data Loss

### The Problem: Why We Need FIFOs

**The Restaurant Kitchen Analogy:**

Imagine a restaurant without a prep area:

-   **Without FIFO**: Chef must cook each order immediately when waiter arrives

    -   If chef is busy → order gets lost!
    -   Waiter must wait → inefficient!
    -   Kitchen backs up during rush hour

-   **With FIFO**: Orders go to a ticket queue (prep station)
    -   Chef cooks in order (First In, First Out)
    -   Waiter can leave immediately
    -   Kitchen runs smoothly even when busy

**In UART terms:**

**TX Without FIFO:**

```
CPU: "Send this byte!"
UART TX: "Sorry, I'm still transmitting the previous byte!"
CPU: *waits... wasting cycles*
```

**TX With FIFO:**

```
CPU: "Send these 16 bytes!"
UART TX FIFO: "Got them! You can do other work now."
UART TX: *transmits bytes one by one from FIFO*
CPU: *free to do other important work*
```

**RX Without FIFO:**

```
UART RX: "New byte received!"
CPU: *busy with other task, can't read immediately*
UART RX: "Another byte coming! Overwriting previous one!"
Result: DATA LOST! ❌
```

**RX With FIFO:**

```
UART RX: "Byte 1 stored in FIFO"
UART RX: "Byte 2 stored in FIFO"
UART RX: "Byte 3 stored in FIFO"
CPU: *finishes task, reads all 3 bytes from FIFO*
Result: All data preserved! ✅
```

### FIFO Fundamentals

**FIFO** = First In, First Out (like a queue/line at a store)

**Key Concepts:**

1. **Depth**: How many bytes the FIFO can hold

    - Common depths: 4, 8, 16, 32, 64 bytes
    - Example: 16-byte FIFO = can store 16 bytes before overflowing
    - **Trade-off**: Deeper FIFO = more chip area but better buffering

2. **Write Pointer**: Points to where next byte will be written
3. **Read Pointer**: Points to where next byte will be read from
4. **Full Flag**: Signals when FIFO cannot accept more data
5. **Empty Flag**: Signals when FIFO has no data to read
6. **Count**: Number of bytes currently in FIFO

### FIFO Operation Example

```
Initial State (Empty FIFO, depth=8):
[_][_][_][_][_][_][_][_]
 ↑
 WR/RD (both at position 0)
 Empty=1, Full=0, Count=0

After writing 'A', 'B', 'C':
[A][B][C][_][_][_][_][_]
 ↑      ↑
 RD     WR
 Empty=0, Full=0, Count=3

Read one byte ('A'):
[_][B][C][_][_][_][_][_]
    ↑  ↑
    RD WR
 Empty=0, Full=0, Count=2

Write 'D', 'E', 'F', 'G', 'H', 'I':
[_][B][C][D][E][F][G][H]
    ↑                  ↑
    RD                 WR
 Empty=0, Full=0, Count=7

Write 'J' (wraps around):
[J][B][C][D][E][F][G][H]
 ↑  ↑
 WR RD
 Empty=0, Full=1, Count=8  ← FIFO FULL!

Attempt to write 'K':
REJECTED! Full flag prevents data loss.
```

### FIFO Watermarks (Thresholds)

**Think of watermarks like fuel gauge indicators:**

-   🔴 **Full**: Tank at maximum (stop pumping!)
-   🟡 **High-Water Mark**: Tank 75% full (slow down!)
-   🟢 **Half**: Tank 50% (normal operation)
-   🟡 **Low-Water Mark**: Tank 25% (time to refuel soon)
-   🔴 **Empty**: Tank empty (urgent!)

**In FIFO terms:**

**TX FIFO Watermarks:**

```
Depth = 16 bytes

[16] ━━━━━━━━━━━━━━━━ FULL (trigger: FIFO_FULL interrupt)
[15]
[14]
[13]
[12] ━━━━━━━━━━━━━━━━ HIGH (trigger: ALMOST_FULL, slow down CPU writes)
[11]
[10]
[09]
[08]
[07]
[06]
[05]
[04] ━━━━━━━━━━━━━━━━ LOW (trigger: ALMOST_EMPTY, CPU should write more)
[03]
[02]
[01]
[00] ━━━━━━━━━━━━━━━━ EMPTY (trigger: FIFO_EMPTY interrupt)
```

**Why Watermarks Matter:**

1. **TX FIFO Low Watermark** (e.g., 4 bytes left):

    - Interrupt CPU: "Please send more data soon!"
    - Prevents TX underrun (UART idle because FIFO is empty)

2. **RX FIFO High Watermark** (e.g., 12 bytes filled):

    - Interrupt CPU: "Please read data soon!"
    - Prevents RX overrun (data lost because FIFO overflows)

3. **Efficient Bulk Transfers**:
    - CPU can wait until LOW watermark → then write 8-12 bytes at once
    - Reduces interrupt overhead (fewer interrupts = less CPU time wasted)

### FIFO Registers & Status

**Typical FIFO Control Registers:**

```
TX_FIFO_CTRL (0x14):
  [7:4] TX_THRESHOLD - Watermark level (0-15)
  [3]   TX_FIFO_RESET - Write 1 to clear FIFO
  [2]   TX_FIFO_INT_EN - Enable TX FIFO interrupt
  [1:0] Reserved

TX_FIFO_STATUS (0x18):
  [7:4] TX_FIFO_COUNT - Number of bytes in FIFO (0-16)
  [3]   TX_FIFO_FULL
  [2]   TX_FIFO_ALMOST_FULL (count > threshold)
  [1]   TX_FIFO_ALMOST_EMPTY (count < threshold)
  [0]   TX_FIFO_EMPTY

RX_FIFO_CTRL (0x1C):
  [7:4] RX_THRESHOLD
  [3]   RX_FIFO_RESET
  [2]   RX_FIFO_INT_EN
  [1:0] Reserved

RX_FIFO_STATUS (0x20):
  [7:4] RX_FIFO_COUNT
  [3]   RX_FIFO_FULL
  [2]   RX_FIFO_ALMOST_FULL
  [1]   RX_FIFO_ALMOST_EMPTY
  [0]   RX_FIFO_EMPTY
```

### FIFO Benefits

✅ **CPU Efficiency**: Write/read multiple bytes in bursts  
✅ **Data Integrity**: No data loss during CPU busy periods  
✅ **Reduced Interrupts**: Process data in batches  
✅ **Higher Throughput**: Continuous transmission without gaps  
✅ **Tolerance to Jitter**: Absorbs timing variations

### FIFO Design Considerations

**Depth Selection:**

```
Small FIFO (4 bytes):
  + Less chip area
  + Lower cost
  - Less buffering
  - More frequent interrupts
  Use when: Simple, low-speed applications

Medium FIFO (16 bytes):
  + Good balance
  + Standard in industry (16550A UART)
  - Moderate area cost
  Use when: General purpose applications ← RECOMMENDED

Large FIFO (64+ bytes):
  + Maximum buffering
  + Handles burst traffic
  - Significant chip area
  - Higher power consumption
  Use when: High-speed bulk data transfers
```

**Implementation Cost (Rough Estimates):**

-   4-byte FIFO: ~150-200 cells
-   8-byte FIFO: ~250-350 cells
-   16-byte FIFO: ~400-600 cells
-   32-byte FIFO: ~750-1000 cells

**Our Choice:** 16-byte TX and RX FIFOs (industry standard, good balance)

---

## Hardware Flow Control: Preventing Overruns

### The Problem: When Receiver Can't Keep Up

**The Package Delivery Analogy:**

**Without Flow Control:**

```
Sender: "Here's package 1!" *throws*
Sender: "Here's package 2!" *throws*
Sender: "Here's package 3!" *throws*
Receiver: "Wait! My hands are full! I can't catch... *DROP* ❌"
Result: Packages on the ground (data lost)
```

**With Flow Control (RTS/CTS):**

```
Receiver: "I'm Ready To receive (RTS low)"
Sender: "Clear To Send (CTS low), sending now!"
Sender: "Package 1" ✅
Sender: "Package 2" ✅
Receiver: "Hands full! NOT ready (RTS high)"
Sender: "Okay, pausing..." *waits*
Receiver: *processes packages*
Receiver: "Ready again! (RTS low)"
Sender: "Package 3" ✅
Result: All packages received safely!
```

### RTS/CTS Signals Explained

**RTS** = Request To Send (actually means "Ready To Receive"!)

-   **Driven by**: Receiver
-   **Purpose**: Tells sender if receiver is ready for data
-   **Active LOW**: RTS=0 means "I'm ready, send data"
-   **Active HIGH**: RTS=1 means "I'm busy, don't send!"

**CTS** = Clear To Send

-   **Driven by**: Sender (or remote device's RTS in typical wiring)
-   **Purpose**: Tells receiver if sender is ready to receive
-   **Active LOW**: CTS=0 means "You can send data"
-   **Active HIGH**: CTS=1 means "Don't send, I'm not ready"

**Typical Wiring (Full-Duplex with Flow Control):**

```
Device A                    Device B
────────                    ────────
TX ──────────────────────→ RX
RX ←────────────────────── TX
RTS ─────────────────────→ CTS  (A's RTS → B's CTS)
CTS ←──────────────────── RTS  (B's RTS → A's CTS)
GND ─────────────────────── GND

Device A wants to send:
  1. Check CTS (connected to B's RTS)
  2. If CTS=0 (B is ready) → Send data
  3. If CTS=1 (B is busy) → Wait

Device B controls flow:
  1. If FIFO almost full → Set RTS=1 ("STOP!")
  2. If FIFO has space → Set RTS=0 ("GO!")
```

### Flow Control FSM

**Transmitter with Flow Control:**

```
IDLE state:
  if (data_to_send && !cts)  // CTS low = ready
    → START state
  else if (cts)  // CTS high = not ready
    → Stay in IDLE (wait)

START state:
  Send START bit
  → DATA state

DATA state:
  Send data bits
  if (cts goes high during transmission):
    ⚠️ Complete current byte (don't stop mid-byte!)
    → After STOP bit, check CTS before next byte

STOP state:
  Send STOP bit
  Check CTS:
    if (!cts && more_data) → START (send next byte)
    if (cts) → IDLE (pause transmission)
```

**Receiver Flow Control Logic:**

```
RX FIFO Monitor:
  if (rx_fifo_count >= HIGH_WATERMARK)
    rts <= 1'b1;  // Signal: "STOP sending!"
  else if (rx_fifo_count <= LOW_WATERMARK)
    rts <= 1'b0;  // Signal: "OK to send again"
```

### Flow Control Timing Diagram

```
Sender                         Receiver

TX: ─┐    ┌───┐   ┌───┬─...    ┌──── (Data bits)
      └────┘   └───┘   └────────┘
     IDLE START DATA...         IDLE

CTS: ──────────────────┐    ┌─────── (Receiver's RTS → Sender's CTS)
                       └────┘
                       BUSY  READY
                       (pause)

Time: ──→──→──→──→──→──→──→──→──→──→
      Byte1 Byte2 PAUSE  Resume Byte3

What happened:
  t1: Byte 1 transmitted
  t2: Byte 2 transmitted
  t3: Receiver FIFO almost full → RTS goes high
  t4: Sender sees CTS high → stops after current byte
  t5: Receiver processes data → FIFO has space → RTS goes low
  t6: Sender sees CTS low → resumes with Byte 3
```

### When to Use Flow Control

**✅ Use Flow Control When:**

1. High-speed data transfer (38400 bps and above)
2. Receiver might be slower than sender (CPU interrupt latency)
3. Large bursts of data (file transfers)
4. RX FIFO can fill up faster than CPU reads
5. Real-time systems where data loss is unacceptable

**❌ Flow Control Not Needed When:**

1. Low-speed communication (9600 bps)
2. Small, infrequent messages
3. Guaranteed CPU response time (hard real-time)
4. One-way communication (TX only or RX only)
5. Software flow control used instead (XON/XOFF)

### Flow Control Modes

**1. Hardware Flow Control (RTS/CTS):**

-   ✅ Fast response (no software delay)
-   ✅ Reliable (dedicated signals)
-   ❌ Requires extra pins (2 more wires)
-   **Use when**: Pins available, high-speed needed

**2. Software Flow Control (XON/XOFF):**

-   ✅ No extra pins needed
-   ❌ Slower (in-band signaling)
-   ❌ Can fail if control characters corrupted
-   Sends special characters: XON (0x11) = "resume", XOFF (0x13) = "pause"
-   **Use when**: Pins limited, speed not critical

**3. No Flow Control:**

-   ✅ Simplest implementation
-   ❌ Risk of data loss
-   **Use when**: FIFO large enough, CPU fast enough, or data loss acceptable

### Our Implementation

**For this project, we're implementing:**

-   ✅ 16-byte TX FIFO
-   ✅ 16-byte RX FIFO
-   ✅ Hardware flow control (RTS/CTS)
-   ✅ FIFO watermark interrupts
-   ✅ Configurable thresholds

**Why?**

-   Demonstrates production-quality design
-   Prevents data loss at all baud rates
-   Efficient CPU usage (batch processing)
-   Industry-standard features (16550A compatible)

---

## FIFO + Flow Control: Complete Example

### Scenario: Receiving a 32-byte Packet

**Setup:**

-   RX FIFO: 16 bytes deep
-   High watermark: 12 bytes
-   Low watermark: 4 bytes
-   Baud rate: 115200 bps (~87 μs per byte)
-   CPU interrupt latency: ~500 μs (busy with other tasks)

**Timeline:**

```
t=0ms: Packet starts arriving
  RX FIFO: [_][_][_][_][_][_][_][_][_][_][_][_][_][_][_][_]
  RTS: LOW (ready)

t=1ms: 11 bytes received (87μs × 11 ≈ 957μs)
  RX FIFO: [01][02][03][04][05][06][07][08][09][10][11][_][_][_][_][_]
  RTS: LOW (still space)
  Count: 11

t=1.1ms: 12th byte received
  RX FIFO: [01][02][03][04][05][06][07][08][09][10][11][12][_][_][_][_]
  RTS: HIGH ← Watermark exceeded! Signal sender to pause!
  Count: 12
  Interrupt: RX_FIFO_ALMOST_FULL → CPU notified

t=1.2ms: Sender sees RTS high (via its CTS pin)
  Sender: "Pausing after current byte completes..."

t=1.7ms: CPU responds to interrupt (500μs latency)
  CPU reads 8 bytes from FIFO in burst
  RX FIFO: [09][10][11][12][_][_][_][_][_][_][_][_][_][_][_][_]
  Count: 4 ← Below low watermark!
  RTS: LOW ← Signal sender: "Resume!"

t=1.8ms: Sender sees RTS low again
  Sender: "Resuming transmission..."
  Remaining 20 bytes start arriving

t=3.5ms: All 32 bytes received successfully!
  Result: ✅ NO DATA LOST despite CPU being slower than data rate!
```

**Without FIFO or Flow Control:**

```
t=1ms: 11 bytes received
  Single-byte register holds only latest byte: [11]
  Bytes 01-10: LOST! ❌

Result: Only last byte preserved, 30 bytes lost!
```

---

## Implementation Checklist (Updated)

### Basic UART (Phase 1 - Completed)

✅ Baud rate generator  
✅ UART TX (basic)  
✅ UART RX (basic)  
✅ Register interface  
✅ Interrupt generation

---

## Part 4: FIFO Buffers (Enhanced UART)

### Why FIFOs Matter

**Problem with Basic UART:**
The basic UART has single-byte TX/RX registers. If the CPU can't service interrupts immediately, data is lost.

**Real-World Scenario:**

```
UART receives bytes at 115200 bps = 1 byte every 86.8 µs
CPU interrupt latency = 200 µs (context switch, handler overhead)

Timeline:
t=0:     Byte 1 received → RX register = 0x41
t=87µs:  Byte 2 received → RX register = 0x42  (Byte 1 OVERWRITTEN!)
t=174µs: Byte 3 received → RX register = 0x43  (Byte 2 OVERWRITTEN!)
t=200µs: CPU reads RX register → Gets 0x43 only

Result: 2 out of 3 bytes LOST! ❌
```

**Solution: FIFO Buffers**

```
UART receives bytes → Stored in 16-byte FIFO
CPU reads when ready → Multiple bytes preserved

Timeline with FIFO:
t=0:     Byte 1 → FIFO[0] = 0x41
t=87µs:  Byte 2 → FIFO[1] = 0x42
t=174µs: Byte 3 → FIFO[2] = 0x43
t=200µs: CPU reads → Gets all 3 bytes!

Result: Zero data loss! ✅
```

### FIFO Fundamentals

**FIFO = First In, First Out**
Think of it like a pipe: First byte in is first byte out.

```
Visual Analogy:
    Marbles entering pipe       Marbles exiting pipe
         ↓                            ↓
    ┌────────────────────────────────────┐
    │  🔴 → 🔵 → 🟢 → 🟡 → ⚪ → 🟣  →  │
    └────────────────────────────────────┘
    Write pointer              Read pointer
         ↑                            ↑
    New data enters here      Old data exits here
```

**FIFO Operations:**

1. **Write (Push)**: Add byte to tail of FIFO
2. **Read (Pop)**: Remove byte from head of FIFO
3. **Full**: Cannot write more (all slots occupied)
4. **Empty**: Cannot read more (no data available)

### TX FIFO Architecture

```
CPU Interface:
    write_data[7:0] ─►┌────────────────────────────┐
    write_enable ─────►│                            │
                       │      TX FIFO Buffer        │◄─── read_enable (from UART TX)
                       │      (16 × 8-bit RAM)      │
                       │                            │──►  read_data[7:0] (to UART TX)
                       │  ┌──┬──┬──┬──┬──┬──┬──┐  │
                       │  │D0│D1│D2│D3│D4│D5│..│  │
                       │  └──┴──┴──┴──┴──┴──┴──┘  │
                       │   ▲                    ▲   │
                       │   │                    │   │
                       │  WR_PTR              RD_PTR│
    full ◄─────────────│                            │
    empty ◄────────────│                            │
    count[4:0] ◄───────│  (Number of bytes in FIFO)│
                       └────────────────────────────┘

Pointers:
- WR_PTR: Points to next write location (0-15)
- RD_PTR: Points to next read location (0-15)
- Both wrap around: After 15, goes back to 0

States:
- Empty: WR_PTR == RD_PTR && count == 0
- Full:  count == 16
- Count: (WR_PTR - RD_PTR) mod 16
```

**TX FIFO Operation Example:**

```
Initial State (Empty):
┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
│  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │
└──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘
 ▲
 │
WR_PTR = 0, RD_PTR = 0, count = 0, empty = 1

CPU writes 0x41:
┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
│41│  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │
└──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘
 ▲  ▲
 │  │
 │  WR_PTR = 1
 RD_PTR = 0, count = 1, empty = 0

CPU writes 0x42, 0x43:
┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
│41│42│43│  │  │  │  │  │  │  │  │  │  │  │  │  │
└──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘
 ▲     ▲
 │     │
 │     WR_PTR = 3
 RD_PTR = 0, count = 3

UART TX reads byte (transmitting 0x41):
┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
│  │42│43│  │  │  │  │  │  │  │  │  │  │  │  │  │
└──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘
    ▲  ▲
    │  │
    │  WR_PTR = 3
    RD_PTR = 1, count = 2

UART TX reads byte (transmitting 0x42):
┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
│  │  │43│  │  │  │  │  │  │  │  │  │  │  │  │  │
└──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘
       ▲  ▲
       │  │
       │  WR_PTR = 3
       RD_PTR = 2, count = 1
```

### RX FIFO Architecture

**Same structure as TX FIFO, but data flows opposite direction:**

```
UART RX Interface:
                       ┌────────────────────────────┐
    write_data[7:0] ──►│                            │
    write_enable ──────►│      RX FIFO Buffer        │◄─── read_enable (from CPU)
    (from UART RX)      │      (16 × 8-bit RAM)      │
                       │                            │──►  read_data[7:0] (to CPU)
                       │  ┌──┬──┬──┬──┬──┬──┬──┐  │
                       │  │D0│D1│D2│D3│D4│D5│..│  │
                       │  └──┴──┴──┴──┴──┴──┴──┘  │
                       │   ▲                    ▲   │
                       │   │                    │   │
                       │  WR_PTR              RD_PTR│
    full ◄─────────────│                            │
    empty ◄────────────│                            │
    count[4:0] ◄───────│                            │
                       └────────────────────────────┘

Write side: UART RX pushes received bytes
Read side: CPU pops bytes when ready
```

### FIFO Watermarks & Thresholds

**Watermark = Trigger level for interrupts/status**

```
16-byte FIFO with watermarks:

RX FIFO (filling up):
┌──────────────────────────────────────┐ ← 16 (Full)
│  │  │  │  │  │  │  │  │  │  │  │  │││ ← Almost Full Watermark (14)
│41│42│43│44│45│46│47│48│49│50│51│52│││
│  │  │  │  │  │  │  │  │  │  │  │  │││
│  │  │  │  │  │  │  │  │  │  │  │  │││ ← Half Full (8)
│  │  │  │  │  │  │  │  │  │  │  │  │││
│  │  │  │  │  │  │  │  │  │  │  │  │││
│  │  │  │  │  │  │  │  │  │  │  │  │││ ← Low Watermark (4)
└──────────────────────────────────────┘ ← 0 (Empty)

Interrupt Strategy:
- RX_READY interrupt when count >= 8 (half full)
- RX_ALMOST_FULL warning when count >= 14
- RX_OVERFLOW error when write to full FIFO

TX FIFO (draining):
- TX_EMPTY interrupt when count == 0
- TX_LOW warning when count <= 4 (ready for more data)
```

**Configurble Watermarks:**

```verilog
// Register: FIFO_CTRL
[7:4] RX_WATERMARK  (interrupt triggers when RX count >= watermark)
[3:0] TX_WATERMARK  (interrupt triggers when TX count <= watermark)

Example:
RX_WATERMARK = 8  → Interrupt when 8+ bytes received
TX_WATERMARK = 4  → Interrupt when 4 or fewer bytes in TX FIFO
```

### FIFO Overflow & Underflow Protection

**Overflow (Writing to Full FIFO):**

```
TX FIFO Full (count = 16):
┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
│41│42│43│44│45│46│47│48│49│50│51│52│53│54│55│56│  (All slots occupied)
└──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘

CPU attempts write:
write_enable = 1, write_data = 0x57

Options:
1. Drop new byte (preserve old data) ← Common choice
2. Overwrite oldest byte (circular buffer)
3. Assert error flag: TX_OVERFLOW = 1

Our Implementation: Drop + Set error flag
```

**Underflow (Reading from Empty FIFO):**

```
RX FIFO Empty (count = 0):
┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
│  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  (No data)
└──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘

CPU attempts read:
read_enable = 1

Options:
1. Return last valid data (stale)
2. Return 0x00 or 0xFF (magic value)
3. Assert error flag: RX_UNDERFLOW = 1

Our Implementation: Return 0x00 + Set error flag
```

---

## Part 5: Hardware Flow Control (RTS/CTS)

### The Flow Control Problem

**Scenario: Fast Sender, Slow Receiver**

```
Sender transmits at 115200 bps = 11520 bytes/sec
Receiver processes at 5000 bytes/sec (CPU busy with other tasks)

Without Flow Control:
t=0:     Receiver FIFO empty [0/16]
t=1ms:   11 bytes received → FIFO [11/16]
t=2ms:   11 more bytes → FIFO [16/16] FULL!
t=3ms:   Sender keeps transmitting → OVERFLOW! ❌
         Bytes lost, data corruption

Result: Data loss inevitable without sender knowing receiver status
```

**Solution: Hardware Flow Control**

```
Receiver signals: "I'm busy, please wait!"
Sender obeys: Pauses transmission until receiver ready

With Flow Control:
t=0:     Receiver FIFO [0/16], RTS=0 (ready)
t=1ms:   FIFO [11/16], RTS=0 (still room)
t=2ms:   FIFO [14/16], RTS=1 (almost full, STOP!)
         Sender sees CTS=1 → Pauses transmission
t=3ms:   CPU reads 10 bytes → FIFO [4/16]
t=3ms:   FIFO below threshold → RTS=0 (ready again)
         Sender sees CTS=0 → Resumes transmission

Result: Zero data loss! ✅
```

### RTS/CTS Handshaking Protocol

**Signal Definitions:**

-   **RTS (Request To Send)**: Output from our device
    -   RTS=0: "I'm ready to receive data"
    -   RTS=1: "I'm busy, don't send data"
-   **CTS (Clear To Send)**: Input to our device
    -   CTS=0: "Remote device ready, you can transmit"
    -   CTS=1: "Remote device busy, don't transmit"

**Note on Naming Confusion:**
The naming is historical and confusing:

-   **RTS** actually means "I'm NOT ready" when HIGH (opposite of name!)
-   **CTS** actually means "Remote is NOT ready" when HIGH

**Think of it as:**

-   RTS = "**R**eceiver **T**oo **S**low" flag
-   CTS = "**C**an't **T**ransmit **S**ignal"

### RTS Logic (Receiver Side)

```
RX FIFO Control:

┌─────────────────────────────────────┐
│         RX FIFO Monitor             │
│                                     │
│  if (rx_fifo_count >= threshold):  │
│      RTS = 1  (stop sending!)       │
│  else:                              │
│      RTS = 0  (ready for data)      │
│                                     │
└──────────────┬──────────────────────┘
               │
               ▼
        ┌─────────────┐
        │ RTS Output  │────► To remote TX device
        │  (GPIO pin) │
        └─────────────┘

Threshold Configuration:
- Conservative: threshold = 12 (activate RTS early)
- Balanced:     threshold = 14 (standard)
- Aggressive:   threshold = 15 (risky, little margin)

Example:
RX_FIFO_THRESHOLD = 14

State transitions:
count = 13 → RTS = 0 (ready)
count = 14 → RTS = 1 (stop!)  ← Assert RTS
count = 13 → RTS = 0 (ready)  ← Deassert RTS
```

### CTS Logic (Transmitter Side)

```
TX State Machine with CTS:

┌─────────────────────────────────────────┐
│          UART TX FSM                    │
│                                         │
│  IDLE:                                  │
│    if (tx_fifo_not_empty && CTS == 0): │
│        → Start transmission             │
│    else:                                │
│        → Wait                           │
│                                         │
│  TRANSMITTING:                          │
│    if (CTS == 1):                       │
│        → Pause after current byte       │
│    else:                                │
│        → Continue normally              │
│                                         │
└──────────────┬──────────────────────────┘
               ▲
               │
        ┌─────────────┐
        │ CTS Input   │◄──── From remote RX device
        │  (GPIO pin) │
        └─────────────┘

CTS Behavior:
- CTS LOW (0):  Transmit normally
- CTS HIGH (1): Hold off, wait for LOW
- CTS can change mid-byte: Finish current byte, then pause
```

### Complete Handshake Example

```
Device A (our UART) ←→ Device B (remote device)

Device A Configuration:
- TX: Checks CTS before transmitting
- RX: Asserts RTS when FIFO nearly full
- Pins: TX (out), RX (in), RTS (out), CTS (in)

Device B Configuration:
- TX: Checks CTS (connected to our RTS)
- RX: Asserts RTS (connected to our CTS)
- Pins: TX (out), RX (in), RTS (out), CTS (in)

Wiring:
Device A              Device B
TX ──────────────────► RX
RX ◄────────────────── TX
RTS ─────────────────► CTS  (A's RTS tells B when A is busy)
CTS ◄───────────────── RTS  (B's RTS tells A when B is busy)

Scenario:
t=0:   Both devices ready
       A: RTS=0, CTS=0
       B: RTS=0, CTS=0

t=1:   A transmits to B (B's RX FIFO filling)
       A: TX active, monitoring CTS=0
       B: RX receiving, RTS=0

t=2:   B's RX FIFO almost full (14/16)
       B: Asserts RTS=1
       A: Sees CTS=1 → Pauses TX

t=3:   B's CPU reads FIFO → (6/16)
       B: Deasserts RTS=0
       A: Sees CTS=0 → Resumes TX

t=4:   A's RX FIFO almost full (14/16)
       A: Asserts RTS=1
       B: Sees CTS=1 → Pauses TX

t=5:   A's CPU reads FIFO → (5/16)
       A: Deasserts RTS=0
       B: Sees CTS=0 → Resumes TX
```

### Timing Diagrams: Flow Control

```
Scenario: Receiver FIFO fills up, uses RTS to pause sender

Clock Cycles:  0    10   20   30   40   50   60   70   80
              ─┴────┴────┴────┴────┴────┴────┴────┴────┴────

RX_FIFO_COUNT ══════5════10═══14═══14═══14═══8════5════3════
                    │         │              │
                    │         │              │
RTS (output)  ─────────────────┐        ┌────────────────────
                                └────────┘
                              (FIFO >= 14)

CTS (at sender)    Same as RTS (wired)
                              ┌────────┐
              ─────────────────┘        └────────────────────

TX_ACTIVE     ────┐                ┌────────────┐
  (at sender)     └────────────────┘            └────────────
                  (Transmitting)  (Paused)    (Resumed)

Explanation:
- Cycle 0-20:  Normal transmission, FIFO filling
- Cycle 30:    FIFO reaches threshold (14), RTS asserts
- Cycle 30-40: Sender sees CTS, pauses after current byte
- Cycle 50:    CPU reads FIFO, count drops to 8
- Cycle 50:    RTS deasserts, sender resumes
```

### Flow Control Configuration Registers

```
Register: FLOW_CTRL (0x2C)
┌───┬───┬───┬───┬───┬───┬───┬───┐
│ 7 │ 6 │ 5 │ 4 │ 3 │ 2 │ 1 │ 0 │
└───┴───┴───┴───┴───┴───┴───┴───┘
  │   │   │   │   └───┴───┴───┴───► RX_RTS_THRESHOLD[3:0]
  │   │   │   └───────────────────► TX_CTS_ENABLE (1=check CTS)
  │   │   └───────────────────────► RX_RTS_ENABLE (1=auto RTS)
  │   └───────────────────────────► Reserved
  └───────────────────────────────► Reserved

RX_RTS_THRESHOLD: FIFO count to assert RTS (default: 14)
TX_CTS_ENABLE:    Enable CTS checking (default: 1)
RX_RTS_ENABLE:    Enable automatic RTS assertion (default: 1)

Register: STATUS (0x04) - Updated bits
┌───┬───┬───┬───┬───┬───┬───┬───┐
│ 7 │ 6 │ 5 │ 4 │ 3 │ 2 │ 1 │ 0 │
└───┴───┴───┴───┴───┴───┴───┴───┘
  │   │   │   │   │   │   │   └───► TX_BUSY
  │   │   │   │   │   │   └───────► RX_READY
  │   │   │   │   │   └───────────► RX_ERROR
  │   │   │   │   └───────────────► RTS_STATUS (current RTS output)
  │   │   │   └───────────────────► CTS_STATUS (current CTS input)
  │   │   └───────────────────────► TX_FIFO_EMPTY
  │   └───────────────────────────► RX_FIFO_FULL
  └───────────────────────────────► Reserved
```

### Advanced: Adaptive Threshold

**Problem:** Fixed threshold might be too conservative or aggressive

**Solution:** Dynamic threshold based on CPU responsiveness

```
Monitor RX interrupt latency:
- Fast CPU (latency < 100µs):  threshold = 15 (aggressive)
- Normal CPU (latency < 500µs): threshold = 12 (balanced)
- Slow CPU (latency > 500µs):   threshold = 8  (conservative)

Pseudocode:
if (rx_interrupt_response_time < 100us):
    rx_rts_threshold = 15
elif (rx_interrupt_response_time < 500us):
    rx_rts_threshold = 12
else:
    rx_rts_threshold = 8
```

---

## FIFO + Flow Control: Complete System

### Enhanced UART Block Diagram

```
                    Secure UART with FIFOs & Flow Control
┌───────────────────────────────────────────────────────────────────────┐
│                                                                       │
│  CPU Interface                                                        │
│  ┌────────────┐                                                       │
│  │  Register  │                                                       │
│  │ Interface  │                                                       │
│  └──────┬─────┘                                                       │
│         │                                                             │
│         ├──────────┬──────────┬──────────┬──────────┐                │
│         │          │          │          │          │                │
│         ▼          ▼          ▼          ▼          ▼                │
│  ┌──────────┬──────────┬──────────┬──────────┬──────────┐           │
│  │ TX_DATA  │ RX_DATA  │  STATUS  │FIFO_CTRL │FLOW_CTRL │           │
│  └────┬─────┴────┬─────┴──────────┴──────────┴──────────┘           │
│       │          │                                                    │
│       ▼          ▼                                                    │
│  ┌─────────┐ ┌─────────┐                                            │
│  │ TX FIFO │ │ RX FIFO │                                            │
│  │ 16 bytes│ │ 16 bytes│                                            │
│  │         │ │         │                                            │
│  │  count  │ │  count  │──────┐                                     │
│  │threshold│ │threshold│      │                                     │
│  └────┬────┘ └────┬────┘      │                                     │
│       │           │            ▼                                     │
│       │           │      ┌──────────┐                                │
│       │           │      │   RTS    │                                │
│       │           │      │ Generator│───► RTS (output)               │
│       │           │      └──────────┘                                │
│       ▼           ▼                                                   │
│  ┌─────────┐ ┌─────────┐                                            │
│  │ UART TX │ │ UART RX │                                            │
│  │  FSM    │ │  FSM    │                                            │
│  └────┬────┘ └────┬────┘                                            │
│       │           │                                                   │
│       │◄──────────┼──── CTS (input)                                 │
│       │           │                                                   │
│       ▼           ▼                                                   │
│     TX pin      RX pin                                                │
│       │           │                                                   │
└───────┼───────────┼───────────────────────────────────────────────────┘
        │           │
        ▼           ▼
    Serial Line (with flow control)
```

### Performance Comparison

**Without FIFOs or Flow Control:**

```
- Max burst: 1 byte (single register)
- CPU must respond within: 86.8 µs @ 115200 bps
- Data loss probability: HIGH (any delay = lost data)
- Suitable for: Slow, simple applications
```

**With FIFOs Only:**

```
- Max burst: 16 bytes (FIFO depth)
- CPU must respond within: 1.39 ms @ 115200 bps
- Data loss probability: MEDIUM (still possible if burst > 16)
- Suitable for: Most embedded applications
```

**With FIFOs + Flow Control:**

```
- Max burst: Unlimited (sender pauses when needed)
- CPU response time: Flexible (seconds if needed)
- Data loss probability: ZERO (hardware guarantees)
- Suitable for: Professional, production systems
```

### Enhanced UART (Phase 2 - Next Steps)

📋 TX FIFO (16 bytes) ← Section complete ✅  
📋 RX FIFO (16 bytes) ← Section complete ✅  
📋 FIFO watermark detection ← Section complete ✅  
📋 RTS output (receiver flow control) ← Section complete ✅  
📋 CTS input (transmitter flow control) ← Section complete ✅  
📋 Updated status registers ← Section complete ✅  
📋 FIFO control registers ← Section complete ✅  
📋 Enhanced testing (FIFO overflow, flow control)

---

**You're now ready to implement a production-grade UART peripheral!** 🎉

The combination of FIFOs and flow control transforms a basic UART into a robust, efficient communication interface suitable for real-world applications. These features are found in every professional UART implementation, from embedded systems to industrial equipment.

Good luck with your implementation!
