---
allowed-tools: Read, Write, Edit, LS, Grep
---

# TDD Convert - Add TDD Workflow to Existing Issues

Convert imported or existing issues to use TDD methodology by adding necessary structure and tracking.

## Usage
```
/pm:tdd-convert <issue_number>      # Convert single issue
/pm:tdd-convert --all               # Convert all issues without TDD
/pm:tdd-convert --epic <name>       # Convert all issues in epic
/pm:tdd-convert --check             # List issues not using TDD
```

## Instructions

### 1. Identify Target Issues

Based on arguments:
```bash
# Single issue
if [[ "$ARGUMENTS" =~ ^[0-9]+$ ]]; then
  TARGET_FILES=".claude/epics/*/$ARGUMENTS.md"
  
# All non-TDD issues
elif [[ "$ARGUMENTS" == "--all" ]]; then
  # Find issues without Implementation Log
  TARGET_FILES=$(grep -L "Implementation Log" .claude/epics/*/*.md)
  
# Epic-specific
elif [[ "$ARGUMENTS" =~ "--epic" ]]; then
  EPIC_NAME="{extract_epic_name}"
  TARGET_FILES=".claude/epics/$EPIC_NAME/*.md"
  
# Check mode
elif [[ "$ARGUMENTS" == "--check" ]]; then
  echo "Issues not using TDD:"
  grep -L "TDD.*Phase" .claude/epics/*/*.md
  exit 0
fi
```

### 2. Analyze Existing Structure

For each target issue:
- Check if Implementation Log exists
- Check for existing task breakdown
- Detect test framework if possible
- Identify completed vs pending work

### 3. Add TDD Structure

For issues without TDD structure, append:

```markdown

## Task Breakdown for TDD

Based on the issue requirements, break into TDD-friendly tasks:

- [ ] Task 1: {analyze_and_extract_task}
- [ ] Task 2: {analyze_and_extract_task}
- [ ] Task 3: {analyze_and_extract_task}

## Implementation Log

### {current_datetime} - TDD Conversion
**Action**: Converted issue to TDD workflow
**Status**: Ready to begin TDD implementation
**Test Framework**: {detected_or_prompt}
**Next**: Start with first task using /pm:tdd {issue_number}
```

### 4. Preserve Existing Work

If issue has existing implementation:

```markdown
### {current_datetime} - Pre-TDD Implementation
**Note**: This issue had existing implementation before TDD conversion
**Existing Files**: {list_modified_files}
**Recommendation**: 
  - Add tests for existing code (retroactive TDD)
  - Or refactor using proper TDD for new changes
```

### 5. Update Metadata

Update frontmatter to include TDD tracking:

```yaml
tdd:
  enabled: true
  converted: {current_datetime}
  test_framework: {detected_framework}
  compliance: pending
```

### 6. Smart Task Detection

Analyze issue description to suggest tasks:

1. **Feature Issues**: 
   - Core functionality task
   - Edge cases task  
   - Error handling task
   - Integration task

2. **Bug Issues**:
   - Reproduce bug test task
   - Fix implementation task
   - Prevent regression task

3. **Refactoring Issues**:
   - Add tests for current behavior task
   - Refactor implementation task
   - Verify behavior unchanged task

### 7. Test Framework Detection

Try to detect test framework:
```bash
# Check package.json
if [ -f "package.json" ]; then
  if grep -q "jest" package.json; then
    FRAMEWORK="jest"
  elif grep -q "mocha" package.json; then
    FRAMEWORK="mocha"
  elif grep -q "vitest" package.json; then
    FRAMEWORK="vitest"
  fi
fi

# Check for Python
if [ -f "pytest.ini" ] || [ -f "setup.py" ]; then
  FRAMEWORK="pytest"
fi

# Check for Rust
if [ -f "Cargo.toml" ]; then
  FRAMEWORK="cargo test"
fi
```

## Batch Conversion

When converting multiple issues:

```
🔄 TDD Conversion Report
========================

Converting 12 issues to TDD workflow...

✅ Converted Successfully (10):
  #1234 - User Authentication
  #1235 - API Endpoints
  #1236 - Database Migration
  ... (7 more)

⚠️ Needs Review (2):
  #1240 - Complex issue, manual task breakdown recommended
  #1241 - Existing tests detected, verify compatibility

📊 Summary:
- Total Converted: 10/12
- Test Framework: npm test (detected)
- Ready for TDD: /pm:tdd to start

Next Steps:
1. Review issues marked for review
2. Start TDD with: /pm:tdd
3. Track progress: /pm:tdd-status
```

## Smart Suggestions

Based on issue content, suggest:

1. **Test Strategy**:
   - Unit tests for isolated functions
   - Integration tests for workflows
   - E2E tests for user features

2. **Task Granularity**:
   - Break large issues into 3-7 tasks
   - Each task should be 1-2 hours
   - Tasks should be independently testable

3. **Priority Order**:
   - Core functionality first
   - Edge cases second
   - Performance optimization last

## Validation

After conversion, validate:

```bash
# Check all issues have required sections
for file in $CONVERTED_FILES; do
  echo "Validating $file..."
  grep -q "Implementation Log" "$file" || echo "Missing Implementation Log"
  grep -q "Task Breakdown" "$file" || echo "Missing Task Breakdown"
done
```

## Integration

After conversion:
- Issues are ready for `/pm:tdd` command
- Progress trackable via `/pm:tdd-progress`
- Commits use `/pm:tdd-commit`
- Status visible in `/pm:tdd-status`

## Error Handling

- Issue not found: "❌ Issue #{num} not found in local system"
- Already has TDD: "✓ Issue #{num} already set up for TDD"
- No test framework: Prompt user to configure with `/testing:prime`
- Complex issue: Flag for manual review with explanation