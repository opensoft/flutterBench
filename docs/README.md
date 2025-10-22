# FlutterBench Documentation

Complete documentation for the Flutter DevContainer development environment.

## 📚 Documentation Overview

This documentation covers the **FlutterBench system** - the template and infrastructure for Flutter development with DevContainers.

### Who This Is For

- **Template Maintainers**: Updating and improving the Flutter DevContainer template
- **System Administrators**: Setting up shared infrastructure
- **Advanced Users**: Understanding the architecture and customization options

### For Project-Level Documentation

If you're working on a **specific Flutter project** using this template:
- See `.devcontainer/docs/` in your project folder
- Start with `.devcontainer/docs/README.md` for quick start guides

---

## 📖 Documentation Files

### Configuration & Setup

**[env-file-docker-compose-guide.md](env-file-docker-compose-guide.md)**  
Complete guide to environment variables and Docker Compose configuration
- How .env files work with Docker Compose
- Complete variable reference (v2.0.0)
- Configuration examples and best practices
- Debugging and troubleshooting

**[template-configuration-guide.md](template-configuration-guide.md)**  
Template configuration architecture and philosophy
- Centralized configuration via .env
- Container naming system
- Variable flow and lifecycle
- File structure and responsibilities

### Architecture & Infrastructure

**[flutter-infrastructure-architecture.md](flutter-infrastructure-architecture.md)**  
System architecture and design
- Shared ADB infrastructure design
- Network topology (dartnet)
- Communication flow diagrams
- Lifecycle management

**[infrastructure-qa-and-setup.md](infrastructure-qa-and-setup.md)**  
Q&A and setup clarifications
- Common setup questions answered
- Infrastructure configuration
- Template usage instructions
- Path verification

### Development Guides

**[vscode-tasks-snippets.md](vscode-tasks-snippets.md)**  
VS Code configuration and code snippets
- Complete tasks.json for Flutter projects
- DevContainer.json templates
- Docker-compose.yml examples
- Dockerfile templates
- Shell script snippets

**[path-pinning-verification.md](path-pinning-verification.md)**  
Path resolution and verification
- Relative path strategy
- Path calculation formulas
- Verification procedures
- Troubleshooting path issues

### Reference Documentation

**[document-index.md](document-index.md)**  
Master index of all documentation
- Document set overview
- Quick navigation guide
- Implementation phases
- Key concepts summary

**[CONTAINER_COMPARISON.md](CONTAINER_COMPARISON.md)**  
Comparison of container approaches
- FlutterBench vs Project containers
- Use case recommendations

**[PROJECT_IMPLEMENTATION_SUMMARY.md](PROJECT_IMPLEMENTATION_SUMMARY.md)**  
Historical implementation summary
- Project evolution
- Implementation decisions
- Lessons learned

---

## 🚀 Quick Start Guides

### For Template Users

**Creating a New Project**:
```bash
cd /home/brett/projects/workBenches/devBenches/flutterBench/scripts
./new-flutter-project.sh myproject ../../Dartwingers
```

**Updating an Existing Project**:
```bash
cd /home/brett/projects/workBenches/devBenches/flutterBench/scripts
./update-flutter-project.sh /path/to/project
```

### For Template Maintainers

1. **Update template files** in `templates/flutter-devcontainer-template/`
2. **Increment version numbers** in:
   - `.devcontainer/Dockerfile` (version comments)
   - `.devcontainer/docker-compose.yml` (version comments)
   - `.devcontainer/.env.base` (version header)
3. **Test template** with new-flutter-project.sh
4. **Update documentation** as needed

---

## 🎯 Key Concepts

### 1. Shared ADB Infrastructure

**What**: Single ADB server container shared by all Flutter projects  
**Why**: Eliminates port 5037 conflicts, consistent device connections  
**Where**: `infrastructure/mobile/android/adb/`

### 2. Environment-Driven Configuration (v2.0.0)

**What**: All project configuration in `.devcontainer/.env` file  
**Why**: Never modify template files, perfect reusability  
**How**: Docker Compose substitutes `${VARIABLES}` from .env

### 3. Template Architecture

