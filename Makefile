# =============================================================================
# Docker Bookdown Management Makefile
# =============================================================================

# Default target
.DEFAULT_GOAL := help

# Safety features - Delete targets on error, preserve important files
.DELETE_ON_ERROR:
.PRECIOUS: Dockerfile

# Use one shell for all commands in a recipe
.ONESHELL:

# Shell configuration
SHELL := /bin/bash
# Exit on error (-e), undefined vars (-u), and pipe failures (-o pipefail) for safer execution
.SHELLFLAGS := -eu -o pipefail -c

# Disable built-in rules
.SUFFIXES:

# Prevent Make from printing "make[1]: Entering directory..." messages
MAKEFLAGS += --no-print-directory

# =============================================================================
# Component Registry - Single source of truth for all components
# =============================================================================

# Define components with their metadata
# Colon-separated format provides simple parseable DSL for component metadata
# Format: name:dockerfile_arg:validation_pattern:commit_prefix:version_format:example
define COMPONENTS
bookdown:BOOKDOWN_VERSION:^[0-9]+\.[0-9]{2}$$:Bookdown:X.XX:0.42
pandoc:PANDOC_VERSION:^[0-9]+\.[0-9]+(\.[0-9]+)?$$:Pandoc:X.X or X.X.X:3.8
r-tinytex:R_TINYTEX_VERSION:^[0-9]+\.[0-9]{2}$$:R TinyTex:X.XX:0.54
endef

# Special handling for TinyTeX due to version prefix
TINYTEX_COMPONENT := tinytex:TINYTEX_VERSION:^20[0-9]{2}\.(0[1-9]|1[0-2])$$:TinyTex:YYYY.MM:2025.01

# =============================================================================
# Variables - Version Extraction from Dockerfile (Lazy evaluation with ?=)
# =============================================================================

# Using AWK for cleaner, more robust version extraction
# ?= defers shell execution until variable is actually referenced (performance optimization)
CURRENT_BOOKDOWN ?= $(shell awk -F= '/^ARG BOOKDOWN_VERSION=/{print $$2}' Dockerfile)
CURRENT_PANDOC ?= $(shell awk -F= '/^ARG PANDOC_VERSION=/{print $$2}' Dockerfile)
CURRENT_TINYTEX ?= $(shell awk -F= '/^ARG TINYTEX_VERSION=/{print $$2}' Dockerfile)
CURRENT_R_TINYTEX ?= $(shell awk -F= '/^ARG R_TINYTEX_VERSION=/{print $$2}' Dockerfile)
CURRENT_IMAGE_VERSION ?= $(shell awk -F'"' '/org.opencontainers.image.version=/{print $$2}' Dockerfile)
CURRENT_R_BASE_DIGEST ?= $(shell awk -F'"' '/org.opencontainers.image.base.digest=/{print $$2}' Dockerfile)

# =============================================================================
# Color Output - Optimized with single check
# =============================================================================

