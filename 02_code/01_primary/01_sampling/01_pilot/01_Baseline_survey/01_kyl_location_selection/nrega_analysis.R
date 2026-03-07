# NREGA Assets Analysis in Barwani, MP (R version)
# This script replicates the Python notebook logic in R

# 1. Load required libraries
library(jsonlite)
library(dplyr)
library(sf)
library(raster)
library(ggplot2)
library(readr)
library(tidyr)
library(stringr)

# 2. Set up directories

current_doc_path <- ""
if (requireNamespace("rstudioapi", quietly = TRUE) &&
    rstudioapi::hasFun("getActiveDocumentContext")) {
  doc <- tryCatch(rstudioapi::getActiveDocumentContext(), error = function(e) NULL)
  if (!is.null(doc) && nzchar(doc$path)) current_doc_path <- doc$path
}

if (nzchar(current_doc_path)) {
  current_dir <- dirname(current_doc_path)
} else if (requireNamespace("rprojroot", quietly = TRUE)) {
  # find project root (requires rprojroot)
  current_dir <- tryCatch(rprojroot::find_root(rprojroot::is_rstudio_project), error = function(e) getwd())
} else {
  current_dir <- getwd()
}

getwd()

base_dir <- file.path(current_dir, "/Dropbox (Personal)/Climate & MGNREGA/Data/01 Data")
raw_dir <- file.path(base_dir, "01 Raw")
clean_dir <- file.path(current_dir, "03 Clean")
plots_dir <- file.path(clean_dir, "01 Figures")
dir.create(plots_dir, showWarnings = FALSE, recursive = TRUE)


cat("Base directory:", base_dir, "\n")
cat("Raw data directory:", raw_dir, "\n")
cat("Clean data directory:", clean_dir, "\n")
cat("Plots directory:", plots_dir, "\n")

# 3. Read NREGA assets data from JSON
nrega_json_path <- file.path(raw_dir, "04 Know Your Landscape/Barwani MP/nrega_features.json")
nrega_data <- fromJSON(nrega_json_path)

# 4. Convert to DataFrame
features_list <- lapply(nrega_data$features, function(feature) {
  list(
    geometry = feature$geometry,
    village = feature$properties$village %||% "",
    asset_type = feature$properties$asset_type %||% "",
    latitude = feature$geometry$coordinates[2],
    longitude = feature$geometry$coordinates[1]
  )
})
df_assets <- bind_rows(features_list)

# 5. Read water stress raster
tif_path <- file.path(raw_dir, "LULC_level_2_LULC_22_23_barwani_level_2.tif")
water_stress_raster <- raster(tif_path)

# 6. Extract water stress indicators for each asset location
get_pixel_value <- function(lon, lat, raster_obj) {
  tryCatch({
    extract(raster_obj, matrix(c(lon, lat), ncol = 2))
  }, error = function(e) NA)
}
df_assets$water_stress_indicator <- mapply(get_pixel_value, df_assets$longitude, df_assets$latitude, MoreArgs = list(raster_obj = water_stress_raster))

# 7. Save processed DataFrame to Clean data folder
write_csv(df_assets, file.path(clean_dir, "processed_assets.csv"))

# 8. Display basic information about the dataset
cat("Total number of assets:", nrow(df_assets), "\n")
cat("\nAsset types distribution:\n")
print(table(df_assets$asset_type))
cat("\nNumber of unique villages:", length(unique(df_assets$village)), "\n")

# Further analysis and visualization can be added below following the notebook logic