**Bench Level**: System-wide templates and infrastructure  
**Project Level**: Individual Flutter project containers  

**Philosophy**: 
- FlutterBench = Heavy development workbench
- Project containers = Lightweight debugging/running

---

## 📁 File Structure

```
flutterBench/
├── docs/                           # THIS DIRECTORY - System documentation
│   ├── README.md                   # This file
│   ├── env-file-docker-compose-guide.md
│   ├── template-configuration-guide.md
│   ├── flutter-infrastructure-architecture.md
│   ├── infrastructure-qa-and-setup.md
│   ├── vscode-tasks-snippets.md
│   ├── path-pinning-verification.md
│   ├── document-index.md
│   ├── CONTAINER_COMPARISON.md
│   └── PROJECT_IMPLEMENTATION_SUMMARY.md
│
├── templates/
│   └── flutter-devcontainer-template/
│       ├── .devcontainer/
│       │   ├── devcontainer.json
│       │   ├── docker-compose.yml
│       │   ├── Dockerfile
│       │   ├── .env.base            # v2.0.0 template
│       │   ├── docs/               # Project-level docs
│       │   ├── scripts/            # Startup scripts
│       │   └── adb-service/        # ADB configuration
│       ├── .vscode/
│       ├── .github/
│       └── scripts/
│
└── scripts/
    ├── new-flutter-project.sh      # Create new projects
    ├── update-flutter-project.sh   # Update existing projects
    └── new-dartwing-project.sh     # Create Dartwing projects
```

---

## 🔄 Version History

### v2.0.0 (October 2025)
- **Centralized .env configuration**: All settings in `.devcontainer/.env`
- **.devcontainer organization**: All Docker files in .devcontainer/ folder
- **Dynamic user configuration**: Use `$(whoami)`, `$(id -u)`, `$(id -g)`
- **Comprehensive variables**: Added COMPOSE_PROJECT_NAME, ADB_INFRASTRUCTURE_PROJECT_NAME, etc.
- **Documentation restructuring**: Consolidated and organized all docs

### v1.0.0 (Earlier 2025)
- Initial shared ADB infrastructure
- Template-based project creation
- Basic environment variable support

---

## 🛠️ Common Tasks

### Update Template After Modifying Files

After modifying any file in `templates/flutter-devcontainer-template/`:

1. **Increment version numbers** (follow rule: hLPRgFHb5Y0f9ulTfGtfm8)
2. **Test the template**:
   ```bash
   cd scripts
   ./new-flutter-project.sh test-project /tmp
   cd /tmp/test-project
   code .
   # Test in container
   ```
3. **Update existing projects** (optional):
   ```bash
   ./update-flutter-project.sh /path/to/existing/project
   ```

### Add New Environment Variable

1. **Add to `.devcontainer/.env.base`** with documentation
2. **Use in docker-compose.yml**: `${NEW_VARIABLE:-default}`
3. **Update documentation**: env-file-docker-compose-guide.md
4. **Increment version numbers**
5. **Test with new project**

### Modify Shared Infrastructure

1. **Update infrastructure files** in `infrastructure/` (outside flutterBench)
2. **Test with existing projects**
3. **Document changes** in relevant docs
4. **Notify project maintainers** if breaking changes

---

## 📖 Additional Resources

### Internal Links
- [Bench-level documentation](.) - This directory
- [Template](../templates/flutter-devcontainer-template/) - DevContainer template
- [Scripts](../scripts/) - Project creation and update scripts

### External Resources
- [VS Code DevContainers](https://code.visualstudio.com/docs/devcontainers/containers)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Flutter Documentation](https://docs.flutter.dev/)

---

## 🤝 Contributing

### Documentation Updates

1. **Follow existing structure** and naming conventions
2. **Update version numbers** in modified files
3. **Test examples** before documenting
4. **Keep README.md updated** with new files

### Template Updates

1. **Test thoroughly** before committing
2. **Increment version numbers** per rules
3. **Update related documentation**
4. **Maintain backward compatibility** when possible

---

**Last Updated**: October 2025  
**Version**: 2.0.0  
**Maintained by**: FlutterBench Team
