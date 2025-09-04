---
allowed-tools: Read, Grep, LS
---

# TDD Progress - Track Test-Driven Development Status

Shows TDD progress across issues, including test coverage, phase tracking, and implementation status.

## Usage
```
/pm:tdd-progress              # Show all active TDD work
/pm:tdd-progress <issue_num>  # Show specific issue TDD status
/pm:tdd-progress --epic <name> # Show TDD status for entire epic
```

## Instructions

### 1. Find Active TDD Work

If no specific issue provided:
```bash
# Find all issues with TDD implementation logs
grep -l "TDD.*Phase" .claude/epics/*/*.md | head -10
```

### 2. Parse TDD Progress

For each issue, read the Implementation Log and extract:
- Current TDD phase (Red/Green/Refactor)
- Number of completed cycles
- Test statistics (total, passing, failing)
- Coverage percentage if available
- Last activity timestamp

### 3. Calculate Metrics

Track these TDD metrics:
- **Cycles Completed**: Count of full Red→Green→Refactor cycles
- **Current Phase**: Where the work stopped
- **Test Ratio**: Tests written vs code written
- **Time in Phase**: How long in current phase
- **Blockers**: Any noted TDD blockers

### 4. Display Progress

Format output as:

```
🧪 TDD Progress Report
=====================

📋 Issue #1234: User Authentication
   Status: 🟢 Green Phase (3/5 tasks complete)
   Cycles: 8 completed, 1 in progress
   Tests: 24 passing, 0 failing
   Coverage: 87%
   Last Activity: 2 hours ago
   Next: Refactor validation logic

📋 Issue #1235: API Endpoints  
   Status: 🔴 Red Phase (1/3 tasks complete)
   Cycles: 3 completed, 1 in progress
   Tests: 12 passing, 1 failing
   Coverage: 72%
   Last Activity: 30 minutes ago
   Next: Implement missing endpoint logic

📊 Overall Statistics
   Total Cycles: 11 completed
   Average Cycle Time: 45 minutes
   Test Success Rate: 96.1%
   TDD Compliance: ✅ 100%
```

### 5. Phase Indicators

Use clear visual indicators:
- 🔴 **Red Phase** - Writing failing tests
- 🟢 **Green Phase** - Making tests pass
- 🔵 **Refactor Phase** - Improving code
- ✅ **Completed** - All tasks done
- ⚠️ **Blocked** - Needs attention
- 🔄 **In Progress** - Active work

### 6. Detailed View

For single issue view, show:
- Complete task list with checkboxes
- Recent TDD cycles (last 5)
- Commit history with TDD phases
- Test file changes
- Implementation file changes

## Integration Points

- Links to `/pm:tdd` to continue work
- Shows which issues need `/pm:issue-sync`
- Identifies issues ready for `/pm:issue-close`
- Highlights TDD violations if any

## Error Handling

- If no TDD work found: "No active TDD work found. Use /pm:tdd to start."
- If issue not using TDD: "Issue #{num} not using TDD workflow. Use /pm:tdd {num} to start."
- If corrupted logs: Show what can be parsed, note errors