#!/bin/zsh
set -eu
cd "${0:A:h:h}"
TEST_BUILD="$(mktemp -d /tmp/taskpulse-db-test.XXXXXX)"
trap 'rm -rf "$TEST_BUILD"' EXIT
xcrun clang -c Tests/DisableURI.c -o "$TEST_BUILD/DisableURI.o"
cat > "$TEST_BUILD/main.swift" <<'SWIFT'
import Foundation
do {
    try runDatabaseReadTests()
} catch {
    fputs("Database regression failed: \(error)\n", stderr)
    exit(1)
}
SWIFT
xcrun swiftc -O -swift-version 5 Sources/TaskSource.swift Sources/DesktopUnread.swift Sources/Localization.swift Sources/ConnectionDiagnostics.swift Tests/DatabaseReadTests.swift "$TEST_BUILD/main.swift" "$TEST_BUILD/DisableURI.o" -o "$TEST_BUILD/test" -lsqlite3
"$TEST_BUILD/test"
