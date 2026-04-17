---
name: embed-code-standards
description: Embedded C coding standards reference. Covers naming, integer types, error handling, comment discipline, and structure-first register access for production-oriented firmware code.
---

# Coding Standards

## Naming

| Element | Convention | Example |
|---------|------------|---------|
| Variables | `snake_case` | `sensor_value` |
| Globals | `g_snake_case` | `g_system_ticks` |
| Constants | `SCREAMING_SNAKE` | `MAX_BUFFER_SIZE` |
| Functions | `camelCase` | `initUart()` |
| Struct types | `snake_case_t` | `uart_config_t` |
| Enum types | `snake_case_t` | `gpio_state_t` |
| Enum values | `PREFIXED_SNAKE` | `GPIO_STATE_LOW` |
| Pointers | `p_snake_case` | `p_rx_buffer` |

## Types

Use only standard fixed-width integer types in public firmware interfaces:

```c
#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
```

Default choices:

- `uint8_t`
- `uint16_t`
- `uint32_t`
- `int32_t`
- `bool`

Avoid `int`, `char`, and `long` as default portable interface types.

## Error Handling

```c
typedef enum {
    EmbedCode_Ok = 0,
    EmbedCode_ErrNullPtr = -1,
    EmbedCode_ErrInvalidArg = -2,
    EmbedCode_ErrTimeout = -3,
    EmbedCode_ErrBusy = -4,
    EmbedCode_ErrNotInit = -5
} embedded_code_status_t;

#define VALIDATE_NOT_NULL(ptr) \
    do { if ((ptr) == NULL) return EmbedCode_ErrNullPtr; } while (0)
```

Every public function should:

- return `embedded_code_status_t`
- validate caller-provided pointers
- return a specific error code for the failure mode

## Struct Patterns

```c
typedef struct {
    uint32_t base_address;
    uint8_t  interrupt_priority;
} peripheral_config_t;

typedef struct {
    bool                initialized;
    peripheral_config_t config;
} peripheral_handle_t;

typedef enum {
    PERIPHERAL_STATE_IDLE = 0,
    PERIPHERAL_STATE_RUNNING,
    PERIPHERAL_STATE_ERROR
} peripheral_state_t;
```

## Register Access

Preferred style:

- one `*_reg.h` per peripheral block
- one `*_reg_t` register structure
- one `*_REG` accessor macro
- named `MASK/SHIFT` field macros

Avoid scattering direct address macros such as `UART_DR(base)` through implementation code.

## No Dynamic Allocation

**Prohibited:** `malloc`, `free`, `calloc`, `realloc`, VLAs

**Preferred:** fixed-size buffers and explicit ownership

```c
#define BUFFER_SIZE 256U
static uint8_t g_rx_buffer[BUFFER_SIZE];
```

## Comments

- Follow the project’s existing language convention
- Explain intent, constraints, or hardware rationale
- Do not restate obvious code

Example:

```c
config |= SPI_CTRL_ENABLE_MASK;  /* 先使能模块，再写时钟参数以避免毛刺 */
```

## Review Checklist

- [ ] fixed-width integer types only
- [ ] one canonical status type: `embedded_code_status_t`
- [ ] no direct register address macros in business logic
- [ ] no unnamed magic numbers
- [ ] no dynamic allocation or VLAs
- [ ] comments add context instead of paraphrasing the code
