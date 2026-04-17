---
name: embedded-code-skill
description: "Generate, rewrite, or review embedded C code for firmware, drivers, and low-level MCU/SoC modules. Use when the user needs production-oriented embedded C, driver skeletons, register abstractions, or code review against a consistent house style."
user-invocable: true
---

# Embedded C 代码规范

## 定位

本 skill 用于生成、重写、审查嵌入式 C 代码，适用于驱动、寄存器抽象层和低层固件模块。

它提供的是**统一规范和流程**，不是芯片厂商手册的替代品。任何真实寄存器偏移、位定义和时序要求，都必须以目标芯片的参考手册为准。

## 输出契约

默认输出一个最小可维护模块：

```text
module/
├── module_reg.h   # 寄存器结构体与位定义
├── module.h       # 公共接口
└── module.c       # 实现
```

当用户只要求 review 时，不生成新文件，只输出问题、风险和修改建议。

## 生成前必须确认的信息

| 信息 | 要求 | 示例 |
|------|------|------|
| 外设/模块名 | 必需 | `uart`, `spi`, `gpio` |
| 基地址 | 必需 | `UART_BASE_ADDR = 0x4000C000U` |
| 芯片或架构 | 强烈建议提供 | `STM32F4`, `Cortex-M4`, `RISC-V` |
| 参考手册来源 | 最佳实践 | RM 编号、寄存器表截图、现有头文件 |

**禁止**伪造寄存器地址、位字段和 reset 值。

## 规范核心

### 1. 类型

- 只使用 `<stdint.h>`, `<stdbool.h>`, `<stddef.h>`
- 公共接口优先使用 `uint8_t` / `uint16_t` / `uint32_t` / `int32_t` / `bool`
- 不把 `int`, `char`, `long` 作为默认跨平台接口类型

### 2. 命名

| 元素 | 规范 | 示例 |
|------|------|------|
| 变量 | `snake_case` | `rx_count` |
| 全局变量 | `g_snake_case` | `g_system_ticks` |
| 函数 | `camelCase` | `uartInit()` |
| 结构体类型 | `snake_case_t` | `uart_handle_t` |
| 枚举值 | `PREFIXED_SNAKE` | `UART_STATE_IDLE` |
| 常量/宏 | `SCREAMING_SNAKE` | `UART_SR_RX_READY_MASK` |

### 3. 错误处理

所有 public 函数默认返回 `embedded_code_status_t`：

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

### 4. 寄存器抽象

规范写法统一为：

- 每个模块单独提供 `*_reg.h`
- 用 `*_reg_t` 定义寄存器结构体
- 用一个 `*_REG` 宏提供访问入口
- 位字段使用 `MASK/SHIFT` 宏命名

示例：

```c
/* 示例仅演示结构，不代表真实芯片寄存器布局 */
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

### 5. 内存与安全编码

- 禁止 `malloc`, `free`, `calloc`, `realloc`
- 禁止 VLA
- 禁止在寄存器赋值时写裸魔法数字
- 缓冲区大小要有命名常量

### 6. 注释

- 注释语言遵循项目现有约定；如果项目无约定，可使用中文
- 注释解释**原因和约束**，不要重复代码字面含义
- Doxygen 文件头只在确实帮助维护时添加

## 三种工作模式

### GENERATE

- 根据已知硬件信息直接生成新模块
- 缺少关键硬件信息时先指出缺口，再生成保守模板
- 不假装知道未提供的数据手册细节

### REWRITE

核心原则：**保留行为意图，不保留明显坏代码**

- 先理解原代码的数据流、状态机、寄存器访问意图
- 默认修复语法错误、类型错误、空指针问题和明显的可编译性缺陷
- 如果代码里可能存在有意 workaround，先标注再决定是否保留
- 只有当用户明确要求“保持 bug 行为”时，才刻意保留该行为

执行步骤：

1. 归纳原代码行为和外设交互意图
2. 列出必须保留的外部行为
3. 按本规范重写类型、命名、文件组织和错误处理
4. 回查行为是否一致，且结果可编译、可审查

### REVIEW

默认按下面的顺序检查：

1. 类型和接口是否可移植
2. 寄存器访问方式是否统一
3. 错误处理是否完整
4. 是否存在魔法数字和未命名位定义
5. 是否存在动态内存、VLA、不可移植关键字

## 回查清单

- [ ] 是否有独立的 `*_reg.h`
- [ ] 是否使用 `*_reg_t` + `*_REG`
- [ ] 是否所有公共接口都返回 `embedded_code_status_t`
- [ ] 是否命名统一
- [ ] 是否无 `malloc/free/VLA`
- [ ] 是否无裸寄存器地址散落在业务代码中
- [ ] 是否所有硬件常量都来自用户输入或参考手册
- [ ] REWRITE 结果是否保留行为意图且可以编译

## 反例

```c
// ❌ 反例：寄存器地址散落、直接写魔法数字
#define SPI_CTRL_ADDR  (*(volatile uint32_t *)0xA0010000U)
void spiInit(void) { SPI_CTRL_ADDR = 0x47U; }

// ✅ 正例：统一结构体访问与命名常量
#include "spi_reg.h"
void spiInit(void) { SPI_REG->CTRL = SPI_CTRL_INIT_VAL; }
```

## 参考模块

- `embedded-code-skill-standards/`：命名、类型、错误处理
- `embedded-code-skill-drivers/`：外设模板
- `embedded-code-skill-arch/`：架构差异与屏障/中断模式
- `embedded-code-skill-domains/`：行业域约束

## 自我评估说明

`.evolution/` 目录提供的是**人工执行的评估与改进流程**，不是内置自动优化引擎。
