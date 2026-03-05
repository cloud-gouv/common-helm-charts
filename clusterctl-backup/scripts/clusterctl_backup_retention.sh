#!/bin/bash
set -eo pipefail

echo "# Start $(basename $0)"
export exit_code=0
if [ -z "${AWS_BUCKET_NAME}" ]; then
  echo "Error: AWS_BUCKET_NAME not set"
  exit_code=1
fi
if [ -z "${AWS_SECRET_ACCESS_KEY}" ] || \
   [ -z "${AWS_ACCESS_KEY_ID}" ] || \
   [ -z "${AWS_ENDPOINT_URL}" ] || \
   [ -z "${AWS_DEFAULT_REGION}" ] ; then
  echo "Error: AWS_ variables not set"
  exit_code=1
fi

[ "$exit_code" -gt 0 ] && exit $exit_code

RETENTION_DAYS=${RETENTION_DAYS:-7}               # Keep all backups from the last X days
RETENTION_WEEKS=${RETENTION_WEEKS:-30}            # Keep one per week for the last X weeks
RETENTION_MONTHS=${RETENTION_MONTHS:-365}         # Keep one per month for X days

aws s3 ls s3://${AWS_BUCKET_NAME} 2>&1 1>/dev/null || exit 1

BACKUP_LIST=($(aws s3 ls s3://${AWS_BUCKET_NAME} | awk ' NR > 1 { print $2 } ' | sort -nr | cut -d '/' -f1))

# Function to check if a date should be kept
should_keep() {
    local backup_date="$1"
    local timestamp=$(date -d "$backup_date" +%s)
    local now=$(date +%s)
    local days_old=$(( (now - timestamp) / 86400 ))
    #echo "# $backup_date, $days_old, $now, $timestamp"

    if (( days_old <= RETENTION_DAYS )); then
        return 0  # Keep all recent backups
    elif (( days_old <= RETENTION_WEEKS )); then
        week_number=$(date -d "$backup_date" +%V)
        [[ ! " ${weekly_kept[*]} " =~ " $week_number " ]] && weekly_kept+=("$week_number") && return 0
    elif (( days_old <= RETENTION_MONTHS )); then
        month_year=$(date -d "$backup_date" +'%Y-%m')
        [[ ! " ${monthly_kept[*]} " =~ " $month_year " ]] && monthly_kept+=("$month_year") && return 0
    fi

    return 1  # Otherwise, delete it
}

# Purge backups based on retention
weekly_kept=()
monthly_kept=()

for backup in "${BACKUP_LIST[@]}"; do
  short_date=$(echo "$backup" |awk -F- ' { printf("%s-%s-%s %.2d:%.2d:%.2d",$1,$2,$3,($4 ? $4 : 0),($5 ? $5 : 0),($6 ? $6 : 0 )) }')

  if ! should_keep "$short_date"; then
    echo "# Deleting old backup: $short_date $backup"
    aws s3 rm "s3://${AWS_BUCKET_NAME}/$backup/" --recursive
  else
    echo "# Keep backup: $short_date $backup"
  fi
done
echo "# End $(basename $0)"
