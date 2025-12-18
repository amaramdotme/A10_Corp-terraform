### DO NOT MODIFY THIS ############
Git Command Reference 
1. Repository Setup
Command	Purpose	Example
git clone <url>	Clone remote repo to local machine	git clone git@github.com:amaramdotme/A10_Corp-terraform.git
git init	Initialize new Git repo in current directory	git init
git remote add origin <url>	Connect local repo to remote	git remote add origin git@github.com:user/repo.git
git remote -v	Show remote repositories	git remote -v
git remote set-url origin <url>	Change remote URL	git remote set-url origin git@github.com:newuser/repo.git
2. Checking Status & History
Command	Purpose	Example
git status	Show working directory and staging area status	git status
git status -s	Show short status (compact view)	git status -s
git log	Show commit history	git log
git log --oneline	Show compact commit history	git log --oneline
git log --graph --oneline	Show branch graph with commits	git log --graph --oneline --all
git log -n 5	Show last 5 commits	git log -n 5
git log --since="2 weeks ago"	Show commits from last 2 weeks	git log --since="2025-01-01"
git log --author="name"	Show commits by specific author	git log --author="Claude"
git show <commit>	Show details of specific commit	git show HEAD
git diff	Show unstaged changes	git diff
git diff --staged	Show staged changes (what will be committed)	git diff --staged
git diff <branch1> <branch2>	Compare two branches	git diff main feature/new-mg
git diff HEAD~1	Compare with previous commit	git diff HEAD~1
3. Branch Management
Command	Purpose	Example
git branch	List local branches (* shows current)	git branch
git branch -a	List all branches (local + remote)	git branch -a
git branch -r	List remote branches only	git branch -r
git branch <name>	Create new branch (doesn't switch to it)	git branch feature/add-finance-mg
git checkout -b <name>	Create and switch to new branch	git checkout -b feature/add-finance-mg
git switch -c <name>	Create and switch to new branch (modern)	git switch -c feature/add-finance-mg
git checkout <branch>	Switch to existing branch	git checkout main
git switch <branch>	Switch to existing branch (modern)	git switch main
git branch -d <name>	Delete local branch (safe - won't delete unmerged)	git branch -d feature/old-feature
git branch -D <name>	Force delete local branch	git branch -D feature/old-feature
git push origin --delete <name>	Delete remote branch	git push origin --delete feature/old-feature
git branch -m <old> <new>	Rename branch	git branch -m old-name new-name
4. Staging Area Operations
Command	Purpose	Example
git add <file>	Stage specific file	git add modules/foundation/management-groups.tf
git add <dir>	Stage entire directory	git add modules/foundation/
git add .	Stage all changes in current directory	git add .
git add -A	Stage all changes in entire repo	git add -A
git add -u	Stage modified/deleted files (not new files)	git add -u
git add -p	Interactively stage parts of files	git add -p modules/foundation/management-groups.tf
git restore --staged <file>	Unstage file (keep changes)	git restore --staged .env
git reset HEAD <file>	Unstage file (older syntax)	git reset HEAD .env
git reset	Unstage all files	git reset
5. Committing Changes
Command	Purpose	Example
git commit -m "message"	Commit staged changes with message	git commit -m "feat: add finance management group"
git commit	Commit with editor for multi-line message	git commit
git commit -am "message"	Stage all tracked files + commit (⚠️ skips staging)	git commit -am "fix: typo in README"
git commit --amend	Edit last commit (message or files)	git commit --amend -m "feat: add finance and marketing MGs"
git commit --amend --no-edit	Add staged changes to last commit (keep message)	git commit --amend --no-edit
git commit --allow-empty -m "msg"	Create empty commit (useful for triggering CI)	git commit --allow-empty -m "chore: trigger workflow"
Commit Message Conventions:

feat: Add new feature
fix: Bug fix
docs: Documentation changes
chore: Maintenance tasks
refactor: Code restructuring
test: Add/update tests
style: Formatting changes
6. Syncing with Remote (Push/Pull)
Command	Purpose	Example
git fetch	Download remote changes (don't merge)	git fetch origin
git fetch --all	Fetch from all remotes	git fetch --all
git pull	Fetch + merge remote changes	git pull origin main
git pull --rebase	Fetch + rebase (cleaner history)	git pull --rebase origin main
git push origin <branch>	Push local branch to remote	git push origin feature/add-finance-mg
git push origin main	Push local main to remote main	git push origin main
git push -u origin <branch>	Push and set upstream tracking	git push -u origin feature/add-finance-mg
git push	Push to tracked upstream branch	git push
git push --force	Force push (⚠️ dangerous - overwrites remote)	git push --force
git push --force-with-lease	Safer force push (fails if remote changed)	git push --force-with-lease
git push --all	Push all branches	git push --all origin
git push --tags	Push all tags	git push --tags
7. Merging & Pull Requests
Command	Purpose	Example
git merge <branch>	Merge branch into current branch	git merge feature/add-finance-mg
git merge --no-ff <branch>	Merge with merge commit (no fast-forward)	git merge --no-ff feature/add-finance-mg
git merge --squash <branch>	Squash all commits into one before merge	git merge --squash feature/add-finance-mg
git merge --abort	Cancel ongoing merge	git merge --abort
gh pr create	Create pull request (GitHub CLI)	gh pr create --base main --head feature/new-mg
gh pr list	List pull requests	gh pr list
gh pr view <number>	View PR details	gh pr view 42
gh pr checkout <number>	Checkout PR locally	gh pr checkout 42
gh pr merge <number>	Merge pull request	gh pr merge 42 --squash
gh pr close <number>	Close pull request	gh pr close 42
8. Undoing Changes
Command	Purpose	Example
git restore <file>	Discard changes in working directory	git restore modules/foundation/management-groups.tf
git restore .	Discard all changes in current directory	git restore .
git checkout -- <file>	Discard changes (older syntax)	git checkout -- file.tf
git restore --staged <file>	Unstage file (keep changes)	git restore --staged .env
git reset --soft HEAD~1	Undo last commit (keep changes staged)	git reset --soft HEAD~1
git reset --mixed HEAD~1	Undo last commit (keep changes unstaged)	git reset --mixed HEAD~1
git reset --hard HEAD~1	Undo last commit (⚠️ delete changes)	git reset --hard HEAD~1
git reset --hard origin/main	Reset to match remote (⚠️ lose local changes)	git reset --hard origin/main
git revert <commit>	Create new commit that undoes specific commit	git revert abc123
git clean -fd	Remove untracked files and directories	git clean -fd
git clean -fdn	Dry run - show what would be deleted	git clean -fdn
9. Stashing (Temporary Storage)
Command	Purpose	Example
git stash	Save changes temporarily	git stash
git stash save "message"	Stash with description	git stash save "WIP: finance MG"
git stash -u	Stash including untracked files	git stash -u
git stash list	Show all stashes	git stash list
git stash show	Show latest stash contents	git stash show
git stash show -p	Show latest stash diff	git stash show -p
git stash pop	Apply latest stash and delete it	git stash pop
git stash apply	Apply latest stash (keep in stash list)	git stash apply
git stash apply stash@{2}	Apply specific stash	git stash apply stash@{2}
git stash drop	Delete latest stash	git stash drop
git stash clear	Delete all stashes	git stash clear
10. Tagging (Version Releases)
Command	Purpose	Example
git tag	List all tags	git tag
git tag <name>	Create lightweight tag	git tag v1.0.0
git tag -a <name> -m "msg"	Create annotated tag (recommended)	git tag -a v1.0.0 -m "Release version 1.0.0"
git tag <name> <commit>	Tag specific commit	git tag v0.9.0 abc123
git show <tag>	Show tag details	git show v1.0.0
git push origin <tag>	Push specific tag to remote	git push origin v1.0.0
git push --tags	Push all tags to remote	git push --tags
git tag -d <name>	Delete local tag	git tag -d v1.0.0
git push origin --delete <tag>	Delete remote tag	git push origin --delete v1.0.0
11. Inspecting & Searching
Command	Purpose	Example
git show <commit>	Show commit details	git show HEAD
git show <commit>:<file>	Show file at specific commit	git show HEAD~1:modules/foundation/main.tf
git blame <file>	Show who changed each line	git blame modules/foundation/main.tf
git grep <pattern>	Search for pattern in tracked files	git grep "azurerm_management_group"
git log -S "text"	Find commits that added/removed text	git log -S "finance"
git log --follow <file>	Show history including renames	git log --follow modules/foundation/main.tf
git ls-files	List all tracked files	git ls-files
git ls-files --others	List untracked files	git ls-files --others
12. Configuration
Command	Purpose	Example
git config --global user.name "name"	Set global username	git config --global user.name "Claude AI"
git config --global user.email "email"	Set global email	git config --global user.email "claude@example.com"
git config --list	Show all configuration	git config --list
git config user.name	Show current username	git config user.name
git config --global core.editor vim	Set default editor	git config --global core.editor "code --wait"
git config --global init.defaultBranch main	Set default branch name	git config --global init.defaultBranch main
git config --global alias.st status	Create alias	git config --global alias.st status
13. Terraform-Specific Workflow Commands
Command	Purpose	Example
git checkout -b feature/new-mg	Create feature branch	git checkout -b feature/add-finance-mg
git add modules/foundation/	Stage Terraform changes	git add modules/foundation/management-groups.tf
git commit -m "feat: add finance MG"	Commit with conventional message	git commit -m "feat: add finance management group"
git push -u origin feature/new-mg	Push feature branch	git push -u origin feature/add-finance-mg
gh pr create --base main	Create PR for review	gh pr create --base main --head feature/add-finance-mg
git checkout main && git pull	Update local main after merge	git checkout main && git pull origin main
git branch -d feature/new-mg	Delete feature branch locally	git branch -d feature/add-finance-mg
14. Emergency Commands (Use with Caution!)
Command	Purpose	Example	⚠️ Warning
git reset --hard HEAD	Discard ALL local changes	git reset --hard HEAD	Loses uncommitted work!
git clean -fd	Delete untracked files/dirs	git clean -fd	Permanent deletion!
git push --force	Overwrite remote history	git push --force	Can break team's work!
git rebase main	Rewrite commit history	git rebase main	Changes commit hashes!
git filter-branch	Rewrite entire repo history	git filter-branch --tree-filter 'rm -f .env'	Extremely dangerous!
15. Workflow Cheat Sheet (Your Terraform CI/CD)

# ===== Feature Branch Workflow (Recommended) =====

# 1. Update local main
git checkout main
git pull origin main

# 2. Create feature branch
git checkout -b feature/add-finance-mg

# 3. Make changes
vim modules/foundation/management-groups.tf

# 4. Stage and commit
git add modules/foundation/management-groups.tf
git commit -m "feat: add finance management group"

# 5. Push feature branch
git push -u origin feature/add-finance-mg

# 6. Create PR (via GitHub CLI)
gh pr create --base main --head feature/add-finance-mg \
  --title "Add finance management group" \
  --body "Adds new management group for finance team"

# 7. After PR merge, clean up
git checkout main
git pull origin main
git branch -d feature/add-finance-mg
git push origin --delete feature/add-finance-mg

# ===== Quick Fix Workflow =====

# For small docs/typo fixes (still use PR for Terraform!)
git checkout -b fix/typo-readme
vim README.md
git add README.md
git commit -m "docs: fix typo in architecture section"
git push -u origin fix/typo-readme
gh pr create --base main --head fix/typo-readme
This comprehensive reference covers all the Git commands you'll need for your Terraform CI/CD workflows! Save this for quick reference.