###############################################################################
# 1) Setup: Working Directory & Package Loads
###############################################################################

# setwd("C:/Users/jesse/Eye Tracking/totals/participant data_original Tobii output-20250208T235151Z-001/participant data_original Tobii output")
# Uncomment and adjust if needed

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
# 2) List Refined-Clean Fixation Files for p6 to p49 (excluding p25 and p28)
###############################################################################

all_files <- list.files(
  pattern = "^[Pp](\\d+)_fixations_refined_clean\\.xlsx$",
  full.names = TRUE,
  ignore.case = TRUE
)

excluded_nums <- c(25, 28)
files_to_process <- all_files[sapply(all_files, function(f) {
  num <- as.numeric(gsub("\\D", "", basename(f)))
  !is.na(num) && num >= 6 && num <= 49 && !(num %in% excluded_nums)
})]

cat("Refined-clean files to process (p6..p49 excluding p25 and p28):\n")
print(files_to_process)
cat("Number of files:", length(files_to_process), "\n\n")

if (length(files_to_process) == 0) {
  stop("No refined-clean files found. Check naming and directory.")
}

###############################################################################
# 3) Define AOI Columns and Helper Function to Get First AOI Hit
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
  # Special rule: if both 'AOI[Main Data]Hit' and 'AOI[Rectangle 4]Hit' == 1, pick 'AOI[Rectangle 4]Hit'
  if (!is.na(row[["AOI[Main Data]Hit"]]) && !is.na(row[["AOI[Rectangle 4]Hit"]]) &&
      row[["AOI[Main Data]Hit"]] == 1 && row[["AOI[Rectangle 4]Hit"]] == 1) {
    return("AOI[Rectangle 4]Hit")
  }
  # Otherwise, return the first AOI in aoi_order that equals 1
  for (col in aoi_order) {
    if (!is.na(row[[col]]) && row[[col]] == 1) {
      return(col)
    }
  }
  return(NA_character_)
}

###############################################################################
# 4) Read Each File, Compute First AOI Hit per Row
###############################################################################

process_file <- function(file_path) {
  participant_id <- gsub("_fixations_refined_clean.*", "", basename(file_path))
  cat("\n=== Processing", participant_id, "===\n")
  
  df <- read_excel(file_path)
  
  # Check required columns
  req_cols <- c("MediaName", "GazeEventDuration")
  if (!all(req_cols %in% names(df))) {
    cat("  -> WARNING: Missing required columns in", file_path, "\n")
    return(tibble(Participant = participant_id))
  }
  
  df <- df %>% filter(!is.na(MediaName) & MediaName != "")
  
  # Compute First_AOI for each row
  df <- df %>%
    mutate(First_AOI = apply(select(., all_of(aoi_order)), 1, get_first_aoi_hit)) %>%
    filter(!is.na(First_AOI))  # keep only rows with an AOI hit
  
  df %>%
    mutate(Participant = participant_id) %>%
    select(Participant, MediaName, First_AOI, GazeEventDuration)
}

all_data <- map_dfr(files_to_process, process_file)
cat("\nAll participant files processed.\n")

###############################################################################
# 5) Summarize by Chart: Sum Duration & Count Rows per AOI
###############################################################################

# For each chart, we group by Participant & First_AOI
# Summaries: Total_Duration & Fixation_Count
chart_summaries <- lapply(unique(all_data$MediaName), function(chart_name) {
  cat("\nSummarizing chart:", chart_name, "\n")
  chart_data <- all_data %>% filter(MediaName == chart_name)
  summary <- chart_data %>%
    group_by(Participant, First_AOI) %>%
    summarize(
      Total_Duration = sum(GazeEventDuration, na.rm = TRUE),
      Fixation_Count = n(),
      .groups = "drop"
    )
  summary$Chart <- chart_name
  summary
})

# Combine into one long data frame
summary_long <- bind_rows(chart_summaries)

###############################################################################
# 6) Pivot Each Chart's Data So Participants = Rows, AOIs in Side-by-Side Columns
###############################################################################

