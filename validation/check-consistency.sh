#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="${1:-$(cd "$script_dir/.." && pwd)}"

targets=(
  "$root/SKILL.md"
  "$root/README.md"
  "$root/README_EN.md"
  "$root/README_JP.md"
  "$root/embedded-code-skill-arch/SKILL.md"
  "$root/embedded-code-skill-domains/SKILL.md"
  "$root/embedded-code-skill-drivers/SKILL.md"
  "$root/embedded-code-skill-standards/SKILL.md"
  "$root/.evolution/SKILL.md"
  "$root/.evolution/README.md"
  "$root/.evolution/test-prompts.json"
)

c_identifier_targets=(
  "$root/SKILL.md"
  "$root/README.md"
  "$root/README_EN.md"
  "$root/README_JP.md"
  "$root/embedded-code-skill-drivers/SKILL.md"
  "$root/embedded-code-skill-standards/SKILL.md"
  "$root/.evolution/test-prompts.json"
)

fail=0

run_absence_check() {
  local label="$1"
  local pattern="$2"
  shift 2

  echo "[$label]"
  if rg -n "$pattern" "$@"; then
    fail=1
  else
    echo "ok"
  fi
  echo
}

run_absence_check "1/5 illegal leading-digit identifiers" '\b[0-9]+_[A-Za-z0-9_]+\b' "${c_identifier_targets[@]}"
run_absence_check "2/5 deprecated status type alias" 'embed_code_status_t' "${targets[@]}"
run_absence_check "3/5 direct register access macros in normative templates" '#define (UART|SPI|I2C|DMA|CAN|GPIO|TIM|WDT)_[A-Z0-9_]+\((base|base,ch)' "${targets[@]}"
run_absence_check "4/5 rewrite-mode defect preservation language" 'bug.*part of|保持原样|不擅自修复|kept by default' "${targets[@]}"
run_absence_check "5/5 mixed-language translation leftovers" 'Never破坏|是否符合|核心原則|人在ループ|AIは.*捏造' "$root/README_EN.md" "$root/README_JP.md"

if [[ "$fail" -ne 0 ]]; then
  echo "Consistency checks failed."
  exit 1
fi

echo "All checks passed."
