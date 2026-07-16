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
cleanup() {
    if [[ -n "${TMPDIR:-}" && -d "${TMPDIR}" ]]; then
        rm -rf "${TMPDIR}"
    fi
}
trap cleanup EXIT

TMPDIR=$(mktemp -d)
DEST_FILE="${TMPDIR}/SKILL.md"

if ! curl -sf --connect-timeout "${CONNECT_TIMEOUT}" --max-time "${MAX_TIME}" \
    "${REPO_URL}/SKILL.md" -o "${DEST_FILE}"; then
    echo "Error: Failed to download SKILL.md from ${REPO_URL}" >&2
    echo "Check your network connection and ensure the repository URL is correct." >&2
    exit 1
fi

if [[ ! -s "${DEST_FILE}" ]]; then
    echo "Error: Downloaded SKILL.md is empty" >&2
    exit 1
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
echo "Work modes: REWRITE (clean up legacy code) | REVIEW (risk findings)"
echo "Examples:"
echo "  /embedded-code-skill rewrite this UART driver, keep register write order"
echo "  /embedded-code-skill review this DMA ISR for race, volatile, or cache issues"
