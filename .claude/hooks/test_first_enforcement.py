#!/usr/bin/env python3
"""
OpenSpec Framework - Test-First Enforcement Hook

Enforces Test-First development for bug fixes:
1. When editing Swift files in ios/, check if corresponding test exists
2. Block edit if no test file exists for the bug being fixed
3. Allow edits to test files themselves

Exit Codes:
- 0: Allowed
- 2: Blocked (stderr shown to Claude)
"""

import json
import os
import sys
import re
from pathlib import Path

try:
    from config_loader import load_config, get_project_root
except ImportError:
    sys.path.insert(0, str(Path(__file__).parent))
    from config_loader import load_config, get_project_root


def is_test_file(file_path: str) -> bool:
    """Check if file is a test file."""
    path_lower = file_path.lower()
    return (
        "test" in path_lower or
        "tests" in path_lower or
        "spec" in path_lower or
        path_lower.endswith("tests.swift") or
        path_lower.endswith("test.swift")
    )


def is_swift_source_file(file_path: str) -> bool:
    """Check if file is a Swift source file (not test)."""
    if not file_path.endswith(".swift"):
        return False
    if is_test_file(file_path):
        return False
    # Only protect ios/ source files
    return "/ios/" in file_path and "/HomeAssistentFahrtenbuch/" in file_path


def is_documentation_file(file_path: str) -> bool:
    """Check if file is documentation (always allowed)."""
    path_lower = file_path.lower()
    return (
        path_lower.endswith(".md") or
        "/docs/" in path_lower or
        "/.agent-os/" in path_lower or
        "/.claude/" in path_lower or
        "/openspec/" in path_lower
    )


def get_workflow_state() -> dict:
    """Load current workflow state."""
    state_file = get_project_root() / ".claude" / "workflow_state.json"
    if state_file.exists():
        with open(state_file, 'r') as f:
            return json.load(f)
    return {"current_phase": "idle", "test_written": False}


def check_test_exists_for_bug() -> bool:
    """Check if any test file was recently created/modified for current bug."""
    project_root = get_project_root()
    test_dir = project_root / "ios" / "HomeAssistentFahrtenbuchTests"

    if not test_dir.exists():
        return False

    # Check for any test files
    test_files = list(test_dir.glob("*.swift"))
    return len(test_files) > 0


def main():
    # Read hook input from stdin
    try:
        hook_input = json.loads(sys.stdin.read())
    except json.JSONDecodeError:
        # No input or invalid JSON - allow
        sys.exit(0)

    tool_name = hook_input.get("tool_name", "")
    tool_input = hook_input.get("tool_input", {})

    # Only check Write and Edit tools
    if tool_name not in ["Write", "Edit"]:
        sys.exit(0)

    file_path = tool_input.get("file_path", "")

    # Always allow documentation files
    if is_documentation_file(file_path):
        sys.exit(0)

    # Always allow test files (that's what we want!)
    if is_test_file(file_path):
        sys.exit(0)

    # Check if this is a Swift source file
    if not is_swift_source_file(file_path):
        sys.exit(0)

    # Load workflow state
    state = get_workflow_state()
    current_phase = state.get("current_phase", "idle")

    # If we're in implemented or validated phase, allow (tests already written)
    if current_phase in ["implemented", "validated", "spec_approved"]:
        sys.exit(0)

    # Check if tests exist
    if not check_test_exists_for_bug():
        error_msg = """
╔══════════════════════════════════════════════════════════════════╗
║  TEST-FIRST ENFORCEMENT: Blocked!                                ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  Du versuchst Swift-Code zu ändern, aber es existieren keine     ║
║  Tests im Projekt!                                               ║
║                                                                  ║
║  WORKFLOW (Test-First):                                          ║
║  1. Zuerst: Test schreiben der den Bug reproduziert              ║
║  2. Test muss FEHLSCHLAGEN (Bug ist reproduziert)                ║
║  3. Dann: Fix implementieren                                     ║
║  4. Test muss BESTEHEN (Bug ist behoben)                         ║
║                                                                  ║
║  AKTION ERFORDERLICH:                                            ║
║  → Erstelle Test in ios/HomeAssistentFahrtenbuchTests/           ║
║  → Oder sage "skip test" wenn kein Test möglich                  ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
"""
        print(error_msg, file=sys.stderr)
        sys.exit(2)

    # Tests exist, allow the edit
    sys.exit(0)


if __name__ == "__main__":
    main()
