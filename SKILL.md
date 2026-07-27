---
name: embedded-code-skill
description: "嵌入式 C 代码规范化助手：驱动骨架、旧代码整理、代码审查、寄存器重构"
user-invocable: true
triggers:
  - embedded
  - firmware
  - driver
  - HAL
  - BSP
  - ISR
  - DMA
  - register
  - MCU
  - SoC
  - Cortex-M
  - RISC-V
  - RTOS
  - FreeRTOS
  - 1553
  - PWM
  - ADC
  - DAC
  - watchdog
  - CAN
  - UART
  - SPI
  - I2C
  - GPIO
  - Timer
  - 嵌入式
  - 固件
  - 驱动
---

# Embedded C 代码助手 Skill

---

## 1. 定位与使用原则

### 1.1 定位

帮助处理嵌入式 C 裸机/驱动代码：驱动骨架生成、旧代码规范化整理、代码审查、寄存器重构。

本 skill 提供不绑定 IDE/agent 的保守编码规范。寄存器偏移、位定义、IRQ、屏障、cache/DMA、时序等须来自手册、厂商头文件或仓库——**不编造硬件事实**。

### 1.2 使用原则

1. 先判 `REWRITE`/`REVIEW`/`GUIDE`（§1.4）→ 读仓库头文件、命名、SDK、已有驱动样例
2. 遵守 §4 四层架构（reg → ll → drv → app；ISR 回调通知 app）
3. 项目规范优先；CMSIS/厂商结构体直接复用，不为 fallback 再包一层
4. 硬件信息缺口先列出；待定值标 placeholder
5. 输出优先 patch；风格让位于 correctness/并发/硬件风险
6. **平铺项目同样四层七文件**：不建 `module/` 子目录时，七文件（`module_reg.h` / `module_ll.h` / `module_ll.c` / `module_drv.h` / `module_drv.c` / `module.h` / `module.c`）直接平铺在现有目录：
   - `module_reg.h`：结构体、位定义、基址宏（纯定义，无函数）
   - `module_ll.h/.c`：寄存器访问函数（无状态；barrier/回读/多步序列）
   - `module_drv.h/.c`：时序编排、ISR、DMA（经 ll 访问硬件）
   - `module.h` 删掉寄存器定义，改为 `#include "module_reg.h"` + 保留对外函数原型
   目录布局不变，四层隔离标准不变（对平铺与带子目录项目同等适用）。

**优先级裁决**（规则冲突时从高到低适用）：

1. 安全红线（P0：伪造硬件/写入时序/volatile/ISR 阻塞/可编译/裸寄存器/malloc）——不让位于任何项目约定
2. P1 并发与可移植类（static 多实例、类型安全、错误处理、宏安全）——不让位
3. P1 结构类（四层拆分粒度、文件组织）——项目已有既定架构时让位

### 1.3 前置信息

| 信息 | 要求 | 示例 |
|------|------|------|
| 外设/模块名 | REWRITE 必需 | `uart`, `spi`, `gpio`, `dma` |
| 硬件来源 | 强烈建议 | 参考手册章节、厂商头文件、现有驱动 |
| 芯片或架构 | 强烈建议 | `STM32F4`, `Cortex-M4`, `ESP32` |
| 基地址/位定义 | 生产代码必需 | `UART_BASE_ADDR = 0x4000C000U` |
| 项目约定 | 重写前读取 | status type、命名、SDK、build macros |
| RTOS（如适用） | 驱动层需确认 | FreeRTOS、Zephyr、RT-Thread、裸机 |

缺口先列出；待定值标 `USER_PROVIDED` / `REPO_DERIVED` / `PLACEHOLDER`。

### 1.4 工作模式

**REWRITE**：按 §4 整理类型/命名/分层。输出：简述 → 缺口 → patch（必要时文件布局）。workaround 标 `/* 有意保留：原因 */`。

**REVIEW**：不产出代码。按寄存器抽象 → 分层/ISR/同步 → volatile/barrier/cache/DMA → 错误处理/内存 顺序查。输出表：`| P0/P1/P2 | 位置 | 问题 | 建议 |`（P0 行为/安全，P1 并发/可移植，P2 风格）。

**GUIDE**：无代码整理/审查需求（RTOS 任务设计、CMake/链接脚本、调试策略等）。按 §5–§8 给建议或示例片段，不走 REVIEW 表。

### 1.5 RED LINES

安全类最高优先级，与 §9.1 P0 表一一对应，不让位于任何项目约定：

- ① 禁伪造硬件参数（寄存器/位域/IRQ/屏障/时序）
- ② 禁打乱寄存器写入顺序与时序序列（REWRITE 必须原样保留）
- ③ 禁 ISR 与主循环共享变量缺 `volatile`
- ④ 禁 ISR 内阻塞调用（delay/malloc/mutex/printf）
- ⑤ 禁不可编译的输出
- ⑥ 禁业务代码裸寄存器地址
- ⑦ 禁驱动层/ISR 使用 `malloc`/VLA

> 接口类型安全与四层解耦为 P1 架构级要求（见 §9.1 P1 表），不列入红线。

---

## 2. Fallback 编码规范

仓库无更强约定时适用；符合则沿用，不符合则不改逻辑地统一。

### 2.1 命名

| 元素 | 规范 | 示例 |
|------|------|------|
| 变量 | `snake_case` | `rx_count` |
| 全局变量 | `g_snake_case` | `g_system_ticks` |
| 函数 | `camelCase` | `uartInit()` |
| 结构体/枚举类型 | `snake_case_t` | `uart_handle_t` |
| 枚举值 | `PREFIXED_SNAKE` | `UART_STATE_IDLE` |
| 常量/宏 | `SCREAMING_SNAKE` | `UART_SR_RX_READY_MASK` |
| 指针 | 项目无约定时用清晰语义名；指针密集、需与值变量区分时用 `p_` 前缀 | `rx_buffer`, `handle`；或 `p_rx_buffer` |

> **命名优先级**：
> - 对外函数（被 `main.c` 或其他模块调用的）→ 保 API 不重命名（REWRITE 模式约束，见 §1.4）
> - `static`/内部函数 → 可按本节规范改为 `camelCase`

### 2.2 类型与错误处理

- 公共接口优先使用 `<stdint.h>`、`<stdbool.h>`、`<stddef.h>`；默认 `uint8_t` / `uint16_t` / `uint32_t`、`int32_t`、`bool`
- 不把 `int`、`char`、`long` 作为默认跨平台接口类型
- **指针参数的 `const` 契约**：输入型指针（函数只读不写）必须加 `const`；输出型指针不加。这是 API 自文档化的关键手段：
  ```c
  /* ✅ buf 只读输入 → const；len 为非指针值参 → 不加 const */
  embedded_code_status_t uartSend(const uint8_t *buf, uint16_t len);
  /* ✅ handle 为读写输出 → 不加 const */
  embedded_code_status_t uartInit(uart_handle_t *handle);
  /* ❌ 输入指针缺 const — 调用方无法确定 buf 是否会被修改 */
  embedded_code_status_t uartSend(uint8_t *buf, uint16_t len);
  ```

