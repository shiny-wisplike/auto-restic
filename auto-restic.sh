#!/bin/bash

PROJECT_FOLDER="$(dirname "$(readlink -f "$0")")"
SCRIPT_VERSION="0.18.3"
BACKUP_REPO=""
SOURCE_TAG=""
SOURCE_LOCATION=""
RESTIC_KEY=""
RESTIC_EXEC_PATH="/usr/local/bin/restic"
RESTIC_EXEC="$RESTIC_EXEC_PATH"
IS_REPO_EXIST="false"
BACKUP_REPO_NAME=""
SNAPSHOT_ID=""
RESTORE_SOURCE_PATH=""
RESTORE_TARGET_FOLDER=""

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
      BACKUP_REPO_NAME="$1"
      RESTIC_KEY="$repo_csv_repo_key"
      IS_REPO_EXIST="true"
      break
    fi
  done < "${PROJECT_FOLDER}/db/repos.csv"
}

selectRepoMenu() {
  REPO_NAMES=($(cut -d '|' -f1 "${PROJECT_FOLDER}/db/repos.csv"))

  select REPO_NAME in "${REPO_NAMES[@]}"; do
    echo "Selected: $REPO_NAME"
    checkRepoExist "$REPO_NAME"
    break
  done
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

listSnapshotFiles() {
  "$RESTIC_EXEC" \
  -r "$BACKUP_REPO" \
  --password-file "$RESTIC_KEY" \
  ls \
  "$SNAPSHOT_ID"
}

restore() {
  if [[ "$RESTORE_SOURCE_PATH" == "all" ]]; then
    "$RESTIC_EXEC" \
    -r "$BACKUP_REPO" \
    --password-file "$RESTIC_KEY" \
    restore \
    "$SNAPSHOT_ID" \
    --target "$RESTORE_TARGET_FOLDER"
  else
    "$RESTIC_EXEC" \
    -r "$BACKUP_REPO" \
    --password-file "$RESTIC_KEY" \
    restore \
    "$SNAPSHOT_ID" \
    --target "$RESTORE_TARGET_FOLDER" \
    --include "$RESTORE_SOURCE_PATH"
  fi
}

viewSnapshotsMenu() {
  selectRepoMenu

  viewSnapshots

  echo ""
  echo "Would you like to open a snapshot? [y/n]"
  read OPEN_SNAPSHOT_ANSWER

  if [[ "$OPEN_SNAPSHOT_ANSWER" == "y" ]]; then
    echo "Please enter the snapshot ID: "
    read SNAPSHOT_ID
    listSnapshotFiles
  fi
}

backupMenu() {
  echo ""
  echo "Would you like to execute restic [n]ormally or with [s]udo? [n/s]"
  read RESTIC_EXEC_ANSWER

  if [[ "$RESTIC_EXEC_ANSWER" == "n" ]]; then
    RESTIC_EXEC="$RESTIC_EXEC_PATH"
  elif [[ "$RESTIC_EXEC_ANSWER" == "s" ]]; then
    RESTIC_EXEC="sudo $RESTIC_EXEC_PATH"
  fi

  echo "Please enter the folder path you want to backup: "
  read SOURCE_LOCATION

  echo "Please enter the tag for this snapshot: "
  read SOURCE_TAG

  selectRepoMenu
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

addNewSchedule() {
  echo ""
  echo "Please enter the day(s): "
  echo "You can specify one day or multiple days separated with a comma"
  echo "For monthly schedules, please enter 'any'"
  read NEW_SCHEDULE_DAYS

  echo "Please enter the time (hh:mm)"
  read NEW_SCHEDULE_TIME

  if [[ "$NEW_SCHEDULE_DAYS" == "any" ]]; then
    echo "Please enter the specific day in number for monthly schedules: "
    read NEW_SCHEDULE_DAY_NUM
  else
    NEW_SCHEDULE_DAY_NUM="any"
  fi

  echo "Please enter the action: "
  read NEW_SCHEDULE_ACTION

  echo "Please enter the source path: "
  read NEW_SCHEDULE_SOURCE

  echo "Please enter the tag name for the schedule: "
  read NEW_SCHEDULE_TAG

  selectRepoMenu

  echo "${NEW_SCHEDULE_DAYS}|${NEW_SCHEDULE_TIME}|${NEW_SCHEDULE_DAY_NUM}|${NEW_SCHEDULE_ACTION}|${NEW_SCHEDULE_SOURCE}|${NEW_SCHEDULE_TAG}|${BACKUP_REPO_NAME}" >> "${PROJECT_FOLDER}/db/schedule.csv"
}

restoreFromBackup() {
  viewSnapshotsMenu

  echo ""
  echo "Please enter one of the displayed paths to restore. "
  echo "You can also enter 'all' to restore all files from the snapshot: "
  read RESTORE_SOURCE_PATH

  echo "Please enter the target folder to restore to: "
  read RESTORE_TARGET_FOLDER

  echo "Creating target folder..."
  mkdir -p "$RESTORE_TARGET_FOLDER"

  restore
}

selectActionMenu() {
  echo ""
  echo "Please select an action: "
  echo "  1 - Backup"
  echo "  2 - View Snapshots"
  echo "  3 - Add New Repo"
  echo "  4 - Restore From Backup"
  echo "  5 - Add New Schedule"
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
    "4")
      restoreFromBackup
      ;;
    "5")
      addNewSchedule
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
