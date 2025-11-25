#!/bin/bash

set -e  # Exit on any error

echo "🚀 Starting release process..."

## Check if we're on main branch
#CURRENT_BRANCH=$(git branch --show-current)
#if [ "$CURRENT_BRANCH" != "main" ]; then
#    echo "❌ Error: You must be on main branch to release. Current branch: $CURRENT_BRANCH"
#    echo "💡 Please switch to main branch: git checkout main"
#    exit 1
#fi
#
#echo "✅ On main branch"
#
## Check for uncommitted changes
#if ! git diff-index --quiet HEAD --; then
#    echo "❌ Error: You have uncommitted changes. Please commit or stash them before releasing."
#    exit 1
#fi
#
#echo "✅ No uncommitted changes"
#
## Pull latest changes
#echo "📥 Pulling latest changes from main..."
#git pull origin main
#
#echo "🧹 Cleaning up old release state..."
#mvn release:clean > /dev/null
#rm -f release.properties pom.xml.releaseBackup

# Get version inputs
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
read -p "📝 Enter release version (e.g., 1.2.0): " RELEASE_VERSION
read -p "📝 Enter next development version (e.g., 1.2.1-SNAPSHOT): " DEV_VERSION
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"

# Check if the tag already exists locally
if git rev-parse "$RELEASE_VERSION" >/dev/null 2>&1; then
    echo "⚠️ Local tag '$RELEASE_VERSION' already exists. Removing it..."
    git tag -d "$RELEASE_VERSION"
fi

# Check if the release tag already exists on GitHub
echo "🔍 Checking if tag $RELEASE_VERSION already exists on origin..."

if git ls-remote --exit-code origin "refs/tags/$RELEASE_VERSION" >/dev/null 2>&1; then
    echo "❌ Error: Tag '$RELEASE_VERSION' already exists on origin (GitHub)."
    echo "💡 Please delete it manually on GitHub before re-running the release."
    exit 1
fi

echo "✅ No existing tag '$RELEASE_VERSION' found on origin. Proceeding..."

# Run Maven release prepare
echo "⚙️ Running mvn release:prepare..."
mvn --batch-mode release:prepare \
    -DreleaseVersion="$RELEASE_VERSION" \
    -DdevelopmentVersion="$DEV_VERSION"

# Get the created tag (Maven release plugin creates a tag)
RELEASE_TAG=$(git describe --tags --abbrev=0)

echo "✅ Release prepared successfully"
echo "🏷️ Release tag: $RELEASE_TAG"

# Push the branch commits (version bumps)
echo "📤 Pushing version bump commits to main..."
git push origin main

# Push the tag to GitHub (This triggers CodePipeline)
echo "📤 Pushing tag $RELEASE_TAG to trigger CodePipeline..."
git push origin "$RELEASE_TAG"

echo "🎉 Release completed successfully!"
echo "✅ Version bump commits pushed to main"
echo "✅ Tag $RELEASE_TAG pushed to trigger CodePipeline"
echo ""
echo "📋 Summary:"
echo "   - Release version: $RELEASE_VERSION"
echo "   - Next dev version: $DEV_VERSION"
echo "   - Tag created: $RELEASE_TAG"