---
name: embedded-code-skill
description: "Generate, rewrite, review, or package embedded C guidance for firmware, drivers, HAL/BSP layers, register access, ISRs, DMA, and low-level MCU/SoC modules. Use in Codex, Cursor, VS Code, Claude-compatible agents, or generic IDE agents; adapt to the target repository's existing status types, naming, vendor SDK, build macros, and hardware sources before applying the fallback house style."
user-invocable: true
---

# Embedded C 代码助手 Skill

## 定位

本 skill 帮助处理嵌入式 C 代码：写新的驱动骨架，整理旧代码，做代码审查，也可以把这些规则适配到不同 IDE 或 agent 环境。它适用于驱动、寄存器抽象层、HAL/BSP、ISR、DMA、板级初始化和低层固件模块。

它提供的是**不绑定某个 IDE 或 agent 的工作流程和保守编码规范**，不是芯片厂商手册、参考设计或认证标准的替代品。任何真实寄存器偏移、位定义、reset 值、IRQ 号、时序限制、cache/DMA 规则和屏障要求，都必须来自目标芯片参考手册、厂商头文件、现有代码或用户提供的资料。

## 使用原则

1. 先判断任务类型：`GENERATE`、`REWRITE`、`REVIEW`、`INSTALL` 或 `ADAPT`。
2. 先读目标仓库的头文件、宏、状态类型、命名、include 顺序、vendor SDK、编译开关和已有驱动样例。
3. 仓库已有稳定约定时，优先沿用仓库约定；只有缺少本地约定时才使用本 skill 的 fallback house style。
4. 不编造硬件事实。信息缺失时先说明缺口；若必须继续，使用清晰标注的 placeholder。
5. 输出要便于 IDE 采用：优先给小补丁、限定代码块、文件/行号 findings 或明确的复制目标。
6. 不依赖某个运行时专属能力。面向不同 IDE 或 agent 环境时，把本文件当作唯一规范入口，再按目标工具的指令文件格式做轻量转写。

## 生成前必须确认的信息

| 信息 | 要求 | 示例 |
|------|------|------|
| 外设/模块名 | 必需 | `uart`, `spi`, `gpio`, `dma` |
| 硬件来源 | 强烈建议 | 参考手册章节、厂商头文件、寄存器表、现有驱动 |
| 芯片或架构 | 强烈建议 | `STM32F4`, `Cortex-M4`, `RISC-V`, `PowerPC` |
| 基地址/位定义 | 生产代码必需 | `UART_BASE_ADDR = 0x4000C000U` |
| 项目约定 | 生成或重写前读取 | status type、命名、SDK、build macros |

缺少生产级硬件信息时，可以生成保守骨架，但必须标注哪些值是 `USER_PROVIDED`、`REPO_DERIVED` 或 `PLACEHOLDER`。

## 仓库优先策略

- 复用已有 status enum、错误码、assert/validate 宏、命名风格、include 顺序和 section/packing 属性。
- 复用项目已有的 interrupt、DMA、cache、critical section、memory barrier 和 clock/reset helper。
- 项目已经使用 CMSIS 或厂商寄存器结构体时，基于它们生成代码；不要为了满足 fallback 风格再包一层。
- 对已有文件做修改时，优先小范围 patch；除非用户明确要求大重写，不整文件替换。
- 风格问题排在 correctness、硬件行为、安全性、并发和可移植风险之后。

## Fallback House Style

仅当目标仓库没有更强约定时使用。

### 类型

- 公共接口优先使用 `<stdint.h>`、`<stdbool.h>`、`<stddef.h>`
- 默认类型：`uint8_t`、`uint16_t`、`uint32_t`、`int32_t`、`bool`
- 不把 `int`、`char`、`long` 作为默认跨平台接口类型

### 命名

