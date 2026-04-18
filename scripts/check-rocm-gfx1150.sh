#!/usr/bin/env bash
# Check whether ROCm has shipped native gfx1150 (Strix Point iGPU) support.
#
# Two signals are considered authoritative:
#   1. "gfx1150" appearing in the release notes of any of the most recent 5
#      ROCm/ROCm GitHub releases.
#   2. "gfx1150" appearing in rocBLAS's Tensile arch-logic directory on the
#      default branch (this is where per-arch GEMM kernels land).
#
# Exits 0 with no output when neither signal is present. Exits 0 and writes
# a human-readable report to stdout when a signal is present, so the caller
# can decide whether to open an issue.
set -euo pipefail

report=""

# Signal 1: ROCm release notes.
release_hits=$(
  gh api 'repos/ROCm/ROCm/releases?per_page=5' \
    --jq '.[] | select((.body // "") | test("gfx1150"; "i")) | "\(.tag_name): \(.html_url)"' \
    2>/dev/null || true
)
if [ -n "$release_hits" ]; then
  report+="ROCm release notes mention gfx1150:\n$release_hits\n\n"
fi

# Signal 2: rocBLAS Tensile arch-logic file listing. Use the Git Trees API to
# list files once rather than recursively cloning.
rocblas_default=$(gh api repos/ROCm/rocBLAS --jq '.default_branch')
tensile_tree=$(
  gh api "repos/ROCm/rocBLAS/git/trees/${rocblas_default}?recursive=1" \
    --jq '.tree[].path' 2>/dev/null || true
)
rocblas_hits=$(printf '%s\n' "$tensile_tree" | grep -i 'gfx1150' || true)
if [ -n "$rocblas_hits" ]; then
  report+="rocBLAS tree contains gfx1150 paths:\n$rocblas_hits\n"
fi

if [ -n "$report" ]; then
  printf '%b' "$report"
  # Emit a short machine-readable flag for the workflow step.
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "signal=true" >> "$GITHUB_OUTPUT"
  fi
else
  echo "No gfx1150 signals in ROCm releases or rocBLAS tree."
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "signal=false" >> "$GITHUB_OUTPUT"
  fi
fi
