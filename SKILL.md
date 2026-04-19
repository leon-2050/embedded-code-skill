---
name: embedded-code-skill
description: "生成、重写或审查嵌入式 C 代码（驱动、寄存器抽象层、固件模块）。专注于：统一类型与命名规范、结构化寄存器抽象、完整的错误处理、可编译可审查的输出。适用于固件工程师日常使用或 CI 流程集成。"
user-invocable: true
---

# Embedded C 代码规范

## 定位

生成、重写、审查嵌入式 C 代码的**统一规范**。覆盖驱动、寄存器抽象层和固件模块。

**不替代芯片手册。** 真实寄存器偏移、位字段定义、时序参数必须查目标芯片参考手册，不得伪造。

## 输出契约

默认输出最小可维护模块：

```
module/
├── module_reg.h   # 寄存器结构体与位定义
├── module.h       # 公共接口
└── module.c       # 实现
```

仅 review 时，不生成文件，只输出问题、风险和修改建议。

## 生成前必须确认

| 信息 | 要求 | 示例 |
|------|------|------|
| 外设/模块名 | 必需 | `uart`, `spi`, `gpio` |
| 基地址 | 必需 | `UART_BASE_ADDR = 0x4000C000U` |
| 芯片或架构 | 强烈建议提供 | `STM32F4`, `Cortex-M4`, `RISC-V` |
| 参考手册来源 | 最佳实践 | RM 编号、寄存器表截图、现有头文件 |

**禁止伪造寄存器地址、位字段或 reset 值。** 缺少信息时，先指出缺口，再生成保守模板，不自行捏造。

## 规范核心

### 类型

- 仅使用 `<stdint.h>`, `<stdbool.h>`, `<stddef.h>`
- 公共接口：`uint8_t` / `uint16_t` / `uint32_t` / `int32_t` / `bool`
- 禁止 `int` / `char` / `long` 作为跨平台接口类型

### 命名

| 元素 | 规范 | 示例 |
|------|------|------|
| 变量 | `snake_case` | `rx_count` |
| 全局变量 | `g_snake_case` | `g_system_ticks` |
| 函数 | `camelCase` | `uartInit()` |
| 结构体类型 | `snake_case_t` | `uart_handle_t` |
| 枚举值 | `PREFIXED_SNAKE` | `UART_STATE_IDLE` |
| 常量/宏 | `SCREAMING_SNAKE` | `UART_SR_RX_READY_MASK` |

### 错误处理

所有 public 函数返回 `embedded_code_status_t`：

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

### 寄存器抽象

统一模式：`独立 *_reg.h` + `*_reg_t 结构体` + `*_REG 访问宏` + `MASK/SHIFT 位字段宏`：

```c
/* 寄存器文件示例（地址需按目标芯片手册替换） */
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

### 内存与安全

- 禁止 `malloc` / `free` / `calloc` / `realloc`
- 禁止 VLA
- 禁止寄存器赋值时写裸魔法数字
- 缓冲区大小使用命名常量

### 注释

- 注释语言跟随项目约定；无约定时使用中文
- 解释**原因和约束**，不重复代码字面含义
- Doxygen 文件头仅在确实有助于维护时添加

## 三种工作模式

### GENERATE

- 有足够硬件信息时，直接生成规范模块
- 信息不足时，先列出缺口，再生成保守模板
- 不编造未提供的寄存器细节

### REWRITE

**保留行为意图，不保留明显坏代码。**

执行步骤：
1. 理解原代码数据流、状态机、寄存器访问意图
2. 列出必须保留的外部行为
3. 按本规范重写类型、命名、文件组织和错误处理
4. 回查：行为是否一致、结果是否可编译

如有有意保留的 workaround，先标注，不自行决定保留或丢弃。

### REVIEW

按以下顺序逐项检查：

1. 类型和接口是否可移植
2. 寄存器访问方式是否统一（`*_reg.h` + `*_REG`）
3. 错误处理是否完整（返回值验证、参数校验）
4. 是否存在魔法数字和未命名位定义
5. 是否存在动态内存、VLA、不可移植关键字

输出具体问题和修改建议，不输出无实质内容的「整体良好」类评价。

## 回查清单

生成或重写完成后，逐项确认：

- [ ] 有独立的 `*_reg.h`
- [ ] 使用 `*_reg_t` + `*_REG` 模式
- [ ] 所有 public 函数返回 `embedded_code_status_t`
- [ ] 命名符合规范表
- [ ] 无 `malloc/free/VLA`
- [ ] 无裸寄存器地址散落在业务代码中
- [ ] 硬件常量来自用户输入或参考手册，不是自行编造
- [ ] REWRITE 结果保留行为意图且可编译

## 反例

```c
/* ❌ 寄存器地址散落、魔法数字无解释 */
#define SPI_CTRL_ADDR  (*(volatile uint32_t *)0xA0010000U)
void spiInit(void) { SPI_CTRL_ADDR = 0x47U; }

/* ✅ 统一结构体访问 + 命名常量 */
#include "spi_reg.h"
void spiInit(void) { SPI_REG->CTRL = SPI_CTRL_INIT_VAL; }
```

## 参考模块

| 模块 | 内容 |
|------|------|
| `embedded-code-skill-standards/` | 命名、类型、错误处理规范 |
| `embedded-code-skill-drivers/` | 外设模板（UART、SPI、I2C、GPIO 等） |
| `embedded-code-skill-arch/` | 架构差异、内存屏障、中断模式 |
| `embedded-code-skill-domains/` | 行业域约束（如车载、军工） |

## 评估流程

`.evolution/` 目录提供**人工执行的评估流程**：评分维度、抽样 prompts、结果记录格式。不包含自动打分或自动优化工具。
