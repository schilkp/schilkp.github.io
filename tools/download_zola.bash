#!/usr/bin/env bash

# Fail on error code, unknown var, and propagate errors from pipes:
set -euo pipefail

# Move to location of this script
SCRIPT_DIR="$(realpath "$(dirname "$0")")"
cd "$SCRIPT_DIR"

# Version:
ZOLA_VERSION="v0.22.0"
ZOLA_CHECKSUM="f1d491f8956b94384c27d75cb6b2bf60d3916d1ade9564bcbfe7c03f0258aebf"

# Cleanup
rm -rf "zola.tar.gz"
rm -rf "zola"

# Download zola
echo "Downloading zola.."
curl -L -o zola.tar.gz "https://github.com/getzola/zola/releases/download/${ZOLA_VERSION}/zola-${ZOLA_VERSION}-x86_64-unknown-linux-gnu.tar.gz"

echo "Checking.."
echo "${ZOLA_CHECKSUM}  zola.tar.gz" | sha256sum -c
echo "Ok!"

echo "Extracting.."
tar -zxf zola.tar.gz
rm -rf "zola.tar.gz"
