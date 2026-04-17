---
name: embedded-code-evolution
description: "Manual evaluation and improvement playbook for the embedded-code-skill package. Use when the user wants to assess the package quality, compare revisions, or improve wording and examples without pretending that a full auto-evolution engine exists."
---

# Embedded Code Skill 评估与改进流程

## 这是什么

这是一个**人工执行的评估流程说明**，用于帮助操作者系统化地改进 `embedded-code-skill`。

它提供：

- 评分维度
- 测试 prompts
- 结果记录格式
- 一次只改一类问题的工作节奏

它**不提供**：

- 自动文件锁
- 自动回滚脚本
- 自动子 agent 编排
- 自动评分执行器

## 评分维度

### 结构维度（60分）

| 维度 | 权重 | 关注点 |
|------|------|--------|
| Frontmatter 质量 | 8 | name、description、触发场景 |
| 规范完整性 | 15 | 类型、命名、错误处理、注释 |
| 安全编码覆盖 | 10 | 无动态内存、无 VLA、无裸魔法数字 |
| 寄存器抽象 | 7 | `*_reg.h` / `*_reg_t` / `*_REG` 是否统一 |
| 工作流清晰度 | 15 | GENERATE / REWRITE / REVIEW 是否可执行 |
| 模块化程度 | 5 | 驱动、架构、领域是否清晰分离 |

### 效果维度（40分）

| 维度 | 权重 | 关注点 |
|------|------|--------|
| 规范覆盖度 | 15 | 常见架构与外设是否被覆盖 |
| 示例质量 | 25 | 示例是否一致、可编译、不会误导模型 |

## 推荐工作流

1. 读取根 `SKILL.md` 和相关子 skill
2. 先跑 `validation/` 里的校验
3. 选一个最低质量维度
4. 只修改这一类问题
5. 重新校验并记录结果
6. 如果改动让结果更差，则人工回退到上一个版本

## 什么时候使用子 agent

如果当前环境支持子 agent，可以把“效果验证”交给子 agent 做独立审查。

如果当前环境不支持，也可以由人工 reviewer 按相同 rubric 打分。不要在文档里假装这一步是自动完成的。

## 结果记录

使用 `results.tsv` 记录每次人工评估：

```tsv
timestamp	skill	old_score	new_score	status	dimension	note	eval_mode
20260417T210000	embedded-code-skill	-	78	baseline	-	初始人工评估	manual
20260417T213000	embedded-code-skill	78	86	keep	寄存器抽象	统一模板结构	manual
```

推荐状态值：

- `baseline`
- `keep`
- `revert`

推荐 `eval_mode`：

- `manual`
- `manual_plus_subagent`

## 与 `test-prompts.json` 的关系

`test-prompts.json` 用于约束 review 场景，不代表真正的自动回归系统。是否运行、如何评分，由操作者决定。
