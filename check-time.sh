#!/bin/bash

PROJECT_FOLDER="$(dirname "$(readlink -f "$0")")"
CSV_FIELDS="csv_days csv_time csv_day_num csv_action csv_source csv_tag csv_repo"

executeAction() {
  CSV_ROW="$1"
  IS_REPO_EXIST="false"

  IFS='|' read -r $CSV_FIELDS <<< "$CSV_ROW"

  while IFS="|" read -r repo_csv_repo_name repo_csv_repo_path repo_csv_repo_key; do
    if [[ "$repo_csv_repo_name" == "$csv_repo" ]]; then
      IS_REPO_EXIST="true"
      break
    fi
  done < "${PROJECT_FOLDER}/db/repos.csv"

  if [[ "$IS_REPO_EXIST" == "false" ]]; then
    echo "Repo name $csv_repo does not exist!"
    return
  fi

  case "$csv_action" in
    "backup")
      /bin/bash "${PROJECT_FOLDER}/auto-restic.sh" "a" "$csv_source" "$csv_tag" "$repo_csv_repo_path" "$repo_csv_repo_key" "$repo_csv_repo_name"
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
    IFS=',' read -ra DAYS_ARRAY <<< "$csv_days"

    for day in "${DAYS_ARRAY[@]}"; do
      CLEAN_DAY=$(echo "$day" | xargs | tr '[:upper:]' '[:lower:]')

      if [[ "$CURRENT_DAY_LOWER" == "$CLEAN_DAY" || "$CLEAN_DAY" == "any" ]]; then
        echo "Current day matches with scheduled day!"

        CURRENT_DAY_NUM=$(date +"%d")

        if [[ "$csv_day_num" == "any" || "$CURRENT_DAY_NUM" == "$csv_day_num" ]]; then
          CSV_ROW=""
          for field in $CSV_FIELDS; do
            CSV_ROW+="${!field}|"
          done
          CSV_ROW="${CSV_ROW%|}"

          checkTime "$CSV_ROW"
        fi
      fi
    done
  done < "${PROJECT_FOLDER}/db/schedule.csv"
}

checkDay