| 元素 | 规范 | 示例 |
|------|------|------|
| 变量 | `snake_case` | `rx_count` |
| 全局变量 | `g_snake_case` | `g_system_ticks` |
| 函数 | `camelCase` | `uartInit()` |
| 结构体/枚举类型 | `snake_case_t` | `uart_handle_t` |
| 枚举值 | `PREFIXED_SNAKE` | `UART_STATE_IDLE` |
| 常量/宏 | `SCREAMING_SNAKE` | `UART_SR_RX_READY_MASK` |
| 指针变量 | 项目无约定时用清晰语义名 | `rx_buffer`, `config`, `handle` |

### 错误处理

项目没有既有 result/status 类型时，公共函数默认返回：

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

公共函数应验证调用者传入的指针、长度、状态和初始化顺序，并返回能区分失败原因的错误码。

## 寄存器抽象

推荐结构：

- 每个外设 block 一个独立 `*_reg.h`
- 使用 `*_reg_t` 定义寄存器结构体，或复用 vendor/CMSIS 已有结构体
- 使用一个明确入口访问寄存器，例如 `*_REG` 或项目已有 wrapper
- 位字段使用 `MASK/SHIFT` 宏，或项目已有等价命名
- 不把裸寄存器地址写散在业务逻辑里
- 对 read-modify-write、reserved bits、write-one-to-clear、unlock sequence 保持谨慎

示例只演示结构，不代表真实芯片布局：

```c
#define SPI_BASE_ADDR  (0xA0010000U)

typedef struct {
    volatile uint32_t CTRL;
    volatile uint32_t STATUS;
    volatile uint32_t DATA;
} spi_reg_t;

#define SPI_CTRL_EN_MASK    (1U << 0)
#define SPI_CTRL_MODE_MASK  (3U << 2)

#define SPI_REG  ((spi_reg_t *)SPI_BASE_ADDR)
```

## 内存、安全和并发默认值

- 低层驱动、ISR 和 hot path 默认不使用 `malloc`、`free`、`calloc`、`realloc`；除非仓库已有受控 allocator 且用户明确要求。
- 禁止 VLA；缓冲区大小、timeout、retry count 使用命名常量。
- critical section 要短、显式，并沿用项目本地 helper。
- ISR、DMA、cache coherency、shared state、volatile 和 memory ordering 代码必须保留硬件相关顺序。
- 不发明 memory barrier、cache maintenance sequence、DMA ownership rule 或 interrupt-controller 细节。
- 对硬件 workaround 保持谨慎；如果可能影响行为，明确说明假设。

## 输出契约

### GENERATE

生成新代码时：

1. 先列出阻塞生产级代码的缺失硬件事实。
2. 标注关键值来源：用户提供、仓库推导、placeholder。
3. 仓库已有驱动骨架时匹配它；否则生成最小可维护模块。
4. 多文件模块默认组织为：

```text
module/
├── module_reg.h   # 寄存器结构体、位定义或 vendor wrapper
├── module.h       # 公共接口
└── module.c       # 实现
```

推荐输出顺序：

```text
Missing Inputs
Assumptions
Proposed Files
Code
```

### REWRITE

重写旧代码时：

1. 先归纳必须保留的外部行为、ABI、公共函数名、寄存器写入顺序和时序敏感序列。
2. 默认修复语法错误、类型错误、空指针、越界、未初始化和明显不安全结构。
3. 尽量给 patch-sized rewrite，避免不必要的全文件重写。
4. 任何可能改变硬件行为的假设放在代码之后说明。

推荐输出顺序：

```text
Preserved Behavior
Rewritten Code
Assumptions
```

### REVIEW

审查代码时，finding 先行，按严重程度排序，并尽量给具体文件和行号。优先级：

