---
name: release-creating
description: Create a release for the Docker Bookdown image. Push commits, tag, verify the remote build, then create a GitHub release with formatted notes.
disable-model-invocation: true
model: sonnet
---

# Release Creating

Create a release after version updates have been committed.

## Steps

### 1. Review release preparation

```bash
make release
```

This shows pre-flight checks, commits since last tag, generated release notes, and suggested commands. Review the output before proceeding.

### 2. Push commits

```bash
git push origin main
```

### 3. Create and push the tag

Extract the current image version from the Dockerfile:

```bash
VERSION=$(awk -F'"' '/org.opencontainers.image.version=/{print $2}' Dockerfile)
```

Create and push the tag:

```bash
git tag $VERSION
git push origin $VERSION
```

This triggers the publish workflow which builds and pushes the Docker image to GHCR.

### 4. Monitor the build

Wait for the GitHub Actions workflow to complete. Check the status:

```bash
gh run list --limit 1
```

Then watch the run:

```bash
gh run watch
```

If the build fails, investigate the logs, fix the issue, and start over. Do NOT create the GitHub release if the build failed.

### 5. Create the GitHub release

Get the previous tag for the changelog link:

```bash
PREV_TAG=$(git describe --tags --abbrev=0 HEAD~1)
```

Categorize commits since the previous tag into sections:

```bash
git log $PREV_TAG..HEAD --oneline
```

Create the release with formatted notes:

```bash
gh release create $VERSION --title "Release $VERSION" --notes "$(cat <<EOF
## What's Changed

### Dependencies Updated
- Pandoc updated to 3.9.0.2.
- TinyTex updated to v2026.04.
- R TinyTex updated to 0.59.

### Fixes
- fix: description (#PR)

### Infrastructure
- chore(deps): description (#PR)

### Docker Image
- Base image: rocker/r-ver (Ubuntu 24.04 LTS)
- Image version: $VERSION

**Full Changelog**: https://github.com/fsbcg-ubt/docker-bookdown/compare/$PREV_TAG...$VERSION
EOF
)"
```

## Release notes formatting rules

- **Dependencies Updated**: Always include. List each component update from the commit log.
- **Fixes**: Only include if there are `fix:` commits. List each with PR number if applicable.
- **Infrastructure**: Only include if there are `chore(deps):` or `ci:` commits. List each with PR number if applicable.
- **Docker Image**: Always include. Shows base image and version.
- Omit sections that have no matching commits.
