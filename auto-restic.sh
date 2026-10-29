#!/bin/bash

PROJECT_FOLDER="$(dirname "$(readlink -f "$0")")"
SCRIPT_VERSION="0.12.2"
BACKUP_REPO=""
SOURCE_TAG=""
SOURCE_LOCATION=""
RESTIC_KEY=""
RESTIC_EXEC="/usr/local/bin/restic"
IS_REPO_EXIST="false"
BACKUP_REPO_NAME=""

notifyUser() {
  MESSAGE="$SOURCE_TAG has been backed up to $BACKUP_REPO_NAME successfully!"

  curl -X POST "${GOTIFY_ADDRESS}/message?token=${GOTIFY_TOKEN}" \
    -H "accept: application/json" \
    -H "Content-Type: application/json" \
    -d "{  \"message\": \"$MESSAGE\",  \"priority\": 0,  \"title\": \"$GOTIFY_TITLE\"}"
}

checkRepoExist() {
  while IFS='|' read repo_csv_repo_name repo_csv_repo_path repo_csv_repo_key; do
    if [[ "$1" == "$repo_csv_repo_name" ]]; then
      BACKUP_REPO="$repo_csv_repo_path"
      RESTIC_KEY="$repo_csv_repo_key"
      IS_REPO_EXIST="true"
      break
    fi
  done < "${PROJECT_FOLDER}/db/repos.csv"
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
  while true; do
    echo "Please enter the repo name: "
    read REPO_NAME

    checkRepoExist "$REPO_NAME"

    if [[ "$IS_REPO_EXIST" == "false" ]]; then
      echo "Repo name is unknown. Please try again!"
      continue
    else
      break
    fi
  done

  viewSnapshots
}

backupMenu() {
  echo ""
  echo "Please enter the folder path you want to backup: "
  read SOURCE_LOCATION

  echo "Please enter the tag for this snapshot: "
  read SOURCE_TAG

  while true: do
    echo "Please enter the name of the backup repo: "
    read REPO_NAME

    checkRepoExist "$REPO_NAME"

    if [[ "$IS_REPO_EXIST" == "false" ]]; then
      echo "Repo name is unknown. Please try again!"
      continue
    else
      break
    fi
  done

  backup
}

addNewRepo() {
  echo ""
  echo "Please enter the repo name: "
  read NEW_REPO_NAME

  echo "Please enter the repo path: "
  read NEW_REPO_PATH

  echo "Please enter the repo key path: "
  read NEW_REPO_KEY_PATH

  echo "${NEW_REPO_NAME}|${NEW_REPO_PATH}|${NEW_REPO_KEY_PATH}" >> "${PROJECT_FOLDER}/db/repos.csv"
}

selectActionMenu() {
  echo ""
  echo "Please select an action: "
  echo "  1 - Backup"
  echo "  2 - View Snapshots"
  echo "  3 - Add New Repo"
  read -p "Selection: " SELECTED_ACTION

  case "$SELECTED_ACTION" in
    "1")
      echo "Selected: Backup"
      backupMenu
      ;;
    "2")
      viewSnapshotsMenu
      ;;
    "3")
      addNewRepo
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
  "m" | "")
    selectActionMenu
    ;;
  "a")
    SOURCE_LOCATION="$2"
    SOURCE_TAG="$3"
    BACKUP_REPO="$4"
    RESTIC_KEY="$5"
    BACKUP_REPO_NAME="$6"

    backup
    notifyUser
    ;;
  *)
    echo "Unknown mode. Please try again!"
    ;;
esac
