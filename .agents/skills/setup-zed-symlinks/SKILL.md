---
name: setup-zed-symlinks
description: Configure or repair this repository's Zed configuration symlinks on macOS, Linux, or Windows. Use when installing the Zed dotfiles on a machine, changing platform-specific files, or diagnosing broken Zed config links.
---

# Setup Zed Symlinks

Connect the files under this repository's `config/` directory to the native Zed
configuration directory for the current operating system.

## Workflow

1. Determine the operating system from the environment; do not ask the user to
   choose it.
2. Locate the repository root relative to this skill. Configuration under
   `config/<platform>/` overrides an entry with the same name under
   `config/common/`.
3. Check whether Zed is running. If existing destination files need replacing,
   ask the user to close Zed before proceeding so it cannot rewrite them during
   the operation.
4. Run the platform script in dry-run mode and review every proposed link and
   backup:
   - macOS/Linux: `scripts/link-zed-config.sh --dry-run`
   - Windows PowerShell: `scripts/link-zed-config.ps1 -DryRun`
5. If the user requested configuration or repair and the preview only affects
   the expected Zed paths, run the same script in apply mode (`--apply` or
   `-Apply`). Existing destinations are moved to a timestamped backup; never
   delete or overwrite them directly.
6. Verify that each destination is a symlink resolving to the selected source
   file. Report the backup path when one was created and show `git status
   --short` so repository changes caused by Zed remain visible.

## Platform mapping

- macOS: `~/.config/zed`
- Linux: `${XDG_CONFIG_HOME:-~/.config}/zed`
- Windows: `%APPDATA%\Zed`

On Windows, if symbolic-link creation is denied, restore the backed-up file and
tell the user to enable Developer Mode or rerun PowerShell with sufficient
privileges. Do not silently fall back to copies: edits made by Zed must continue
to update this repository.

Only manage Zed configuration. Do not link global agent skills, credentials,
extension downloads, databases, threads, workspace state, or Vim marks.
