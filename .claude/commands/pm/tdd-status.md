---
allowed-tools: Read, Grep, LS, Bash
---

# TDD Status - Test-Driven Development Dashboard

Comprehensive dashboard showing all TDD activity across the project with metrics and insights.

## Usage
```
/pm:tdd-status                # Full TDD dashboard
/pm:tdd-status --summary      # Brief summary only
/pm:tdd-status --violations   # Show TDD violations
```

## Instructions

### 1. Collect TDD Data

Find all issues with TDD activity:
```bash
# Find files with TDD implementation logs
TDD_FILES=$(grep -l "TDD.*Phase" .claude/epics/*/*.md 2>/dev/null)

# Get issue numbers and titles
for file in $TDD_FILES; do
  ISSUE_NUM=$(basename "$file" .md)
  # Extract issue title and current phase
done
```

### 2. Analyze Metrics

For each issue, calculate:
- **Phase Distribution**: Time spent in each phase
- **Cycle Velocity**: Average time per TDD cycle
- **Test Growth**: Tests added over time
- **Coverage Trend**: Coverage improvement
- **Commit Frequency**: Commits per phase

### 3. Check TDD Compliance

Identify violations:
- Code commits without preceding test commits
- Large commits spanning multiple phases  
- Skipped refactoring phases
- Tests added after implementation
- Uncommitted work in progress

### 4. Generate Dashboard

```
🧪 TDD Status Dashboard
=======================
Generated: {timestamp}

📊 Overall Metrics
------------------
Active Issues: 5
Total Cycles: 47 completed
Avg Cycle Time: 38 minutes
Test Coverage: 84.3% (↑ 12.1%)
TDD Compliance: 94%

📈 Phase Distribution
--------------------
🔴 Red:      32% ████████
🟢 Green:    48% ████████████
🔵 Refactor: 20% █████

🏃 Active Work
--------------
#1234 User Auth         🟢 Green    87% coverage   2h ago
#1235 API Endpoints     🔴 Red      72% coverage   30m ago
#1236 Data Migration    🔵 Refactor 91% coverage   1h ago

⏱️ Velocity Trends
-----------------
This Week:  12 cycles/day (↑ 20%)
Last Week:  10 cycles/day
This Month: 11 cycles/day

🎯 Top Performers
----------------
1. #1240 Payment Flow    - 15 cycles, 96% coverage
2. #1236 Data Migration  - 12 cycles, 91% coverage  
3. #1234 User Auth       - 10 cycles, 87% coverage

⚠️ Attention Needed
-------------------
- #1235: Failing test for 2+ hours
- #1237: No refactoring in last 5 cycles
- #1238: Uncommitted changes detected

💡 Insights
-----------
- Refactoring phase often skipped (only 20%)
- Best velocity on Tuesday/Wednesday
- Test coverage improving steadily
- Consider more frequent commits
```

### 5. Summary Mode

For --summary flag, show only:
```
TDD Summary: 5 active issues | 94% compliance | 84.3% coverage
Next: 2 issues need attention (run full status for details)
```

### 6. Violations Mode

For --violations flag, show:
```
🚨 TDD Violations Detected
-------------------------

#1237: Skipped Refactoring
  - Last 5 cycles went Red→Green only
  - Technical debt accumulating
  - Action: Schedule refactoring sprint

#1239: Implementation Before Test  
  - Commit a5f3d2b added code without test
  - Violated TDD principle
  - Action: Add tests retroactively

#1241: Large Multi-Phase Commit
  - Commit b7e9c4a mixed test and implementation
  - Makes rollback difficult
  - Action: Use atomic commits per phase
```

### 7. Export Options

Provide data export for tracking:
```bash
# Generate CSV report
echo "issue,cycles,coverage,compliance" > tdd-report.csv
# Add data rows...

# Generate JSON metrics
cat > tdd-metrics.json << EOF
{
  "generated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "metrics": { ... }
}
EOF
```

## Integration Features

### Git Integration
Show recent TDD commits:
```bash
# Last 10 TDD-related commits
git log --oneline --grep="test:\|feat:\|refactor:" -10
```

### Test Runner Integration
If test results available:
```bash
# Parse test output for metrics
npm test -- --json 2>/dev/null | parse_test_results
```

### GitHub Integration
Link to issues for quick access:
```
View on GitHub:
- #1234: https://github.com/{owner}/{repo}/issues/1234
- #1235: https://github.com/{owner}/{repo}/issues/1235
```

## Advanced Analytics

### Cycle Time Analysis
- Identify bottlenecks in TDD phases
- Compare cycle times across issues
- Trend analysis over time

### Coverage Correlation
- Correlate TDD compliance with coverage
- Identify issues with low test effectiveness
- Suggest focus areas

### Team Patterns
- Identify common TDD anti-patterns
- Highlight best practices from data
- Generate improvement suggestions

## Error Handling

- No TDD data: "No TDD activity found. Use /pm:tdd to start."
- Incomplete data: Show partial dashboard with warnings
- Git errors: Gracefully degrade without git metrics