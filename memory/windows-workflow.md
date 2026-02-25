# Windows Workflow

## Environment
- **Platform**: Windows 11
- **Shell**: bash (MSYS2/Git Bash)
- **Compiler**: MinGW GCC

## Important Notes
- Unix commands like `pwd`, `ls`, `cd` don't work in the Bash tool
- Use dedicated tools instead:
  - `Glob` for file listing
  - `Read` for reading files
  - `Bash` only for actual shell commands that need execution
- Build commands must be run from the `src` directory
- Makefiles use POSIX syntax and work in Git Bash

## Build Commands
```bash
cd src
make all          # Build regular tablebase tools
make atomic       # Build atomic chess tools
make suicide      # Build suicide chess tools
make giveaway     # Build giveaway chess tools
make shatranj     # Build shatranj tools
```

## Path Handling
- Paths use forward slashes even on Windows
- Windows line endings (CRLF) may need to be converted