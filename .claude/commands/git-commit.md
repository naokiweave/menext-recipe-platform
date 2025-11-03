---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*), Bash(git log:*)
description: Create a git commit with staged changes
---

Create a git commit following these steps:

1. Run git status to see all untracked files and modifications
2. Run git diff to see both staged and unstaged changes
3. Run git log to see recent commit messages and follow the repository's commit message style
4. Analyze all changes and draft an appropriate commit message
5. Add relevant files to staging if needed
6. Create the commit with the message ending with:

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>

7. Run git status after the commit to verify success

Important:
- Focus on the "why" rather than the "what" in commit messages
- Keep commit messages concise (1-2 sentences)
- Do not commit files that likely contain secrets (.env, credentials.json, etc.)
- Use git commit -m with HEREDOC format for proper formatting