项目没有既有 status 类型时，公共函数默认返回 `embedded_code_status_t`：

```c
typedef enum {
    EMBED_CODE_OK              =  0,
    EMBED_CODE_ERR_NULL_PTR    = -1,
    EMBED_CODE_ERR_INVALID_ARG = -2,
    EMBED_CODE_ERR_TIMEOUT     = -3,
    EMBED_CODE_ERR_BUSY        = -4,
    EMBED_CODE_ERR_NOT_INIT    = -5,
} embedded_code_status_t;

#define VALIDATE_NOT_NULL(ptr) \
    do { if ((ptr) == NULL) return EMBED_CODE_ERR_NULL_PTR; } while (0)

#define VALIDATE_INIT(handle) \
    do { if (!(handle) || !(handle)->initialized) return EMBED_CODE_ERR_NOT_INIT; } while (0)
/* VALIDATE_INIT 仅适用于含 initialized 字段的句柄（如 drv 句柄，见 §2.3.1） */
```

### 2.3 数据结构

重写或修改时：状态/错误/标志 → `enum`；配置/上下文 → `struct`；>3 标量参数 → 结构体指针；位域用 `MASK` 宏，禁裸魔数。

### 2.3.1 结构体模式

默认拆成配置、驱动层句柄和应用层句柄（与 §4.3 表一致）；config 由调用方填充，Init 时以 `const` 指针独立传入（见 §2.4.2），不嵌入句柄：

```c
/* 配置：Init 时以 const 指针传入 */
typedef struct {
    uint32_t base_address;
    uint32_t baud_rate;
} uart_config_t;

/* 驱动层句柄：寄存器入口 + ISR 回调（对应 §4.3 drv handle 列） */
typedef struct {
    uart_reg_t *regs;                  /* 寄存器入口；多实例时各实例绑定不同基址 */
    void (*rx_callback)(uint8_t byte); /* ISR → 应用层回调 */
    void (*tx_callback)(void);
    bool initialized;
} uart_drv_handle_t;

/* 应用层句柄：缓冲区与队列状态（对应 §4.3 app handle 列） */
typedef struct {
    uint8_t           *rx_buffer;
    volatile uint16_t  rx_head;     /* ISR 写入位置，主循环读取 */
    volatile uint16_t  rx_tail;     /* 主循环写入位置，ISR 读取 */
    volatile bool      tx_busy;
    uart_drv_handle_t *drv_handle;
} uart_handle_t;
```

状态枚举命名与格式示例见 §2.6.3。

### 2.4 注释

#### 2.4.1 注释原则

- 注释语言遵循项目约定；项目无约定时可用中文或用户指定语言。
- 注释解释硬件原因、约束、时序和意图；不要逐行复述代码。
- 注释应回答"为什么"而非"是什么"——代码本身说明"是什么"，注释补充"为什么这样写"。
- 保持注释与代码同步更新；过时注释比无注释更有害。
- **寄存器层注释要详细**：每个寄存器必须标注偏移地址 `/* 0xNN */`、位域含义 `bit[n]=功能`、读写属性。底层代码是硬件交互的唯一依据，注释不够详细会导致后续维护者误操作。
- **应用层注释侧重意图**：说明业务目的、调用约束、错误处理策略，不需要重复底层已有的位域信息。

#### 2.4.2 必须注释的场景

| 场景 | 说明 | 示例 |
|------|------|------|
| **操作步骤** | 驱动层和应用层函数体内的关键步骤用编号注释标注操作顺序（P2 级） | 见下方示例 |
| 硬件约束 | 寄存器写入顺序、时序要求、errata workaround | `/* 必须先写 CTRL 再写 DATA，否则 FIFO 错位（Errata 3.2） */` |
| 非显而易见的逻辑 | 算法选择原因、特殊边界处理 | `/* 使用查表法而非计算，节省 12 个 CPU 周期 */` |
| 临时方案 | workaround、TODO、待确认项 | `/* FIXME: 临时绕过芯片 Rev.A 的 DMA 冻结问题 */` |
| 安全关键路径 | 看门狗刷新点、冗余检查、故障注入点 | `/* 喂狗必须在 SPI 传输完成后，否则超时复位 */` |
| 并发/中断相关 | critical section、屏障、volatile 使用原因 | `/* 关中断保护 tx_tail，ISR 中会修改 */` |
| 魔数来源 | 非自明的常量值来源 | `/* 1200 = 72MHz / (16 * 3750)，参考手册 §23.4.2 */` |

**操作步骤注释要求（驱动层 + 应用层均适用，P2 风格级；）：**

驱动层函数和应用层函数体内，每个关键操作步骤用编号注释标注，让读者不用看手册也能理解操作流程：

```c
embedded_code_status_t uartDrvInit(uart_drv_handle_t *p_handle, const uart_config_t *p_config)
{
    /* Step 1: 参数校验（baud_rate 为 0 会在 calcBaudDivider 中除零） */
    VALIDATE_NOT_NULL(p_handle);
    VALIDATE_NOT_NULL(p_config);
    if (p_config->baud_rate == 0U) { return EMBED_CODE_ERR_INVALID_ARG; }

    /* Step 2: 禁用 UART，避免配置过程中产生意外中断 */
    uartLlDisable(p_handle->regs);

    /* Step 3: 配置波特率（值来自参考手册 §23.4.2 公式） */
    uartLlSetBaudDiv(p_handle->regs, calcBaudDivider(p_config->baud_rate));

    /* Step 4: 等待波特率发生器稳定（≥2 个 PCLK 周期） */
    for (volatile uint32_t i = 0U; i < UART_BAUD_SETTLE_CYCLES; i++) { __NOP(); }

    /* Step 5: 使能外设，标记初始化完成 */
    uartLlEnable(p_handle->regs);
    p_handle->initialized = true;
    return EMBED_CODE_OK;
}
```

应用层同理：`Step 1: 参数校验` → `Step 2: 填充驱动配置` → `Step 3: 调用驱动层` → `Step 4: 初始化缓冲区和状态`。

#### 2.4.3 注释格式

**函数注释**：

| 函数类型 | 注释位置 | 格式 | 说明 |
|---------|---------|------|------|
| 公共 API | **`.h` 声明处** | Doxygen `@brief/@param/@return/@note` | 唯一文档源，`.c` 定义处不重复 |
| 公共 API 的 `.c` 定义 | `.c` 实现处 | 仅简要行注释（如有非显而易见逻辑） | 解释"如何做"而非"做什么" |
| `static` 函数 | `.c` 定义处 | Doxygen 或简要注释 | 无 `.h` 声明，注释必须写在定义处 |

**为什么 `.c` 不重复 Doxygen 注释**：双重维护必然漂移——修改实现时容易只改一处，另一处过时。`.h` 是 API 合约，一处更新，调用方和实现方同步可见。

