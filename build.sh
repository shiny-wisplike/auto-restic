#!/bin/bash

PROJECT_FOLDER="$(dirname "$(readlink -f "$0")")"

CURRENT_VERSION=$(grep -m 1 "^SCRIPT_VERSION=" "${PROJECT_FOLDER}/auto-restic.sh" | cut -d'=' -f2 | tr -d '"' | tr -d '\r')

zip -j "${PROJECT_FOLDER}/builds/${CURRENT_VERSION}-release.zip" "${PROJECT_FOLDER}/auto-restic.sh" "${PROJECT_FOLDER}/check-time.sh"