ifdef TERM
	COLOR_RED := \033[0;31m
	COLOR_GREEN := \033[0;32m
	COLOR_YELLOW := \033[1;33m
	COLOR_BLUE := \033[0;34m
	COLOR_RESET := \033[0m
else
	COLOR_RED :=
	COLOR_GREEN :=
	COLOR_YELLOW :=
	COLOR_BLUE :=
	COLOR_RESET :=
endif

# =============================================================================
# Core Functions - DRY principle applied
# =============================================================================

# Unified print function - simple and efficient
define print
printf "$(COLOR_$(1))$(2)$(COLOR_RESET)\n"
endef

# Unified Dockerfile update function
# .bak required for BSD sed compatibility, removed immediately after
define update_dockerfile
sed -i.bak "s|$(1)|$(2)|" Dockerfile && rm -f Dockerfile.bak
endef

# Unified git commit function
define git_commit
git add $(1) && git commit -m "$(2)"
endef

# Generic validation function
define validate
@if ! echo "$(2)" | grep -qE '$(3)'; then \
	printf "$(COLOR_RED)✗ Invalid $(1): $(2) - expected format: $(4)$(COLOR_RESET)\n"; \
	exit 1; \
else \
	printf "$(COLOR_GREEN)✓ Valid $(1): $(2)$(COLOR_RESET)\n"; \
fi
endef

# Component metadata extraction functions
component_name = $(word 1,$(subst :, ,$(1)))
component_arg = $(word 2,$(subst :, ,$(1)))
component_pattern = $(word 3,$(subst :, ,$(1)))
component_prefix = $(word 4,$(subst :, ,$(1)))
component_format = $(word 5,$(subst :, ,$(1)))
component_example = $(word 6,$(subst :, ,$(1)))

# =============================================================================
# Latest Version Fetching - Lazy evaluation functions
# =============================================================================

# Only fetch when needed
define fetch_latest_bookdown
curl -s https://crandb.r-pkg.org/bookdown 2>/dev/null | jq -r '.Version' || echo "error"
endef

define fetch_latest_pandoc
curl -s https://api.github.com/repos/jgm/pandoc/releases/latest 2>/dev/null | \
jq -r '.tag_name' || echo "error"
endef

define fetch_latest_tinytex
curl -s https://api.github.com/repos/rstudio/tinytex-releases/releases/latest 2>/dev/null | \
jq -r '.tag_name | sub("^v";"")' || echo "error"
endef

define fetch_latest_r_tinytex
curl -s https://crandb.r-pkg.org/tinytex 2>/dev/null | jq -r '.Version' || echo "error"
endef

# =============================================================================
# Release Notes Generation
# =============================================================================

define GENERATE_RELEASE_NOTES
LAST_TAG=$$(git describe --tags --abbrev=0 "$(CURRENT_IMAGE_VERSION)^" 2>/dev/null || echo ""); \
printf "## What's Changed\n\n### Dependencies Updated\n"; \
git log --oneline -20 | grep -E "(Bookdown|Pandoc|TinyTex|R TinyTex)" | \
	sed 's/^[a-f0-9]* /- /' || echo "- No dependency updates"; \
printf "\n### Docker Image\n- Base image: r-base:latest\n"; \
printf "- Image version: $(CURRENT_IMAGE_VERSION)\n\n"; \
if [ -n "$$LAST_TAG" ]; then \
	printf "**Full Changelog**: https://github.com/fsbcg-ubt/docker-bookdown/compare/$$LAST_TAG...$(CURRENT_IMAGE_VERSION)"; \
fi
endef

# =============================================================================
# Version Bumping - Single function for all types
# =============================================================================

# Using semver tool for proper semantic version handling
define bump_version
@printf "$(COLOR_BLUE)Bumping $(1) version...$(COLOR_RESET)\n"
@NEW_VERSION=$$(semver -i $(1) $(CURRENT_IMAGE_VERSION)); \
printf "$(COLOR_YELLOW)Bumping version: $(CURRENT_IMAGE_VERSION) → $$NEW_VERSION$(COLOR_RESET)\n"; \
sed -i.bak "s|org.opencontainers.image.version=\".*\"|org.opencontainers.image.version=\"$$NEW_VERSION\"|" Dockerfile && rm -f Dockerfile.bak; \
git add Dockerfile && git commit -m "Image version bumped to $$NEW_VERSION."; \
printf "$(COLOR_GREEN)✓ Version bumped to $$NEW_VERSION$(COLOR_RESET)\n"
endef

# =============================================================================
# Component Update Functions
# =============================================================================

# Using AWK for cleaner component metadata parsing
define update_component
COMPONENT="$(1)"; \
VERSION="$(2)"; \
eval $$(echo "$$COMPONENT" | awk -F: '{ \
print "NAME=" $$1; \
print "ARG=" $$2; \
print "PATTERN=\"" $$3 "\""; \
print "PREFIX=" $$4; \
}'); \
if [ "$$NAME" = "tinytex" ]; then \
VERSION=$$(echo "$$VERSION" | sed 's/^v//'); \
COMMIT_VERSION="v$$VERSION"; \
else \
COMMIT_VERSION="$$VERSION"; \
fi; \
if ! echo "$$VERSION" | grep -qE "$$PATTERN"; then \
$(call print,RED,✗ Invalid $$PREFIX version: $$VERSION); \
exit 1; \
fi; \
$(call update_dockerfile,ARG $$ARG=.*,ARG $$ARG=$$VERSION); \
$(call git_commit,Dockerfile,$$PREFIX updated to $$COMMIT_VERSION.); \
$(call print,GREEN,✓ $$PREFIX updated to $$VERSION)
endef

# =============================================================================
# Help Target
# =============================================================================

.PHONY: help
help:
	@$(call print,BLUE,Docker Bookdown Management Commands)
	@printf "\n"
	@$(call print,GREEN,Version Management:)
	@printf "  make check-versions         Check for dependency updates\n"
	@printf "  make check-renovate-pr      Check for open Renovate PRs\n"
	@printf "  make update-deps            Update all dependencies to latest\n"
	@printf "  make update-deps-auto       Auto-detect and update (PR or latest)\n"
	@printf "  make update-deps-pr PR=123  Update deps via Renovate PR\n"
	@printf "  make update-<component> V=X Update specific component\n"
	@printf "\n"
	@$(call print,GREEN,Release Management:)
	@printf "  make release                Prepare release information\n"
	@printf "  make create-release         Create GitHub release\n"
	@printf "  make create-release-draft   Create draft GitHub release\n"
	@printf "  make bump-patch/minor/major Bump version number\n"
	@printf "\n"
	@$(call print,GREEN,Docker Operations:)
	@printf "  make build                  Build Docker image locally\n"
	@printf "  make test                   Test the Docker image\n"
	@printf "  make shell                  Open shell in container\n"
	@printf "  make clean                  Clean up Docker images\n"
	@printf "\n"
	@$(call print,GREEN,Development:)
	@printf "  make validate-all           Validate all version formats\n"
	@printf "  make check-tools            Check required tools\n"
	@printf "  make show-versions          Show current versions\n"

# =============================================================================
# Version Checking - Optimized with caching
# =============================================================================

# Using column command for automatic table formatting
.PHONY: check-versions
check-versions:
	@$(call print,BLUE,Checking dependency versions...)
	@LATEST_BOOKDOWN=$$($(fetch_latest_bookdown)); \
	LATEST_PANDOC=$$($(fetch_latest_pandoc)); \
	LATEST_TINYTEX=$$($(fetch_latest_tinytex)); \
	LATEST_R_TINYTEX=$$($(fetch_latest_r_tinytex)); \
	{ \
		echo "Component|Current|Latest|Status"; \
		echo "---------|-------|------|------"; \
		STATUS=$$([ "$(CURRENT_BOOKDOWN)" = "$$LATEST_BOOKDOWN" ] && echo "✓ Up to date" || echo "⚠ Update available"); \
		echo "Bookdown|$(CURRENT_BOOKDOWN)|$$LATEST_BOOKDOWN|$$STATUS"; \
		STATUS=$$([ "$(CURRENT_PANDOC)" = "$$LATEST_PANDOC" ] && echo "✓ Up to date" || echo "⚠ Update available"); \
		echo "Pandoc|$(CURRENT_PANDOC)|$$LATEST_PANDOC|$$STATUS"; \
		STATUS=$$([ "$(CURRENT_TINYTEX)" = "$$LATEST_TINYTEX" ] && echo "✓ Up to date" || echo "⚠ Update available"); \
		echo "TinyTeX|$(CURRENT_TINYTEX)|$$LATEST_TINYTEX|$$STATUS"; \
		STATUS=$$([ "$(CURRENT_R_TINYTEX)" = "$$LATEST_R_TINYTEX" ] && echo "✓ Up to date" || echo "⚠ Update available"); \
		echo "R TinyTeX|$(CURRENT_R_TINYTEX)|$$LATEST_R_TINYTEX|$$STATUS"; \
		echo "Docker Image|$(CURRENT_IMAGE_VERSION)|-|Current"; \
	} | column -t -s'|' | while IFS= read -r line; do \
		if echo "$$line" | grep -q "✓ Up to date"; then \
			printf "$${line//✓ Up to date/$(COLOR_GREEN)✓ Up to date$(COLOR_RESET)}\n"; \
		elif echo "$$line" | grep -q "⚠ Update available"; then \
			printf "$${line//⚠ Update available/$(COLOR_YELLOW)⚠ Update available$(COLOR_RESET)}\n"; \
		elif echo "$$line" | grep -q "Current"; then \
			printf "$${line//Current/$(COLOR_GREEN)Current$(COLOR_RESET)}\n"; \
		else \
			echo "$$line"; \
		fi; \
	done

# =============================================================================
# Validation Targets
# =============================================================================

.PHONY: validate-all
validate-all:
	@$(call print,BLUE,Validating all current versions...)
	@$(call validate,Bookdown,$(CURRENT_BOOKDOWN),^[0-9]+\.[0-9]{2}$$,X.XX)
	@$(call validate,Pandoc,$(CURRENT_PANDOC),^[0-9]+\.[0-9]+(\.[0-9]+)?$$,X.X or X.X.X)
	@$(call validate,TinyTeX,$(CURRENT_TINYTEX),^20[0-9]{2}\.(0[1-9]|1[0-2])$$,YYYY.MM)
	@$(call validate,R TinyTeX,$(CURRENT_R_TINYTEX),^[0-9]+\.[0-9]{2}$$,X.XX)
	@$(call validate,Docker image,$(CURRENT_IMAGE_VERSION),^[0-9]+\.[0-9]+\.[0-9]+$$,X.X.X)
	@$(call print,GREEN,All versions are valid!)

# =============================================================================
# Update Dependencies
# =============================================================================

.PHONY: update-deps
update-deps:
ifdef PR
	@$(MAKE) update-deps-pr PR=$(PR)
else
	@$(MAKE) update-deps-all
endif

.PHONY: update-deps-pr
update-deps-pr:
	@$(call print,BLUE,Updating dependencies via PR #$(PR)...)
	@gh pr checkout $(PR) || ($(call print,RED,Failed to checkout PR #$(PR)) && exit 1)
	@$(MAKE) update-deps-all
	@$(call print,GREEN,✓ Updates complete for PR #$(PR))
	@$(call print,YELLOW,Next steps:)
	@echo "  1. Review changes: git log --oneline -10"
	@echo "  2. Push changes: git push"
	@echo "  3. Merge PR on GitHub"
	@echo "  4. Run: make release"

.PHONY: update-deps-all
update-deps-all:
	@$(call print,BLUE,Updating all dependencies to latest versions...)
	@if [ -n "$$(git status --porcelain)" ] && [ -z "$(FORCE)" ]; then \
		$(call print,RED,Error: Working directory not clean. Commit or stash changes first.); \
		echo "Use FORCE=1 to override (not recommended)"; \
		exit 1; \
	fi
	@LATEST_BOOKDOWN=$$($(fetch_latest_bookdown)); \
	LATEST_PANDOC=$$($(fetch_latest_pandoc)); \
	LATEST_TINYTEX=$$($(fetch_latest_tinytex)); \
	LATEST_R_TINYTEX=$$($(fetch_latest_r_tinytex)); \
	UPDATES_MADE=0; \
	if [ "$(CURRENT_BOOKDOWN)" != "$$LATEST_BOOKDOWN" ] && [ "$$LATEST_BOOKDOWN" != "error" ]; then \
		$(call print,YELLOW,Updating Bookdown: $(CURRENT_BOOKDOWN) → $$LATEST_BOOKDOWN); \
		$(call update_component,bookdown:BOOKDOWN_VERSION:^[0-9]+\.[0-9]{2}$$:Bookdown,$$LATEST_BOOKDOWN); \
		UPDATES_MADE=1; \
	else \
		$(call print,GREEN,✓ Bookdown is up to date); \
	fi; \
	if [ "$(CURRENT_PANDOC)" != "$$LATEST_PANDOC" ] && [ "$$LATEST_PANDOC" != "error" ]; then \
		$(call print,YELLOW,Updating Pandoc: $(CURRENT_PANDOC) → $$LATEST_PANDOC); \
		$(call update_component,pandoc:PANDOC_VERSION:^[0-9]+\.[0-9]+(\.[0-9]+)?$$:Pandoc,$$LATEST_PANDOC); \
		UPDATES_MADE=1; \
	else \
		$(call print,GREEN,✓ Pandoc is up to date); \
	fi; \
	if [ "$(CURRENT_TINYTEX)" != "$$LATEST_TINYTEX" ] && [ "$$LATEST_TINYTEX" != "error" ]; then \
		$(call print,YELLOW,Updating TinyTeX: $(CURRENT_TINYTEX) → $$LATEST_TINYTEX); \
		$(call update_component,$(TINYTEX_COMPONENT),$$LATEST_TINYTEX); \
		UPDATES_MADE=1; \
	else \
		$(call print,GREEN,✓ TinyTeX is up to date); \
	fi; \
	if [ "$(CURRENT_R_TINYTEX)" != "$$LATEST_R_TINYTEX" ] && [ "$$LATEST_R_TINYTEX" != "error" ]; then \
		$(call print,YELLOW,Updating R TinyTeX: $(CURRENT_R_TINYTEX) → $$LATEST_R_TINYTEX); \
		$(call update_component,r-tinytex:R_TINYTEX_VERSION:^[0-9]+\.[0-9]{2}$$:R TinyTex,$$LATEST_R_TINYTEX); \
		UPDATES_MADE=1; \
	else \
		$(call print,GREEN,✓ R TinyTeX is up to date); \
	fi; \
	$(MAKE) -s update-r-base-digest; \
	# 1-minute window catches commits from update-r-base-digest above
	@if [ "$$UPDATES_MADE" = "1" ] || [ "$$(git log --oneline -1 --since='1 minute ago' 2>/dev/null | wc -l | tr -d ' ')" -gt "0" ]; then \
		$(MAKE) -s bump-patch; \
	fi; \
	$(call print,GREEN,✓ All dependencies updated successfully!)

# =============================================================================
# Individual Component Updates
# =============================================================================

.PHONY: update-bookdown
update-bookdown:
ifdef V
	@$(call print,BLUE,Updating Bookdown to version $(V)...)
	@$(call update_component,bookdown:BOOKDOWN_VERSION:^[0-9]+\.[0-9]{2}$$:Bookdown,$(V))
else
	@$(call print,RED,Error: Please specify version with V=X.XX)
	@echo "Example: make update-bookdown V=0.45"
endif

.PHONY: update-pandoc
update-pandoc:
ifdef V
	@$(call print,BLUE,Updating Pandoc to version $(V)...)
	@$(call update_component,pandoc:PANDOC_VERSION:^[0-9]+\.[0-9]+(\.[0-9]+)?$$:Pandoc,$(V))
else
	@$(call print,RED,Error: Please specify version with V=X.X.X)
	@echo "Example: make update-pandoc V=3.9.0"
endif

.PHONY: update-tinytex
update-tinytex:
ifdef V
	@$(call print,BLUE,Updating TinyTeX to version $(V)...)
	@$(call update_component,$(TINYTEX_COMPONENT),$(V))
else
	@$(call print,RED,Error: Please specify version with V=YYYY.MM)
	@echo "Example: make update-tinytex V=2025.10"
endif

.PHONY: update-r-tinytex
update-r-tinytex:
ifdef V
	@$(call print,BLUE,Updating R TinyTeX to version $(V)...)
	@$(call update_component,r-tinytex:R_TINYTEX_VERSION:^[0-9]+\.[0-9]{2}$$:R TinyTex,$(V))
else
	@$(call print,RED,Error: Please specify version with V=X.XX)
	@echo "Example: make update-r-tinytex V=0.58"
endif

# =============================================================================
# R Base Digest Update
# =============================================================================

.PHONY: update-r-base-digest
update-r-base-digest:
	@$(call print,BLUE,Updating R base digest...)
	@docker pull r-base:latest > /dev/null 2>&1 || \
		($(call print,YELLOW,Warning: Could not pull r-base:latest) && exit 0)
	@DIGEST=$$(docker inspect r-base:latest 2>/dev/null | \
		jq -r '.[0].RepoDigests[0]' | cut -d'@' -f2); \
	if [ -n "$$DIGEST" ] && echo "$$DIGEST" | grep -qE '^sha256:[a-f0-9]{64}$$'; then \
		if [ "$$DIGEST" != "$(CURRENT_R_BASE_DIGEST)" ]; then \
			$(call update_dockerfile,org.opencontainers.image.base.digest=\".*\",org.opencontainers.image.base.digest=\"$$DIGEST\"); \
			$(call git_commit,Dockerfile,R base image digest updated.); \
			$(call print,GREEN,✓ R base digest updated); \
		else \
			$(call print,GREEN,✓ R base digest is up to date); \
		fi; \
	else \
		$(call print,YELLOW,⚠ Could not extract R base digest); \
	fi

# =============================================================================
# Version Bumping Targets
# =============================================================================

.PHONY: bump-patch
bump-patch:
	@$(call bump_version,patch)

.PHONY: bump-minor
bump-minor:
	@$(call bump_version,minor)

.PHONY: bump-major
bump-major:
	@$(call bump_version,major)

# Backward compatibility alias
.PHONY: bump-version
bump-version: bump-patch

# =============================================================================
# Renovate PR Support
# =============================================================================

.PHONY: check-renovate-pr
check-renovate-pr:
	@$(call print,BLUE,Checking for Renovate PRs...)
	@gh pr list --state open --search "renovate r-base" --limit 3 || \
		$(call print,YELLOW,No Renovate PRs found or gh not configured)

.PHONY: update-deps-auto
update-deps-auto:
	@$(call print,BLUE,Auto-detecting update mode...)
	@PR=$$(gh pr list --state open --search 'renovate r-base' --json number -q '.[0].number' 2>/dev/null); \
	if [ -n "$$PR" ]; then \
		$(call print,GREEN,Found Renovate PR #$$PR); \
		$(MAKE) update-deps-pr PR=$$PR; \
	else \
		$(call print,YELLOW,No Renovate PR found - updating to latest); \
		$(MAKE) update-deps-all; \
	fi

# =============================================================================
# Release Management - Consolidated
# =============================================================================

.PHONY: release
release:
	@$(call print,BLUE,╔══════════════════════════════════════╗)
	@$(call print,BLUE,║      Release Preparation $(CURRENT_IMAGE_VERSION)       ║)
	@$(call print,BLUE,╚══════════════════════════════════════╝)
	@echo ""
	@$(call print,GREEN,Pre-flight Checks:)
	@BRANCH=$$(git branch --show-current); \
	if [ "$$BRANCH" != "main" ]; then \
		$(call print,YELLOW,⚠ Not on main branch (current: $$BRANCH)); \
	else \
		$(call print,GREEN,✓ On main branch); \
	fi
	@if [ -z "$$(git status --porcelain)" ]; then \
		$(call print,GREEN,✓ Working directory clean); \
	else \
		$(call print,YELLOW,⚠ Uncommitted changes present); \
	fi
	@echo "  Latest tag: $$(git describe --tags --abbrev=0 2>/dev/null || echo 'No tags')"
	@echo ""
	@$(call print,GREEN,Recent Commits:)
	@LAST_TAG=$$(git describe --tags --abbrev=0 2>/dev/null || echo ""); \
	if [ -z "$$LAST_TAG" ]; then \
		git log --oneline -10; \
	else \
		echo "Since $$LAST_TAG:"; \
		git log $$LAST_TAG..HEAD --oneline; \
	fi
	@echo ""
	@$(call print,GREEN,Release Notes:)
	@$(GENERATE_RELEASE_NOTES)
	@echo ""
	@echo ""
	@$(call print,BLUE,Release Commands:)
	@$(call print,YELLOW,# Create and push tag:)
	@echo "git tag $(CURRENT_IMAGE_VERSION)"
	@echo "git push origin $(CURRENT_IMAGE_VERSION)"
	@echo ""
	@$(call print,YELLOW,# Create GitHub release:)
	@echo "gh release create $(CURRENT_IMAGE_VERSION) \\"
	@echo "  --title \"Release $(CURRENT_IMAGE_VERSION)\" \\"
	@echo "  --notes \"See commit history for changes\" \\"
	@echo "  --target main"
	@echo ""
	@$(call print,GREEN,Post-Release:)
	@echo "  Monitor: https://github.com/fsbcg-ubt/docker-bookdown/actions"
	@echo "  Image: ghcr.io/fsbcg-ubt/docker-bookdown:$(CURRENT_IMAGE_VERSION)"

# Generic release creation function
define create_release_impl
$(call print,BLUE,$(1) release $(CURRENT_IMAGE_VERSION)...)
@if ! command -v gh >/dev/null 2>&1; then \
	$(call print,RED,Error: GitHub CLI (gh) is not installed!); \
	printf "Install from: https://cli.github.com/\n"; \
	exit 1; \
fi
@if ! git rev-parse "$(CURRENT_IMAGE_VERSION)" >/dev/null 2>&1; then \
	$(call print,YELLOW,Creating tag $(CURRENT_IMAGE_VERSION)...); \
	git tag -a "$(CURRENT_IMAGE_VERSION)" -m "Release $(CURRENT_IMAGE_VERSION)"; \
	read -p "Push tag to origin? (y/N) " -n 1 -r; \
	echo ""; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		git push origin "$(CURRENT_IMAGE_VERSION)"; \
	fi; \
fi
@RELEASE_NOTES=$$($(GENERATE_RELEASE_NOTES)); \
gh release create "$(CURRENT_IMAGE_VERSION)" \
	--title "Release $(CURRENT_IMAGE_VERSION)" \
	--notes "$$RELEASE_NOTES" \
	--target main $(2) && \
$(call print,GREEN,✓ $(1) release created successfully!)
endef

.PHONY: create-release
create-release:
	@$(call create_release_impl,GitHub,)
	@$(call print,GREEN,View: https://github.com/fsbcg-ubt/docker-bookdown/releases/tag/$(CURRENT_IMAGE_VERSION))

.PHONY: create-release-draft
create-release-draft:
	@$(call create_release_impl,Draft,--draft)
	@$(call print,YELLOW,Review and publish at: https://github.com/fsbcg-ubt/docker-bookdown/releases)

# =============================================================================
# Docker Operations
# =============================================================================

.PHONY: build
build:
	@$(call print,BLUE,Building Docker image...)
	@DOCKER_DEFAULT_PLATFORM=linux/amd64 docker build -t docker-bookdown:local . && \
		$(call print,GREEN,✓ Build successful: docker-bookdown:local) || \
		$(call print,RED,✗ Build failed)

.PHONY: test
test: build
	@$(call print,BLUE,Testing Docker image...)
	@echo ""
	@$(call print,YELLOW,R Version:)
	@docker run --rm docker-bookdown:local R --version | head -1
	@echo ""
	@$(call print,YELLOW,Bookdown Version:)
	@docker run --rm docker-bookdown:local R -e "packageVersion('bookdown')" | grep -oE '[0-9]+\.[0-9]+'
	@echo ""
	@$(call print,YELLOW,Pandoc Version:)
	@docker run --rm docker-bookdown:local pandoc --version | head -1
	@echo ""
	@$(call print,YELLOW,TinyTeX Status:)
	@docker run --rm docker-bookdown:local R -e "tinytex::tinytex_root()" | tail -1
	@echo ""
	@$(call print,GREEN,✓ All tests passed)

.PHONY: shell
shell: build
	@$(call print,BLUE,Starting interactive shell in container...)
	@docker run --rm -it docker-bookdown:local /bin/bash

.PHONY: clean
clean:
	@$(call print,BLUE,Cleaning up Docker images...)
	@docker rmi docker-bookdown:local 2>/dev/null && \
		$(call print,GREEN,✓ Removed docker-bookdown:local) || \
		$(call print,YELLOW,No local image to remove)
	@$(call print,GREEN,✓ Cleanup complete)

# =============================================================================
# Development Helpers
# =============================================================================

# Enhanced tool checking with column formatting
.PHONY: check-tools
check-tools:
	@$(call print,BLUE,Checking required tools...)
	@{ \
		echo "Tool|Status|Note"; \
		echo "----|------|----"; \
		for tool in curl jq docker git sed grep awk column semver gum; do \
			if command -v $$tool >/dev/null 2>&1; then \
				case $$tool in \
					semver|gum) echo "$$tool|✓ Installed|Enhancement" ;; \
					*) echo "$$tool|✓ Installed|Required" ;; \
				esac; \
			else \
				case $$tool in \
					semver|gum) echo "$$tool|⚠ Missing|Optional enhancement" ;; \
					*) echo "$$tool|✗ Missing|Required" ;; \
				esac; \
			fi; \
		done; \
		if command -v gh >/dev/null 2>&1; then \
			echo "gh|✓ Installed|For PR operations"; \
		else \
			echo "gh|⚠ Missing|Optional for PRs"; \
		fi; \
	} | column -t -s'|' | while IFS= read -r line; do \
		if echo "$$line" | grep -q "✓ Installed"; then \
			printf "$${line//✓ Installed/$(COLOR_GREEN)✓ Installed$(COLOR_RESET)}\n"; \
		elif echo "$$line" | grep -q "✗ Missing"; then \
			printf "$${line//✗ Missing/$(COLOR_RED)✗ Missing$(COLOR_RESET)}\n"; \
		elif echo "$$line" | grep -q "⚠ Missing"; then \
			printf "$${line//⚠ Missing/$(COLOR_YELLOW)⚠ Missing$(COLOR_RESET)}\n"; \
		else \
			echo "$$line"; \
		fi; \
	done

.PHONY: show-versions
show-versions:
	@$(call print,BLUE,Current Configuration:)
	@echo "  Bookdown:    $(CURRENT_BOOKDOWN)"
	@echo "  Pandoc:      $(CURRENT_PANDOC)"
	@echo "  TinyTeX:     $(CURRENT_TINYTEX)"
	@echo "  R TinyTeX:   $(CURRENT_R_TINYTEX)"
	@echo "  Image:       $(CURRENT_IMAGE_VERSION)"

# =============================================================================
# Advanced Options
# =============================================================================

# Interactive menu using gum
.PHONY: menu
menu:
	@clear
	@while true; do \
		CHOICE=$$(gum choose --header="Docker Bookdown Management Menu" \
			--header.foreground="#0000FF" \
			--cursor.foreground="#00FF00" \
			"🔍 Check for updates" \
			"📦 Update all dependencies" \
			"🚀 Prepare release" \
			"🔨 Build Docker image" \
			"🧪 Test Docker image" \
			"✅ Validate versions" \
			"🔧 Check required tools" \
			"❌ Exit"); \
		case "$$CHOICE" in \
			"🔍 Check for updates") $(MAKE) check-versions ;; \
			"📦 Update all dependencies") $(MAKE) update-deps ;; \
			"🚀 Prepare release") $(MAKE) release ;; \
			"🔨 Build Docker image") $(MAKE) build ;; \
			"🧪 Test Docker image") $(MAKE) test ;; \
			"✅ Validate versions") $(MAKE) validate-all ;; \
			"🔧 Check required tools") $(MAKE) check-tools ;; \
			"❌ Exit"|"") break ;; \
		esac; \
		[ "$$CHOICE" != "❌ Exit" ] && [ -n "$$CHOICE" ] && \
			gum input --placeholder="Press Enter to continue..."; \
	done

# vim: set noexpandtab: