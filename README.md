<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://img.shields.io/badge/Embedded%20C%20Code%20Assistant-00C853?style=for-the-badge&logo=c&logoColor=white">
    <img src="https://img.shields.io/badge/Embedded%20C%20Code%20Assistant-2E7D32?style=for-the-badge&logo=c&logoColor=white" alt="Embedded C Code Assistant">
  </picture>
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/leon-2050/embedded-code-skill?style=flat-square&logo=github" alt="stars">
  <img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="MIT">
  <img src="https://img.shields.io/badge/language-C-A8B9CC?style=flat-square&logo=c&logoColor=white" alt="C">
  <img src="https://img.shields.io/badge/platform-Cortex--M%20%7C%20RISC--V%20%7C%20Xtensa-00897B?style=flat-square" alt="platform">
  <img src="https://img.shields.io/badge/RTOS-FreeRTOS%20%7C%20Zephyr%20%7C%20RT--Thread-FF6F00?style=flat-square" alt="RTOS">
  <br>
  <img src="https://img.shields.io/badge/Codex-412991?style=flat-square&logo=openai&logoColor=white" alt="Codex">
  <img src="https://img.shields.io/badge/Claude%20Code-5678a0?style=flat-square&logo=anthropic&logoColor=white" alt="Claude Code">
  <img src="https://img.shields.io/badge/Cursor-7C3AED?style=flat-square&logo=cursor&logoColor=white" alt="Cursor">
</p>

<p align="center">
  <b>AI 代理的嵌入式 C 代码规范助手</b><br>
  <i>驱动骨架生成 · 旧代码整理 · 代码审查 · 寄存器重构</i>
</p>

<p align="center">
  <a href="README_EN.md">English</a> • <a href="README_JP.md">日本語</a>
</p>

---

## 概览

**embedded-code-skill** 是专为 AI 编程助手（Codex、Claude Code、Cursor）设计的嵌入式 C 技能文件。让 AI 在生成、审查和重构嵌入式 C 代码时，遵循一套保守、可审查的编码规范。

**它能做什么：**

| 工作模式 | 说明 |
|---------|------|
| 🔄 **代码整理（REWRITE）** | 整理旧驱动代码，保持寄存器写入顺序和时序 |
| 🔍 **代码审查（REVIEW）** | 审查中断服务/DMA/缓存/竞态风险，输出结构化问题表 |
| 📖 **设计咨询（GUIDE）** | 实时操作系统任务设计、编译构建配置、调试策略咨询 |

**设计边界：**

本技能文件不替代硬件资料、不编造实现细节、不覆盖项目自有规范，而是确保 AI 在这些约束下输出一致、可审查的代码。

---

## 安装

```bash
# 克隆仓库
git clone https://github.com/leon-2050/embedded-code-skill.git

# 安装到 Codex（默认）
cd embedded-code-skill && ./install.sh

# 安装到其他平台
./install.sh cursor   # → ~/.cursor/skills/embedded-code-skill/
./install.sh claude   # → ~/.claude/skills/embedded-code-skill/
```

**手动安装方式：** 将 `SKILL.md` 文件复制到对应平台的 skills 目录即可。

---

## 快速开始

### 整理驱动代码（REWRITE）

```bash
/embedded-code-skill 整理这段 UART 驱动，按三层架构拆分
```

AI 会保留公共接口与应用二进制接口、按规范整理类型与命名、按三层解耦重新组织文件、输出可直接应用的补丁。

### 审查代码风险（REVIEW）

```bash
/embedded-code-skill 审查这段 DMA 中断是否有竞态或缓存问题
```

AI 会按照「等级、位置、问题、建议」四栏格式输出问题表：

| 等级 | 位置 | 问题 | 建议 |
|------|------|------|------|
| P0 | `uart_drv.c:42` | 中断中调用了阻塞函数 | 改为 FromISR 系列接口 |

> P0 = 行为/安全风险，P1 = 并发/可移植问题，P2 = 风格建议

### 设计咨询（GUIDE）

```bash
/embedded-code-skill 设计 FreeRTOS 任务优先级和栈大小
```

AI 会根据目标架构给出保守建议和示例代码片段。

---

## 架构

### 核心设计：三层解耦

代码整理和审查模式下，所有代码必须遵守三层五文件架构：

```
┌──────────────────────────────────────┐
│          应用层                       │
│       (module.h / module.c)          │
│                                      │
│  缓冲管理 · 协议解析 · 对外接口       │
│  ✗ 不直写寄存器  ✗ 不含中断处理       │
└──────────────┬───────────────────────┘
               │  中断通过回调通知
┌──────────────▼───────────────────────┐
│          驱动层                       │
│      (module_drv.h / module_drv.c)    │
│                                      │
│  寄存器读写 · 中断处理 · DMA 传输     │
│  ✗ 不含业务逻辑  ✗ 不分配缓存         │
└──────────────┬───────────────────────┘
│               │  通过结构体访问
┌──────────────▼───────────────────────┐
│          寄存器层                     │
│           (module_reg.h)             │
│                                      │
│  寄存器结构体 · 位定义宏 · 基址宏     │
│  ✗ 无函数实现  ✗ 无业务代码           │
└──────────────────────────────────────┘
```

