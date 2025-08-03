# CLAUDE.md Template Section for Productivity Tools

Add this section to your project's CLAUDE.md file to help Claude Code use the productivity tools effectively:

---

## Development Tools Usage

When working in this codebase, use these modern CLI tools instead of traditional commands:

### File Navigation and Exploration
- **Use `eza` instead of `ls`** for file listings:
  - `eza --tree --level=2` - Show project structure
  - `eza -la --git` - Show files with git status
  - `eza --tree --git-ignore` - Show structure respecting .gitignore

- **Use `zoxide` for navigation** - After visiting a directory once, jump directly:
  - `z components` - Jump to any components directory previously visited
  - `zi` - Interactive directory selection

### Code Analysis
- **Use `tokei`** to analyze codebase:
  - `tokei` - Show lines of code by language
  - `tokei src/` - Analyze specific directories
  - `tokei --sort lines` - Sort by line count

- **Use `bat` instead of `cat`** for viewing files:
  - `bat README.md` - Syntax highlighted viewing
  - `bat -A file.txt` - Show non-printable characters

### Git Operations
- **Use `lazygit` for complex git operations**:
  - `lg` - Open visual git interface
  - Use for: interactive rebasing, conflict resolution, commit history exploration
  - Still use regular git commands for simple operations

### System and Performance
- **Use `btm` instead of `top/htop`** for system monitoring:
  - `btm` - Interactive system monitor
  - Check when builds are slow or container is unresponsive

- **Use `dust` instead of `du`** for disk usage:
  - `dust` - Visual disk usage in current directory
  - `dust -d 3` - Limit depth to 3 levels
  - Use when checking why builds are large

### Network and APIs
- **Use `gping` for network diagnostics**:
  - `gping google.com` - Visual ping with graphs
  - Use when debugging network issues

- **Use `http` for API testing**:
  - `http GET api.example.com/users` - Test GET requests
  - `http POST api.example.com/users name=John` - Test POST with data
  - Use instead of curl for better readability

### Quick Help
- **Use `tldr` for command help**:
  - `tldr git` - Quick git examples
  - `tldr docker` - Quick docker examples
  - Use instead of man pages for common tasks

### Docker Management
- **Use `lazydocker` for container management**:
  - `lzd` - Open Docker UI
  - Use for: viewing logs, monitoring resources, managing containers

### JSON Processing
- **Use `jq` for JSON manipulation**:
  - `cat package.json | jq '.dependencies'` - Extract dependencies
  - `http GET api.example.com | jq '.data[]'` - Parse API responses

## Best Practices

1. **For file exploration**: Start with `eza --tree` to understand structure
2. **For git history**: Use `lg` when you need to understand complex branch history
3. **For performance issues**: Run `btm` to check resource usage
4. **For large repos**: Use `tokei` to get quick statistics
5. **For debugging**: Combine tools (e.g., `http GET api | jq '.error'`)

Remember: These tools are faster and more informative than traditional Unix commands. Use them to provide better answers and work more efficiently.

---