1. `volatile`、barrier、cache、DMA ownership 或 memory ordering 假设错误
2. 寄存器写入顺序、reserved bits、read-modify-write、write-one-to-clear 风险
3. timeout、overflow、符号/宽度、对齐、生命周期和空指针问题
4. IRQ 安全、shared-state race、atomicity 和 critical section 问题
5. init/deinit、clock gating、reset flow 和错误回滚
6. ABI 破坏、接口兼容性、可移植类型和风格问题

推荐 finding 格式：

```text
1. [High] path/to/file.c:42 - Register write clears reserved bits on every init call.
```

没有问题时明确说明，并补充残余风险或测试缺口。

### INSTALL / ADAPT

当用户要把本 skill 装进不同 IDE 或 agent 平台时，把本 `SKILL.md` 作为规范源，再按目标平台需要生成或更新适配文件。不要同时启用多份 always-on 指令，除非用户明确希望合并规则。

下表路径是**目标仓库中的生成位置**，不是本仓库自带文件。本仓库保持单入口，只提供生成这些文件所需的规则。

| 平台 | 推荐入口 | 说明 |
|------|----------|------|
| Codex skill runtime | `SKILL.md` | 保留 YAML frontmatter 和正文 |
| Cursor | `.cursor/rules/embedded-code-core.mdc` | 用 scoped rule；从本文按需提取相关段落 |
| VS Code / Copilot | `.github/copilot-instructions.md` | 作为 always-on 入口 |
| VS Code scoped instructions | `.github/instructions/embedded-code-core.instructions.md` | 适合只作用于 `**/*.c,**/*.h` |
| Claude-compatible agents | `CLAUDE.md` | 提取核心规则，保持仓库优先 |
| Generic agents | `AGENTS.md` | 作为通用 fallback |

适配文件应保留这些核心句子：

- Adapt to repository-local status types, naming, vendor headers, SDKs, and build macros before applying fallback style.
- Do not invent register offsets, bit definitions, reset values, IRQ numbers, timing limits, barriers, or cache/DMA rules.
- If hardware facts are missing, ask for sources or emit clearly labeled placeholders.
- Preserve public behavior, ABI, register write order, and timing-sensitive sequences in rewrite tasks.
- In review tasks, lead with correctness, races, volatile/DMA/cache issues, timeout/overflow bugs, and init ordering; treat style as secondary.

## 子领域规则

### Standards

优先复用目标仓库的命名、状态类型、断言宏和 include 风格。仓库没有约定时使用 fallback house style。

| 元素 | fallback 规范 | 示例 |
|------|---------------|------|
| 变量 | `snake_case` | `sensor_value` |
| 全局变量 | `g_snake_case` | `g_system_ticks` |
| 常量/宏 | `SCREAMING_SNAKE` | `MAX_BUFFER_SIZE` |
| 函数 | `camelCase` | `initUart()` |
| 结构体/枚举类型 | `snake_case_t` | `uart_config_t` |
| 枚举值 | `PREFIXED_SNAKE` | `GPIO_STATE_LOW` |
| 指针 | 项目无约定时可用 `p_snake_case` | `p_rx_buffer` |

公共接口使用固定宽度整数和明确布尔类型：`uint8_t`、`uint16_t`、`uint32_t`、`int32_t`、`bool`。避免把 `int`、`char`、`long` 作为默认跨平台接口类型。

结构体默认拆成配置、运行时句柄和状态：

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

标准检查项：

- public 函数验证调用者传入的指针、长度、状态和初始化顺序。
- 寄存器位、buffer size、timeout、retry count 必须有命名常量。
- 低层驱动默认不用 `malloc`、`free`、`calloc`、`realloc` 和 VLA。
- 注释解释硬件原因、约束、时序和意图；不要逐行复述代码。
- 风格重写必须服务于可维护性、可审查性或真实缺陷修复。
- review 时检查固定宽度类型、单一 status 类型、无业务逻辑裸寄存器地址、无未命名 magic number、无动态分配/VLA。

### Drivers

驱动模板用于组织代码，不是厂商级寄存器头文件。所有真实 offset、reserved bit、reset 值、时序和 errata 都必须来自目标资料。