**文件骨架：** `module_reg.h` → `module_drv.h/.c` → `module.h/.c`

### 设计原则

| 原则 | 说明 |
|------|------|
| **寄存器结构体化** | 所有外设寄存器块必须定义为 struct 结构体，禁止散落地址宏 |
| **常量指针契约** | 输入型指针加 const，输出型指针不加 —— 接口自文档化 |
| **编号步骤注释** | 驱动和应用函数体内用「步骤 1 / 步骤 2 ...」标注操作顺序 |
| **枚举优先** | 互相关联的整型常量集合必须用枚举定义，禁止用宏堆砌 |
| **默认静态** | 内部函数和模块私有变量必须加 static，只有公开接口才对外开放 |
| **拒绝魔数** | 除 0 和 1 外，所有字面量必须定义为命名常量 |
| **自包含头文件** | 每个文件必须显式包含自身使用的符号对应的头文件 |

---

## 工作模式详解

### 代码整理（REWRITE）

保留公共接口、应用二进制接口、寄存器写入顺序与时序。按三层架构重新组织类型、命名和文件层次。

**输出格式：** 概括说明 → 待补充信息清单 → 代码补丁（必要时包含文件目录结构）

> 硬件规避措施必须标注 `/* 有意保留：原因 */`

### 代码审查（REVIEW）

不产出代码。按以下顺序逐一检查：

1. 寄存器抽象层
2. 分层设计 / 中断处理 / 同步机制
3. volatile / 内存屏障 / 缓存 / DMA
4. 错误处理 / 内存管理

**输出格式：**

| 等级 | 位置 | 问题 | 建议 |
|------|------|------|------|
| P0 | `uart_drv.c:42` | 中断中调用阻塞函数 | 改用 FromISR 系列接口 |

### 设计咨询（GUIDE）

不涉及代码整理或审查。按架构规则、实时操作系统场景、构建系统等方向给出建议或示例。

---

## 设计约束

以下约束是确保 AI 输出安全、可审查、可编译代码的基石，违反任一规则都会导致不可接受的后果。

| 约束 | 理由 | 后果 |
|------|------|------|
| **硬件参数必须有据可查** | 寄存器偏移、中断号、时序、屏障行为必须来自手册、厂商头文件或仓库 | 编造的参数会直接导致硬件故障，且难以排查 |
| **底层代码禁止动态分配** | 低层驱动、中断处理和热点路径不能使用 malloc/free 或变长数组 | 触发内存碎片、实时性不可控、安全认证失败 |
| **公共接口使用精确类型** | 接口参数必须使用 uintN_t、intN_t、bool 等定长类型，拒绝 int/char/long | 跨平台移植时隐式类型宽度变化导致难以发现的 bug |
| **业务层禁止操作裸地址** | 应用代码不能出现 0x40001000 形式的寄存器地址，必须通过驱动层封装 | 硬件细节渗透到业务层，代码不可移植、不可测试 |
| **所有输出必须可编译** | AI 给出的代码片段必须是语法完整、依赖自洽的可编译单元 | 不可编译的输出浪费审查时间、破坏工作流信任 |
| **三层解耦是刚性约束** | 寄存器层 → 驱动层 → 应用层，依赖方向单向，中断通过回调通知应用层 | 违反此约束会导致维护成本暴涨、复用性归零 |

---

## 章节导航

| 章节 | 内容 |
|------|------|
| §1 | 定位、使用原则、工作模式、红线 |
| §2 | 后备编码规范 —— 命名 / 类型 / 注释 / 枚举 / 静态作用域 / 魔数 / 宏安全 |
| §3 | 寄存器抽象 —— 结构体 / 位掩码与移位 / 使用方式 / CMSIS 复用 |
| §4 | 驱动模板 —— 三层五文件 / 接口规范 / 关键结构 |
| §5 | 架构规则 —— Cortex-M / RISC-V 屏障与中断速查 |
| §6 | 实时操作系统速查 —— FreeRTOS / Zephyr / RT-Thread |
| §7 | 构建系统 —— 链接脚本 / 编译器属性 |
| §8 | 内存、安全和并发默认值 |
| §9 | 回查清单与维护自检 |

完整规范请阅读 [`SKILL.md`](SKILL.md)。

---

## 许可

[MIT](LICENSE) © 2024 [leon-2050](https://github.com/leon-2050)
