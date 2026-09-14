#!/bin/bash

PROJECT_FOLDER="$(dirname "$(readlink -f "$0")")"
SCRIPT_VERSION="0.6.0"
BACKUP_REPO=""
SOURCE_TAG=""
SOURCE_LOCATION=""

backup() {
  restic \
  --host "$HOSTNAME" \
  -r "$BACKUP_REPO" \
  --verbose \
  --password-file "$RESTIC_KEY" \
  --exclude-file "${PROJECT_FOLDER}/db/excludes.txt" \
  backup \
  --tag "$SOURCE_TAG" \
  "$SOURCE_LOCATION"
}

source "${PROJECT_FOLDER}/.env"

if [ -z "${USERNAME}" ]; then
  USERNAME="shiny-wisplike"
fi

echo "Welcome to ${USERNAME}'s auto-restic script - v${SCRIPT_VERSION}"
echo ""

case "$1" in
  "backup")
    SOURCE_LOCATION="$2"
    SOURCE_TAG="$3"
    BACKUP_REPO="$4"

    backup
    ;;
  *)
    echo "Unknown action. Please try again!"
    ;;
esac
