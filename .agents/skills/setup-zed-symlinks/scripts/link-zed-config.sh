#!/usr/bin/env bash

set -eu

usage() {
  printf 'Usage: %s --dry-run|--apply\n' "$0" >&2
  exit 2
}

mode=''
case "${1:-}" in
  --dry-run) mode='dry-run' ;;
  --apply) mode='apply' ;;
  *) usage ;;
esac

if [ "$#" -ne 1 ]; then
  usage
fi

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
repo_root=$(CDPATH='' cd -- "$script_dir/../../../.." && pwd -P)
common_root="$repo_root/config/common"

case "$(uname -s)" in
  Darwin)
    platform='macos'
    target_root="$HOME/.config/zed"
    backup_base="$HOME/Library/Application Support/zed-config/backups"
    ;;
  Linux)
    platform='linux'
    config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
    target_root="$config_home/zed"
    backup_base="$state_home/zed-config/backups"
    ;;
  *)
    printf 'Unsupported operating system. Use link-zed-config.ps1 on Windows.\n' >&2
    exit 1
    ;;
esac

platform_root="$repo_root/config/$platform"
backup_root="$backup_base/$(date -u '+%Y%m%dT%H%M%SZ')-$$"
backup_created='false'

if [ ! -d "$common_root" ] || [ ! -d "$platform_root" ]; then
  printf 'Expected configuration directories are missing under %s/config.\n' "$repo_root" >&2
  exit 1
fi

link_entry() {
  source_path=$1
  destination_path=$2
  entry_name=$3

  if [ -L "$destination_path" ] && [ "$(readlink "$destination_path")" = "$source_path" ]; then
    printf 'ok      %s -> %s\n' "$destination_path" "$source_path"
    return
  fi

  if [ "$mode" = 'dry-run' ]; then
    if [ -e "$destination_path" ] || [ -L "$destination_path" ]; then
      printf 'backup  %s\n' "$destination_path"
    fi
    printf 'link    %s -> %s\n' "$destination_path" "$source_path"
    return
  fi

  mkdir -p "$target_root"
  moved_existing='false'
  backup_path="$backup_root/$entry_name"

  if [ -e "$destination_path" ] || [ -L "$destination_path" ]; then
    mkdir -p "$backup_root"
    mv "$destination_path" "$backup_path"
    moved_existing='true'
    backup_created='true'
    printf 'backed up %s -> %s\n' "$destination_path" "$backup_path"
  fi

  if ln -s "$source_path" "$destination_path"; then
    printf 'linked    %s -> %s\n' "$destination_path" "$source_path"
  else
    if [ "$moved_existing" = 'true' ]; then
      mv "$backup_path" "$destination_path"
      printf 'restored  %s after link creation failed\n' "$destination_path" >&2
    fi
    exit 1
  fi
}

for source_path in "$common_root"/*; do
  [ -e "$source_path" ] || continue
  entry_name=$(basename -- "$source_path")
  if [ -e "$platform_root/$entry_name" ] || [ -L "$platform_root/$entry_name" ]; then
    continue
  fi
  link_entry "$source_path" "$target_root/$entry_name" "$entry_name"
done

for source_path in "$platform_root"/*; do
  [ -e "$source_path" ] || continue
  entry_name=$(basename -- "$source_path")
  link_entry "$source_path" "$target_root/$entry_name" "$entry_name"
done

if [ "$mode" = 'dry-run' ]; then
  printf 'Dry run only. Re-run with --apply to make these changes.\n'
elif [ "$backup_created" = 'true' ]; then
  printf 'Backup: %s\n' "$backup_root"
fi

