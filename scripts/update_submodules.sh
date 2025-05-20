#!/bin/sh
#
# update_submodules.sh
# 
# Script to update BATS helper libraries (bats-assert, bats-support, bats-mock) 
# to their latest semantic version tags.
#
# This script:
# 1. Updates all submodules to the latest commit on their tracked branch
# 2. For each submodule, checks out the latest semantic version tag
#
# Usage: ./scripts/update_submodules.sh
#

# Exit on any error
set -e

# Script must be run from the project root directory
SCRIPT_DIR=$(dirname "$0")
if [ "$SCRIPT_DIR" != "scripts" ] && [ "$SCRIPT_DIR" != "./scripts" ]; then
    echo "Error: This script must be run from the project root directory."
    echo "Usage: ./scripts/update_submodules.sh"
    exit 1
fi

# Ensure submodules are initialized
echo "Ensuring submodules are initialized..."
git submodule init

# Update all submodules to the latest commit on their tracked branch
echo "Updating all submodules to latest commits..."
git submodule update --remote --merge

# Function to update a submodule to its latest semantic version tag
update_submodule_to_latest_tag() {
    submodule_path="$1"
    echo "Updating submodule: $submodule_path"

    if [ ! -d "$submodule_path" ]; then
        echo "Error: Submodule path $submodule_path does not exist."
        return 1
    fi

    (
        cd "$submodule_path" || exit 1
        echo "  - Current directory: $(pwd)"
        
        # Fetch all tags from remote
        echo "  - Fetching tags..."
        git fetch --tags
        
        # Get the latest semantic version tag (vX.Y.Z)
        # This sorts tags that look like versions and picks the last one.
        # It assumes tags are like v0.3.0, v1.2.5 etc.
        latest_tag=$(git tag -l 'v*' | sort -V | tail -n 1)

        if [ -z "$latest_tag" ]; then
            echo "  - No version tags (v*) found for $submodule_path. Skipping tag checkout."
            # Optionally, you might want to checkout a default branch here
            # git checkout main # or master, or the default branch of the submodule
        else
            echo "  - Checking out latest tag: $latest_tag"
            git checkout "$latest_tag"
        fi
    )
    echo "------------------------------------"
}

# Update each BATS helper submodule
update_submodule_to_latest_tag "test/libs/bats-assert"
update_submodule_to_latest_tag "test/libs/bats-support"
update_submodule_to_latest_tag "test/libs/bats-mock"

echo "Submodule update process complete!"
echo "Review changes and commit the updated submodule references:"
echo "git add test/libs/bats-assert test/libs/bats-support test/libs/bats-mock"
echo "git commit -m \"Update BATS helper submodules to latest tags\""