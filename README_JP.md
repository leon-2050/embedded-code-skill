# embedded-code-skill

> ドライバや低レベルファームウェアコードを生成・書き換え・レビューするための Embedded C スキルパッケージ。

[简体中文](README.md) · [English](README_EN.md) · [日本語](README_JP.md)

---

## このパッケージの目的

このパッケージは、モデルに一貫した Embedded C の作法を与えるためのものです。主な用途は次のとおりです。

- 新しいドライバ骨格の生成
- 既存の組込み C コードの整理された構造への書き換え
- ファームウェアコードの移植性・保守性レビュー

これはターゲット MCU/SoC のリファレンスマニュアルの代替ではありません。

---

## 設計上の境界

- まず規約を与え、ハードウェア詳細を捏造しない
- レジスタアクセスは `*_reg_t` と `*_REG` に統一する
- サンプルは構成例であり、そのまま量産投入できるレジスタ定義ではない
- `.evolution/` は手動で使う評価プレイブックであり、自動最適化エンジンではない

---

## クイックスタート

```bash
/ecs STM32 UART ドライバを生成、ベースアドレス 0x4000C000
/ecs この SPI 初期化コードを、振る舞いの意図を保って書き換える
/ecs この GPIO ドライバを規約に照らしてレビューする
```

---

## コアルール

| 分類 | ルール |
|------|--------|
| 型 | 公開インターフェースでは `stdint.h` / `stdbool.h` を優先する |
| エラー処理 | public 関数は `embedded_code_status_t` を返す |
| レジスタ抽象 | 専用の `*_reg.h`、`*_reg_t`、`*_REG` を使う |
| マジックナンバー | レジスタビットと定数には名前を付ける |
| メモリ | `malloc`、`free`、VLA を使わない |
| 書き換え | 振る舞いの意図は保つが、構文エラーや明白な欠陥は修正する |

---

## パッケージ構成

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

## サンプルスタイル

```c
/* 説明用サンプル。実際のフィールドやオフセットは必ずリファレンスマニュアルで確認すること */
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

`.evolution/` ディレクトリには以下が入っています。

- 評価基準
- テストプロンプト
- 結果ログ形式
- 手動で回す改善ワークフロー

ファイルロック、自動ロールバック、自動実行スクリプトは同梱していません。

---

## `validation/`

`validation/` ディレクトリでは、次の軽量チェックを提供します。

- 不正な C 識別子
- ステータス型名の不一致
- 矛盾したレジスタアクセステンプレート
- EN/JP ドキュメントの翻訳残り
- MIL-STD-1553 サンプルのコンパイル smoke test

---

## ライセンス

MIT License
