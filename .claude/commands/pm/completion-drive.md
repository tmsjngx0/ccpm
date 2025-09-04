---
allowed-tools: Read, Write, Edit, Bash, Grep, Task
---

# Completion Drive - Track Assumptions During Implementation

Harness Claude's completion drive productively by tracking assumptions made during code generation for later verification.

## Usage
```
/pm:completion-drive         # Enable for current session
/pm:completion-drive verify  # Find and verify all assumptions
/pm:completion-drive clean   # Remove verified assumption tags
```

## Instructions

### 1. Enable Completion Drive Mode

When enabled, Claude will:
- Mark any assumptions made during generation with `#COMPLETION_DRIVE:`
- Continue generating code without stopping
- Track all assumptions for later verification

Example tags:
```python
# COMPLETION_DRIVE: Assumed method name is get_user_stats() not verified
stats = player.get_user_stats()

# COMPLETION_DRIVE: Assumed response format is JSON dict with 'data' key
return response.json()['data']
```

### 2. Work Normally with TDD

Continue with normal TDD workflow:
- Write tests (assumptions in test are marked too)
- Implement code (assumptions tracked)
- Let completion drive work naturally

### 3. Verify Assumptions

After implementation, run verification:
```bash
# Find all assumption tags
grep -r "COMPLETION_DRIVE:" . --include="*.py" --include="*.js" --include="*.ts"

# For each assumption found:
# 1. Check if assumption is correct
# 2. If correct: Note it
# 3. If incorrect: Fix the code
# 4. Remove the tag after verification
```

### 4. Integration with TDD

During TDD phases:

**Red Phase:**
```python
# Test with assumption
def test_user_authentication():
    # COMPLETION_DRIVE: Assumed auth returns user object with 'id' field
    user = auth.login("test@example.com", "password")
    assert user.id is not None
```

**Green Phase:**
```python
# Implementation with assumption
def login(email, password):
    # COMPLETION_DRIVE: Assumed validate_credentials exists
    if validate_credentials(email, password):
        # COMPLETION_DRIVE: Assumed User model has from_email method
        return User.from_email(email)
```

**Verify Phase (after Green):**
- Run `/pm:completion-drive verify`
- Fix any incorrect assumptions
- Tests will catch assumption errors

### 5. Clean Up

After verification:
```bash
# Remove all verified tags
# Replace with brief comment about what was verified
sed -i 's/# COMPLETION_DRIVE: Assumed/# Verified:/g' file.py
```

## Benefits

1. **No Flow Interruption** - Keep coding without stopping
2. **Systematic Accuracy** - All assumptions tracked and verified
3. **Test Safety Net** - TDD tests catch assumption errors
4. **Learning Pattern** - See where assumptions happen most

## Example Workflow

```bash
# 1. Start TDD with completion drive
/pm:tdd 1234
# Enable completion drive tracking during implementation

# 2. After implementing (with assumptions tracked)
/pm:completion-drive verify

# 3. Fix any incorrect assumptions
# Tests will fail if assumptions wrong

# 4. Clean up tags
/pm:completion-drive clean

# 5. Commit clean code
/pm:tdd-commit green 1234
```

## Quick Report

After verification, see summary:
```
Completion Drive Summary:
- Total assumptions: 8
- Correct: 6 (75%)
- Fixed: 2
- Common pattern: Method naming assumptions
```

## Integration with PM System

- Assumptions tracked in Implementation Log
- Verification part of TDD cycle
- No new complexity, just awareness