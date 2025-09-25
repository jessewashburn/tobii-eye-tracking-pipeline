
# -------------------------------------------------------------
# AOI Gaze Journey Mapper (Interactive Calibration + Data-Driven Plot)
# -------------------------------------------------------------
# This script combines interactive AOI (Area of Interest) mapping and gaze journey visualization for eye-tracking analysis.
#
# Workflow:
# 1. Prompts the user for participant ID, chart name, image file, and number of rows to plot.
# 2. Loads and displays the AOI image for calibration.
# 3. Guides the user to click the four corners of the chart for global calibration (affine transformation).
# 4. Prompts for AOI names, then guides the user to click the four corners for each AOI, saving calibrated coordinates.
# 5. Computes AOI centers and displays them on the image.
# 6. Reads the participant's CSV file, filters for the selected chart, and extracts AOI sequence and gaze durations.
# 7. Maps AOI characters in the data to the calibrated AOIs.
# 8. Plots the gaze journey on the image, using color and size to indicate sequence and duration (green for first AOI, blue for middle, red for last).
# 9. Saves the output as a PNG and prints journey coordinates.
#
# Usage:
# - Run the script in R. Follow prompts to calibrate AOIs and visualize gaze journeys for any participant/chart.
# - No hardcoded AOI coordinates: all mapping is done interactively and data-driven.
# - Output PNG and journey coordinates are saved for further analysis.
# -------------------------------------------------------------

# Load required packages
library(png)

# -----------------------------
# 1. USER SETTINGS
# -----------------------------
participant       <- readline(prompt = "Enter participant ID (e.g., P33): ")
n_rows_to_plot    <- as.integer(readline(prompt = "Enter number of rows to plot (e.g., 20): "))
chart_to_analyze  <- readline(prompt = "Enter chart name (e.g., Chart 1.JPG): ")
img_path          <- readline(prompt = "Enter AOI image filename (e.g., Chart_1_AOI.png): ")

# -----------------------------
# 2. Load and Display the Image
# -----------------------------
img <- readPNG(img_path)
plot(1, type = "n",
     xlim = c(0, ncol(img)),
     ylim = c(0, nrow(img)),
     xaxs = "i", yaxs = "i",
     xlab = "", ylab = "",
     asp = 1)
rasterImage(img, xleft = 0, ybottom = 0,
            xright = ncol(img), ytop = nrow(img))

# -----------------------------
# 3. Global Calibration: Capture the 4 Corners of the Overall Chart
# -----------------------------
cat("Global Calibration: Click on the TOP-LEFT corner of the image.\n")
cal_tl <- locator(1)
cat("Global Calibration: Click on the TOP-RIGHT corner of the image.\n")
cal_tr <- locator(1)
cat("Global Calibration: Click on the BOTTOM-RIGHT corner of the image.\n")
cal_br <- locator(1)
cat("Global Calibration: Click on the BOTTOM-LEFT corner of the image.\n")
cal_bl <- locator(1)

measured_x <- c(cal_tl$x, cal_tr$x, cal_br$x, cal_bl$x)
measured_y <- c(cal_tl$y, cal_tr$y, cal_br$y, cal_bl$y)
ideal_x    <- c(0, ncol(img), ncol(img), 0)
ideal_y    <- c(nrow(img), nrow(img), 0, 0)
U          <- cbind(measured_x, measured_y, 1)
p_x        <- solve(t(U) %*% U, t(U) %*% ideal_x)
p_y        <- solve(t(U) %*% U, t(U) %*% ideal_y)
transform_coord <- function(x, y, p_x, p_y) {
  new_x <- p_x[1] * x + p_x[2] * y + p_x[3]
  new_y <- p_y[1] * x + p_y[2] * y + p_y[3]
  c(new_x, new_y)
}

# -----------------------------
# 4. AOI Calibration: Capture the 4 Corners for Each AOI
# -----------------------------
aoi_names <- unlist(strsplit(readline(prompt = "Enter AOI names separated by commas (e.g., Title,Y_axis,X_axis,Rectangle4,MainData): "), ","))
aoi_names <- trimws(aoi_names)
AOI_boxes <- vector("list", length = length(aoi_names))
for (i in seq_along(aoi_names)) {
  cat(sprintf("\nFor AOI '%s':\n", aoi_names[i]))
  cat("  Click the TOP-LEFT corner.\n")
  tl <- locator(1)
  cat("  Click the TOP-RIGHT corner.\n")
  tr <- locator(1)
  cat("  Click the BOTTOM-RIGHT corner.\n")
  br <- locator(1)
  cat("  Click the BOTTOM-LEFT corner.\n")
  bl <- locator(1)
  corners <- rbind(
    transform_coord(tl$x, tl$y, p_x, p_y),
    transform_coord(tr$x, tr$y, p_x, p_y),
    transform_coord(br$x, br$y, p_x, p_y),
    transform_coord(bl$x, bl$y, p_x, p_y)
  )
  AOI_boxes[[i]] <- list(corners = corners)
}
cat("\nCalibrated AOI Boxes (4 corners each):\n")
for (i in seq_along(aoi_names)) {
  cat(sprintf("AOI %d ('%s'):\n", i, aoi_names[i]))
  print(AOI_boxes[[i]]$corners)
}

