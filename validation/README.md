# Validation

This folder contains lightweight checks for the `embeded-code-optimizer-main` package.

## What It Checks

- Example C identifiers do not start with a digit.
- The package uses one canonical status type name: `embedded_code_status_t`.
- Normative templates do not fall back to direct `REG(base)` register macros.
- REWRITE mode does not tell the model to preserve compile failures or obvious defects.
- English and Japanese READMEs do not contain known mixed-language leftovers from partial translation.

## Commands

Run the consistency checks:

```bash
bash validation/check-consistency.sh
```

Compile the MIL-STD-1553 example:

```bash
cc -fsyntax-only validation/compile-smoke-1553.c
```

## Expected Results

- `check-consistency.sh` exits with status `0` and prints `All checks passed.`
- `cc -fsyntax-only` exits with status `0`

## Notes

- These checks are intentionally simple and deterministic.
- They validate package consistency, not hardware correctness against a vendor reference manual.