统一结构：

- 独立 `*_reg.h`
- `*_reg_t` 寄存器结构体，或仓库已有 vendor/CMSIS 结构体
- 一个 `*_REG` 或项目本地等价访问入口
- `MASK/SHIFT` 位字段宏
- 配置结构体、运行时句柄结构体、状态返回值分离

常用模板骨架：

| 模块 | 寄存器结构示例 | 关键数据结构 |
|------|----------------|--------------|
| UART | `DATA`, `STATUS`, `CTRL`, `BAUD` | `uart_config_t { base_address, baud_rate }`, `uart_handle_t { initialized, rx_buffer, rx_head, rx_tail }` |
| SPI | `CTRL`, `STATUS`, `DATA`, `BAUD` | `spi_config_t { base_address, clock_hz, master_mode }` |
| I2C | `CTRL`, `STATUS`, `ADDR`, `DATA` | 地址、方向、timeout 和 bus state 分离 |
| DMA | `GLOBAL_STATUS`, `channel[n].CTRL/SRC_ADDR/DST_ADDR/LENGTH` | channel 配置、buffer ownership、completion 状态分离 |
| CAN | `CTRL`, `STATUS`, `BIT_TIMING`, `TX_DATA`, `RX_DATA` | `can_msg_t { id, dlc, data[8] }` |
| GPIO | `MODE`, `INPUT_DATA`, `OUTPUT_DATA`, `BIT_SET_RESET` | `gpio_mode_t { INPUT, OUTPUT, ALT, ANALOG }` |
| Timer | `CTRL`, `COUNT`, `AUTO_RELOAD`, `PRESCALER` | period、prescaler、callback/flag 分离 |
| Watchdog | `KEY`, `RELOAD`, `STATUS` | unlock/feed/reload sequence 保持显式 |
| MIL-STD-1553 | mode、command/status word、data words | `BC`、`RT`、`BM` 模式和 32 个 data word |

最小寄存器字段参考：

```c
typedef struct { volatile uint32_t DATA, STATUS, CTRL, BAUD; } uart_reg_t;
typedef struct { volatile uint32_t CTRL, STATUS, DATA, BAUD; } spi_reg_t;
typedef struct { volatile uint32_t CTRL, STATUS, ADDR, DATA; } i2c_reg_t;
typedef struct { volatile uint32_t CTRL, SRC_ADDR, DST_ADDR, LENGTH; } dma_channel_reg_t;
typedef struct { volatile uint32_t GLOBAL_STATUS; dma_channel_reg_t channel[8]; } dma_reg_t;
typedef struct { volatile uint32_t CTRL, STATUS, BIT_TIMING, TX_DATA, RX_DATA; } can_reg_t;
typedef struct { volatile uint32_t MODE, INPUT_DATA, OUTPUT_DATA, BIT_SET_RESET; } gpio_reg_t;
typedef struct { volatile uint32_t CTRL, COUNT, AUTO_RELOAD, PRESCALER; } timer_reg_t;
typedef struct { volatile uint32_t KEY, RELOAD, STATUS; } wdt_reg_t;
```

常用位和枚举命名示例：

```c
#define UART_STATUS_RX_READY_MASK  (1U << 0)
#define UART_STATUS_TX_EMPTY_MASK  (1U << 1)
#define UART_CTRL_ENABLE_MASK      (1U << 0)
#define SPI_CTRL_ENABLE_MASK       (1U << 0)
#define SPI_CTRL_MASTER_MASK       (1U << 1)
#define DMA_CTRL_ENABLE_MASK       (1U << 0)
#define CAN_CTRL_ENABLE_MASK       (1U << 0)

typedef enum {
    GPIO_MODE_INPUT = 0,
    GPIO_MODE_OUTPUT = 1,
    GPIO_MODE_ALT = 2,
    GPIO_MODE_ANALOG = 3
} gpio_mode_t;
```

