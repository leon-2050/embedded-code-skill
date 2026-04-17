---
name: embed-code-drivers
description: Canonical peripheral driver templates for UART, SPI, I2C, DMA, CAN, GPIO, timers, watchdogs, and MIL-STD-1553. Use these as structure-first examples, then fill in hardware-specific offsets and bit fields from the target reference manual.
---

# Driver Templates

## Normative Style

本文件提供的是**规范模板**，不是厂商级寄存器头文件。

所有模板都遵循同一规则：

- 独立 `*_reg.h`
- `*_reg_t` 寄存器结构体
- 一个 `*_REG` 访问宏
- `MASK/SHIFT` 位字段宏
- 配置结构体、运行时句柄结构体、状态返回值分离

以下示例中的字段名仅用于说明结构。真实偏移、保留位和 reset 值必须来自目标芯片手册。

## UART

```c
/* uart_reg.h */
#define UART_BASE_ADDR  (0x4000C000U)  /* 用真实参考手册值替换 */

typedef struct {
    volatile uint32_t DATA;
    volatile uint32_t STATUS;
    volatile uint32_t CTRL;
    volatile uint32_t BAUD;
} uart_reg_t;

#define UART_STATUS_RX_READY_MASK  (1U << 0)
#define UART_STATUS_TX_EMPTY_MASK  (1U << 1)
#define UART_CTRL_ENABLE_MASK      (1U << 0)

#define UART_REG  ((uart_reg_t *)UART_BASE_ADDR)

typedef struct {
    uint32_t base_address;
    uint32_t baud_rate;
} uart_config_t;

typedef struct {
    bool     initialized;
    uint8_t  rx_buffer[256];
    uint16_t rx_head;
    uint16_t rx_tail;
} uart_handle_t;
```

## SPI

```c
/* spi_reg.h */
#define SPI_BASE_ADDR  (0xA0010000U)  /* 示例地址，必须按芯片手册替换 */

typedef struct {
    volatile uint32_t CTRL;
    volatile uint32_t STATUS;
    volatile uint32_t DATA;
    volatile uint32_t BAUD;
} spi_reg_t;

#define SPI_CTRL_ENABLE_MASK   (1U << 0)
#define SPI_CTRL_MASTER_MASK   (1U << 1)
#define SPI_STATUS_RX_READY_MASK  (1U << 0)

#define SPI_REG  ((spi_reg_t *)SPI_BASE_ADDR)

typedef struct {
    uint32_t base_address;
    uint32_t clock_hz;
    bool     master_mode;
} spi_config_t;
```

## I2C

```c
/* i2c_reg.h */
#define I2C_BASE_ADDR  (0x40005400U)  /* 示例地址，必须按芯片手册替换 */

typedef struct {
    volatile uint32_t CTRL;
    volatile uint32_t STATUS;
    volatile uint32_t ADDR;
    volatile uint32_t DATA;
} i2c_reg_t;

#define I2C_CTRL_ENABLE_MASK       (1U << 0)
#define I2C_STATUS_TX_READY_MASK   (1U << 0)
#define I2C_STATUS_RX_READY_MASK   (1U << 1)

#define I2C_REG  ((i2c_reg_t *)I2C_BASE_ADDR)
```

## DMA

```c
typedef struct {
    volatile uint32_t CTRL;
    volatile uint32_t SRC_ADDR;
    volatile uint32_t DST_ADDR;
    volatile uint32_t LENGTH;
} dma_channel_reg_t;

typedef struct {
    volatile uint32_t GLOBAL_STATUS;
    dma_channel_reg_t channel[8];
} dma_reg_t;

#define DMA_CTRL_ENABLE_MASK  (1U << 0)
```

## CAN

```c
typedef struct {
    volatile uint32_t CTRL;
    volatile uint32_t STATUS;
    volatile uint32_t BIT_TIMING;
    volatile uint32_t TX_DATA;
    volatile uint32_t RX_DATA;
} can_reg_t;

typedef struct {
    uint32_t id;
    uint8_t  dlc;
    uint8_t  data[8];
} can_msg_t;

#define CAN_CTRL_ENABLE_MASK  (1U << 0)
```

## GPIO

```c
typedef struct {
    volatile uint32_t MODE;
    volatile uint32_t INPUT_DATA;
    volatile uint32_t OUTPUT_DATA;
    volatile uint32_t BIT_SET_RESET;
} gpio_reg_t;

typedef enum {
    GPIO_MODE_INPUT = 0,
    GPIO_MODE_OUTPUT = 1,
    GPIO_MODE_ALT = 2,
    GPIO_MODE_ANALOG = 3
} gpio_mode_t;
```

## Timer / Watchdog

```c
typedef struct {
    volatile uint32_t CTRL;
    volatile uint32_t COUNT;
    volatile uint32_t AUTO_RELOAD;
    volatile uint32_t PRESCALER;
} timer_reg_t;

typedef struct {
    volatile uint32_t KEY;
    volatile uint32_t RELOAD;
    volatile uint32_t STATUS;
} wdt_reg_t;
```

## MIL-STD-1553

```c
typedef enum {
    MIL1553_MODE_BC = 0,
    MIL1553_MODE_RT = 1,
    MIL1553_MODE_BM = 2
} mil1553_mode_t;

typedef struct {
    uint8_t  command_word;
    uint16_t status_word;
    uint16_t data_words[32];
} mil1553_msg_t;
```

## Anti-Pattern

不要把寄存器访问散落成 `UART_DR(base)`、`SPI_CR1(base)` 这类地址宏。

统一使用 `*_reg_t` + `*_REG`，这样更容易 review、mock、迁移和做静态检查。
