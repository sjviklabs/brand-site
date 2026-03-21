#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

PASS="${HOSTINGER_PASS:-}"
if [[ -z "$PASS" && -f ~/.hostinger-tahala-pass ]]; then
  PASS="$(cat ~/.hostinger-tahala-pass)"
fi
if [[ -z "$PASS" && "${1:-}" != "--build-only" ]]; then
  echo "ERROR: Set HOSTINGER_PASS env var or create ~/.hostinger-tahala-pass"
  exit 1
fi

echo "==> Building SJVIK Labs landing page..."
npx astro build

# Copy static assets that live outside the Astro build (beta PDFs, etc.)
if [[ -d static-assets/beta ]]; then
  echo "==> Copying beta PDFs into dist/beta/..."
  mkdir -p dist/beta
  cp static-assets/beta/* dist/beta/
fi

echo "==> Build complete: dist/"

if [[ "${1:-}" == "--build-only" ]]; then
  echo "==> --build-only flag set, skipping deploy."
  exit 0
fi

echo "==> Deploying to Hostinger (sjvik-labs/) via FTP..."
lftp -u "u964877707.deploy01,$PASS" ftp://ftp.stevenjvik.tech -e "
  set ssl:verify-certificate no;
  mkdir -p sjvik-labs;
  mirror --reverse --delete --verbose dist/ sjvik-labs/;
  bye
"

echo "==> Live at https://sjvik-labs.stevenjvik.tech"
