# Zed configuration

Personal Zed configuration shared across macOS, Linux, and Windows.

## Layout

```text
config/
├── common/          Shared Zed files
├── macos/           macOS overrides
├── linux/           Linux overrides
└── windows/         Windows overrides
```

For a file with the same name, the platform-specific version takes precedence
over `config/common`. At present, `settings.json` is shared and `keymap.json`
is platform-specific.

The canonical setup skill lives at:

```text
.agents/skills/setup-zed-symlinks/
```

The `.claude/skills` and `.cursor/skills` entries are relative symlinks to that
canonical skill.

## Setup

Invoke `$setup-zed-symlinks` from an agent that recognizes repository skills.
The skill detects the operating system, previews the changes, applies them, and
verifies the resulting links.

The underlying scripts can also be run directly:

```sh
# macOS or Linux: preview, then apply
bash .agents/skills/setup-zed-symlinks/scripts/link-zed-config.sh --dry-run
bash .agents/skills/setup-zed-symlinks/scripts/link-zed-config.sh --apply
```

```powershell
# Windows PowerShell: preview, then apply
& .\.agents\skills\setup-zed-symlinks\scripts\link-zed-config.ps1 -DryRun
& .\.agents\skills\setup-zed-symlinks\scripts\link-zed-config.ps1 -Apply
```

Existing destination files are moved to a timestamped backup before a link is
created. On Windows, creating symbolic links may require Developer Mode or an
elevated PowerShell session. Git must also be configured to check out repository
symlinks if the Claude/Cursor aliases are needed.

Zed extensions are declared through `auto_install_extensions` in
`config/common/settings.json`; downloaded extension files, caches, credentials,
workspace state, agent threads, and Vim marks are intentionally not stored here.

