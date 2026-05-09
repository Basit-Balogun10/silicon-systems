# Software Driver Guide - Secure UART

Quick reference for writing software drivers for the Secure UART peripheral.

## Register Definitions

```c
// Base address
#define SECURE_UART_BASE  0x80000000

// Register offsets
#define UART_CTRL    (*(volatile uint32_t*)(SECURE_UART_BASE + 0x00))
#define UART_STATUS  (*(volatile uint32_t*)(SECURE_UART_BASE + 0x04))
#define TX_DATA      (*(volatile uint32_t*)(SECURE_UART_BASE + 0x08))
#define RX_DATA      (*(volatile uint32_t*)(SECURE_UART_BASE + 0x0C))
#define INT_EN       (*(volatile uint32_t*)(SECURE_UART_BASE + 0x10))
#define INT_CLR      (*(volatile uint32_t*)(SECURE_UART_BASE + 0x14))
#define AES_CTRL     (*(volatile uint32_t*)(SECURE_UART_BASE + 0x20))
#define AES_STATUS   (*(volatile uint32_t*)(SECURE_UART_BASE + 0x24))
#define AES_KEY0     (*(volatile uint32_t*)(SECURE_UART_BASE + 0x28))
#define AES_KEY1     (*(volatile uint32_t*)(SECURE_UART_BASE + 0x2C))
#define AES_KEY2     (*(volatile uint32_t*)(SECURE_UART_BASE + 0x30))
#define AES_KEY3     (*(volatile uint32_t*)(SECURE_UART_BASE + 0x34))

// Bit definitions
#define UART_TX_BUSY   (1 << 0)
#define UART_RX_READY  (1 << 1)
#define UART_RX_ERROR  (1 << 2)
#define AES_ENABLE     (1 << 0)
```

## Initialization

```c
void secure_uart_init(uint8_t baud_sel, const uint32_t *key, bool encrypt) {
    // Configure baud rate and enable TX/RX
    UART_CTRL = (baud_sel & 0x0F) | (1 << 4) | (1 << 5);
    
    // Load AES key (if encryption enabled)
    if (encrypt && key) {
        AES_KEY0 = key[0];
        AES_KEY1 = key[1];
        AES_KEY2 = key[2];
        AES_KEY3 = key[3];
        
        // Enable AES encryption
        AES_CTRL = AES_ENABLE;
    } else {
        // Disable AES (bypass mode)
        AES_CTRL = 0;
    }
    
    // Enable interrupts (optional)
    INT_EN = 0x03;  // TX done + RX ready
}
```

## Transmit Functions

```c
// Blocking transmit (polls TX_BUSY)
void uart_putc(char c) {
    while (UART_STATUS & UART_TX_BUSY);
    TX_DATA = c;
}

// String transmit
void uart_puts(const char *str) {
    while (*str) {
        uart_putc(*str++);
    }
}

// Buffer transmit
void uart_write(const uint8_t *buf, size_t len) {
    for (size_t i = 0; i < len; i++) {
        uart_putc(buf[i]);
    }
}
```

## Receive Functions

```c
// Blocking receive (polls RX_READY)
char uart_getc(void) {
    while (!(UART_STATUS & UART_RX_READY));
    return RX_DATA & 0xFF;
}

// Non-blocking receive
bool uart_getc_nb(char *c) {
    if (UART_STATUS & UART_RX_READY) {
        *c = RX_DATA & 0xFF;
        return true;
    }
    return false;
}

// Buffer receive (blocking)
void uart_read(uint8_t *buf, size_t len) {
    for (size_t i = 0; i < len; i++) {
        buf[i] = uart_getc();
    }
}
```

## Example: Echo Server

```c
int main(void) {
    // Initialize with encryption
    uint32_t key[4] = {0x0f0e0d0c, 0x0b0a0908, 0x07060504, 0x03020100};
    secure_uart_init(3, key, true);  // 115200 baud, encrypted
    
    uart_puts("Secure UART Echo Server\\r\\n");
    
    while (1) {
        char c = uart_getc();
        uart_putc(c);  // Echo back
        
        if (c == '\\r') {
            uart_putc('\\n');
        }
    }
}
```

## Mode Switching

```c
// Switch to plaintext mode
void set_plaintext_mode(void) {
    AES_CTRL = 0;  // Disable AES
}

// Switch to encrypted mode
void set_encrypted_mode(void) {
    AES_CTRL = AES_ENABLE;
}

// Check current mode
bool is_encrypted(void) {
    return (AES_CTRL & AES_ENABLE) != 0;
}
```

## Interrupt Handler

```c
void secure_uart_irq_handler(void) {
    uint32_t status = UART_STATUS;
    
    if (status & UART_RX_READY) {
        // Handle received data
        char c = RX_DATA & 0xFF;
        rx_buffer_put(c);
        INT_CLR = (1 << 1);  // Clear RX interrupt
    }
    
    if (!(status & UART_TX_BUSY)) {
        // TX complete - send next byte if available
        if (tx_buffer_available()) {
            TX_DATA = tx_buffer_get();
        }
        INT_CLR = (1 << 0);  // Clear TX interrupt
    }
}
```

## Baud Rate Selection

| baud_sel | Baud Rate | Use Case |
|----------|-----------|----------|
| 0        | 9600      | Slow, reliable |
| 1        | 19200     | Moderate |
| 2        | 38400     | Standard |
| 3        | 115200    | Fast (default) |
| 4        | 230400    | Very fast |
| 5        | 460800    | High speed |
| 6        | 921600    | Maximum |

## Best Practices

1. **Always check AES_STATUS before changing keys**: Changing keys during encryption can corrupt data
2. **Use interrupts for efficiency**: Polling wastes CPU cycles
3. **Handle RX_ERROR**: Check UART_STATUS bit 2 for framing/parity errors
4. **Buffer management**: Use circular buffers for interrupt-driven I/O
5. **Encryption awareness**: Remember 16-byte buffering latency when AES enabled

## Common Pitfalls

❌ **Writing to TX_DATA when TX_BUSY**: Data will be lost
❌ **Changing AES_CTRL during transmission**: Can corrupt in-flight data
❌ **Not handling RX overflow**: Data lost if not read promptly
✅ **Always check status bits before I/O operations**
✅ **Use interrupt-driven I/O for better responsiveness**

For complete examples, see `dp-1/peripheral/test/test_secure_uart.py`
