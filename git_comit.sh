#!/usr/bin/env bash

# Check for uncommitted changes in the git repository
if git diff-index --quiet HEAD --; then
    echo "No changes to commit."
else
    # Add all changes to the staging area
    git add .

    # Commit the changes
    echo "Auto-comit"
    read commitMessage
    git commit -m "$commitMessage"

    # Push the changes to the remote repository
    echo "Pushing to remote repository..."
    git push origin main

    echo "Changes committed and pushed to remote repository successfully."
fi
