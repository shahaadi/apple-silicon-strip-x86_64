#!/bin/bash

# Prompt for app path
read -p "Enter the full path to the .app bundle (e.g., /Users/you/Downloads/MyApp.app): " app_path

# Validate input
if [ ! -d "$app_path" ]; then
  echo "❌ Error: Directory not found: $app_path"
  exit 1
fi

# Find all executable files and check if they are fat binaries
find "$app_path" -type f -perm +111 | while read -r f; do
  archs=$(lipo -info "$f" 2>/dev/null)

  echo "Checking: $f"
  echo "Architecture Info: $archs"

  if [[ "$archs" == *"x86_64"* && "$archs" == *"arm64"* ]]; then
    echo "Stripping x86_64 from: $f"
    lipo -remove x86_64 "$f" -output "$f.arm64"

    if [ -f "$f.arm64" ]; then
      mv "$f.arm64" "$f"
      echo "✅ Stripped and replaced: $f"
    else
      echo "⚠️ Failed to strip architecture: $f"
    fi
  else
    echo "➡️ Not a fat binary with both x86_64 and arm64: $f"
  fi
done

# Re-sign the app
echo "🔐 Re-signing the app..."
codesign --force --deep --sign - "$app_path"

echo "✅ Done!"

