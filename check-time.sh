#!/bin/bash

PROJECT_FOLDER="$(dirname "$(readlink -f "$0")")"
CSV_FIELDS="csv_day csv_time"

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

checkTime() {
  IS_MATCH="false"
  CURRENT_TIME=$(date +"%H:%M")

  while IFS="|" read -r $CSV_FIELDS; do
    if [[ "$CURRENT_TIME" == "$csv_time" ]]; then
      echo "Current time matches with scheduled time!"
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
checkTime