MIL-STD-1553 fallback 类型：

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

反模式：不要把寄存器访问散落成 `UART_DR(base)`、`SPI_CR1(base)` 这类地址宏。统一的寄存器结构更容易 review、mock、迁移和静态检查。

### Architecture

架构相关代码包括 ISR、barrier、DMA、cache、interrupt controller、SMP、memory ordering、CSR/SPR 和 board bring-up。

常见架构 quick ref：

| 架构 | Barrier | Interrupt | CSR/SPR |
|------|---------|-----------|---------|
| ARM Cortex-M | `__DMB()`, `__DSB()`, `__ISB()` | NVIC | N/A |
| ARM Cortex-A | `dmb ish` | GIC | system registers |
| PowerPC | `msync` | PIC | `mfspr` |
| SPARC V8 | `stbar` | INTC | `rd psr` |
| RISC-V | `fence` | PLIC/CLINT | `csrr` |

架构辅助函数要放在小而集中的 wrapper 中，并使用项目已有实现。例如 PowerPC `mfspr`、SPARC `rd psr`、RISC-V `csrr` 这类 inline asm 必须匹配目标编译器约束。

架构 wrapper 示例：

```c
static inline uint32_t ppcMfspr(uint16_t spr) {
    uint32_t value;
    __asm volatile ("mfspr %0, %1" : "=r"(value) : "K"(spr));
    return value;
}

static inline uint32_t sparcGetPsr(void) {
    uint32_t psr;
    __asm volatile ("rd %%psr, %0" : "=r"(psr));
    return psr;
}

static inline uint32_t riscvCsrr(uint32_t csr) {
    uint32_t value;
    __asm volatile ("csrr %0, %1" : "=r"(value) : "K"(csr));
    return value;
}
```

未知架构处理：

1. 先根据芯片、工具链、vendor headers 和已有低层代码判断架构。
2. 仍不确定时，使用可用资料源查官方文档或要求用户提供参考手册、中断控制器说明、barrier/cache/DMA 规则或已有驱动样例。
3. 需要反馈时，列出已确认信息、待确认假设和会影响生成结果的风险。
4. 不能确认时，只生成架构无关 C 骨架，并把 barrier、interrupt enable、cache maintenance 标成 placeholder。
5. 不猜测 memory barrier、cache maintenance、DMA ownership、IRQ number 或 interrupt-controller 行为。

常见芯片归类只作为初始线索，不可当成事实来源：

| 常见芯片 | 常见架构 |
|----------|----------|
| STM32, NXP LPC/Kinetis, GD32 | ARM Cortex-M |
| i.MX6/i.MX7, STM32MP | ARM Cortex-A |
| MPC5748, QorIQ | PowerPC |
| FE310, SiFive | RISC-V |

### Domains

先通过关键词识别领域，但合规目标必须由用户或项目资料确认。

| 领域 | 关键词 | 关注点 |
|------|--------|--------|
| Aerospace | DO-178C, DAL, ARINC, flight | determinism, traceability, MC/DC target when specified |
| Military | 1553B, SpaceWire, MIL-STD, radar | redundancy, SEU protection, BIT diagnostics |
| Industrial | IEC 61508, SIL, PLC, SCADA | safe state, watchdog, deterministic response |
| Automotive | ISO 26262, ASIL, CANFD | ASIL decomposition, freedom from interference, SPFM/LFM when specified |

不要把 DAL、ASIL、SIL、MC/DC、SPFM、LFM、BIT 覆盖率当成通用默认值。只有用户或项目资料明确标准和等级时，才写入文件头、需求追踪或 review 结论。

领域默认要求：

