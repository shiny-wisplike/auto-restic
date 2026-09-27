#!/bin/bash

PROJECT_FOLDER="$(dirname "$(readlink -f "$0")")"
SCRIPT_VERSION="0.8.0"
BACKUP_REPO=""
SOURCE_TAG=""
SOURCE_LOCATION=""
RESTIC_KEY=""
RESTIC_EXEC="/usr/local/bin/restic"

notifyUser() {
  MESSAGE="$SOURCE_TAG has been backed up to $BACKUP_REPO successfully!"

  curl -X POST "${GOTIFY_ADDRESS}/message?token=${GOTIFY_TOKEN}" \
    -H "accept: application/json" \
    -H "Content-Type: application/json" \
    -d "{  \"message\": \"$MESSAGE\",  \"priority\": 0,  \"title\": \"$GOTIFY_TITLE\"}"
}

backup() {
  "$RESTIC_EXEC" \
  --host "$HOSTNAME" \
  -r "$BACKUP_REPO" \
  --verbose \
  --password-file "$RESTIC_KEY" \
  --exclude-file "${PROJECT_FOLDER}/db/excludes.txt" \
  backup \
  --tag "$SOURCE_TAG" \
  "$SOURCE_LOCATION"
}

selectActionMenu() {
  echo ""
  echo "Please select an action: "
  echo "  1 - Backup"
  read -p "Selection: " SELECTED_ACTION

  case "$SELECTED_ACTION" in
    "1")
      echo "Selected: Backup"
      ;;
    *)
      echo "Unknown selection!"
      ;;
  esac
}

source "${PROJECT_FOLDER}/.env"

if [ -z "${USERNAME}" ]; then
  USERNAME="shiny-wisplike"
fi

echo "Welcome to ${USERNAME}'s auto-restic script - v${SCRIPT_VERSION}"
echo ""

case "$1" in
  "m")
    selectActionMenu
  "a")
    SOURCE_LOCATION="$2"
    SOURCE_TAG="$3"
    BACKUP_REPO="$4"
    RESTIC_KEY="$5"

    backup
    notifyUser
    ;;
  *)
    echo "Unknown mode. Please try again!"
    ;;
esac
