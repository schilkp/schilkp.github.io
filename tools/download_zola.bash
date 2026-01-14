#!/usr/bin/env bash

# Fail on error code, unknown var, and propagate errors from pipes:
set -euo pipefail

# Move to location of this script
SCRIPT_DIR="$(realpath "$(dirname "$0")")"
cd "$SCRIPT_DIR"

# Version:
ZOLA_VERSION="v0.21.0"
ZOLA_CHECKSUM="5c37a8f706567d6cad3f0dbc0eaebe3b9591cc301bd67089e5ddc0d0401732d6"

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
