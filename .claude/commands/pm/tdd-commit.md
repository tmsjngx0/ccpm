---
allowed-tools: Bash, Read, Grep
---

# TDD Commit - Atomic Commits for TDD Phases

Create properly formatted commits following TDD phase conventions with automatic message generation.

## Usage
```
/pm:tdd-commit red <issue_num>      # Commit test files (Red phase)
/pm:tdd-commit green <issue_num>    # Commit implementation (Green phase)  
/pm:tdd-commit refactor <issue_num> # Commit refactoring (Refactor phase)
/pm:tdd-commit --auto                # Auto-detect phase and commit
```

## Instructions

### 1. Validate Phase and Issue

Check arguments:
```bash
PHASE=$1  # red, green, or refactor
ISSUE=$2  # issue number

# Validate phase
if [[ ! "$PHASE" =~ ^(red|green|refactor|--auto)$ ]]; then
  echo "❌ Invalid phase. Use: red, green, refactor, or --auto"
  exit 1
fi
```

### 2. Auto-Detect Phase (if --auto)

If --auto flag used:
```bash
# Check git status for changed files
if git status --porcelain | grep -q "test"; then
  # Test files changed - likely Red phase
  PHASE="red"
elif git diff --cached --name-only | grep -q "test"; then
  # Tests already staged - likely Green phase  
  PHASE="green"
else
  # No test changes - likely Refactor phase
  PHASE="refactor"
fi
```

### 3. Read Implementation Log

Find and read the latest TDD entry:
```bash
# Get task description from implementation log
TASK_FILE=$(find .claude/epics -name "${ISSUE}.md")
LAST_ENTRY=$(grep -A5 "TDD.*Phase" "$TASK_FILE" | tail -5)
```

Extract:
- Current task description
- What was implemented/changed
- Test names or functionality

### 4. Generate Commit Message

Based on phase, generate appropriate message:

**Red Phase:**
```bash
# For test commits
MESSAGE="test: add failing test for ${FUNCTIONALITY} #${ISSUE}

- Added test: ${TEST_NAME}
- Expects: ${EXPECTED_BEHAVIOR}
- TDD Red phase for: ${TASK_DESCRIPTION}"
```

**Green Phase:**
```bash
# For implementation commits  
MESSAGE="feat: implement ${FUNCTIONALITY} to pass tests #${ISSUE}

- Made ${TEST_NAME} pass
- Added: ${WHAT_WAS_ADDED}
- TDD Green phase complete"
```

**Refactor Phase:**
```bash
# For refactoring commits
MESSAGE="refactor: ${WHAT_WAS_REFACTORED} #${ISSUE}

- Improved: ${IMPROVEMENT}
- Maintains: All tests passing
- TDD Refactor phase"
```

### 5. Stage Appropriate Files

Based on phase, stage correct files:

```bash
case $PHASE in
  red)
    # Stage only test files
    git add "*test*" "*spec*" "tests/" "test/" 2>/dev/null
    ;;
  green)
    # Stage implementation files (not tests)
    git add --all -- . ':!*test*' ':!*spec*' ':!tests/' ':!test/' 2>/dev/null
    ;;
  refactor)
    # Stage all modified files
    git add -A
    ;;
esac
```

### 6. Create Commit

Execute commit with generated message:
```bash
git commit -m "$MESSAGE"

# Show what was committed
echo "✅ TDD Commit created for $PHASE phase"
git log --oneline -1
```

### 7. Update Implementation Log

Append commit info to implementation log:
```markdown
**Commit**: $(git rev-parse --short HEAD) - $PHASE phase
```

## Advanced Features

### Validation Checks

Before committing, ensure:
1. **Red Phase**: At least one test file changed
2. **Green Phase**: Tests are actually passing
3. **Refactor Phase**: No test failures introduced

```bash
# For Green/Refactor phases - verify tests pass
if [[ "$PHASE" != "red" ]]; then
  echo "🧪 Running tests to verify..."
  if ! npm test 2>&1 | grep -q "fail"; then
    echo "✅ All tests passing"
  else
    echo "❌ Tests failing! Cannot commit $PHASE phase"
    exit 1
  fi
fi
```

### Smart Detection

Detect phase from git diff patterns:
- New test files → Red phase
- Modified implementation files → Green phase  
- Multiple small changes → Refactor phase

### Integration with Issue

Add commit reference to issue:
```bash
# After successful commit
/pm:issue-sync $ISSUE --commit-only
```

## Output Format

```
🧪 TDD Commit Generator
======================

Phase Detected: 🔴 Red 
Issue: #1234 - User Authentication
Task: Implement password validation

Files to commit:
  - tests/auth/password.test.js (new)
  - tests/auth/validation.test.js (modified)

Commit message:
"test: add failing test for password validation #1234"

✅ Committed successfully!
Hash: a1b2c3d

Next: Run /pm:tdd 1234 to continue with Green phase
```

## Error Handling

- No changed files: "❌ No files to commit for $PHASE phase"
- Tests failing in Green/Refactor: "❌ Cannot commit - tests must pass"  
- No issue found: "❌ Issue #$ISSUE not found in local system"
- Mixed changes: "⚠️ Both tests and implementation changed. Separate commits recommended"