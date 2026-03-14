#!/usr/bin/env bash

# Fail on error code, unknown var, and propagate errors from pipes:
set -euo pipefail

# Move to location of this script
SCRIPT_DIR="$(realpath "$(dirname "$0")")"
cd "$SCRIPT_DIR"

# Cleanup
rm -rf "zola"

# Clone zola
if [ ! -f repo/Cargo.toml ]; then
    echo "Cloning..."
    git clone git@github.com:getzola/zola.git repo
fi

# Checkout
echo "Checkout..."
pushd repo
git checkout 2508f4b

echo "Building..."
cargo build
popd

mv ./repo/target/debug/zola ./zola
