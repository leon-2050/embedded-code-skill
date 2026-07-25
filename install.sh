#!/usr/bin/env bash
# embedded-code-skill install script
set -euo pipefail

TARGET="${1:-codex}"
REPO_URL="https://raw.githubusercontent.com/leon-2050/embedded-code-skill/main"

# 网络超时设置（秒）
CONNECT_TIMEOUT=10
MAX_TIME=30

case "${TARGET}" in
  codex)
    SKILL_DIR="${HOME}/.codex/skills/embedded-code-skill"
    ;;
  cursor)
    SKILL_DIR="${HOME}/.cursor/skills/embedded-code-skill"
    ;;
  claude)
    SKILL_DIR="${HOME}/.claude/skills/embedded-code-skill"
    ;;
  *)
    echo "Usage: $0 [codex|cursor|claude]" >&2
    echo "  codex  -> ~/.codex/skills/embedded-code-skill   (default)" >&2
    echo "  cursor -> ~/.cursor/skills/embedded-code-skill" >&2
    echo "  claude -> ~/.claude/skills/embedded-code-skill" >&2
    exit 1
    ;;
esac

echo "Installing embedded-code-skill to ${SKILL_DIR}..."

# 创建临时目录，函数返回时清理
# 注意：WORK_DIR 初始化为空，mktemp 失败时 cleanup 不会误删任何目录
WORK_DIR=""
cleanup() {
    if [[ -n "${WORK_DIR}" && -d "${WORK_DIR}" ]]; then
        rm -rf "${WORK_DIR}"
    fi
}
trap cleanup EXIT

WORK_DIR=$(mktemp -d)
DEST_FILE="${WORK_DIR}/SKILL.md"

# 优先使用脚本同目录的本地 SKILL.md（克隆安装无需联网，且版本与本地一致）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/SKILL.md" ]]; then
    echo "Using local SKILL.md from ${SCRIPT_DIR}"
    cp "${SCRIPT_DIR}/SKILL.md" "${DEST_FILE}"
elif ! curl -sf --connect-timeout "${CONNECT_TIMEOUT}" --max-time "${MAX_TIME}" \
    "${REPO_URL}/SKILL.md" -o "${DEST_FILE}"; then
    echo "Error: Failed to download SKILL.md from ${REPO_URL}" >&2
    echo "Check your network connection and ensure the repository URL is correct." >&2
    exit 1
fi

if [[ ! -s "${DEST_FILE}" ]]; then
    echo "Error: Downloaded SKILL.md is empty" >&2
    exit 1
fi

# 完整性校验：仓库提供 SKILL.md.sha256 时强制校验（本地与下载路径均适用）
if [[ -f "${SCRIPT_DIR}/SKILL.md.sha256" ]]; then
    if command -v shasum >/dev/null 2>&1; then
        CHECK_CMD="shasum -a 256"
    elif command -v sha256sum >/dev/null 2>&1; then
        CHECK_CMD="sha256sum"
    else
        CHECK_CMD=""
    fi
    if [[ -n "${CHECK_CMD}" ]]; then
        if ! (cd "${WORK_DIR}" && ${CHECK_CMD} -c "${SCRIPT_DIR}/SKILL.md.sha256" >/dev/null 2>&1); then
            echo "Error: SKILL.md checksum mismatch." >&2
            echo "If SKILL.md was updated intentionally, regenerate the checksum:" >&2
            echo "  shasum -a 256 SKILL.md > SKILL.md.sha256" >&2
            exit 1
        fi
        echo "Checksum verified."
    else
        echo "Warning: no sha256 tool found; skipping checksum verification." >&2
    fi
fi

# 创建目标目录
mkdir -p "${SKILL_DIR}"

# 备份现有文件
if [[ -f "${SKILL_DIR}/SKILL.md" ]]; then
    cp "${SKILL_DIR}/SKILL.md" "${SKILL_DIR}/SKILL.md.bak"
    echo "Backup created: ${SKILL_DIR}/SKILL.md.bak"
fi

mv "${DEST_FILE}" "${SKILL_DIR}/SKILL.md"

echo "Done! Installed to ${SKILL_DIR}/SKILL.md"
echo ""
echo "Work modes: REWRITE (clean up legacy code) | REVIEW (risk findings) | GUIDE (design advisory)"
echo "Examples:"
echo "  /embedded-code-skill rewrite this UART driver, keep register write order"
echo "  /embedded-code-skill review this DMA ISR for race, volatile, or cache issues"
