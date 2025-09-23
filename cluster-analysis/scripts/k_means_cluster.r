# -------------------------------------------------------------
# K-Means Clustering Script for Eye Tracking Data
#
# This script loads participant feature/count data, normalizes it,
# determines the optimal number of clusters using the elbow method,
# runs k-means clustering, and outputs cluster assignments and plots.
# -------------------------------------------------------------
library(readr)
library(dplyr)
library(cluster)
library(ggplot2)
library(factoextra)
library(scales)



# ---- User-configurable variables ----
condition_num <- 1   # Set condition number here
chart_num <- 1       # Set chart number here
chart_name <- "Chart1"  # Set chart name here

# ---- Load and prepare data ----
input_file <- paste0("FS+Counts_participants_condition", condition_num, "_chart", chart_num, "_", chart_name, ".csv")
data <- read_csv(input_file)

# Select participant columns and transpose for clustering
participant_data <- select(data, starts_with("Participant"))
data_transposed <- as.data.frame(t(participant_data))

# Normalize data (row-wise for participants)
data_normalized <- as.data.frame(scale(data_transposed))

# ---- Elbow method to determine optimal clusters ----
sse <- numeric()
for (k in 1:10) {
  set.seed(123)
  km <- kmeans(data_normalized, centers = k, nstart = 25)
  sse[k] <- km$tot.withinss
}
elbow_df <- data.frame(k = 1:10, sse = sse)
elbow_plot <- ggplot(elbow_df, aes(x = k, y = sse)) +
  geom_point() +
  geom_line() +
  labs(x = "Number of clusters K", y = "Total within-clusters sum of squares") +
  theme_minimal()
print(elbow_plot)
ggsave("elbow_plot.pdf", plot = elbow_plot)

# ---- Run k-means clustering ----

# ---- Automatically select best k from elbow method ----
# Find the 'elbow' point: where reduction in SSE slows down
find_elbow <- function(sse) {
  # Use the "knee" point detection (second derivative method)
  diffs <- diff(sse)
  elbow <- which.min(diffs[-1] - diffs[-length(diffs)]) + 1
  return(elbow)
}
best_k <- find_elbow(sse)
cat(paste("Best k selected by elbow method:", best_k, "\n"))

set.seed(123)
kmeans_result <- kmeans(data_normalized, centers = best_k, nstart = 25)

# ---- Output cluster assignments ----
participant_names <- rownames(data_transposed)
cluster_assignments <- kmeans_result$cluster

output_file <- paste0("Classified_Participants_with_Clusters_condition", condition_num, "_chart", chart_num, "_", chart_name, ".csv")
write_csv(output_data, output_file)

# ---- Cluster plot ----
cluster_plot_file <- paste0("cluster_plot_condition", condition_num, "_chart", chart_num, "_", chart_name, ".pdf")
cluster_plot <- fviz_cluster(kmeans_result, data = data_normalized, geom = "point", 
                             ellipse.type = "norm", palette = "jco", ggtheme = theme_minimal())
ggsave(cluster_plot_file, plot = cluster_plot)

# ---- Silhouette plot ----
silhouette_plot_file <- paste0("silhouette_plot_condition", condition_num, "_chart", chart_num, "_", chart_name, ".pdf")
silhouette_info <- silhouette(kmeans_result$cluster, dist(data_normalized))
silhouette_plot <- fviz_silhouette(silhouette_info)
ggsave(silhouette_plot_file, plot = silhouette_plot)

# ---- Print cluster assignments ----
print(output_data)
