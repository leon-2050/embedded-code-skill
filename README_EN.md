# embedded-code-skill

> Embedded C skill bundle for generating, rewriting, and reviewing drivers and low-level firmware code.

[简体中文](README.md) · [English](README_EN.md) · [日本語](README_JP.md)

---

## What This Package Is For

This package gives the model one consistent house style for:

- generating new driver skeletons
- rewriting legacy embedded C into a cleaner structure
- reviewing firmware code for portability and maintainability issues

It is **not** a substitute for the target vendor reference manual.

---

## Design Boundaries

- style guidance first, hardware fabrication never
- structure-first register access: `*_reg_t` plus `*_REG`
- examples show organization, not production-ready register maps
- `.evolution/` is a manual evaluation playbook, not an automated optimizer

---

## Quick Start

```bash
/embedded-code-skill Generate an STM32 UART driver with base address 0x4000C000
/embedded-code-skill Rewrite this SPI init code while preserving behavior intent
/embedded-code-skill Review this GPIO driver against the house style
```

---

## Core Rules

| Category | Rule |
|----------|------|
| Types | Prefer `stdint.h` and `stdbool.h` in public interfaces |
| Error handling | Public functions should return `embedded_code_status_t` |
| Register abstraction | Use a dedicated `*_reg.h`, `*_reg_t`, and `*_REG` |
| Magic numbers | Name register fields and hardware constants |
| Memory | Do not use `malloc`, `free`, or VLAs |
| Rewrite mode | Preserve behavior intent, but repair syntax and obvious defects |

---

## Package Layout

```text
embedded-code-skill/
├── SKILL.md
├── README.md
├── README_EN.md
├── README_JP.md
├── embedded-code-skill-standards/
├── embedded-code-skill-drivers/
├── embedded-code-skill-arch/
├── embedded-code-skill-domains/
├── .evolution/
└── validation/
```

---

## Example Style

```c
/* Illustrative only: verify every field and offset against the target manual */
#define UART_BASE_ADDR  (0x4000C000U)

typedef struct {
    volatile uint32_t DATA;
    volatile uint32_t STATUS;
    volatile uint32_t CTRL;
    volatile uint32_t BAUD;
} uart_reg_t;

#define UART_STATUS_RX_READY_MASK  (1U << 0)
#define UART_CTRL_ENABLE_MASK      (1U << 0)

#define UART_REG  ((uart_reg_t *)UART_BASE_ADDR)
```

---

## `.evolution/`

The `.evolution/` directory contains:

- scoring criteria
- test prompts
- results log format
- a manual improvement workflow

It does not ship with file locking, automatic rollback, or automated orchestration scripts.

---

## `validation/`

The `validation/` directory contains lightweight checks for:

- illegal C identifiers
- status type consistency
- contradictory register-access templates
- translation leftovers in EN/JP docs
- a compile smoke test for the MIL-STD-1553 example

---

## License

MIT License
