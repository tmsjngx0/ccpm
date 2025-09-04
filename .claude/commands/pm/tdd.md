---
allowed-tools: Bash, Read, Write, LS, Task, Grep, Edit
---

# TDD - Test-Driven Development Workflow

Execute TDD methodology on GitHub issues from the PM system. Follows Red-Green-Refactor cycle with structured logging.

## Usage
```
/pm:tdd                    # Work on next priority WIP issue
/pm:tdd <issue_number>     # Work on specific issue
/pm:tdd --select          # Select from available issues
```

## Quick Check

1. **If no issue specified, find next priority:**
   ```bash
   # Check WIP issues first
   if [ -z "$ARGUMENTS" ]; then
     WIP_ISSUES=$(ls .claude/epics/*/wip/*.md 2>/dev/null | head -5)
     if [ -z "$WIP_ISSUES" ]; then
       echo "❌ No WIP issues found. Use: /pm:next to find and move issues to WIP"
       exit 1
     fi
   fi
   ```

2. **Verify issue exists:**
   ```bash
   gh issue view $ARGUMENTS --json state,title || echo "❌ Cannot access issue #$ARGUMENTS"
   ```

3. **Find task file:**
   - Check `.claude/epics/*/$ARGUMENTS.md`
   - If not found: "❌ No local task for issue #$ARGUMENTS"

## TDD Workflow Instructions

### 1. Setup TDD Environment

Read the issue requirements from task file:
```bash
# Find and read task file
TASK_FILE=$(find .claude/epics -name "$ARGUMENTS.md" | head -1)
```

Check for existing test framework:
```bash
# Detect test runner (prioritize based on package.json, Cargo.toml, etc)
if [ -f "package.json" ] && grep -q "test" package.json; then
  TEST_CMD="npm test"
elif [ -f "Cargo.toml" ]; then
  TEST_CMD="cargo test"
elif [ -f "pytest.ini" ] || [ -f "setup.py" ]; then
  TEST_CMD="pytest"
fi
```

### 2. Initialize TDD Log

Create or append to implementation log in task file:
```markdown
## Implementation Log

### {current_datetime} - TDD Session Started
**Issue**: #{issue_number}
**Test Framework**: {detected_framework}
**Starting Task**: {next_uncompleted_task}
```

### 3. TDD Cycle Execution

For each uncompleted task or subtask:

#### RED Phase - Write Failing Test
1. Identify the next uncompleted task from the issue
2. Write a minimal failing test that defines the expected behavior
3. Run test to confirm failure
4. Log the red phase:

```markdown
### {timestamp} - TDD Red Phase
**Task**: {task_description}
**Action**: Created failing test for {specific_functionality}
**Test File**: `{test_file_path}`
**Test Name**: `{descriptive_test_name}`
**Commands Run**: `{test_command}`
**Result**: Red - {failure_message}
**Next**: Implement minimal code to pass
```

#### GREEN Phase - Make Test Pass
1. Write the minimum code needed to make the test pass
2. Mark any assumptions with `# COMPLETION_DRIVE: assumption details`
3. Run test to confirm it passes
4. Log the green phase:

```markdown
### {timestamp} - TDD Green Phase  
**Action**: Implemented minimal solution
**Files Modified**:
- `{implementation_file}` - {brief_description}
**Commands Run**: `{test_command}`
**Result**: Green - Test passing
**Next**: {refactor_if_needed_or_next_test}
```

#### VERIFY & REFACTOR Phase
1. First verify any COMPLETION_DRIVE assumptions:
   - Run `grep -n "COMPLETION_DRIVE:" {files}`
   - Check each assumption
   - Fix if incorrect, remove tag if correct
2. Then refactor when all tests are green
3. Make one refactoring change at a time
4. Run tests after each change
5. Log refactoring:

```markdown
### {timestamp} - TDD Refactor Phase
**Action**: {refactoring_description}
**Refactoring Type**: {extract_method|rename|remove_duplication|etc}
**Files Modified**:
- `{file}` - {what_changed}
**Commands Run**: `{test_command}`
**Result**: Green - All tests still passing
**Next**: {continue_with_next_task}
```

### 4. Update Task Progress

After each cycle, update the task checkboxes:
- `[ ]` → `[⚒]` when starting a task
- `[⚒]` → `[✓]` when tests pass and implementation is complete

### 5. Commit Discipline

Follow commit patterns based on change type:

**For Test Commits (Red Phase):**
```bash
git add {test_files}
git commit -m "test: add failing test for {functionality} #$ARGUMENTS"
```

**For Implementation Commits (Green Phase):**
```bash
git add {implementation_files}
git commit -m "feat: implement {functionality} to pass tests #$ARGUMENTS"
```

**For Refactoring Commits (Refactor Phase):**
```bash
git add {refactored_files}
git commit -m "refactor: {what_was_refactored} #$ARGUMENTS"
```

### 6. Sync Progress

After significant progress or completion:
```bash
# Update issue with progress
/pm:issue-sync $ARGUMENTS
```

## TDD Rules

1. **Never write code without a failing test first**
2. **Write the simplest test that could possibly fail**
3. **Write the minimum code to make the test pass**
4. **Refactor only when tests are green**
5. **Run ALL tests after each change**
6. **Keep test names descriptive of behavior**
7. **One assertion per test when possible**
8. **Commit after each phase (Red, Green, Refactor)**

## Output Format

```
🧪 Starting TDD on Issue #$ARGUMENTS: {title}

Current Status:
- [ ] Task 1: {description}
- [⚒] Task 2: {description} ← Starting here
- [ ] Task 3: {description}

Test Framework: {detected}
Test Command: {command}

Beginning RED phase for Task 2...
[Test writing happens here]

✓ Test written and failing as expected

Beginning GREEN phase...
[Implementation happens here]

✓ Test passing with minimal implementation

Refactoring opportunity identified...
[Optional refactoring]

✓ Task 2 complete - Updated checkbox

Next: Task 3 or run /pm:tdd to continue
```

## Integration with PM System

This command integrates with:
- `/pm:issue-start` - Can be used after starting work
- `/pm:issue-sync` - Syncs TDD logs as GitHub comments  
- `/pm:epic-status` - Shows TDD progress across epic
- `/pm:tdd-progress` - Track TDD metrics and phase status
- `/pm:tdd-commit` - Create atomic commits for each phase
- `/pm:tdd-status` - View dashboard of all TDD activity
- Standard git workflow in worktrees

## Error Handling

- If no test framework detected: Prompt user for test command
- If tests won't run: Check environment and dependencies
- If task file not found: Ensure issue was created via PM system
- If already completed: Show completion status and suggest next issue