```c
/* ===== uart_drv.h ===== */
#ifndef UART_DRV_H
#define UART_DRV_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief  初始化 UART 外设并配置波特率
 * @param  p_handle  UART 驱动句柄指针
 * @param  p_config  配置指针（波特率支持 9600 / 115200 / 921600）
 * @return EMBED_CODE_OK 成功；EMBED_CODE_ERR_NULL_PTR 指针为空；
 *         EMBED_CODE_ERR_INVALID_ARG 波特率不支持
 * @note   调用前需确保 GPIO 已配置为 AF 模式
 */
embedded_code_status_t uartDrvInit(uart_drv_handle_t *p_handle, const uart_config_t *p_config);

#ifdef __cplusplus
}
#endif

#endif /* UART_DRV_H */

/* ===== uart_drv.c ===== */
/* （公共 API 不重复 Doxygen 注释，函数体内用 Step 注释标注关键步骤，见 2.4.2 节） */
embedded_code_status_t uartDrvInit(uart_drv_handle_t *p_handle, const uart_config_t *p_config)
{
    /* Step 1: 参数校验（baud_rate 为 0 会在 calcBaudDivider 中除零） */
    VALIDATE_NOT_NULL(p_handle);
    VALIDATE_NOT_NULL(p_config);
    if (p_config->baud_rate == 0U) { return EMBED_CODE_ERR_INVALID_ARG; }

    /* Step 2: 先关使能再配置，防止 FIFO 残留数据导致错位 */
    uartLlDisable(p_handle->regs);

    /* Step 3: 配置波特率 */
    uartLlSetBaudDiv(p_handle->regs, calcBaudDivider(p_config->baud_rate));

    /* Step 4: 等待波特率发生器稳定（≥2 个 PCLK 周期） */
    for (volatile uint32_t i = 0U; i < UART_BAUD_SETTLE_CYCLES; i++) { __NOP(); }

    /* Step 5: 使能外设，标记初始化完成 */
    uartLlEnable(p_handle->regs);
    p_handle->initialized = true;
    return EMBED_CODE_OK;
}

/* ===== uart_drv.c（static 函数必须有注释，无 .h 声明） ===== */
#define UART_BAUD_OVERSAMPLING  (16U)   /* 过采样倍数，来自手册分频公式 */

/**
 * @brief  计算波特率分频值
 * @param  target_baud 目标波特率
 * @return 分频寄存器写入值
 * @note   公式：DIV = PCLK / (UART_BAUD_OVERSAMPLING × target_baud)，PCLK 为 PLACEHOLDER，以项目时钟配置为准
 */
static uint32_t calcBaudDivider(uint32_t target_baud)
{
    return (SYSTEM_PCLK / (UART_BAUD_OVERSAMPLING * target_baud));
}
```

**内联注释**：关键行上方或同行，解释原因而非复述代码。

```c
/* 等待发送完成，超时防止硬件死锁 */
uint32_t timeout = UART_TX_TIMEOUT_MS;
while (!(uartLlGetStatus(UART1_REG) & UART_STATUS_TX_EMPTY_MASK) && --timeout) {
}
```

**结构体注释**：

```c
typedef struct {
    uint8_t *rx_buffer;     /* 应用层分配，驱动层不管理生命周期 */
    volatile uint16_t rx_head;       /* ISR 写入位置，主循环只读 */
    volatile bool tx_busy;  /* ISR 在发送完成时清零 */
} uart_handle_t;
```

**寄存器注释**：

```c
typedef struct uart_reg_t {
    volatile uint32_t CTRL;          /* 0x00 控制寄存器：bit[0]=EN, bit[2:1]=MODE, bit[4]=IE */
    const  uint32_t RESERVED0[3];    /* 0x04~0x0C 保留，禁止访问 */
    const  volatile uint32_t STATUS; /* 0x10 状态寄存器：只读，bit[0]=TX_EMPTY, bit[1]=RX_FULL */
    volatile uint32_t DATA;          /* 0x14 数据寄存器：写=TX FIFO，读=RX FIFO */
    volatile uint32_t BAUD;          /* 0x18 波特率寄存器：BAUD = PCLK / (16 × target_rate) */
} uart_reg_t;
```

**宏定义注释**:

```c
/* ===== 常量 / 位域 —— 行尾注释 ===== */
#define UART_RX_FIFO_SIZE    64U                  /* FIFO 深度（字节） */
#define TIMER_PRESCALER      84U                  /* PCLK=84MHz → 1MHz 计数 */
#define UART_CTRL_EN         BIT(0)               /* 使能位 */
#define UART_CTRL_MODE_MASK  (0x3UL << 1)         /* 模式[2:1]掩码 */
```

#### 2.4.4 文件头注释

**所有 `.c` 和 `.h` 文件使用统一 Doxygen 风格文件头注释（P2 风格级；）。**

- **`.h`** 重点描述模块接口和调用约束
- **`.c`** 重点描述实现方式、硬件依赖和运行限制

```c
/**
 * @file    dma.c
 *
 * @brief   [Driver] DMA控制器驱动：
 *          通道配置、链表传输、中断处理
 *
 * @author  Embedded Team
 * @date    2026-07-12
 *
 * @hardware Synopsys DW_ahb_dmac
 *
 * @depends dma_reg.h
 *
 * @note    本文件运行于裸机环境
 * @note    ISR上下文禁止调用阻塞接口
 */
```

**字段说明**：

| 字段 | `.c` | `.h` | 说明 |
|------|------|------|------|
| `@file` | ✅ 必填 | ✅ 必填 | 文件名，与文件系统中的名称一致 |
| `@brief` | ✅ 必填 | ✅ 必填 | 文件职责描述，**前缀标注所属分层**（见下方分层前缀），第二行补充核心功能要点 |
| `@author` | ✅ 必填 | ✅ 必填 | 创建者或团队名，项目统一后不再变更 |
| `@date` | ✅ 必填 | ✅ 必填 | 文件创建日期 `YYYY-MM-DD`；重大重构时可追加 `@date 2026-07-12，重构 2026-08-01`，不覆盖原始日期 |
| `@hardware` | ✅ `.c` 必填 | ❌ 不适用 | 本文件操作的硬件 IP 核型号（如 `ARM PL011`、`Synopsys DW_apb_uart`），`.h` 仅声明接口不写；纯软件模块（协议解析、ring buffer 等无直接硬件操作）填 `N/A（纯软件模块）` |
| `@depends` | 建议 | 建议 | 本文件直接依赖的头文件或模块，用于快速定位编译/链接依赖 |
| `@note` | 实现方式、硬件依赖、运行限制 | 调用约束 | `.h` 写调用前提和限制；`.c` 写实现要点、裸机/RTOS 环境、ISR 约束，可多条 |

**`@brief` 分层前缀**（必须四选一）：

| 前缀 | 适用文件 | 示例 |
|------|---------|------|
| `[Register]` | `*_reg.h` | `[Register] UART寄存器定义：控制、状态、数据寄存器` |
| `[LowLevel]` | `*_ll.h` / `*_ll.c` | `[LowLevel] UART寄存器访问：使能、波特率配置、标志清除` |
| `[Driver]` | `*_drv.h` / `*_drv.c` | `[Driver] SPI驱动层：初始化、传输、中断处理` |
| `[Application]` | `*.h` / `*.c`（非 reg/ll/drv） | `[Application] 串口协议解析：帧同步、超时管理` |

### 2.5 头文件包含规范

