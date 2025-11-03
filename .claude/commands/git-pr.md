---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git push:*), Bash(git branch:*), Bash(gh pr create:*)
description: Create a pull request for the current branch
---

Create a pull request following these steps:

1. Run git status to see all untracked files
2. Run git diff to see both staged and unstaged changes
3. Check if the current branch tracks a remote branch and is up to date with the remote
4. Run git log and git diff [base-branch]...HEAD to understand the full commit history for the current branch
5. Analyze all changes that will be included in the pull request (ALL commits, not just the latest one)
6. Draft a comprehensive pull request summary
7. Create new branch if needed
8. Push to remote with -u flag if needed
9. Create PR using gh pr create with the format:

```
gh pr create --title "the pr title" --body "$(cat <<'EOF'
## Summary
<1-3 bullet points>

## Test plan
[Bulleted markdown checklist of TODOs for testing the pull request...]

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

10. Return the PR URL so the user can see it

Important:
- Review ALL commits that will be included in the PR, not just the latest one
- Make sure the PR description accurately reflects all changes
- Include a clear test plan