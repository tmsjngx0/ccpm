# Migration Guide - Adopting Claude Code PM in Existing Projects

This guide helps you migrate an existing project with GitHub issues to the Claude Code PM system with TDD integration.

## Quick Start (5 minutes)

### 1. Install Claude Code PM

```bash
# In your existing project directory
cd /path/to/your/project

# Install the PM system (backs up existing .claude if present)
curl -sSL https://raw.githubusercontent.com/automazeio/ccpm/main/ccpm.sh | bash

# Or if you already cloned this repo:
cp -r /path/to/ccpm/.claude /path/to/your/project/
```

### 2. Initialize the System

```bash
# Run initialization
/pm:init

# Create CLAUDE.md with TDD instructions
/re-init and add tdd methodology

# Prime the context
/context:create
```

### 3. Import Existing GitHub Issues

```bash
# Import all open issues
/pm:import --all

# Or import specific issues
/pm:import 123 456 789

# Import by label
/pm:import --label "in-progress"
```

## Detailed Migration Steps

### Step 1: Prepare Your Repository

Before migration:
1. **Commit all pending changes** - Start with a clean working tree
2. **Create a backup branch** - `git checkout -b pre-pm-backup`
3. **Document current workflow** - Note your existing process

### Step 2: Install and Configure

```bash
# Clone or install Claude Code PM
curl -sSL https://raw.githubusercontent.com/automazeio/ccpm/main/ccpm.sh | bash

# Initialize
/pm:init

# Configure .gitignore
echo "
# Claude Code PM
.claude/epics/
.claude/context/
.claude/prds/
.claude/settings.local.json
" >> .gitignore
```

### Step 3: Import Existing Issues

The `/pm:import` command converts GitHub issues to the PM format:

```bash
# Import all open issues as an epic
/pm:import --all --epic "existing-work"

# Import specific milestone
/pm:import --milestone "v2.0"

# Import with filters
/pm:import --label "bug" --label "enhancement"
```

What happens during import:
- Creates epic from milestone or groups issues
- Converts each issue to a task file in `.claude/epics/`
- Preserves issue numbers, titles, and descriptions
- Maintains label mappings
- Links to original GitHub issues

### Step 4: Organize Into Epics

After import, organize your issues:

```bash
# List imported issues
ls .claude/epics/imported/

# Create logical epics
/pm:epic-new authentication-refactor
/pm:epic-new performance-optimization

# Move issues to appropriate epics
mv .claude/epics/imported/1234.md .claude/epics/authentication-refactor/
mv .claude/epics/imported/5678.md .claude/epics/performance-optimization/
```

### Step 5: Add TDD to Existing Issues

For each imported issue, add TDD workflow:

```bash
# Start TDD on imported issue
/pm:tdd 1234

# Or batch convert to TDD
/pm:tdd-convert --all
```

This adds:
- Implementation Log section for TDD tracking
- Task breakdown for TDD cycles
- Test framework detection

### Step 6: Create PRDs (Optional)

For better organization, create PRDs retroactively:

```bash
# Create PRD from existing epic
/pm:prd-from-epic authentication-refactor

# This analyzes the epic and creates a PRD
```

## Migration Strategies

### Strategy 1: Big Bang Migration
- Import all issues at once
- Reorganize into epics
- Start using PM system immediately
- Best for: Small teams, <50 issues

### Strategy 2: Incremental Migration
- Import issues by milestone/sprint
- Migrate one epic at a time
- Run both systems in parallel briefly
- Best for: Large teams, many issues

### Strategy 3: New Work Only
- Keep existing issues in GitHub
- Use PM system for new features only
- Gradually migrate old issues as needed
- Best for: Risk-averse teams

## Common Scenarios

### Scenario: Existing PR in Progress

```bash
# Import the issue
/pm:import 1234

# Link to existing PR
/pm:issue-edit 1234 --add-pr 567

# Continue with TDD for remaining work
/pm:tdd 1234
```

### Scenario: Multi-Repository Project

```bash
# In each repository
/pm:init --shared-epics ../shared-pm/

# This creates a shared PM structure
```

### Scenario: Existing Test Suite

```bash
# Configure test command
/testing:prime

# Update test runner configuration
echo 'TEST_CMD="npm test"' >> .claude/settings.local.json

# Start TDD with existing tests
/pm:tdd 1234 --existing-tests
```

## Issue Mapping

The import process creates this mapping:

```
GitHub Issue #123 → .claude/epics/{epic-name}/123.md

Preserves:
- Issue number (filename)
- Title
- Description  
- Labels (as tags)
- Assignee
- Milestone (as epic)

Adds:
- Frontmatter with metadata
- Implementation Log section
- Task breakdown structure
- TDD tracking fields
```

## Validation and Verification

After migration:

```bash
# Validate imported issues
/pm:validate

# Check import status
/pm:import-status

# Compare with GitHub
/pm:sync --dry-run

# Generate migration report
/pm:migration-report
```

## Rollback Plan

If you need to rollback:

```bash
# Remove PM system but keep issues
rm -rf .claude/

# Or full rollback
git checkout pre-pm-backup
git branch -D main
git checkout -b main

# Issues remain in GitHub unchanged
```

## Team Training

### Quick Team Onboarding

1. **Share this guide** with your team
2. **Run a practice session**:
   ```bash
   # Create practice epic
   /pm:prd-new practice-feature
   /pm:prd-parse practice-feature
   /pm:epic-decompose practice-feature
   ```

3. **Practice TDD workflow**:
   ```bash
   # Demo TDD cycle
   /pm:tdd
   /pm:tdd-commit red
   /pm:tdd-progress
   ```

### Gradual Adoption

Week 1: Import and organize issues
Week 2: Start using TDD commands
Week 3: Full workflow adoption
Week 4: Review and optimize

## Troubleshooting

### "Can't import private repository"
```bash
# Ensure GitHub CLI is authenticated
gh auth login
gh auth status
```

### "Issues not syncing"
```bash
# Force sync
/pm:sync --force

# Check for conflicts
/pm:validate --fix
```

### "TDD commands not working"
```bash
# Reinstall TDD components
/re-init and add tdd

# Verify test framework
/testing:prime
```

## Best Practices

1. **Start Small** - Import a few issues first
2. **Train the Team** - Everyone should understand TDD workflow
3. **Document Conventions** - Add team rules to CLAUDE.md
4. **Regular Syncs** - Keep GitHub updated
5. **Incremental Adoption** - Don't force everything at once

## Next Steps

After successful migration:

1. Create new features with full workflow:
   ```bash
   /pm:prd-new new-feature
   /pm:prd-parse new-feature
   /pm:epic-oneshot new-feature
   /pm:tdd
   ```

2. Monitor TDD adoption:
   ```bash
   /pm:tdd-status
   ```

3. Optimize for your team:
   - Customize commands in `.claude/commands/`
   - Add team-specific agents
   - Create custom rules

## Support

- **Documentation**: See README.md
- **Commands Help**: `/pm:help`
- **TDD Help**: `/pm:tdd --help`
- **Issues**: https://github.com/automazeio/ccpm/issues