#### 2.5.1 Include What You Use

**每个 `.c` / `.h` 文件必须显式包含自身直接使用的符号所对应的头文件，不依赖传递包含，不保留不再使用的 `#include`。**

| 规则 | 说明 |
|------|------|
| 自包含 | 每个头文件独立可编译 — 若 `a.h` 使用了 `uint32_t`，自身必须 `#include <stdint.h>` |
| 直接包含 | 使用 `UART_HandleTypeDef` 则必须包含其定义所在头文件，不依赖其他头文件的传递 |
| 最小化 | 头文件只包含接口必须的类型，实现细节的依赖放在 `.c` 中 |
| 无冗余 | 删除不再使用的 `#include` — 重构或功能移除时同步清理 |
| 无循环 | 通过前置声明解循环依赖（include guard 只防重复包含，不能解循环依赖） |

#### 2.5.2 Include 顺序

项目无既有约定时，按以下顺序分组，组间空行分隔：

```c
/* 1. 自身头文件（.c 包含自己的 .h，验证自包含） */
#include "uart_drv.h"

/* 2. 项目内头文件（按模块依赖层级，低层在前） */
#include "uart_reg.h"
#include "gpio_drv.h"

/* 3. 厂商 / 第三方头文件 */
#include "stm32f4xx_hal.h"

/* 4. C 标准库头文件 */
#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
```

#### 2.5.3 头文件中减少包含

头文件中优先使用**前置声明**，将 `#include` 推迟到 `.c`：

```c
/* ===== uart_drv.h ===== */
#ifndef UART_DRV_H
#define UART_DRV_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>       /* 接口用到 uint32_t → 必须包含 */
#include <stdbool.h>      /* 接口用到 bool → 必须包含 */

/* 前置声明 — 代替 #include "uart_reg.h" */
typedef struct uart_reg_t uart_reg_t;   /* 指针参数只需前置声明 */

typedef struct {
    uart_reg_t *regs;                  /* 指针，前置声明足够 */
    void (*rx_callback)(uint8_t byte); /* 函数指针 */
} uart_drv_handle_t;

#ifdef __cplusplus
}
#endif

#endif /* UART_DRV_H */

/* ===== uart_ll.c ===== */
#include "uart_ll.h"
#include "uart_reg.h"   /* ll 访问寄存器成员，这里才需要完整定义 */
```

**前置声明适用条件**：头文件仅将类型用作指针或引用（函数参数、结构体成员指针），不访问其成员、不计算 `sizeof`。

#### 2.5.4 Include guard 与 extern "C"

- 每个 `.h` 必须有 include guard，命名为文件名大写、点替换为下划线（`uart_drv.h` → `UART_DRV_H`）。
- 公共 `.h` 用 `#ifdef __cplusplus` / `extern "C"` 包裹全部声明，保证 C++ 调用方可直接包含。

```c
#ifndef UART_DRV_H
#define UART_DRV_H

#ifdef __cplusplus
extern "C" {
#endif

/* 类型与函数声明 ... */

#ifdef __cplusplus
}
#endif

#endif /* UART_DRV_H */
```

---

### 2.6 枚举规范

#### 2.6.1 优先枚举，其次宏

**互相关联的整型常量集合，必须使用 `typedef enum` 定义命名类型，禁止用一堆 `#define` 替代。枚举提供类型安全、IDE 补全和调试器可读性。**

#### 2.6.2 枚举 vs `#define` 的适用场景

| 场景 | 用枚举 | 用 `#define` | 说明 |
|------|--------|-------------|------|
| 状态机状态 | ✅ | ❌ | `UART_STATE_IDLE` 等，调试器可显示符号名 |
| 错误码 | ✅ | ❌ | 枚举值可逐步扩展，不破坏 ABI |
| 外设模式选择 | ✅ | ❌ | `SPI_MODE_0/1/2/3`、`GPIO_MODE_INPUT` 等 |
| 配置选项 | ✅ | ❌ | `DMA_DIR_PERIPH_TO_MEM` 等互斥选项 |
| 寄存器位掩码 | ❌ | ✅ | 位宽和移位需精确定义，`(3U << 2)` 形式 |
| 基地址/时钟频率 | ❌ | ✅ | 单个独立常量，非互相关联的集合 |
| 数组大小/buffer 长度 | ❌ | ✅ | 用于 `uint8_t buf[MAX_SIZE]`；数组长度惯例用宏，避免与状态枚举混用 |

**判断标准**：如果一组常量在逻辑上属于同一"种类"（state / mode / error / speed / direction），用枚举；如果各自独立（地址 / 掩码 / 超时值），用宏。

#### 2.6.3 命名与格式

沿用 2.1 节命名规范：类型 `snake_case_t`，值 `PREFIXED_SNAKE`。

```c
/* 类型名：外设前缀 + 含义 + _t */
typedef enum {
    UART_STATE_IDLE      = 0,   /* 显式赋值，值有意义时不可省略 */
    UART_STATE_TX_BUSY   = 1,
    UART_STATE_RX_ACTIVE = 2,
    UART_STATE_ERROR     = 3,
} uart_state_t;

/* 函数签名使用枚举类型，不用 int/uint32_t */
uart_state_t uartGetState(uart_handle_t *handle);
```

#### 2.6.4 显式赋值规则

| 情况 | 规则 | 示例 |
|------|------|------|
| 硬件定义的值（寄存器位段、datasheet 规定） | **必须**显式赋值 | `SPI_MODE_0 = 0, SPI_MODE_1 = 1` |
| 错误码（跨模块、可能持久化） | **必须**显式赋值 | `ERR_TIMEOUT = -3` |
| 通信协议中的命令/类型码 | **必须**显式赋值 | `CMD_PING = 0x01, CMD_READ = 0x02` |
| 纯软件内部序列（状态机、流程步骤） | 可自增，首个建议显式 `= 0` | `STATE_IDLE = 0, STATE_BUSY, STATE_DONE` |

**switch 覆盖**：`switch` 枚举变量时覆盖所有枚举值；是否加 `default` 视项目 MISRA 要求。

---

### 2.7 静态作用域（static）规范

#### 2.7.1 默认 static，公开例外

**所有仅在当前 `.c` 内使用的函数和全局变量必须声明为 `static`。** 在 C 语言缺乏命名空间和访问控制的前提下，`static` 是实现模块封装的一等机制——限制符号可见范围、防止跨模块命名冲突、告知编译器可以进行更激进的内联优化。

**只有模块公共 API（`.h` 中声明的函数和全局变量）不加 `static`。**

#### 2.7.2 static 适用范围

| 对象 | 规则 | 示例 |
|------|------|------|
| **内部辅助函数** | **必须** `static` | 寄存器位操作 helper、校验函数、查表函数 |
| **向量表入口 ISR** | **必须** `static` | `static void UART_IRQHandler(void)` — 仅由中断向量表引用 |
| **DMA/回调函数** | **必须** `static` | `static void dmaTxComplete(void)` — 仅注册为回调 |
| **文件级全局变量** | **必须** `static` | `static uart_handle_t g_uart1_handle` — 模块私有状态 |
| **查找表 / 常量数据** | **必须** `static const` | `static const uint16_t baud_div_table[]` — 编译期只读 |
| **函数内持久状态** | **建议** `static` 局部 | `static bool first_init_done = false` — 单次初始化标记；多实例函数禁止用 static 局部保存实例状态 |
| **公共 API 函数** | **禁止**加 `static` | `.h` 中声明的接口函数 |
| **公共全局变量** | **禁止**加 `static` | `.h` 中 `extern` 声明的 `g_xxx` |

