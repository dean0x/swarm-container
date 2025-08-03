# CLAUDE.md Template - Productivity Tools

Add this minimal section to your project's CLAUDE.md file:

---

## Available CLI Tools

This environment includes modern CLI tools. Use them when appropriate:

### Development Tools
- **lazygit** (`lg`) - Interactive git UI for complex operations (rebase, merge conflicts)
- **gh** - GitHub CLI for PRs, issues, releases (`gh pr create`, `gh issue list`)
- **tokei** - Fast code statistics (`tokei`, `tokei src/`)
- **jq** - JSON processor (`cat file.json | jq '.key'`)

### File Tools  
- **eza** - Modern ls with git status (`eza --tree`, `eza -la --git`)
- **bat** - Syntax highlighting (`bat file.py`)
- **ripgrep** (`rg`) - Fast code search (already using)
- **fd** - Fast file finder (already using)

### System Tools
- **bottom** (`btm`) - System monitor when investigating performance
- **dust** - Disk usage visualization (`dust -d 2`)
- **lazydocker** (`lzd`) - Docker container UI

### Navigation
- **zoxide** (`z`) - Smart cd that learns (`z project`, `z docs`)

### Network Tools
- **httpie** (`http`) - User-friendly HTTP client (`http GET api.example.com`)
- **gping** - Visual ping (`gping google.com`)

### Aliases Available
- `lsf`, `llf`, `laf` - Fancy file listings with icons
- `catf` - Fancy cat with syntax highlighting  
- `duf` - Fancy disk usage
- `help` - Simplified man pages (tldr)

---