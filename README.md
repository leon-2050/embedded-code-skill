# embedded code skill

> 嵌入式 C 代码规范包，用于生成、重写、审查驱动和低层固件代码。

[简体中文](README.md) · [English](README_EN.md) · [日本語](README_JP.md)

---

## 这个包解决什么问题

它提供一套统一的嵌入式 C 规范，让模型在以下任务中保持一致输出：

- 生成新的驱动骨架
- 把旧代码重写成更可维护的结构
- 审查现有驱动是否存在风格或可移植性问题

它**不是**芯片厂商参考手册，也不会替代真实寄存器表。

---

## 设计边界

- 规范优先，不伪造硬件细节
- 结构优先，统一采用 `*_reg_t` + `*_REG` 模式
- 示例优先说明组织方式，不宣称示例偏移可直接投入生产
- `.evolution/` 是人工执行的评估流程，不是自动优化引擎

---

## 快速开始

```bash
/ecs 生成一个 STM32 UART 驱动，基地址 0x4000C000
/ecs 重写这段 SPI 初始化代码并保持行为意图
/ecs 审查这段 GPIO 驱动是否符合规范
```

---

## 核心规则

| 类别 | 规则 |
|------|------|
| 类型 | 公共接口优先使用 `stdint.h` / `stdbool.h` |
| 错误处理 | public 函数默认返回 `embedded_code_status_t` |
| 寄存器抽象 | 使用独立 `*_reg.h`、`*_reg_t`、`*_REG` |
| 魔法数字 | 寄存器位和常量必须命名 |
| 内存 | 禁止 `malloc/free/VLA` |
| 重写 | 保留行为意图，但默认修复语法和明显缺陷 |

---

## 包结构

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

## 示例风格

```c
/* 示例仅演示组织方式，真实寄存器字段必须核对手册 */
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

## `.evolution/` 说明

`.evolution/` 目录提供：

- 评分维度
- 测试 prompts
- 结果记录格式
- 人工执行的改进流程

它不包含真正的文件锁、自动回滚或自动调度脚本。

---

## `validation/` 说明

`validation/` 目录提供轻量校验：

- 非法 C 标识符检查
- 类型命名一致性检查
- 规范模板冲突检查
- 多语言 README 残留问题检查
- MIL-STD-1553 示例编译 smoke test

---

## 许可

MIT License
