---
name: version-updating
description: Check for and apply component version updates (Bookdown, Pandoc, TinyTeX, R TinyTeX, R base image) using Makefile targets, then squash into a single commit.
disable-model-invocation: true
model: sonnet
---

# Version Updating

Update all component versions in the Docker Bookdown image.

## Steps

### 1. Check for updates

```bash
make check-versions
```

Review the output. If everything is up to date, stop here.

### 2. Save the current commit as starting point

```bash
START=$(git rev-parse HEAD)
```

You will need this later for the squash step.

### 3. Run the automated update

```bash
make update-deps-all
```

This command:
- Updates each outdated component with an individual commit
- Updates the R base image digest
- Bumps the image version (patch)

### 4. Handle failures

If a component update fails, update it individually:

```bash
make update-bookdown V=X.XX
make update-pandoc V=X.X.X
make update-tinytex V=YYYY.MM
make update-r-tinytex V=X.XX
```

Then run the remaining steps that `update-deps-all` would have done:

```bash
make update-r-base-digest
make bump-patch
```

### 5. Verify

Run these commands and confirm they all pass:

```bash
make validate-all
make build
make test
```

If any step fails, fix the issue before proceeding.

### 6. Squash commits

Collect the individual commit messages:

```bash
git log --reverse --format="- %s" $START..HEAD
```

Save this output. Then squash all update commits:

```bash
git reset --soft $START
```

Create a single commit with the collected messages as body:

```bash
git commit -m "$(cat <<'EOF'
Dependencies updated.

- Pandoc updated to 3.9.0.2.
- TinyTex updated to v2026.04.
- R TinyTex updated to 0.59.
- R base image digest updated.
- Image version bumped to 0.4.5.
EOF
)"
```

Replace the body lines with the actual output from the `git log` command above. The title is always `Dependencies updated.` followed by an empty line. The body lists the specifics.
