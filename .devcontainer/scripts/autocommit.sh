#!/bin/bash

# Navigate to the root directory of the repository
cd "$(git rev-parse --show-toplevel)" > /dev/null 2>&1

# Update local repository information and integrate changes from the remote branch
git pull origin main > /dev/null 2>&1

# Check if the local branch is tracking the remote branch
if ! git rev-parse --abbrev-ref @{u} >/dev/null 2>&1; then
    git branch --set-upstream-to=origin/main > /dev/null 2>&1
    exit 1
fi

# Check for local changes
if git diff-index --quiet HEAD --; then
    # No changes to commit
    exit 0
else
    # Add all changes to the staging area
    git add -A > /dev/null 2>&1

    # Commit the changes
    if ! git commit -m "Auto-commit changes" > /dev/null 2>&1; then
        echo "Autocommit failed."
        exit 1
    fi
fi

# Check if there are commits to push (i.e., local branch is ahead of the remote)
if git log origin/main..HEAD --oneline | grep . > /dev/null 2>&1; then
    # Push the changes to the remote repository
    if ! git push origin main > /dev/null 2>&1; then
        echo "Push failed. Your local branch (codespaces) might be out of sync with the remote (GitHub)."
        exit 1
    fi
fi

exit 0  # Changes successfully committed and pushed (if there were any to push)