**ISR 两级模式**：向量表入口函数（如 `UART_IRQHandler`）加 `static`，仅被向量表引用；驱动层公共中断处理函数 `xxxDrvIRQHandler`（见 §4.2）**不加** `static`——入口函数调用它，应用层也可手动触发。

#### 2.7.3 四层架构中的 static 应用

结合第 4 节四层七文件架构，`static` 的分布如下：

```c
/* ===== module_reg.h ===== */
/* 无函数，不含 static */

/* ===== module_ll.h ===== */
/* 寄存器访问函数声明（公共，不加 static；单步访问可 static inline 放头文件） */
void uartLlEnable(uart_reg_t *regs);
uint32_t uartLlGetStatus(const uart_reg_t *regs);

/* ===== module_ll.c ===== */
static void waitFifoDrain(uart_reg_t *regs);  /* static：ll 内部多步序列 helper */

/* ===== module_drv.h ===== */
/* 仅声明公共 API，不加 static */
embedded_code_status_t uartDrvInit(uart_drv_handle_t *h, const uart_config_t *p_config);
embedded_code_status_t uartDrvSendByte(uint8_t byte);
void uartDrvIRQHandler(void);    /* 公共：应用层可能需手动触发中断处理（ISR 处理函数无返回值，为错误码规则的有意例外） */

/* ===== module_drv.c ===== */
static void txIsrCallback(void);        /* static：仅 ISR 内调用 */

static uart_drv_handle_t g_uart1_drv;   /* static：模块私有驱动句柄 */
static volatile bool g_tx_done;         /* static：模块私有传输标志 */

/* （公共 API 实现，不加 static；寄存器访问一律经 module_ll.h 函数） */
embedded_code_status_t uartDrvInit(uart_drv_handle_t *h, const uart_config_t *p_config) { /* ... */ }

/* ===== module.h ===== */
embedded_code_status_t uartInit(uart_handle_t *handle, const uart_config_t *p_config);  /* 公共 API */
embedded_code_status_t uartSend(const uint8_t *buf, uint16_t len);

/* ===== module.c ===== */
static bool validateBaud(uint32_t baud); /* static：内部校验 */
static void ringBufPush(uint8_t byte);   /* static：环形缓冲区操作 */

static uint8_t g_rx_ring_buf[256];       /* static：模块私有缓冲区 */
```

---

### 2.8 魔数规范

#### 2.8.1 拒绝裸字面量

**除 `0` 和 `1` 外，所有字面量必须定义为命名常量。** 裸数字在代码中无法表达含义，修改时需逐个查找替换，极易遗漏。

| 例外 | 示例 | 说明 |
|------|------|------|
| `0` | `memset(buf, 0, len)`, `flag = 0` | 清零/初始化语义自明 |
| `1` | `for (i = 1; i < n; i++)`, `addr + 1` | 循环步进、相邻地址等自明场景 |
| `0`/`1` 在寄存器位操作中 | `(1U << 3)` | 移位量允许直接写，但掩码本身必须命名 |
| 常量定义语句内部 | `#define UART_CTRL_MODE_MASK (3U << 1)` 中的 `3U`、`1` | 定义语句内的字面量即命名行为本身，豁免 |

其余所有字面量——寄存器复位值、超时毫秒数、数组大小、波特率分频系数、协议命令码——都必须命名。

#### 2.8.2 常量定义位置

| 常量类型 | 定义位置 | 示例 |
|---------|---------|------|
| 寄存器位掩码/移位 | `*_reg.h` | `#define UART_CTRL_EN_MASK (1U << 0)` |
| 外设基地址 | `*_reg.h` | `#define UART1_BASE_ADDR (0x40001000U)` |
| 超时/重试/缓冲区大小 | 使用该常量的 `.c` 顶部 | `#define UART_TX_TIMEOUT_MS (100U)` |
| 模块共用的配置常量 | 对应 `.h` 中 | `#define UART_MAX_BAUD (921600U)` |

---

### 2.9 宏定义安全规范

#### 2.9.1 宏 vs 内联函数的选择

| 场景 | 用宏 | 用 `static inline` 函数 |
|------|------|------------------------|
| 寄存器位操作、MASK/SHIFT 拼接 | ✅ 需要 `##` 拼接 | ❌ |
| 简单数学运算、类型转换 | 可以 | ✅ 有类型检查，优先 |
| 多语句逻辑（含分支/循环） | ❌ 极易出错 | ✅ 必须 |
| 需要返回值的复杂表达式 | ❌ 副作用风险 | ✅ |

**原则**：能用 `static inline` 就不用宏。宏仅用于字符串化（`#`）、拼接（`##`）、编译期常量。

#### 2.9.2 宏定义安全规则

```c
/* ✅ 规则1：多语句宏用 do-while(0) 包裹 */
#define VALIDATE_NOT_NULL(ptr) \
    do { if ((ptr) == NULL) return EMBED_CODE_ERR_NULL_PTR; } while (0)

/* ✅ 规则2：所有参数必须加括号；位域宏传 base 名，宏内拼接 _MASK/_SHIFT */
#define REG_SET_BITS(reg, base, value) \
    ((reg) = (((reg) & ~(base##_MASK)) | \
              (((uint32_t)(value) << (base##_SHIFT)) & (base##_MASK))))
#define REG_GET_BITS(reg, base) \
    (((reg) & (base##_MASK)) >> (base##_SHIFT))
/* 用法：REG_SET_BITS(UART1_REG->CTRL, UART_CTRL_MODE, 2U)
   展开引用 UART_CTRL_MODE_MASK / UART_CTRL_MODE_SHIFT，与 §3.2 命名一致 */

/* ✅ 规则3：整体表达式加括号（作为值使用时安全） */
#define MAX(a, b)  (((a) > (b)) ? (a) : (b))

/* ❌ 禁止：无保护的宏 */
#define ADD(x, y)  x + y            /* ADD(1,2)*3 = 1+2*3 = 7，非 9 */
#define SQUARE(x)  (x * x)          /* SQUARE(i++) = i++ * i++，未定义行为 */
```

---

## 3. 寄存器抽象

### 3.1 强制规则：寄存器必须定义为结构体

**所有外设寄存器块必须以 `*_reg_t` 结构体形式定义，禁止将寄存器散落为独立的 `#define` 地址宏。**

