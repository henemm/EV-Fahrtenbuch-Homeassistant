# Bug Fix Workflow

## Overview

Every bug fix follows **Test-First + Analysis-First** principles. No quick fixes!

**CRITICAL:** Tests MUST be written BEFORE the fix. The test must FAIL first, then PASS after the fix.

---

## Workflow Steps

### 1. Bug Reported
- User describes problem
- Note exact steps to reproduce
- Understand expected vs actual behavior

### 2. Use Bug-Investigator Agent
```
/bug [description]
```

The agent will:
- Analyze the bug systematically
- Trace data flow
- Identify root cause with certainty
- Create ACTIVE-todos.md entry

### 3. Root Cause Identification

**Before writing ANY test or fix:**
- [ ] Problem scope fully understood
- [ ] All possible causes listed
- [ ] Root cause identified with certainty (specific code lines)
- [ ] No speculation - evidence only

### 4. Write Tests FIRST (MANDATORY!)

**STOP! Before writing ANY fix code, tests must exist.**

#### 4a. Unit Test (if applicable)
```swift
// Tests/BugXXX_DescriptionTests.swift
func test_bugDescription_expectedBehavior() {
    // Arrange: Setup test data
    // Act: Trigger the buggy behavior
    // Assert: Verify expected outcome
}
```

#### 4b. UI Test (if UI-related bug)
```swift
// UITests/BugXXX_UITests.swift
func test_bugDescription_userFlow() {
    // Navigate to affected screen
    // Perform action that triggers bug
    // Assert correct UI state
}
```

#### 4c. Run Tests - They MUST FAIL!
```bash
xcodebuild test -project ios/HomeAssistentFahrtenbuch.xcodeproj \
  -scheme "HomeAssistentFahrtenbuch" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

**If tests pass before fix → Test is wrong! Rewrite test.**

### 5. Implement Fix

**Only AFTER tests are written and failing:**

**Constraints:**
- Max 4-5 files changed
- Max +/-250 LoC
- Functions <= 50 LoC
- No side effects outside ticket

### 6. Run Tests - They MUST PASS!

```bash
xcodebuild test -project ios/HomeAssistentFahrtenbuch.xcodeproj \
  -scheme "HomeAssistentFahrtenbuch" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

**All tests must pass. If not → Fix is incomplete.**

### 7. Commit (Two Commits!)

**Commit 1: Tests (before fix works)**
```bash
git commit -m "test: Add failing test for [bug description]

Reproduces bug where [symptom].
Test will pass after fix is applied."
```

**Commit 2: Fix**
```bash
git commit -m "fix: [Brief description]

Problem: [What was wrong]
Root Cause: [Why it happened]
Fix: [What was changed]

Tested: Unit tests + UI tests passing"
```

### 8. Documentation

Update:
- [ ] DOCS/ACTIVE-todos.md (mark as GEFIXT)
- [ ] .agent-os/standards/ (if new lesson learned)

### 9. User Verification

Prepare test instructions for user:
- Clear steps to verify on device
- Expected result
- Edge cases to check

---

## Anti-Patterns

- **Fix before test:** Writing fix code before test exists
- **Test that passes before fix:** Test doesn't actually reproduce the bug
- **Trial-and-error:** Multiple attempts without analysis
- **Quick fix:** Change code without understanding
- **Scope creep:** "While I'm here, let me also..."
- **Skip tests:** "It's a small change..."

---

## Test-First Checklist

Before implementing fix, verify:

- [ ] Unit test written for bug scenario
- [ ] UI test written (if UI-related)
- [ ] Tests currently FAIL (bug is reproduced)
- [ ] Root cause documented in ACTIVE-todos.md

**If any checkbox is unchecked → DO NOT write fix code!**
