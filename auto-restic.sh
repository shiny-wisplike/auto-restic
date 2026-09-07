#!/bin/bash

PROJECT_FOLDER="$(dirname "$(readlink -f "$0")")"
BACKUP_REPO=""
SOURCE_TAG=""
SOURCE_LOCATION=""

backup() {
  restic \
  --host "$HOSTNAME" \
  -r "$BACKUP_REPO" \
  --verbose \
  --password-file "$RESTIC_KEY" \
  backup \
  --tag "$SOURCE_TAG" \
  "$SOURCE_LOCATION"
}

source "${PROJECT_FOLDER}/.env"

echo "Please enter the backup repo: "
read BACKUP_REPO

echo "Please enter a tag name for the backup: "
read SOURCE_TAG

echo "Please enter the folder you want to backup: "
read SOURCE_LOCATION

backup
