#!/bin/bash
set -euo pipefail
sunlit_root=$(cd "$(dirname "$0")/.." && pwd)
sunlit_test_dir=$(mktemp -d "${TMPDIR:-/tmp}/sunlit-state-tests.XXXXXX")
trap 'rm -rf "$sunlit_test_dir"' EXIT
"${SWIFTC:-swiftc}" "$sunlit_root/Sunlit/Source/Data/MicropubState.swift" "$sunlit_root/Tests/MicropubState/main.swift" -o "$sunlit_test_dir/state-tests"
"$sunlit_test_dir/state-tests"
