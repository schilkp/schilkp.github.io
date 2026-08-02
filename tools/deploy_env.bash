#!/usr/bin/env bash

export SCHILK_IO_BUILD_TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
export SCHILK_IO_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
