# -------------------------------------------------------------
# Sequence Analysis Script for Eye Tracking Data
#
# This script performs sequential pattern mining on cleaned eye tracking data.
# It uses the arulesSequences package to discover frequent AOI (Area of Interest)
# sequences for each participant, summarizes sequence statistics, and outputs
# results for further analysis.
#
# Main workflow:
# 1. Loads cleaned AOI hit sequences for a given chart and condition.
# 2. Assigns event IDs to each AOI hit per participant.
# 3. Prepares data for SPADE sequence mining (arulesSequences).
# 4. Runs SPADE to find frequent AOI sequences and their support.
# 5. Counts occurrences of each sequence for every participant.
# 6. Computes sequence metadata (length, unique AOIs, support, averages).
# 7. Outputs summary statistics and detailed sequence counts to CSV.
#
# User can set chartNum and condNum at the top to analyze different datasets.
# -------------------------------------------------------------
# Load required libraries
library(readr)
library(dplyr)
library(arules)
library(arulesSequences)

# ---- User-configurable variables ----
chartNum <- 1      # Chart number (set as needed)
condNum <- 0       # Condition number (set as needed)

# ---- File paths ----
input_file <- paste0("cleaned_sequences_final_chart", chartNum, "_cond_", condNum, ".csv")
output_file <- paste0("sequences_counts_summary_info_chart", chartNum, "_cond_", condNum, ".csv")
hits_file <- paste0("hits_chart", chartNum, "_cond_", condNum, ".txt")

# ---- Load and prepare data ----
data <- read_csv(input_file, col_types = cols(
	ParticipantID = col_integer(),
	ChartName = col_character(),
	AOIHit = col_character()
))

# Assign event IDs per participant
data_filtered <- data %>%
	group_by(ParticipantID) %>%
	mutate(EventID = row_number())

# Write SPADE input file
write.table(data_filtered[, c("ParticipantID", "EventID", "AOIHit")],
						hits_file, row.names = FALSE, col.names = FALSE, quote = FALSE, sep = ";")

# ---- Sequence mining ----
trans_matrix <- read_baskets(con = hits_file, sep = ";", info = c("sequenceID", "eventID"))
s1 <- cspade(trans_matrix, parameter = list(support = 0.5, maxgap = 1, maxlen = 50, maxsize = 5), control = list(verbose = TRUE))
frequent_sequences_df <- as(s1, "data.frame")
sequence_counts <- data.frame(Sequence = frequent_sequences_df$sequence, Support = frequent_sequences_df$support)

# ---- Count sequence occurrences per participant ----
participant_ids <- unique(data_filtered$ParticipantID)

count_sequences_all <- function(sequence, participant_data) {
	pattern_items <- unlist(strsplit(gsub("[\\{\\}<>"]", "", sequence), ","))
	participant_items <- unlist(strsplit(participant_data, ","))
	if (length(participant_items) < length(pattern_items)) return(0)
	if (length(pattern_items) == 1) {
		return(sum(participant_items == pattern_items))
	}
	count <- 0
	maxgap <- 1
	for (i in 1:(length(participant_items) - length(pattern_items) + 1)) {
		match_found <- TRUE
		current_index <- i
		for (j in 1:length(pattern_items)) {
			if (current_index > length(participant_items) || participant_items[current_index] != pattern_items[j]) {
				match_found <- FALSE
				break
			}
			if (j < length(pattern_items)) {
				next_match <- NA
				for (gap in 1:maxgap) {
					if ((current_index + gap) <= length(participant_items) &&
							participant_items[current_index + gap] == pattern_items[j + 1]) {
						next_match <- current_index + gap
						break
					}
				}
				if (is.na(next_match)) {
					match_found <- FALSE
					break
				} else {
					current_index <- next_match
				}
			}
		}
		if (match_found) {
			count <- count + 1
		}
	}
	return(count)
}

for (pid in participant_ids) {
	participant_data <- data_filtered %>%
		filter(ParticipantID == pid) %>%
		arrange(EventID) %>%
		pull(AOIHit) %>%
		paste(collapse = ",")
	sequence_counts[[paste("Participant", pid)]] <- sapply(frequent_sequences_df$sequence, count_sequences_all, participant_data = participant_data)
}

# ---- Sequence metadata and summary ----
sequence_length <- function(sequence) {
	cleaned_sequence <- gsub("[\\{\\}<>"]", "", sequence)
	length(strsplit(cleaned_sequence, ",")[[1]])
}
unique_aois_count <- function(sequence) {
	cleaned_sequence <- gsub("[\\{\\}<>"]", "", sequence)
	length(unique(strsplit(cleaned_sequence, ",")[[1]]))
}
sequence_counts$Sequence_Length <- sapply(sequence_counts$Sequence, sequence_length)
sequence_counts$Unique_AOIs <- sapply(sequence_counts$Sequence, unique_aois_count)
participant_cols <- grep("^Participant", names(sequence_counts))
sequence_counts$Avg_Counts <- rowMeans(sequence_counts[, participant_cols], na.rm = TRUE)
sequence_counts$True_Support <- rowMeans(sequence_counts[, participant_cols] > 0)

sequence_counts <- sequence_counts %>%
	select(Sequence, Sequence_Length, Unique_AOIs, Support, True_Support, Avg_Counts, everything()) %>%
	arrange(desc(True_Support))

# ---- Summary statistics ----
num_sequences <- nrow(sequence_counts)
total_avg_counts <- mean(sequence_counts$Avg_Counts, na.rm = TRUE)
avg_sequence_length <- mean(sequence_counts$Sequence_Length, na.rm = TRUE)
avg_unique_aois <- mean(sequence_counts$Unique_AOIs, na.rm = TRUE)
summary_data <- data.frame(
	Metric = c("Number of Sequences", "Total Average Counts", "Average Sequence Length", "Average Unique AOIs"),
	Value = c(num_sequences, total_avg_counts, avg_sequence_length, avg_unique_aois)
)

# ---- Write output ----
write.table(summary_data, file = output_file, sep = ",", col.names = TRUE, row.names = FALSE, quote = FALSE)
write.table(sequence_counts, file = output_file, append = TRUE, sep = ",", col.names = TRUE, row.names = FALSE)

print(paste("Output saved with True_Support for chart", chartNum, "condition", condNum))
