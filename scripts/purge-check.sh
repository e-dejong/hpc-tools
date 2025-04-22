#!/bin/bash
#SBATCH --account=pawsey0812
#SBATCH --job-name=purge-check-future
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --time=00:20:00
#SBATCH --mem=4G
#SBATCH --export=NONE
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

# ----------------------
# CONFIGURATION
# ----------------------
WORKDIR="/scratch/pawsey0812/edejong"
REPORT_FILE="purge_risk_report.txt"
SKIP_FILE="skipped_files.txt"
FILELIST="file_list.txt"
DIRLIST=$(mktemp /tmp/highrisk_dirs.XXXXXX)  # temp file for dirs

# ----------------------
# PARSE ARGUMENTS
# ----------------------
SUMMARY_ONLY=false
if [[ "$1" == "--summary-only" ]]; then
    SUMMARY_ONLY=true
fi

# ----------------------
# BEGIN SCRIPT
# ----------------------
echo "Purge scan started on $(date)"
echo "Scanning directory: $WORKDIR"
if [ "$SUMMARY_ONLY" = true ]; then
    echo "Running in SUMMARY-ONLY mode (only reporting directories)"
else
    echo "Running in FULL REPORT mode (reporting individual files)"
fi

# ----------------------
# FIND FILES
# ----------------------
find "$WORKDIR" -type f -print > "$FILELIST"
echo "File list collected: $(wc -l < "$FILELIST") files found."

# ----------------------
# INITIALIZE OUTPUT FILES
# ----------------------
echo "Report for files older than 20 days" > "$REPORT_FILE"
echo "----------------------------------------" >> "$REPORT_FILE"
echo >> "$REPORT_FILE"

echo "Skipped files (timeout or error)" > "$SKIP_FILE"
echo "----------------------------------------" >> "$SKIP_FILE"
echo >> "$SKIP_FILE"

# ----------------------
# PROCESS FILES
# ----------------------
while read -r file; do
    mod_time=$(timeout 2 stat -c %Y "$file" 2>/dev/null)

    if [ -z "$mod_time" ]; then
        echo "SKIPPED: $file" >> "$SKIP_FILE"
        continue
    fi

    mod_days=$(( ( $(date +%s) - mod_time ) / 86400 ))

    if [ "$mod_days" -gt 20 ]; then
        mod_date=$(date -d @"$mod_time" "+%Y-%m-%d")
        purge_date=$(date -d "$mod_date +30 days" "+%Y-%m-%d")

        if [ "$SUMMARY_ONLY" = false ]; then
            echo "HIGH RISK OF PURGE: $file" >> "$REPORT_FILE"
            echo "  Last modified: $mod_date ($mod_days days ago)" >> "$REPORT_FILE"
            echo "  Estimated purge date: $purge_date" >> "$REPORT_FILE"
            echo >> "$REPORT_FILE"
        fi

        # Capture parent directory at two levels deep
        echo "$file" | awk -F'/' '{print "/"$2"/"$3"/"$4"/"$5}' >> "$DIRLIST"
    fi

done < "$FILELIST"

# ----------------------
# FINAL SUMMARY
# ----------------------
echo "----------------------------------------" >> "$REPORT_FILE"
echo "SUMMARY: High-risk directories (up to two levels) with file counts:" >> "$REPORT_FILE"
sort "$DIRLIST" | uniq -c | sort -nr >> "$REPORT_FILE"
echo "----------------------------------------" >> "$REPORT_FILE"

# ----------------------
# CLEANUP
# ----------------------
echo
echo "Purge scan completed on $(date)"
echo "Results:"
echo "- $REPORT_FILE (high risk report)"
echo "- $SKIP_FILE (files skipped due to timeout)"
echo

rm -f "$DIRLIST"  # Remove temporary directory list

# End of script
