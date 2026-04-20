---
name: ecs
description: "生成、重写、审查嵌入式 C 代码。覆盖驱动、寄存器抽象层、固件模块。强制类型安全、寄存器抽象规范、完整错误处理、可编译可审查输出。禁止伪造硬件参数。"
user-invocable: true
---

# Embedded C 代码规范

## 定位

生成、重写、审查嵌入式 C 代码。适用于驱动、寄存器抽象层、固件模块。

**这不是芯片手册。** 寄存器偏移、位定义、时序参数必须查目标芯片手册。不得伪造。

## 输出格式

GENERATE / REWRITE 默认输出最小可维护模块：

```
module/
├── module_reg.h   # 寄存器结构体与位定义（仅存放硬件相关信息）
├── module.h       # 公共接口
└── module.c       # 实现
```

REVIEW 时不生成文件，只输出问题清单和修改建议。

## 前置确认

生成或重写前，必须明确以下信息：

| 信息 | 级别 | 说明 |
|------|------|------|
| 外设名 | 必需 | 如 `uart`、`spi`、`gpio` |
| 基地址 | 必需 | 形如 `0x4000C000U`，不得自行编造 |
| 芯片/架构 | 强烈建议 | 如 `STM32F4`、`Cortex-M4`、`RISC-V` |
| 手册来源 | 最佳实践 | RM 编号、截图、现有头文件均可 |

**信息不足时，先列出缺口，再生成保守模板。绝不自行捏造寄存器地址或位字段。**

## 类型规范

- 仅使用 `<stdint.h>`、`<stdbool.h>`、`<stddef.h>`
- 公共接口类型：`uint8_t` / `uint16_t` / `uint32_t` / `int32_t` / `bool`
- 禁止 `int` / `char` / `long` / `unsigned` 作为跨平台接口

## 命名规范

| 元素 | 规范 | 示例 |
|------|------|------|
| 变量 | `snake_case` | `rx_count` |
| 全局变量 | `g_snake_case` | `g_uart_state` |
| 函数 | `camelCase` | `uartInit()` |
| 结构体类型 | `snake_case_t` | `uart_handle_t` |
| 枚举值 | `PREFIXED_SNAKE` | `UART_STATE_IDLE` |
| 常量/宏 | `SCREAMING_SNAKE` | `UART_CTRL_EN_MASK` |
| 指针变量 | `p_snake_case` | `p_rx_buffer` |

## 错误处理

所有 public 函数必须返回 `embedded_code_status_t`：

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

## 寄存器抽象

**每模块必须有独立的 `*_reg.h`。** 禁止在业务代码中直接写寄存器地址。

模式：

```
独立 *_reg.h   ← 只含硬件相关信息
+ *_reg_t      ← 寄存器结构体
+ *_REG        ← 访问宏
+ MASK/SHIFT   ← 位字段宏（不得在业务代码中写裸值）
```

```c
/* ========== spi_reg.h ========== */
#define SPI_BASE_ADDR  (0xA0010000U)  /* 需替换为真实地址 */

typedef struct {
    volatile uint32_t CTRL;
    volatile uint32_t STATUS;
    volatile uint32_t DATA;
} spi_reg_t;

#define SPI_CTRL_EN_MASK     (1U << 0)
#define SPI_CTRL_MODE_MASK   (3U << 2)
#define SPI_STATUS_BUSY_MASK (1U << 0)

#define SPI_REG  ((spi_reg_t *)SPI_BASE_ADDR)
```

## 内存与安全

- **禁止**：`malloc` / `free` / `calloc` / `realloc` / VLA
- **禁止**：寄存器赋值时写裸魔法数字
- 缓冲区大小必须用命名常量

## 注释规范

- 注释语言跟随项目；无约定时用中文
- 注释解释**原因和约束**，不重复代码字面含义
- 不要写「设置寄存器」这种只换了个词的无意义注释

## 工作模式

### GENERATE

1. 核对前置确认表，信息不足时先列缺口
2. 按本规范生成 `*_reg.h` / `module.h` / `module.c`
3. 生成后逐项通过回查清单

### REWRITE

**保留行为意图，不保留明显坏代码。**

步骤：

1. 理解原代码的数据流、状态机、寄存器访问意图
2. 列出必须保留的外部行为（对外设的副作用、接口契约等）
3. 按本规范重写：类型、命名、文件组织、错误处理
4. 回查：行为是否一致，结果是否可编译

**如有有意保留的 workaround，先用 `/* 有意保留：原因 */` 标注，不自行决定丢弃。**

### REVIEW

按顺序检查：

1. 类型和接口是否可移植（无 `int` / `char` / `long` 在公共接口中）
2. 寄存器访问是否统一通过 `*_reg.h` + `*_REG`
3. 错误处理是否完整（返回值验证、参数校验）
4. 是否存在未命名位字段或魔法数字
5. 是否存在动态内存或 VLA

输出格式：每条问题列出**位置**（文件/函数）、**问题**、**建议修改**。

## 回查清单

```
□ 独立的 *_reg.h 存在，且仅含硬件相关信息
□ 使用 *_reg_t + *_REG 模式，无裸地址散落在外
□ 所有 public 函数返回 embedded_code_status_t
□ 命名符合规范表
□ 无 malloc/free/VLA
□ 无裸寄存器值在业务代码中（如 0x47U 直接写进寄存器）
□ 硬件常量来自用户输入或手册，不是自行编造
□ REWRITE 结果：行为意图保留 + 可编译 + 无新增警告
```

## RED LINES（绝对禁止）

1. **伪造寄存器地址或位字段**——不知道就说不知道
2. **生成包含 `malloc` 的嵌入式代码**
3. **用 `int` / `char` / `long` 作为公共接口参数类型**
4. **寄存器裸地址散落在业务代码**（不在 `*_reg.h` 中的 `*(volatile uint32_t *)0x...`）
5. **编译无法通过的输出**

## 参考模块

| 模块 | 用途 |
|------|------|
| `embedded-code-skill-standards/` | 命名、类型、错误处理规范 |
| `embedded-code-skill-drivers/` | 外设模板（UART/SPI/I2C/GPIO/TIMER 等） |
| `embedded-code-skill-arch/` | 架构约束、内存屏障、中断模式 |
| `embedded-code-skill-domains/` | 行业域（车载、军工等特殊要求） |

## 评估说明

`.evolution/` 是人工执行的评估流程（评分维度 + 抽样 prompts + 结果记录），不含自动打分工具。
