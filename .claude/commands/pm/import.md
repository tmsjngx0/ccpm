---
allowed-tools: Bash, Read, Write, LS
---

# Import

Import existing GitHub issues into the PM system.

## Usage
```
/pm:import [options] [issue_numbers...]
```

Options:
- `--all` - Import all open issues
- `--epic <name>` - Import into specific epic
- `--label <label>` - Import only issues with specific label
- `--milestone <name>` - Import all issues from milestone
- `--state <state>` - Import issues with state (open/closed/all)
- `--dry-run` - Show what would be imported without doing it
- Issue numbers - Import specific issues (e.g., 123 456 789)

## Instructions

### 1. Fetch GitHub Issues

```bash
# Get issues based on filters
if [[ "$ARGUMENTS" == *"--label"* ]]; then
  gh issue list --label "{label}" --limit 1000 --json number,title,body,state,labels,createdAt,updatedAt
else
  gh issue list --limit 1000 --json number,title,body,state,labels,createdAt,updatedAt
fi
```

### 2. Identify Untracked Issues

For each GitHub issue:
- Search local files for matching github URL
- If not found, it's untracked and needs import

### 3. Categorize Issues

Based on labels:
- Issues with "epic" label → Create epic structure
- Issues with "task" label → Create task in appropriate epic
- Issues with "epic:{name}" label → Assign to that epic
- No PM labels → Ask user or create in "imported" epic

### 4. Create Local Structure

For each issue to import:

**If Epic:**
```bash
mkdir -p .claude/epics/{epic_name}
# Create epic.md with GitHub content and frontmatter
```

**If Task:**
```bash
# Find next available number (001.md, 002.md, etc.)
# Create task file with GitHub content
```

Set frontmatter:
```yaml
name: {issue_title}
status: {open|closed based on GitHub}
created: {GitHub createdAt}
updated: {GitHub updatedAt}
github: https://github.com/{org}/{repo}/issues/{number}
imported: true
```

### 5. Output

```
📥 Import Complete

Imported:
  Epics: {count}
  Tasks: {count}
  
Created structure:
  {epic_1}/
    - {count} tasks
  {epic_2}/
    - {count} tasks
    
Skipped (already tracked): {count}

Next steps:
  Run /pm:status to see imported work
  Run /pm:sync to ensure full synchronization
```

## Important Notes

Preserve all GitHub metadata in frontmatter.
Mark imported files with `imported: true` flag.
Don't overwrite existing local files.