- Aerospace / DO-178C：无动态分配、确定性行为、无递归、复杂度受控、需求 ID 可追踪。
- Military / MIL-STD-1553B：冗余、SEU 防护、BIT diagnostics、总线模式和状态字处理清晰。
- Industrial / IEC 61508：safe state 明确、watchdog supervision、故障时进入可控状态。
- Automotive / ISO 26262：接口隔离、故障传播控制、诊断覆盖和硬件容错假设明确。
- General Embedded：不默认声明特殊认证要求。

文件头示例只在项目已有 Doxygen 或用户要求时使用：

```c
/**
 * @file navigation.c
 * @brief Navigation processing
 *
 * ### Safety Level: DAL-B ###
 * - Requirement ID: NAV-001
 */
```

安全敏感 review 优先看确定性、fail-safe、诊断覆盖、traceability、watchdog 和错误进入安全状态。

## 注释和文档

- 注释语言遵循项目现有约定；项目无约定时可使用中文或用户指定语言。
- Doxygen 文件头只在项目已有模式或确实帮助维护时添加。
- 不在答案里重复长篇规范；直接应用规则并说明关键假设。

## 回查清单

- [ ] 是否优先读取并沿用目标仓库约定
- [ ] 是否所有硬件常量都来自用户、仓库或明确 placeholder
- [ ] 是否避免编造寄存器、IRQ、barrier、cache/DMA 规则
- [ ] 是否复用 vendor/CMSIS 结构而不是重复包装
- [ ] 是否无裸寄存器地址散落在业务逻辑中
- [ ] 是否无低层驱动默认动态内存和 VLA
- [ ] 是否命名、类型和错误处理与仓库或 fallback style 一致
- [ ] `REWRITE` 是否保留外部行为、ABI 和时序敏感顺序
- [ ] `REVIEW` 是否把 correctness 和硬件风险放在风格之前
- [ ] IDE 适配时是否只启用必要的一份 always-on 入口

## 维护自检

修改本 skill 后，用下面的轻量流程确认没有把规则改偏。这个流程只写在 `SKILL.md` 里，不再拆目录或伪装成自动能力。

1. 选取本次改动影响的范围：核心规则、输出契约、Standards、Drivers、Architecture、Domains、IDE 适配或 README。
2. 至少用这些场景做人工 smoke check：
   - `GENERATE`：生成一个 UART/SPI/GPIO 驱动，缺少位定义时是否使用 placeholder。
   - `REWRITE`：整理 SPI/I2C 初始化代码，是否保留 public API、ABI、寄存器写入顺序。
   - `REVIEW`：审查 DMA ISR 或 cache 相关代码，是否优先指出 race、volatile、barrier、ownership 风险。
   - `INSTALL / ADAPT`：转成 Cursor、VS Code、`CLAUDE.md` 或 `AGENTS.md` 时，是否只保留一份 always-on 入口。
   - 领域场景：DO-178C、MIL-STD-1553、IEC 61508、ISO 26262 是否只在用户提供标准和等级时才写合规结论。
3. 检查通过标准：
   - 不编造硬件事实。
   - 仓库优先策略仍然在 fallback house style 之前。
   - 子领域能力没有丢失或互相矛盾。
   - README 和 `SKILL.md` 的能力描述保持一致。
   - 没有重新引入重复目录、运行时绑定工具或散落的 adapter 模板。

## 反例

```c
/* 反例：寄存器地址散落、直接写魔法数字 */
#define SPI_CTRL_ADDR  (*(volatile uint32_t *)0xA0010000U)
void spiInit(void) { SPI_CTRL_ADDR = 0x47U; }

/* 正例：统一结构体访问与命名常量 */
#include "spi_reg.h"
void spiInit(void) { SPI_REG->CTRL = SPI_CTRL_INIT_VAL; }
```

## 单入口说明

本仓库的嵌入式 C 规则以这个 `SKILL.md` 为唯一入口。此前拆分出的重复规则、IDE 适配规则和参考说明已经合并到本文中，避免不同平台读取到互相重复或不一致的规则。