# Compute AOI centers
centers <- t(sapply(AOI_boxes, function(box) colMeans(box$corners)))
points(centers[,1], centers[,2], col = "red", pch = 19, cex = 1.5)
text(centers[,1], centers[,2], labels = 1:length(aoi_names), pos = 3, col = "red")

# -----------------------------
# 5. Read and Filter Data
# -----------------------------
csv_file <- paste0(tolower(participant), "_TransformedAOIHits.csv")
df       <- read.csv(csv_file, stringsAsFactors = FALSE)
df_sub   <- subset(df, ChartName == chart_to_analyze)
df_sub   <- head(df_sub, n_rows_to_plot)
journey_sequence_letters <- df_sub$AOI_Character
durations                <- df_sub$GazeEventDuration
label_mapping            <- aoi_names
journey_sequence         <- match(journey_sequence_letters, label_mapping)

# -----------------------------
# 6. Prepare PNG Device
# -----------------------------
output_filename <- paste0(
  participant, "_",
  gsub(" |\\.JPG$", "", chart_to_analyze),
  "_first", n_rows_to_plot, ".png"
)
png(output_filename, width = 800, height = 600)

# -----------------------------
# 7. Load & Display Background Image
# -----------------------------
img <- readPNG(img_path)
if (length(dim(img))>=3 && dim(img)[3]>=3) {
  gray  <- 0.299*img[,,1] + 0.587*img[,,2] + 0.114*img[,,3]
  bgImg <- array(rep(gray,3), dim=c(dim(gray),3))
} else {
  bgImg <- img
}
plot(1, type="n",
     xlim=c(0,ncol(bgImg)), ylim=c(0,nrow(bgImg)),
     xaxs="i", yaxs="i", xlab="", ylab="", asp=1)
rasterImage(bgImg, 0, 0, ncol(bgImg), nrow(bgImg))

# -----------------------------
# 8. Compute Trajectory Coordinates & Cumulative Durations
# -----------------------------
compute_center <- function(c) colMeans(c)
sample_point <- function(c) {
  u<-runif(1); v<-runif(1)
  A<-c[1,]; B<-c[2,]; C<-c[3,]; D<-c[4,]
  (1-u)*(1-v)*A + u*(1-v)*B + u*v*C + (1-u)*v*D
}
n <- length(journey_sequence)
coords <- matrix(NA, n, 2)
eff_dur <- numeric(n)
for (i in seq_len(n)) {
  idx <- journey_sequence[i]
  if (i==1) {
    coords[i,] <- centers[idx,]
    eff_dur[i] <- durations[i]
  } else if (journey_sequence[i]==journey_sequence[i-1]) {
    coords[i,] <- coords[i-1,]
    eff_dur[i] <- eff_dur[i-1] + durations[i]
  } else {
    if (!any(journey_sequence[1:(i-1)]==idx)) {
      coords[i,] <- centers[idx,]
    } else {
      coords[i,] <- sample_point(AOI_boxes[[idx]]$corners)
    }
    eff_dur[i] <- durations[i]
  }
}
x <- coords[,1]; y <- coords[,2]
eff_sizes <- 2.0 * (eff_dur/300) * 1.2

# -----------------------------
# 9. Draw Trajectory + Halos + Circles
# -----------------------------
lines(x, y, col = "blue", lwd = 2)
first_aoi <- journey_sequence[1]
change_idx <- which(journey_sequence != first_aoi)[1]
if (is.na(change_idx)) {
  last_green <- n - 1
} else {
  last_green <- change_idx - 1
}
for (i in seq_len(n)) {
  if (i <= last_green) {
    col_main <- "green"
  } else if (i == n) {
    col_main <- "red"
  } else {
    col_main <- "blue"
  }
  if (eff_dur[i] > durations[i]) {
    points(x[i], y[i],
           pch = 21,
           bg  = adjustcolor(col_main, alpha.f = 0.3),
           col = NA,
           cex = eff_sizes[i] * 1.5)
  }
  points(x[i], y[i],
         pch = 21,
         bg  = col_main,
         col = col_main,
         cex = eff_sizes[i])
}

# -----------------------------
# 10. Output & Close
# -----------------------------
journey_df <- data.frame(AOI=journey_sequence_letters, x=x, y=y)
cat("\nJourney coordinates:\n"); print(journey_df)
dev.off()
cat(sprintf("\nSaved '%s'\n", output_filename))