| 要求 | 说明 |
|------|------|
| 一个外设一个 `*_reg.h` | 每个外设 block 独立一个头文件，仅含寄存器结构体、位定义宏、基地址宏，无 `.c` 无函数实现 |
| 结构体命名 `*_reg_t` | 如 `uart_reg_t`、`spi_reg_t`、`dma_reg_t` |
| 使用 `volatile uint32_t` 成员 | 所有寄存器成员必须 `volatile`，确保每次访问都真正读写硬件 |
| 只读寄存器加 `const` | 状态寄存器等只读寄存器声明为 `const volatile uint32_t`，编译期阻止误写 |
| reserved 区域显式填充 | 寄存器间的保留空间用 `const uint32_t RESERVED[n]` 占位，确保偏移正确 |
| 一个明确的基地址入口 | 单实例：通过 `*_REG` 宏或项目已有 wrapper 访问，不裸写地址转换；多实例外设（UART1/UART2…）：句柄内嵌 `regs` 指针（§4.3），Init 时按实例绑定基址 |
| 位字段用 `MASK/SHIFT` 宏 | 每个位域定义 `_MASK` 和 `_SHIFT` 宏，不写魔法数字 |

### 3.2 标准模板

```c
/* ===== 寄存器结构体 — 成员顺序 = 硬件地址升序 ===== */
/* 带 tag 定义，与 §2.5.3 前置声明 typedef struct uart_reg_t uart_reg_t; 兼容 */
typedef struct uart_reg_t {
    /* --- 0x00 --- */
    volatile uint32_t CTRL;          /* 控制寄存器：bit[0]=EN, bit[2:1]=MODE, bit[4]=IE */
    const    uint32_t RESERVED0[3];  /* 0x04~0x0C 保留，禁止访问 */
    /* --- 0x10 --- */
    const    volatile uint32_t STATUS;  /* 状态寄存器：只读，bit[0]=TX_EMPTY, bit[1]=RX_FULL */
    volatile uint32_t DATA;          /* 数据寄存器：写=TX FIFO，读=RX FIFO */
    volatile uint32_t BAUD;          /* 波特率寄存器：BAUD = PCLK / (16 × target_rate) */
} uart_reg_t;

/* ===== 基地址宏 — 来自芯片参考手册 ===== */
#define UART1_BASE_ADDR  (0x40001000U)  /* USER_PROVIDED: 以芯片手册 Memory Map 为准 */

/* ===== 寄存器入口 — 全局唯一访问点 ===== */
#define UART1_REG  ((uart_reg_t *)UART1_BASE_ADDR)

/* ===== 位定义宏 — CTRL 寄存器 ===== */
#define UART_CTRL_EN_MASK     (1U << 0)
#define UART_CTRL_EN_SHIFT    (0U)
#define UART_CTRL_MODE_MASK   (3U << 1)
#define UART_CTRL_MODE_SHIFT  (1U)
#define UART_CTRL_IE_MASK     (1U << 4)
#define UART_CTRL_IE_SHIFT    (4U)

/* ===== 位定义宏 — STATUS 寄存器 ===== */
#define UART_STATUS_TX_EMPTY_MASK  (1U << 0)
#define UART_STATUS_RX_FULL_MASK   (1U << 1)

/* ===== 寄存器操作 helper 宏（可选，放 _reg.h 尾部；实现与用法见 §2.9.2） ===== */
/* REG_SET_BITS(reg, base, value) / REG_GET_BITS(reg, base) — 传位域 base 名（如 UART_CTRL_MODE），宏内拼接 _MASK/_SHIFT */
```

### 3.3 结构体成员布局规范

1. **成员顺序**必须与硬件寄存器地址升序一致，偏移隐含在结构体布局中。
2. **reserved 区域**用 `const uint32_t RESERVEDn[count]` 显式占位，注释注明地址范围。
3. **只读寄存器**声明为 `const volatile uint32_t` — 只读约束由编译器在编译期检查。
4. **读写寄存器**声明为 `volatile uint32_t`。
5. **写-only 寄存器**声明为 `volatile uint32_t`（C 语言无 write-only 限定符，靠注释说明）。
6. **多字节访问**的寄存器组（如 64-bit timer counter）使用连续两个 `uint32_t` 成员，注释标注 low/high。
7. 若同一地址存在**读/写含义不同**的寄存器（如读=FIFO 数据，写=TX 数据），使用**单个成员**并注释说明读写语义（如 §3.2 的 `DATA`）；禁止用两个成员表示同一地址（结构体成员必占不同偏移），确需区分命名时使用 `union`。
8. **禁止 C 位域（bit-field）用于寄存器定义**：`struct { uint32_t enable : 1; }` 的位域布局（起始位、填充方向、跨字节行为）是编译器实现定义的，不可移植。硬件寄存器一律用 `MASK/SHIFT` 宏。

### 3.4 寄存器使用方式

```c
/* ✅ 正确：通过结构体访问（仅访问层 _ll.h/.c 内允许，见 §4.1） */
UART1_REG->CTRL |= UART_CTRL_EN_MASK;
uint32_t status = UART1_REG->STATUS;
UART1_REG->DATA = tx_byte;
```

### 3.5 复用 vendor/CMSIS 已有结构体的例外

若项目已使用 CMSIS 或厂商 SDK 提供的寄存器结构体（如 `USART_TypeDef`、`SPI_TypeDef`），则**直接复用**，不再自定义 `*_reg_t`。此时只需补充：
- 缺失的位定义 `MASK/SHIFT` 宏
- 寄存器入口宏 `*_REG`（若 SDK 未提供）

```c
/* 复用 STM32 CMSIS 结构体，仅补充位定义 */
#define UART_SR_RXNE_MASK   USART_SR_RXNE
#define UART_REG            (USART1)
```

**不可既自定义结构体又同时用裸地址宏来描述同一外设的寄存器。**

---

## 4. 驱动模板

模板仅示组织方式；offset/reset/errata 须来自目标资料。四层七文件：reg（纯定义）→ ll（寄存器访问）→ drv（时序/ISR/DMA）→ app（缓冲/协议/API）。

> **`module/` 子目录为示范性组织方式，非编译硬约束**。平铺项目不建 `module/` 子目录，但七文件照样建齐，直接平铺在现有目录（见 §1.2-6）。四层隔离标准对平铺与带子目录项目一致。

### 4.1 统一结构

```text
module/
├── module_reg.h    # 寄存器结构体、位定义、基地址宏 — 无 .c，无函数实现
├── module_ll.h     # 访问层：寄存器访问函数声明（单步访问可 static inline）
├── module_ll.c     # 访问层：多步访问序列（清标志/读 FIFO/barrier/回读）
├── module_drv.h    # 驱动层：时序编排、ISR、DMA — 经 ll 访问硬件，不直触寄存器结构体
├── module_drv.c
├── module.h        # 应用层：缓冲管理、协议处理、对外 API — 不直写寄存器、不含 ISR
└── module.c
```

调用链：应用层 → 驱动层 → 访问层 → 寄存器层。驱动层 ISR 通过函数指针回调通知应用层，不直接操作 ring buffer。

> **ll/drv 边界**：ll 回答"怎么读写"——无状态、无逻辑决策，barrier/回读/多步序列只许出现在此；drv 回答"何时读写、按什么顺序"（时序、状态机、ISR、DMA）。

### 4.2 接口模板