# We'll produce one output CSV per chart.
# The pivot creates columns: e.g. 'AOI[Title]Hit_Total_Duration', 'AOI[Title]Hit_Fixation_Count', ...
# Then we reorder them so that each AOI's duration & count are side by side, in aoi_order.

reorder_aoi_columns <- function(df_wide) {
  # 'df_wide' has columns: Participant, possibly 'Chart', and then e.g.
  # 'AOI[Title]Hit_Total_Duration', 'AOI[Title]Hit_Fixation_Count', ...
  # We want them side by side for each AOI in 'aoi_order'.
  
  # We'll keep 'Participant' (and 'Chart' if it exists) first.
  base_cols <- c("Participant", "Chart")
  base_cols <- intersect(base_cols, names(df_wide))
  
  # The rest are AOI columns. Let's parse them to find pairs: 'AOI[...]Hit_Total_Duration' and 'AOI[...]Hit_Fixation_Count'
  other_cols <- setdiff(names(df_wide), base_cols)
  
  # Example col name: 'AOI[Title]Hit_Total_Duration'
  # We'll parse out the prefix (e.g. 'AOI[Title]Hit') and suffix (e.g. 'Total_Duration').
  # Then reorder them according to aoi_order, side by side.
  
  # Parse the columns into a data frame: 'prefix' & 'suffix'
  parsed_cols <- tibble(
    col_name = other_cols,
    prefix = sub("_(Total_Duration|Fixation_Count)$", "", other_cols),
    suffix = sub(".*_(Total_Duration|Fixation_Count)$", "\\1", other_cols)
  )
  
  # We'll define an order for 'prefix' based on aoi_order, and for suffix: 'Total_Duration' before 'Fixation_Count'
  
  # Keep only the prefix that appear in the data
  # We want them in the same order as aoi_order, ignoring any not present
  prefix_levels <- intersect(aoi_order, unique(parsed_cols$prefix))
  
  # We'll define a small function to order suffix: 'Total_Duration' then 'Fixation_Count'
  suffix_order <- c("Total_Duration", "Fixation_Count")
  
  # We'll create a factor for prefix, and a factor for suffix
  parsed_cols <- parsed_cols %>%
    mutate(
      prefix_factor = factor(prefix, levels = prefix_levels),
      suffix_factor = factor(suffix, levels = suffix_order)
    ) %>%
    arrange(prefix_factor, suffix_factor)
  
  # Now build the final col order
  final_col_order <- c(base_cols, parsed_cols$col_name)
  
  df_wide <- df_wide[, intersect(final_col_order, names(df_wide))]
  df_wide
}

###############################################################################
# 7) Create & Save One CSV per Chart
###############################################################################

unique_charts <- unique(summary_long$Chart)

for (chart_name in unique_charts) {
  cat("\nPivoting data for chart:", chart_name, "\n")
  df_chart <- summary_long %>% filter(Chart == chart_name)
  
  # Pivot: rows = Participant, columns = AOI
  df_wide <- df_chart %>%
    pivot_wider(
      id_cols = c("Participant"),
      names_from = First_AOI,
      values_from = c(Total_Duration, Fixation_Count),
      names_glue = "{First_AOI}_{.value}"
    )
  
  # Sort participants in ascending numeric order
  df_wide <- df_wide %>%
    arrange(as.numeric(gsub("[^0-9]", "", Participant)))
  
  # Optionally add 'Chart' column
  df_wide$Chart <- chart_name
  
  # Reorder columns so each AOI's duration & count are side by side
  df_wide <- reorder_aoi_columns(df_wide)
  
  # Save CSV
  # Clean the chart name for the filename
  out_name <- paste0(gsub("[^A-Za-z0-9]", "", chart_name), "_AOI_Summary.csv")
  out_path <- file.path(results_dir, out_name)
  write.csv(df_wide, out_path, row.names = FALSE)
  cat("\n✅ Saved", out_path)
}

cat("\n\n✅ All chart summaries saved with AOI columns side by side.\n")
