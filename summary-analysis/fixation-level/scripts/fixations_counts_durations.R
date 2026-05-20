###############################################################################
# 1) Setup: Working Directory & Package Loads
###############################################################################

# Uncomment and adjust the working directory if needed:
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
# 2) List Refined-Clean Fixation Files for Participants p6 to p49
###############################################################################

# List files matching pXX_fixations_refined_clean.xlsx (e.g., p6_fixations_refined_clean.xlsx)
all_files <- list.files(
  pattern = "^[Pp](\\d+)_fixations_refined_clean\\.xlsx$",
  full.names = TRUE,
  ignore.case = TRUE
)

# Exclude participants p25 and p28 (keep p21)
excluded_nums <- c(25, 28)
files_to_process <- all_files[sapply(all_files, function(f) {
  num <- as.numeric(gsub("\\D", "", basename(f)))
  !is.na(num) && num >= 6 && num <= 49 && !(num %in% excluded_nums)
})]

cat("Refined-clean files found (p6..p49 excluding p25 and p28):\n")
print(files_to_process)
cat("Number of files:", length(files_to_process), "\n\n")

if (length(files_to_process) == 0) {
  stop("No refined-clean files found for the specified participants. Check naming and directory.")
}

###############################################################################
# 3) Function: Summarize Each Participant's Chart Durations & Counts
###############################################################################

summarize_fixations <- function(file_path) {
  # Extract participant ID from filename, e.g. "p18_fixations_refined_clean.xlsx" -> "p18"
  participant_id <- gsub("_fixations_refined_clean.*", "", basename(file_path))
  
  cat("\n=== Processing", participant_id, "from file:", file_path, "===\n")
  
  df <- read_excel(file_path)
  
  # Check if required columns exist
  required_cols <- c("MediaName", "GazeEventDuration")
  if (!all(required_cols %in% names(df))) {
    cat("  -> WARNING: Missing required columns in", file_path, "\n")
    return(tibble(Participant = participant_id))
  }
  
  # Optionally remove rows with missing MediaName
  df <- df %>% filter(!is.na(MediaName) & MediaName != "")
  
  # Group by MediaName and summarize duration and fixation count
  summary_by_chart <- df %>%
    group_by(MediaName) %>%
    summarize(
      Total_Duration = sum(GazeEventDuration, na.rm = TRUE),
      Fixation_Count = n(),
      .groups = "drop"
    ) %>%
    mutate(Participant = participant_id)
  
  if(nrow(summary_by_chart) == 0) {
    cat("  -> No fixations found in", file_path, "\n")
    return(tibble(Participant = participant_id))
  }
  
  cat("  -> Charts Processed:", paste(unique(summary_by_chart$MediaName), collapse = ", "), "\n")
  summary_by_chart
}

###############################################################################
# 4) Process All Files & Combine into a Long Format Table
###############################################################################

results_long <- map_dfr(files_to_process, function(f) {
  tryCatch(
    summarize_fixations(f),
    error = function(e) {
      cat("  -> ERROR processing", f, "\nMessage:", e$message, "\n")
      tibble(Participant = gsub("_fixations_refined_clean.*", "", basename(f)))
    }
  )
})

cat("\nAll participant files processed.\n")

###############################################################################
# 5) Pivot to Wide Format with Custom Column Names and Order
###############################################################################

# Pivot using names_glue to create column names like "Chart1_Total_Duration", etc.
results_wide <- results_long %>%
  pivot_wider(
    id_cols = Participant,
    names_from = MediaName,
    values_from = c(Total_Duration, Fixation_Count),
    names_glue = "Chart{gsub('[^0-9]', '', MediaName)}_{.value}"
  )

# Define expected columns in desired order
expected_cols <- c(
  "Chart1_Total_Duration", "Chart1_Fixation_Count",
  "Chart2_Total_Duration", "Chart2_Fixation_Count",
  "Chart3_Total_Duration", "Chart3_Fixation_Count",
  "Chart4_Total_Duration", "Chart4_Fixation_Count"
)

# Add missing expected columns if needed (fill with NA)
for (col in expected_cols) {
  if (!col %in% names(results_wide)) {
    results_wide[[col]] <- NA_real_
  }
}

# Reorder columns: Participant first, then the expected columns
results_wide <- results_wide %>%
  select(Participant, all_of(expected_cols))

# Sort participants ascending by the numeric portion of the ID (e.g., p6, p7, ... p49)
results_wide <- results_wide %>%
  mutate(Participant_num = as.numeric(gsub("[^0-9]", "", Participant))) %>%
  arrange(Participant_num) %>%
  select(-Participant_num)

###############################################################################
# 6) Save the Results to CSV
###############################################################################

output_file <- file.path(results_dir, "fixations_summary_counts_durations.csv")
write.csv(results_wide, output_file, row.names = FALSE)
cat("\n✅ Results saved to", output_file, "\n")
