#!/bin/bash

PROJECT_FOLDER="$(dirname "$(readlink -f "$0")")"

checkDay() {
  IS_MATCH="false"
  CURRENT_DAY=$(date +"%a")
  CURRENT_DAY_LOWER=${CURRENT_DAY,,}

  while IFS='|' read csv_day csv_time; do
    if [[ "$CURRENT_DAY_LOWER" == "$csv_day" ]]; then
      echo "Current day matches with scheduled day!"
      IS_MATCH="true"
      break
    fi
  done < "${PROJECT_FOLDER}/db/schedule.csv"

  if [[ "$IS_MATCH" == "true" ]]; then
    return
  else
    exit
  fi

}

checkDay
