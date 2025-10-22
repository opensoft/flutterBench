# GitHub Copilot Instructions for flutterBench

## Version Management

All template files and configuration files in this repository include version tracking in their header comments.

### Version Format
```
# Version: MAJOR.MINOR.PATCH
# Template: template-name-MAJOR.MINOR.PATCH
```

### Versioning Rules

**When modifying any file with version headers:**

1. **ALWAYS increment the version number** based on the type of change:
   - **PATCH (X.Y.Z+1)**: Bug fixes, typo corrections, minor improvements, documentation updates
   - **MINOR (X.Y+1.0)**: New features, new functionality, backwards-compatible changes
   - **MAJOR (X+1.0.0)**: Breaking changes, major refactoring, incompatible API changes

2. **Update BOTH lines** if present:
   - `# Version: X.Y.Z`
   - `# Template: template-name-X.Y.Z`

3. **Files requiring version tracking:**
   - Docker Compose files (`docker-compose.yml`)
   - Dockerfiles (`Dockerfile`)
   - Environment templates (`.env.base`, `.env.template`)
   - DevContainer configuration files (`devcontainer.json`)
   - Shell scripts in `/scripts` and `/templates/*/scripts`
   - README files with version information

### Examples

**Bug fix (increment patch):**
```diff
- # Version: 2.0.0
+ # Version: 2.0.1
```

**New feature (increment minor):**
```diff
- # Version: 2.0.1
+ # Version: 2.1.0
```

**Breaking change (increment major):**
```diff
- # Version: 2.1.0
+ # Version: 3.0.0
```

## General Coding Standards

- Use consistent indentation (2 spaces for YAML, 4 for shell scripts)
- Always include descriptive comments for complex logic
- Follow existing file structure and naming conventions
- Maintain backwards compatibility unless explicitly making a breaking change
- Test changes in isolated environments before committing
