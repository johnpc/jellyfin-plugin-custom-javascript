#!/bin/bash

REPO="johnpc/jellyfin-plugin-custom-javascript"
OUTPUT_FILE="manifest.json"
GITHUB_API_URL="https://api.github.com/repos/$REPO/releases"

echo "Fetching releases from $REPO..."
if [[ -n "$GITHUB_TOKEN" ]]; then
  AUTH_HEADER="-H \"Authorization: token $GITHUB_TOKEN\""
  RELEASES=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$GITHUB_API_URL")
else
  AUTH_HEADER=""
  RELEASES=$(curl -s "$GITHUB_API_URL")
fi

if [[ $RELEASES == *"API rate limit exceeded"* ]]; then
  echo "Error: GitHub API rate limit exceeded."
  exit 1
fi

RELEASE_TAGS=$(echo "$RELEASES" | grep -o '"tag_name": "[^"]*' | sed 's/"tag_name": "//')

if [[ -z "$RELEASE_TAGS" ]]; then
  echo "Error: No releases found"
  exit 1
fi

# Find first valid manifest
FIRST_MANIFEST=""
for TAG in $RELEASE_TAGS; do
  MANIFEST_URL="https://github.com/$REPO/releases/download/$TAG/manifest.json"
  if [[ -n "$GITHUB_TOKEN" ]]; then
    TEST_MANIFEST=$(curl -s -L -H "Authorization: token $GITHUB_TOKEN" "$MANIFEST_URL")
  else
    TEST_MANIFEST=$(curl -s -L "$MANIFEST_URL")
  fi
  
  if [[ -n "$TEST_MANIFEST" && "$TEST_MANIFEST" != "Not Found" ]]; then
    FIRST_MANIFEST="$TEST_MANIFEST"
    break
  fi
done

if [[ -z "$FIRST_MANIFEST" || "$FIRST_MANIFEST" == "Not Found" ]]; then
  echo "Error: Could not fetch first manifest"
  exit 1
fi

BASE_MANIFEST=$(echo "$FIRST_MANIFEST" | jq '.[0] | del(.versions)')
ALL_VERSIONS="[]"

for TAG in $RELEASE_TAGS; do
  MANIFEST_URL="https://github.com/$REPO/releases/download/$TAG/manifest.json"
  if [[ -n "$GITHUB_TOKEN" ]]; then
    RELEASE_MANIFEST=$(curl -s -L -H "Authorization: token $GITHUB_TOKEN" "$MANIFEST_URL")
  else
    RELEASE_MANIFEST=$(curl -s -L "$MANIFEST_URL")
  fi
  
  [[ -z "$RELEASE_MANIFEST" || "$RELEASE_MANIFEST" == "Not Found" ]] && continue
  
  VERSION_ENTRY=$(echo "$RELEASE_MANIFEST" | jq '.[0].versions[0]')
  [[ "$VERSION_ENTRY" == "null" ]] && continue
  
  if [[ "$ALL_VERSIONS" == "[]" ]]; then
    ALL_VERSIONS="[$VERSION_ENTRY]"
  else
    ALL_VERSIONS=$(echo "$ALL_VERSIONS" | jq ". + [$VERSION_ENTRY]")
  fi
done

SORTED_VERSIONS=$(echo "$ALL_VERSIONS" | jq 'sort_by(.version | split(".") | map(tonumber)) | reverse')
FINAL_MANIFEST=$(echo "$BASE_MANIFEST" | jq --argjson versions "$SORTED_VERSIONS" '. + {versions: $versions}')
echo "[$FINAL_MANIFEST]" | jq '.' > "$OUTPUT_FILE"
echo "Generated manifest.json"
