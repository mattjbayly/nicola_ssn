####################################################
# IMPORTANT: YOU MUST DOWNLOAD THE FOLLOWING NETWORK
# FILES HERE (https://www.dropbox.com/sh/73nxgjfn2llq4vz/AACYZJBF_ai-UvkfZIQp8Gx1a?dl=0)

# Download the folder called 'network', unzip it and
# place it within the nicola_ssn folder directory (alongside
# environmental_vars, ssn_model and other items at the
# parent directory of the git repo). The network file
# was excluded from the git repo due to its size.
####################################################

# Generate Upstream Summaries for Sample Variables

# Load external libraries needed
library(sf)
library(data.table)
library(dplyr)
# rm(list = ls())

# Source helper functions
source("./environmental_vars/functions/summarize_upstream.R")


# Load RCA (reach catchment area) polygons (see Dropbox link above)
rca_polygons <- st_read("./network/NICA_rca.gpkg")
# Load stream lines
strm_lines <- st_read("./network/NICA_strm.gpkg")
strm_lines <- st_zm(strm_lines) # drop z geom

# Load the upstream index table linking
net <- read.csv("./network/NICA_rid_us_rca.csv")
# Make the network a data.table - remove duplicates
net <- net[which(!(duplicated(net))), ]

# -----------------------------------------
# Start with a simple area-based summary
# upload your data here (substitute)!
enviro_metric <- st_read("./environmental_vars/demo/polygon.gpkg")

# Run intersection with RCA polygons
rca_env_data <- st_intersection(enviro_metric, rca_polygons)
plot(st_geometry(rca_env_data))

# Summarize upstream percent coverage
strm_summary <- summarize_upstream(
  net = net,
  summary_type = 'percent_coverage',
  rca_polygons = rca_polygons,
  rca_env_data = rca_env_data,
  utm_zone = 26910,
  output_fieldname = 'sample_polygon'
)

# Output is polygon percent cover upstream of each stream reach ID
strm_lines2 <- merge(strm_lines, strm_summary,
                     by.x = "rid", by.y = "rid",
                     all.x = TRUE, all.y = FALSE)

strm_lines2$sample_polygon <- ifelse(strm_lines2$sample_polygon == 0, NA, strm_lines2$sample_polygon)
plot(strm_lines2['sample_polygon'])


# ------------------------------------------------
# Try again with a simple line
# upload your data here (substitute)!
mlines <- st_read("./environmental_vars/demo/line.gpkg")
mlines$id <- 1
st_crs(mlines)

# Run intersection with RCA polygons
env_line <- st_intersection(rca_polygons, mlines)

check <- rca_polygons[which(rca_polygons$rca_id %in% unique(env_line$rca_id)), ]
plot(st_geometry(check))


# Summarize upstream percent coverage
linear_summary <- summarize_upstream(
  net = net,
  summary_type = 'linear_density',
  rca_polygons = rca_polygons,
  rca_env_data = env_line,
  utm_zone = 26910,
  output_fieldname = 'sample_line'
)


# linear_summary <- ret_obj

# Output is polygon percent cover upstream of each stream reach ID
strm_lines2 <- merge(strm_lines, linear_summary,
                     by.x = "rid", by.y = "rid",
                     all.x = TRUE, all.y = FALSE)

strm_lines2$col <- ifelse(strm_lines2$sample_line == 0, 'lightgrey', 'blue')
plot(st_geometry(strm_lines2), col = strm_lines2$col)
plot(st_geometry(env_line), add = TRUE, col = "red")
