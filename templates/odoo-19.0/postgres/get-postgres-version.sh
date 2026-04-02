#!/bin/bash
# Get the latest minor version for a given PostgreSQL major version
# Usage: ./get-postgres-version.sh <major_version>

MAJOR_VERSION="${1:?Usage: $0 <major_version>}"

# Query Docker Hub for the latest tag matching the major version
VERSION=$(curl -s "https://registry.hub.docker.com/v2/repositories/library/postgres/tags?page_size=100&name=${MAJOR_VERSION}." \
  | grep -oP "\"name\":\\s*\"${MAJOR_VERSION}\\.\\d+\"" \
  | head -1 \
  | grep -oP "${MAJOR_VERSION}\\.\\d+")

if [ -z "$VERSION" ]; then
  echo "${MAJOR_VERSION}" # Fallback to major version only
else
  echo "$VERSION"
fi
