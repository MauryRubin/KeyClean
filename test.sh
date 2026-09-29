#!/usr/bin/env bash
# Runs the unit tests. The Command Line Tools ship Swift Testing outside the
# default search path, so the framework flags are added here.
set -euo pipefail
cd "$(dirname "$0")"
FW="/Library/Developer/CommandLineTools/Library/Developer/Frameworks"
swift test -Xswiftc -F"$FW" -Xlinker -F"$FW" -Xlinker -rpath -Xlinker "$FW" "$@"
