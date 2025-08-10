# GOTCHA.md

Common gotchas and pitfalls when working [Claude Code](https://claude.ai/code) in AI-aided fashion.

This file provides guidance to Claude when it keeps making the same mistakes.

## 🐚 Shell Compatibility in Makefiles

### Issue
Makefile targets that use bash-specific syntax (like `[[`, `==`, pattern matching) will fail when executed with `/bin/sh` instead of bash.

### Symptoms
```
/bin/sh: [[: not found
```

### Example Problem
```makefile
# ❌ Bash-specific syntax
if [[ "$$file" == *".pdb" ]]; then
```

### Solution
Use POSIX-compliant shell syntax:
```makefile
# ✅ POSIX-compliant
if [ "$$(echo $$file | grep -c '\.pdb$$')" = "0" ]; then

# ✅ Or use case statements
case "$$file" in
    *.pdb) echo "PDB file" ;;
    *) echo "Other file" ;;
esac
```

### Why This Happens
- Make executes shell commands using `/bin/sh`
- `[[` is a bash builtin not available in POSIX sh
- CI/CD environments often use strict POSIX shells

### Prevention
- Always use POSIX shell syntax in Makefiles
- Test Makefiles with `/bin/sh` explicitly: `sh -c "command"`
- Use `case` statements instead of `[[ == ]]` pattern matching
- Use `grep` for pattern matching instead of shell globs in conditionals
