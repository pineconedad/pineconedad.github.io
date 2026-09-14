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

  case "$relative_path" in
    profile/*) thumbnail_size='420x420>' ;;
    *) thumbnail_size='420x360>' ;;
  esac

  if [ -f "$destination" ] &&
     [ "$destination" -nt "$source" ] &&
     [ "$destination" -nt "$0" ]; then
    continue
  fi

  mkdir -p "$(dirname "$destination")"

  extension="$(printf '%s' "${source##*.}" | tr '[:upper:]' '[:lower:]')"
  case "$extension" in
    gif)
      magick "$source" -coalesce -thumbnail "$thumbnail_size" -layers Optimize "$destination"
      ;;
    *)
      magick "$source" -auto-orient -thumbnail "$thumbnail_size" "$destination"
      ;;
  esac

  echo "Created ${destination#"$ROOT_DIR"/}"
done
