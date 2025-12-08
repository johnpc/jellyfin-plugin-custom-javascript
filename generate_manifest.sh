#!/bin/bash

REPO="johnpc/jellyfin-plugin-custom-javascript"
OUTPUT_FILE="manifest.json"
GITHUB_API_URL="https://api.github.com/repos/$REPO/releases"

echo "Fetching releases from $REPO..."
AUTH_HEADER=""
[[ -n "$GITHUB_TOKEN" ]] && AUTH_HEADER="-H \"Authorization: token $GITHUB_TOKEN\""
RELEASES=$(curl -s $AUTH_HEADER "$GITHUB_API_URL")

if [[ $RELEASES == *"API rate limit exceeded"* ]]; then
  echo "Error: GitHub API rate limit exceeded."
  exit 1
fi

RELEASE_TAGS=$(echo "$RELEASES" | grep -o '"tag_name": "[^"]*' | sed 's/"tag_name": "//')

if [[ -z "$RELEASE_TAGS" ]]; then
  echo "Error: No releases found"
  exit 1
fi

FIRST_TAG=$(echo "$RELEASE_TAGS" | head -n 1)
FIRST_MANIFEST_URL="https://github.com/$REPO/releases/download/$FIRST_TAG/release-manifest.json"
FIRST_MANIFEST=$(curl -s -L $AUTH_HEADER "$FIRST_MANIFEST_URL")

if [[ -z "$FIRST_MANIFEST" || "$FIRST_MANIFEST" == "Not Found" ]]; then
  echo "Error: Could not fetch first manifest"
  exit 1
fi

BASE_MANIFEST=$(echo "$FIRST_MANIFEST" | jq '.[0] | del(.versions)')
ALL_VERSIONS="[]"

for TAG in $RELEASE_TAGS; do
  MANIFEST_URL="https://github.com/$REPO/releases/download/$TAG/release-manifest.json"
  RELEASE_MANIFEST=$(curl -s -L $AUTH_HEADER "$MANIFEST_URL")
  
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
