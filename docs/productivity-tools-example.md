# Productivity Tools Usage Example

## Without Instructions in CLAUDE.md

**User**: "Show me the structure of the src directory"

**Claude Code** (might use):
```bash
ls -la src/
find src -type f -name "*.js"
tree src/  # if installed
```

## With Instructions in CLAUDE.md

**User**: "Show me the structure of the src directory"

**Claude Code** (will use):
```bash
eza --tree src/ --git-ignore --icons
```

---

## Another Example

**User**: "Analyze the codebase and tell me which language is used most"

### Without Instructions:
Claude Code might try various approaches:
- `find . -name "*.js" | wc -l`
- `find . -name "*.py" | wc -l`
- Manual counting

### With Instructions:
Claude Code will immediately use:
```bash
tokei --sort lines
```

Output:
```
===============================================================================
 Language            Files        Lines         Code     Comments       Blanks
===============================================================================
 JavaScript            156        15234        12456          789         1989
 TypeScript             89         8901         7234          456         1211
 JSON                   23          567          567            0            0
 Markdown               12          890          890            0            0
===============================================================================
 Total                 280        25592        21147         1245         3200
===============================================================================
```

---

## Benefits of Adding Instructions

1. **Consistency** - Claude Code uses the best tool for each task
2. **Speed** - Modern tools are significantly faster
3. **Better Output** - Rich, colorful, informative displays
4. **Fewer Errors** - Tools handle edge cases better
5. **Project-Specific** - You can customize which tools to emphasize

## Quick Setup

1. Copy the template from `docs/CLAUDE_MD_TEMPLATE.md`
2. Add it to your project's `CLAUDE.md` file
3. Customize based on your project needs
4. Claude Code will automatically use these tools when appropriate