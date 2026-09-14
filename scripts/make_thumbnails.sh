#!/usr/bin/env bash

set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/assets/images"
DESTINATION_DIR="$ROOT_DIR/assets/thumbnails"

if ! command -v magick >/dev/null 2>&1; then
  echo "ImageMagick is required. Install it, then run this script again." >&2
  exit 1
fi

find "$SOURCE_DIR" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \) -print0 |
while IFS= read -r -d '' source; do
  relative_path="${source#"$SOURCE_DIR"/}"
  destination="$DESTINATION_DIR/$relative_path"

  if [ -f "$destination" ] && [ "$destination" -nt "$source" ]; then
    continue
  fi

  mkdir -p "$(dirname "$destination")"

  extension="$(printf '%s' "${source##*.}" | tr '[:upper:]' '[:lower:]')"
  case "$extension" in
    gif)
      magick "$source" -coalesce -thumbnail '420x360>' -layers Optimize "$destination"
      ;;
    *)
      magick "$source" -auto-orient -thumbnail '420x360>' "$destination"
      ;;
  esac

  echo "Created ${destination#"$ROOT_DIR"/}"
done