| 模块 | 驱动层 (`_drv.h`) | 应用层 (`.h`) |
|------|-------------------|---------------|
| UART | `uartDrvInit/DeInit/SendByte/RecvByte/EnableIRQ/RegisterCallbacks/StartDmaTx/StartDmaRx/IRQHandler` | `uartInit/DeInit/Send/Recv/SendIT/RecvIT/SendDMA/RecvDMA` |
| SPI | `spiDrvInit/Transfer/SetCS/EnableIRQ/RegisterCallback/StartDmaTransfer/IRQHandler` | `spiInit/Transfer/SelectCS/TransferIT/TransferDMA` |
| GPIO | `gpioDrvInit/WritePin/ReadPin/TogglePin/EnableIRQ/RegisterCallback/IRQHandler` | `gpioInit/WritePin/ReadPin/TogglePin/SetCallback` |
| DMA | `dmaDrvChannelInit/Start/Abort/IsComplete/IRQHandler` | `dmaChannelInit/StartTransfer/AbortTransfer/IsTransferComplete` |

**访问层接口（`_ll.h`）**：细粒度寄存器访问函数，命名 `xxxLlVerb`，如 `uartLlEnable/Disable/SetBaudDiv/WriteData/ReadData/ClearRxFlag/GetStatus`；无状态、不返回业务错误码（参数校验在 drv）。

app 的 IT/DMA 只编排缓冲与回调，委托 drv；drv 经 ll 访问硬件，不直触寄存器结构体。

**Init 模式（驱动层）**：经 ll 禁用外设 → 配置参数（值来自厂商或 PLACEHOLDER）→ 清挂起标志 → 使能 → 标记 initialized

**ISR 模式（驱动层）**：经 ll 读 STATUS → 按 mask 分支 → 回调通知应用层 → 经 ll 清中断标志 → 从不阻塞

### 4.3 关键结构

| 模块 | 寄存器 | 驱动层 handle | 应用层 handle |
|------|--------|--------------|--------------|
| UART | `DATA, STATUS, CTRL, BAUD` | `regs, rx/tx_callback` | `rx_buffer, rx_head, rx_tail, drv_handle` |
| SPI | `CTRL, STATUS, DATA, BAUD` | `regs, cs_callback` | `drv_handle` |
| I2C | `CTRL, STATUS, ADDR, DATA` | `regs, addr, direction` | `timeout, bus_state, drv_handle` |
| DMA | `GLOBAL_STATUS, ch[n].CTRL/SRC/DST/LEN` | `regs, channel_cfg[]` | `buffers[], drv_handle` |
| CAN | `CTRL, STATUS, BIT_TIMING, TX/RX_DATA` | `regs, bit_timing` | `can_msg_t{id,dlc,data[8]}, drv_handle` |
| GPIO | `MODE, INPUT/DATA, OUTPUT_DATA, BIT_SET_RESET` | `regs, pin_map` | `pin_callbacks[], gpio_mode_t, drv_handle` |
| Timer | `CTRL, COUNT, AUTO_RELOAD, PRESCALER` | `regs, prescaler, auto_reload` | `period, callback, drv_handle` |
| Watchdog | `KEY, RELOAD, STATUS` | `regs, key_reg` | `timeout_ms, drv_handle` |

访问层（ll）无状态、无句柄，不列入本表；其接口规范见 §4.2。

---

## 5. 架构规则

架构相关代码包括 ISR、barrier、DMA、cache、interrupt controller、memory ordering 和 board bring-up。

### 5.1 Quick Ref

| 架构 | Barrier | Interrupt | 代表芯片 |
|------|---------|-----------|---------|
| ARM Cortex-M | `__DMB()/__DSB()/__ISB()` | NVIC | STM32, GD32, NXP, RP2040 |
| RISC-V | `fence` | PLIC/CLINT | FE310, CH32V |
| ESP32 (Xtensa) | `esp_cpu_dsb()` | INT matrix | ESP32, S2/S3 |

**中断优先级**：多中断场景下，Init 函数中必须显式配置各中断优先级（具体数值与分组来自项目需求和手册），不依赖复位默认值。

> 其他架构（Cortex-A、PowerPC、SPARC）和平台细节（ESP32 IRAM_ATTR、nRF52 SoftDevice、RP2040 Pico SDK）仅在用户明确提及该芯片时才查阅对应文档，不在此展开。

### 5.2 未知架构处理

1. 根据芯片、工具链、vendor headers 和已有低层代码判断架构
2. 不确定时查官方文档或要求用户提供资料
3. 不能确认时，只给出架构无关的审查建议或保守改写，barrier/interrupt/cache maintenance 标成 placeholder
4. 不猜测 barrier、cache maintenance、DMA ownership、IRQ number 或 interrupt-controller 行为

---

## 6. RTOS 场景速查

裸机项目跳过本节。RTOS 项目仅在用户明确后才应用以下规则（不主动引入 RTOS 依赖）：

- **ISR 规则**：禁止阻塞（不调用 `osDelay`/`osMutexAcquire`），FreeRTOS 用 `...FromISR()` API，只做读状态→清标志→通知任务
- **数据共享**：任务间用互斥量，ISR→任务用队列，简单标志用 `<stdatomic.h>`
- **死锁预防**：固定锁顺序、超时替代无限等待、持锁不调阻塞 API
- **常用 RTOS**：FreeRTOS / Zephyr / RT-Thread 的 API 对照仅在用户指定 RTOS 时提供

---

## 7. 构建系统与链接

### 7.1 Linker Script 与 Startup

```
Reset_Handler：搬运 .data（Flash→RAM）→ 清零 .bss → SystemInit() → main()
```

MEMORY 中 FLASH 放 `.text`/`.rodata`，RAM 放 `.data`/`.bss`；`__data_start/end` 和 `__bss_start/end` 符号供 startup 引用。

### 7.2 编译器 Attribute

| 用途 | 写法 |
|------|------|
| 中断函数 | 以目标工具链文档为准（RISC-V 用 `__attribute__((interrupt))`；ARM 经向量表注册，无此 attribute） |
| 指定 section | `__attribute__((section(".dma_buf")))` |
| 对齐 | `__attribute__((aligned(32)))` |
| 弱符号 | `__attribute__((weak))` |
| 始终内联 | `__attribute__((always_inline))` |

### 7.3 构建工具

交叉编译 CMake 模板仅在用户使用 CMake 时提供（`CMAKE_SYSTEM_NAME Generic` + `arm-none-eabi-` toolchain）；Makefile/Keil/IAR 按项目现有构建系统沿用。

---

## 8. 内存、安全和并发默认值

- 驱动层与 ISR 禁用 `malloc/free/calloc/realloc`，禁 VLA（红线 ⑦）；缓冲区大小、timeout、retry count 使用命名常量
- ISR 与主循环共享的变量必须声明 `volatile`（并发可见性语义；区别于 §3.1 寄存器成员的硬件内存映射语义）
- DMA cache 一致性：DMA 写完后 CPU 读之前做 cache 失效；CPU 写完后 DMA 读之前做 cache 回写；DMA buffer 按 cache line 对齐
- critical section 要短、显式，沿用项目本地 helper
- ISR、DMA、cache coherency、volatile 和 memory ordering 必须保留硬件相关顺序
- 不发明 barrier、cache maintenance、DMA ownership 或 interrupt-controller 细节

