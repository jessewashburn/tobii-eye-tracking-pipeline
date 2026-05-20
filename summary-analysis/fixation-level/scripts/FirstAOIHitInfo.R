###############################################################################
# 1) Setup: Working Directory & Package Loads
###############################################################################

# Uncomment and adjust if needed:
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

all_files <- list.files(
  pattern = "^[Pp](\\d+)_fixations_refined_clean\\.xlsx$",
  full.names = TRUE,
  ignore.case = TRUE
)

# Exclude participants p25 and p28; keep all others from p6 to p49 (including p21)
excluded_nums <- c(25, 28)
files_to_process <- all_files[sapply(all_files, function(f) {
  num <- as.numeric(gsub("\\D", "", basename(f)))  # extract numeric portion from filename
  !is.na(num) && num >= 6 && num <= 49 && !(num %in% excluded_nums)
})]

cat("Refined-clean files to process (p6..p49 excluding p25 and p28):\n")
print(files_to_process)
cat("Number of files:", length(files_to_process), "\n\n")

if (length(files_to_process) == 0) {
  stop("No refined-clean files found for the specified participants. Check naming and directory.")
}

###############################################################################
# 3) Define AOI Column Order and Helper Function
###############################################################################

aoi_order <- c(
  "AOI[Title]Hit",
  "AOI[Main Data]Hit",
  "AOI[Rectangle 4]Hit",
  "AOI[Y axis]Hit",
  "AOI[X axis]Hit",
  "AOI[Help text]Hit",
  "AOI[Main chart]Hit",
  "AOI[Title]Hit_1",
  "AOI[Y axis (Solar)]Hit",
  "AOI[Y axis (Temp)]Hit",
  "AOI[X axis]Hit_2",
  "AOI[Title]Hit_3",
  "AOI[AI and AN Reading Data]Hit",
  "AOI[Asian Reading Data]Hit",
  "AOI[Black Reading Data]Hit",
  "AOI[Hispanic Reading Data]Hit",
  "AOI[White Reading Data]Hit",
  "AOI[AI and AN Math Data]Hit",
  "AOI[Asian Math Data]Hit",
  "AOI[Black Math Data]Hit",
  "AOI[Hispanic Math Data]Hit",
  "AOI[White Math Data]Hit",
  "AOI[Title]Hit_4",
  "AOI[Key]Hit",
  "AOI[Main Chart]Hit.1",
  "AOI[Y axis]Hit_5",
  "AOI[Chart Help Text]Hit"
)

get_first_aoi_hit <- function(row) {
  # Special case: if both "AOI[Main Data]Hit" and "AOI[Rectangle 4]Hit" are 1, choose "AOI[Rectangle 4]Hit"
  if (!is.na(row[["AOI[Main Data]Hit"]]) && !is.na(row[["AOI[Rectangle 4]Hit"]]) &&
      row[["AOI[Main Data]Hit"]] == 1 && row[["AOI[Rectangle 4]Hit"]] == 1) {
    return("AOI[Rectangle 4]Hit")
  }
  for (col in aoi_order) {
    if (!is.na(row[[col]]) && row[[col]] == 1) {
      return(col)
    }
  }
  return(NA_character_)
}

###############################################################################
# 4) Function: Summarize Each Participant's First AOI Hit per Chart
###############################################################################

summarize_first_aoi <- function(file_path) {
  participant_id <- gsub("_fixations_refined_clean.*", "", basename(file_path))
  
  cat("\n=== Processing", participant_id, "from file:", file_path, "===\n")
  
  df <- read_excel(file_path)
  
  required_cols <- c("MediaName", "GazeEventDuration")
  if (!all(required_cols %in% names(df))) {
    cat("  -> WARNING: Missing required columns in", file_path, "\n")
    return(tibble(Participant = participant_id))
  }
  
  df <- df %>% filter(!is.na(MediaName) & MediaName != "")
  
  summary_by_chart <- df %>%
    group_by(MediaName) %>%
    slice(1) %>%  # take the first row for each chart
    ungroup() %>%
    mutate(
      First_AOI = apply(select(., all_of(aoi_order)), 1, get_first_aoi_hit),
      First_AOI_GazeEventDuration = GazeEventDuration,
      Participant = participant_id
    ) %>%
    select(Participant, MediaName, First_AOI, First_AOI_GazeEventDuration)
  
  if (nrow(summary_by_chart) == 0) {
    cat("  -> No charts processed in", file_path, "\n")
    return(tibble(Participant = participant_id))
  }
  
  cat("  -> Charts Processed:", paste(unique(summary_by_chart$MediaName), collapse = ", "), "\n")
  summary_by_chart
}

###############################################################################
# 5) Process All Files & Combine into a Long-Format Table
###############################################################################

results_long <- map_dfr(files_to_process, function(f) {
  tryCatch(
    summarize_first_aoi(f),
    error = function(e) {
      cat("  -> ERROR processing", f, "\nMessage:", e$message, "\n")
      tibble(Participant = gsub("_fixations_refined_clean.*", "", basename(f)))
    }
  )
})

cat("\nAll participant files processed.\n")

###############################################################################
# 6) Pivot to Wide Format: Participants as Rows, Charts as Columns
###############################################################################

results_wide <- results_long %>%
  pivot_wider(
    id_cols = Participant,
    names_from = MediaName,
    values_from = c(First_AOI, First_AOI_GazeEventDuration),
    names_glue = "Chart{gsub('[^0-9]', '', MediaName)}_{.value}"
  ) %>%
  arrange(as.numeric(gsub("[^0-9]", "", Participant)))

###############################################################################
# 7) Save the Results to CSV
###############################################################################

output_file <- file.path(results_dir, "First_AOI_Hits_Summary.csv")
write.csv(results_wide, output_file, row.names = FALSE)
cat("\n✅ Results saved to", output_file, "\n")
