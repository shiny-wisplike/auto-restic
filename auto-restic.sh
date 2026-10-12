#!/bin/bash

PROJECT_FOLDER="$(dirname "$(readlink -f "$0")")"
SCRIPT_VERSION="0.10.0"
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

viewSnapshots() {
  "$RESTIC_EXEC" \
  --host "$HOSTNAME" \
  -r "$BACKUP_REPO" \
  --verbose \
  --password-file "$RESTIC_KEY" \
  snapshots
}

viewSnapshotsMenu() {
  IS_REPO_EXIST="false"

  while true; do
    echo "Please enter the repo name: "
    read REPO_NAME

    while IFS='|' read repo_csv_repo_name repo_csv_repo_path repo_csv_repo_key; do
      if [[ "$REPO_NAME" == "$repo_csv_repo_name" ]]; then
        BACKUP_REPO="$repo_csv_repo_path"
        RESTIC_KEY="$repo_csv_repo_key"
        IS_REPO_EXIST="true"
        break
      fi
    done < "${PROJECT_FOLDER}/db/repos.csv"

    if [[ "$IS_REPO_EXIST" == "false" ]]; then
      echo "Repo name is unknown. Please try again!"
      continue
    else
      break
    fi
  done

  viewSnapshots
}

selectActionMenu() {
  echo ""
  echo "Please select an action: "
  echo "  1 - Backup"
  echo "  2 - View Snapshots"
  read -p "Selection: " SELECTED_ACTION

  case "$SELECTED_ACTION" in
    "1")
      echo "Selected: Backup"
      ;;
    "2")
      viewSnapshotsMenu
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
    ;;
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
