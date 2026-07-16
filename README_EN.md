# embedded-code-skill

**Embedded C Code Assistant**: Helps AI produce conservative, reviewable code in embedded scenarios.

| Resource | Description |
|----------|-------------|
| [SKILL.md](SKILL.md) | Single rule entrypoint |
| [install.sh](install.sh) | Install script |

---

## What It Does

- **REWRITE**: Clean up legacy drivers, preserve register write order and timing
- **REVIEW**: Audit ISR/DMA/cache/race risks, output issue table
- **GUIDE**: RTOS task design, CMake config, debug strategy advisory

**Not a chip manual**. Does not replace register maps, IRQ tables, or certification artifacts.

---

## Core Principle: Three-Layer Decoupling

REWRITE/REVIEW must follow the three-layer architecture:

```
┌──────────────────────────────────────┐
│  Application (module.h / module.c)   │
│  Buffers, protocol, public API      │
│  ✗ No direct register writes  ✗ No ISR │
├──────────────────────────────────────┤
│  Driver (module_drv.h / .c)         │
│  Register R/W, ISR, DMA            │
│  ✗ No business logic  ✗ No buffer alloc │
│  → ISR notifies app via callbacks   │
├──────────────────────────────────────┤
│  Register (module_reg.h)            │
│  Structs, bit defs, base macros    │
│  ✗ No function implementations     │
└──────────────────────────────────────┘
```

Five-file layout: `module_reg.h` → `module_drv.h/.c` → `module.h/.c`

---

## Quick Start

```bash
# REWRITE: Clean up UART driver, preserve register write order
/ecs Clean up this UART driver into three layers

# REVIEW: Audit DMA ISR risks
/ecs Review this DMA ISR for race or cache issues

# GUIDE: RTOS task design
/ecs Design FreeRTOS task priorities and stack sizes
```

---

## RED LINES

1. No invented hardware facts (registers/IRQ/barriers/timing)
2. No `malloc` / VLAs in low-level code
3. No `int`/`char`/`long` as default public interface types
4. No bare register addresses in business logic
5. No non-compilable output
6. **No violation of three-layer decoupling**

---

## Install

```bash
./install.sh          # ~/.codex/skills/embedded-code-skill/
./install.sh cursor   # ~/.cursor/skills/embedded-code-skill/
./install.sh claude   # ~/.claude/skills/embedded-code-skill/
```

---

## Chapter Navigation

| Chapter | Coverage |
|---------|----------|
| §1 | Positioning, principles, work modes, RED LINES |
| §2 | Coding standards (naming, types, error handling, data structures, comments) |
| §3 | Register abstraction (hierarchical structs, `MASK/SHIFT`) |
| §4 | Driver templates (three-layer five-file, interface specs) |
| §5 | Architecture rules (Cortex-M/A, ESP32, RISC-V, etc.) |
| §6 | RTOS guidance (FreeRTOS/Zephyr/RT-Thread) |
| §7 | Build system (linker scripts, CMake) |
| §8 | Memory, safety, and concurrency defaults |
| §9 | Review checklist & maintenance self-check |
See [SKILL.md](SKILL.md) for full specifications.

---

## License

MIT License
