#!/bin/bash

PROJECT_FOLDER="$(dirname "$(readlink -f "$0")")"
CSV_FIELDS="csv_day csv_time csv_action csv_source csv_tag csv_repo"

executeAction() {
  CSV_ROW="$1"

  IFS='|' read -r $CSV_FIELDS <<< "$CSV_ROW"

  case "$csv_action" in
    "backup")
      /bin/bash "${PROJECT_FOLDER}/auto-restic.sh" "backup" "$csv_source" "$csv_tag" "$csv_repo"
      ;;
  esac
}

checkTime() {
  CURRENT_TIME=$(date +"%H:%M")
  CSV_ROW="$1"

  IFS='|' read -r $CSV_FIELDS <<< "$CSV_ROW"

  if [[ "$CURRENT_TIME" == "$csv_time" ]]; then
    echo "Current time matches with scheduled time!"

    executeAction "$CSV_ROW"
  else
    echo "Time does not match!"
  fi
}

checkDay() {
  CURRENT_DAY=$(date +"%a")
  CURRENT_DAY_LOWER=${CURRENT_DAY,,}

  while IFS='|' read $CSV_FIELDS; do
    if [[ "$CURRENT_DAY_LOWER" == "$csv_day" ]]; then
      echo "Current day matches with scheduled day!"

      CSV_ROW=""
      for field in $CSV_FIELDS; do
        CSV_ROW+="${!field}|"
      done
      CSV_ROW="${CSV_ROW%|}"

      checkTime "$CSV_ROW"
    fi
  done < "${PROJECT_FOLDER}/db/schedule.csv"
}

checkDay
