# Style Guide

Writing standards for project documentation.

## Core Principles

**Brevity.** Every word must serve a purpose.

**Technical accuracy over accessibility.** Be precise, not friendly.

**Direct language.** Use commands, not suggestions or questions.

**Focus on why.** Explain rationale when it matters, skip obvious explanations.

**Single source of truth.** Never duplicate content across documents.

**No generic content.** Avoid boilerplate and template language.

## General Standards

### Voice and Tone
Write in active voice with imperative mood. Use present tense for facts, imperative for instructions. Keep a professional, technical tone. Skip social pleasantries.

### Formatting
- Standard markdown syntax throughout
- Consistent heading hierarchy (# ## ###)
- Limit code examples to 120 characters per line
- Use backticks for `commands`, `file names`, and technical terms
- Tables only when they clarify complex information

### Language Patterns
Start instructions with action verbs. Use technical terminology consistently and define abbreviations on first use. In technical contexts, use digits for all numbers.

## Document Guidelines

### README.md
User-facing quick reference. Keep it brief. If approaching 150 lines, move details to dedicated documentation. Focus on:
- Project description (2-3 lines)
- Quick start instructions
- Common usage examples (3 to 5)
- Links to detailed documentation
- License information

Never include implementation details, contribution guidelines, or development setup.

### CONTRIBUTING.md
Contribution process and standards for the project. Keep it approachable by staying around 100 lines. Include:
- Core requirements for contributions
- Bug report format and requirements
- Pull request process
- Commit message standards
- Essential style points

Avoid welcome messages, thank you statements, or recognition sections.

### DEVELOPMENT.md
Technical reference for active developers. While detailed, keep content focused. If exceeding 400 lines, split into topic-specific files in a docs/ directory. Cover:
- Tool prerequisites
- Setup commands
- Development workflows
- Testing procedures
- Troubleshooting tables

Link to external resources for installation guides. Focus on commands and validation, not explanations.

When documentation grows beyond these guidelines, create a `docs/` directory with topic-specific files rather than cramming everything into one document.

## Code Documentation

Comments explain why, not what. Remove commented-out code and obvious comments.

Good example:
```bash
# Validate path is absolute and ancestor of CWD for security
```

Bad example:
```bash
# Set variable to true
VAR=true
```

## Forbidden Elements

Never use:
- Emojis
- Thank you statements
- Welcome messages
- "We're excited" or similar enthusiasm
- Duplicate content across files
- Tables of contents for documents under 200 lines
- Recognition or contributor sections
- Exclamation points except in warnings
- Questions as section headers
- "Please" in instructions

## Examples

Instead of:
> Thank you for your interest in contributing! We're excited to have you join our community and look forward to your contributions.

Write:
> Contribution requirements and process.

Instead of:
> Feel free to reach out if you have any questions! We're here to help!

Write:
> See documentation for technical details.

## Validation Checklist

Documentation checklist:
- Remove all emojis and enthusiasm
- Eliminate welcome and thank you statements
- Convert to imperative voice
- Remove redundant explanations
- Verify no content duplication
- Check document length guidelines
- Validate all cross-references
- Confirm technical accuracy

## Maintenance

Update documentation when functionality changes, commands are modified, or breaking changes occur in dependencies.

Update this guide when adding new document types or identifying consistency issues that need addressing.