---

## 9. 回查清单与维护自检

### 9.1 回查清单

> **执行规则**：
> - REWRITE：输出代码前，逐条过 P0 → P1 → P2，全部通过才输出（P2 项在项目有既定约定时从项目约定，视为通过；结构类 P1 让位规则见 §1.2 优先级裁决）。
> - REVIEW：按 P0 → P1 → P2 顺序检查，发现 P0 立即报告，不必等 P1/P2 完成。
> - GUIDE：不执行本清单。
> - 每条检查项标注对应规则章节，便于溯源。

---

#### P0 — 违反 = 硬件损坏 / 数据丢失 / 编译失败（与 §1.5 RED LINES 一一对应）

| # | 检查项 | 判定标准 | 规则来源 |
|---|--------|----------|----------|
| P0-1 | 不编造硬件事实 | 所有寄存器地址/位域/IRQ 号/barrier 指令/cache 操作/DMA 通道，均来自用户输入、仓库代码或标注 `USER_PROVIDED`/`PLACEHOLDER` | §1.5-①, §3 |
| P0-2 | 寄存器写入顺序正确 | REWRITE 保留原始初始化序列顺序；有时序依赖的写入顺序未被打乱 | §1.5-②, §1.4 |
| P0-3 | ISR 与主循环共享变量有 `volatile` | 所有被 ISR 写+主循环读（或反向）的变量声明处有 `volatile` | §1.5-③, §8 |
| P0-4 | ISR 无阻塞调用 | ISR 内无 delay/malloc/mutex/printf；RTOS 环境下仅用 ISR 安全 API（如 FreeRTOS 的 `...FromISR()` 变体） | §1.5-④, §6 |
| P0-5 | 输出可编译 | 类型名/枚举值/宏名拼写一致；宏展开后语法正确；函数签名与声明匹配 | §1.5-⑤ |
| P0-6 | 无裸寄存器地址 | 业务代码中无 `*(volatile uint32_t *)0x400xxxxx`；寄存器结构体成员访问集中在访问层 `_ll.h/.c`（自定义 `*_reg_t` 或复用 vendor/CMSIS 结构体，见 §3.5） | §1.5-⑥, §3.1 |
| P0-7 | 禁 malloc/VLA | 驱动层和 ISR 中无 `malloc`/`calloc`/`realloc`/`free`；无 VLA | §1.5-⑦, §8 |

---

#### P1 — 违反 = 并发 bug / 可移植性问题 / 架构腐化

| # | 检查项 | 判定标准 | 规则来源 |
|---|--------|----------|----------|
| P1-1 | 四层解耦 | 应用层不直写寄存器、不含 ISR；驱动层不含业务逻辑、不直触寄存器结构体（经 `_ll.h` 访问函数）；访问层（`_ll.h/.c`）无状态、无时序逻辑，barrier/回读/多步序列只出现在访问层；寄存器定义在 `module_reg.h` | §4.1, §4.2 |
| P1-2 | 寄存器结构体完整 | 每个外设寄存器块有 `*_reg_t` 结构体；`reserved` 区域占位；只读寄存器标 `const volatile` | §3.1, §3.3 |
| P1-3 | MASK/SHIFT 宏配对 | 每个可写位域有 `_MASK` 和 `_SHIFT` 两个宏；无 C 位域用于寄存器定义 | §3.2, §3.3 |
| P1-4 | 宏定义安全 | 所有宏参数加括号；多语句宏用 `do { } while(0)`；无 `##` 拼接歧义 | §2.9 |
| P1-5 | DMA cache 一致性 | DMA 写完后 CPU 读之前有 cache 失效；CPU 写完后 DMA 读之前有 cache 回写；DMA buffer 对齐 | §8 |
| P1-6 | 中断优先级已配置 | 多中断场景下 Init 函数中有优先级配置，不依赖复位默认值 | §5.1 |
| P1-7 | 公共接口类型安全 | 公共 API 参数和返回值无裸 `int`/`char`/`long`；使用 `uint32_t`/`int32_t`/`bool`/`size_t` | §2.2 |
| P1-8 | static 使用正确 | 内部函数和模块私有变量有 `static`；公共 API 无 `static`（向量表入口 ISR 除外，见 §2.7.2 两级模式）；多实例函数无 `static` 局部变量存实例状态 | §2.7 |
| P1-9 | 错误处理完整 | 所有公共 API 返回 `embedded_code_status_t`（ISR 入口/回调函数除外）；调用处检查返回值；错误路径有资源清理 | §2.2 |
| P1-10 | 无裸魔术数字 | 除 0/1 外所有字面量已提取为命名常量；常量定义位置正确 | §2.8 |

---

#### P2 — 违反 = 风格不一致 / 文档缺失

| # | 检查项 | 判定标准 | 规则来源 |
|---|--------|----------|----------|
| P2-1 | 函数命名 | 全部 `camelCase`（或项目约定的 `snake_case`），无混用 | §2.1 |
| P2-2 | 宏命名 | 全部 `UPPER_SNAKE_CASE`，无小写宏 | §2.1 |
| P2-3 | 类型命名 | 结构体/枚举 `xxx_t` 后缀；枚举值 `MODULE_STATE_XXX` 格式 | §2.1 |
| P2-4 | 变量命名 | 局部变量 `snake_case`；无单字母变量名（`i`/`j`/`k` 循环计数器除外） | §2.1 |
| P2-5 | 文件头注释 | 每个 `.c`/`.h` 有 `@brief`/`@author`/`@date` | §2.4.4 |
| P2-6 | include 规范 | 顺序：自身头 → 项目头 → 厂商/第三方头 → C 标准库；无冗余 include；include guard `MODULE_H` | §2.5.2, §2.5.4 |
| P2-7 | Step 注释 | 驱动层和应用层函数体内有 `/* Step N: ... */` 编号注释 | §2.4.2 |
| P2-8 | 枚举值显式赋值 | 硬件相关枚举值已显式赋值；switch(enum) 覆盖所有值（是否加 default 视项目 MISRA 要求） | §2.6.4 |
| P2-9 | 复用已有结构 | 若项目已有 vendor/CMSIS 寄存器结构体，不重复定义 | §3.5 |
| P2-10 | extern "C" 保护 | 公共 `.h` 有 `#ifdef __cplusplus` / `extern "C"` 包裹 | §2.5.4 |

### 9.2 维护自检

修改本 skill 后，用以下场景做 smoke check：

- `REVIEW`：优先指出 race/volatile/barrier/ownership 风险
- RTOS：共享数据有互斥保护，ISR 只用 ISR 安全 API
- 自洽：用本 skill 自身的示例代码过一遍 P0–P2 清单，必须全部通过
- 对齐：每条清单项可溯源到正文规则；正文每处"必须/禁"在清单中有对应检查项
- 领域：DO-178C/MIL-STD/IEC 61508/ISO 26262 只在用户明确时写合规结论

通过标准：不编造硬件事实、仓库代码符合本规范或在不改变逻辑前提下统一、子领域无丢失或矛盾。
