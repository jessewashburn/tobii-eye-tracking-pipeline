###############################################################################
# 1) Setup: Working Directory & Package Loads
###############################################################################

# Uncomment and adjust if necessary:
# setwd("C:/Users/jesse/Eye Tracking/totals/participant data_original Tobii output-20250208T235151Z-001/participant data_original Tobii output")

library(dplyr)
library(readxl)
library(tidyr)
library(purrr)
library(tibble)

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_flag <- "--file="
  matched <- grep(file_flag, cmd_args)

  if (length(matched) > 0) {
    return(dirname(normalizePath(sub(file_flag, "", cmd_args[matched[1]]))))
  }

  if (!is.null(sys.frames()[[1]]$ofile)) {
    return(dirname(normalizePath(sys.frames()[[1]]$ofile)))
  }

  normalizePath(getwd())
}

results_dir <- file.path(get_script_dir(), "..", "results")
dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)

###############################################################################
# 2) List Refined-Clean Fixation Files for Participants p6 to p49 (excluding p25 and p28)
###############################################################################

# List files matching pattern: e.g., p6_fixations_refined_clean.xlsx, p21_fixations_refined_clean.xlsx, etc.
all_files <- list.files(
  pattern = "^[Pp](\\d+)_fixations_refined_clean\\.xlsx$",
  full.names = TRUE,
  ignore.case = TRUE
)

# Exclude participants p25 and p28 (all others 6 to 49 are kept)
excluded_nums <- c(25, 28)
files_to_process <- all_files[sapply(all_files, function(f) {
  num <- as.numeric(gsub("\\D", "", basename(f)))  # extract numeric part from filename
  !is.na(num) && num >= 6 && num <= 49 && !(num %in% excluded_nums)
})]

cat("Refined-clean files to process (p6..p49 excluding p25 and p28):\n")
print(files_to_process)
cat("Number of files:", length(files_to_process), "\n\n")

if (length(files_to_process) == 0) {
  stop("No refined-clean files found for the specified participants. Check naming and directory.")
}

###############################################################################
# 3) Function: Summarize Each Participant's Task Time per Chart
###############################################################################

summarize_task_time <- function(file_path) {
  # Extract participant ID from filename, e.g., "p18_fixations_refined_clean.xlsx" -> "p18"
  participant_id <- gsub("_fixations_refined_clean.*", "", basename(file_path))
  
  cat("\n=== Processing", participant_id, "from file:", file_path, "===\n")
  
  df <- read_excel(file_path)
  
  # Check that required columns exist (lookup by name, order doesn't matter)
  required_cols <- c("MediaName", "RecordingTimestamp", "GazeEventDuration")
  if (!all(required_cols %in% names(df))) {
    cat("  -> WARNING: Missing one or more required columns in", file_path, "\n")
    return(tibble(Participant = participant_id))
  }
  
  # Remove rows with missing or empty MediaName (optional)
  df <- df %>% filter(!is.na(MediaName) & MediaName != "")
  
  # Group by MediaName (chart)
  summary_by_chart <- df %>%
    group_by(MediaName) %>%
    summarize(
      First_TS = first(RecordingTimestamp),
      Last_TS = last(RecordingTimestamp),
      Last_Duration = last(GazeEventDuration),
      .groups = "drop"
    ) %>%
    mutate(
      Time_Diff = Last_TS - First_TS,
      Task_Time = Time_Diff + Last_Duration,
      Participant = participant_id
    ) %>%
    select(Participant, MediaName, Task_Time)
  
  if(nrow(summary_by_chart) == 0) {
    cat("  -> No data found in", file_path, "\n")
    return(tibble(Participant = participant_id))
  }
  
  cat("  -> Charts Processed:", paste(unique(summary_by_chart$MediaName), collapse = ", "), "\n")
  summary_by_chart
}

###############################################################################
# 4) Process All Files & Combine into a Long-Format Table
###############################################################################

results_long <- map_dfr(files_to_process, function(f) {
  tryCatch(
    summarize_task_time(f),
    error = function(e) {
      cat("  -> ERROR processing", f, "\nMessage:", e$message, "\n")
      tibble(Participant = gsub("_fixations_refined_clean.*", "", basename(f)))
    }
  )
})

cat("\nAll participant files processed.\n")

###############################################################################
# 5) Pivot to Wide Format (Charts as Columns with Custom Column Names)
###############################################################################

results_wide <- results_long %>%
  pivot_wider(
    id_cols = Participant,
    names_from = MediaName,
    values_from = Task_Time,
    names_glue = "Chart{gsub('[^0-9]', '', MediaName)}_Task_Time"
  ) %>%
  arrange(as.numeric(gsub("[^0-9]", "", Participant)))

###############################################################################
# 6) Save the Results to CSV
###############################################################################

output_file <- file.path(results_dir, "fixations_task_time_summary.csv")
write.csv(results_wide, output_file, row.names = FALSE)
cat("\n✅ Results saved to", output_file, "\n")
