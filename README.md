<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />


<h1 align="center">Nicola Basin Spatial Stream Network SSN Model</h1>

<div align="center">
  <a href="https://github.com/mattjbayly/nicola_ssn">
    <img src="/www/img/logos.png" alt="Logo" height="80">
  </a>
  
  <p align="center" style="font-weight: bold;">
  Matthew Bayly, M.J. Bayly Analytics Ltd.
  </p>
    <p align="center">
  Support email: mjbayly@mjbayly.com
  </p>
  <p align="center">
  Nicola Basin Spatial Stream Network SSN Model
    <br />
    <a href="https://github.com/mattjbayly/nicola_ssn/issues">Report Bugs</a>
    ·
    <a href="https://www.fs.usda.gov/rm/boise/AWAE/projects/SSN_STARS/downloads/SSN/SSNvignette2014.pdf">SSN Model Tutorial (Ver Hoef, 2014)</a>
    ·
    <a href="https://www.fs.usda.gov/rm/boise/AWAE/projects/SpatialStreamNetworks.shtml">
SSN & STARS</a>
  </p>
</div>



<!-- ABOUT THE MODEL -->
## Overview

Spatial Statistical Modeling on Stream Networks (SSN) consists of a set of functions for modeling stream network data. In many cases, basin-scale environmental variables are spatially decoupled upstream or downstream in a hydrological network. For example, consider a large forest fire or cut block that may result in sedimentation and runoff issues many kilometers downstream. How do we capture these effects with classical GIS functions like intersections and zonal statistics? Depending on what we are evaluating, effects may also dissipate (from the source) as we travel further downstream and pass major confluence points with larger systems. Similarly, an upstream barrier to fish passage may block access to fish habitat and all stream reaches upstream of a point. This GitHub repository includes a small collection of tools and sample datasets for demonstration purposes within the Nicola Basin in British Columbia.

## Upstream and Downstream Effects

Until recently, working with vectorized stream network data was extremely challenging. Researchers had to first generate their own network models and then deal with numerous issues to make node and edge junctions hydrologically relevant. GIS analysts were then faced with the challenge of trying to integrate different types of environmental input data in various formats in the network. While some tools were available to support this process, it was intractable and computationally challenging. These challenges forced many groups to resort to generating watershed summaries with large polygon units (subbasins or pseudo-watersheds) as their fundamental spatial unit to develop various area-based indicator metrics (e.g., road density, forest harvest % etc.). In British Columbia, the BC Freshwater Atlas ‘Assessment Watersheds’ layer was the most commonly used spatial unit for large-scale watershed assessments. Equivlenet spatial units in American applications include hydrological unit code (HUC) polygons at different scales from the National Hydrography Dataset (NHD). Conducting watershed assessments with large polygon units was convenient to generate heatmaps and summarize variables. However, these summaries rarely considered upstream or downstream effects. Furthermore, when reviewing various indicator metrics (e.g., stream crossing density) for a target stream reach, the Assessment Watersheds (and other larger spatial units) would often capture spatial data from neighbouring basins inflating or underestimating each metric for a specific stream reach. These limitations made it difficult to trust the predictions and cumbersom to link data from field surveys.

[![App Screen Shot][app-screenshot]](www/img/strm_walk.gif)

## SSN & STARS

The SSN & STARS: Tools for Spatial Statistical Modeling on Stream Networks (https://www.fs.usda.gov/rm/boise/AWAE/projects/SpatialStreamNetworks.shtml) is an ongoing development from the US Forest Service, the US Geological Survey, and the Oregon State Office of the Bureau of Land Management. The STARs toolset takes an existing stream network and converts it into a specialized format to facilitate stream network summaries. The SSN R-package (https://github.com/jayverhoef/SSN, Jay Ver Hoef and Erin Peterson) is a statistical framework to improve predictions of physical, chemical, and biological characteristics on stream networks. SSN models account for patterns of spatial autocorrelation among locations based on both Euclidean and in-stream distances. They also have practical applications for the design of monitoring strategies and the derivation of information from databases with non-random sample locations.

[![SSN components][ssn-components]](www/img/preview.png)

## SSN Model for the Nicola Basin

The nicola_ssn GitHub repository provides an analysis-ready sample SSN model and associate file architecture for the Nicola Basin in British Columbia. The idea is to make the tools and framework available to researchers and conservation practitioners wishing to experiment with these frameworks without having to start from scratch. Users may wish to use these tools to conduct upstream or downstream summaries of individual metrics or use the framework to generate a full-on SSN predictive model.

<!-- GETTING STARTED -->
## Getting Started

It is useful to start with simple upstream and downstream summaries of key variables. This can help users get familiar with the framework (and study system). A handful of highly relevant environmental predictor variables have already been generated within this repo to help you get started. Data layers can be downloaded from the following subdirectory: `./environmental_vars/us_summaries/`. These cvs files are linked by `rid` values to the BCFWA streamlines for display/manipulation in GIS platforms (see below).

[![App Screen Shot2][app-screenshot2]](www/img/enviro_metrics.gif)

All features map onto the BC Freshwater Atlas (BCFWA, https://www2.gov.bc.ca/gov/content/data/geographic-data-services/topographic-data/freshwater). You should download a copy of the FWA_STREAM_NETWORKS_SP.gdb streamlines layer. Due to the file size constraints of GitHub repositories key data files have been uploaded to an external FTP site (https://www.dropbox.com/sh/73nxgjfn2llq4vz/AACYZJBF_ai-UvkfZIQp8Gx1a?dl=0). Download a copy of this repository and then also download a copy of the `network` folder. unzip the repository and network folder and place the network folder within the nicola_ssn folder directory (alongside, environmental_vars, ssn_model and other items).

Everything is linked to the BCFWA IDs. The file structure follows the STARs framework (https://www.fs.usda.gov/rm/boise/AWAE/projects/SSN_STARS/downloads/STARS/STARS_vignette2014.pdf). Please refere to the STARs manual for a furter descritpion of terms like RIDs, RCAs etc.

* **rid (reach ID)**: RID (reach ID) a unique ID value assigned to each streamline reach. The RIDs match the LFID (linear feature IDs from the BCFWA to facilite data linkages). Each stream reach has a unique RID.
* **RCA polygon **: RCA (reach contributing area) is the lateral drainage boundary for an individual stream reach. For first-order (headwater stream) segments, the RCA polygons are miniature watershed. For larger streams, the RCA polygon outlines the overland draining directly to the stream. Each RCA is identified by a unique `rca_id`, and there is a one-to-one linkage between `rca_id` and `rid` (each stream segment has one RCA). In related literature, RCA polygons have been referred to as butterfly wings. In the SSN framework, the RCA polygons are the fundamental unit of analysis. Upstream summaries work by summaries values in all RCA polygons upstream from a stream reach.
* **Network Index Tables **: Network index tables: Network index tables are pre-populated reference tables that contain the upstream and downstream relationships between all stream reaches and RCA IDs. These tables are generated externally in a graph model. If you wish to apply this framework to another system, please read the tutorials available in the STARs user manual. Note that there are numerous corrections that need to be made when working with the BCFWA in a new region. RCA polygons along mainstem segments have been corrected here, but the original “RCA-precursors” available in (FWA_WATERSHEDS_POLY.gdb) have inaccurate delineations around larger mainstem reaches. Please contact me if you wish to learn more - the process is non-trivial.


### Generating Your Own Basin Variables

The following script shows a quick example of how we can create our own basin-level variables. In this example I include and area-based summary and linear density summary (additional options below). The general workflow involves running an intersection or zonal statistic summary (if working with raster data) to link your raw environmental input data with the RCA polygons. That intermediate summary product is then run trough the function `summarize_upstream()` to calculate the upstream densities for each stream reach in the basin by combining the RCA polygons, the network tables and raw environmental input data.

You will need to download the index tables available here: https://www.dropbox.com/sh/73nxgjfn2llq4vz/AACYZJBF_ai-UvkfZIQp8Gx1a?dl=0 and add the folder called `network` into the parent directory of this repo (excluded due to GitHub contraints).


```r
# Generate Upstream Summaries for Sample Variables

# Install (if needed) and load external libraries
library(sf)
library(data.table)
library(dplyr)

# Source helper functions (inside this repo)
source("./environmental_vars/functions/summarize_upstream.R")

# Load RCA (reach catchment area) polygons (see Dropbox link above)
rca_polygons <- st_read("./network/NICA_rca.gpkg")
# Load stream lines
strm_lines <- st_read("./network/NICA_strm.gpkg")
strm_lines <- st_zm(strm_lines) # drop z geom

# Load the upstream index table linking (big file!)
net <- read.csv("./network/NICA_rid_us_rca.csv")
# Remove duplicates (just to be sure)
net <- net[which(!(duplicated(net))), ]
```

We will start with a simple area-based summary to calculate the basin coverage of the four orange squares in the image below. The orange squares are obviously dummy data, but you can substitute  for other data sources that interest you (different methods are available for linear summaries, feature counts, and weighted mean estimates – see below).

```r
# Upload your data here (substitute)!
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

# (optional) inspect the output
strm_lines2 <- merge(strm_lines, strm_summary,
                     by.x = "rid", by.y = "rid",
                     all.x = TRUE, all.y = FALSE)

strm_lines2$sample_polygon <- ifelse(strm_lines2$sample_polygon == 0, NA, strm_lines2$sample_polygon)
plot(strm_lines2['sample_polygon'])

```

[![SSN components][ssn-components2]](www/img/demo_polygon.png)

```r

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

```

[![SSN components][ssn-components3]](www/img/demo_line.png)

The `summarize_upstream()` function has several options to facilitate different types of input data. Before adding a new metric review the options to ensure that the calculation method is appropriate. For example, if we were to summarize the mean annual temperature of the upstream basin, we wouldn’t want to look at percent coverage (km2/km2), but instead we would want to estimate the mean value from an attribute field and weight our predictions by the area of the RCA polygons. Key arguments are listed below:

* **net**: Streamline to rca network object (large file). Load from the external Dropbox link: `./network/NICA_rid_us_rca.csv`.
* **summary_type**: Options include `percent_coverage`, `linear_density`, `feature_count`, or `area_weighted_mean`. `percent_coverage` is the simple upstream summary evaluating the polygon area of an environmental variable divided by the upstream basin area. `percent_coverage` is most useful for metrics such as a land cover class, % agriculture etc. summary units are (km2/km2) or (0 – 1, portion of the upstream basin area covered by the layer of interest).`linear_density` is similar to `percent_coverage` but is used when the input layer consists of lines rather than polygons. The output metric is expressed as upstream density as upstream kilometers of the layer of interest divided by the upstream basin area. A common example for `linear_density` is road density (km of road / km2 of the watershed area. `feature_count` is similar to the other two metrics, but consists of an upstream density counted of features. An example of `feature_count` could include upstream water licenses (#/km2 of water licenses issued upstream / divided by the upstream basin area) or stream cross density (#/km2). The final option `area_weighted_mean` is reserved for cases when the upstream summary metric is a numeric value for each RCA polygon. For example, consider elevation, mean annual temperature, PET etc. These metrics will all have mean values estimated for each RCA. It is then necessary to summarize these metrics using an area-weighted mean where the size of the RCA unit is used as the weight in the upstream summary. `area_weighted_mean` is most useful when the metric of interest consists of a continuous numeric variable.
* **summary_field**: Character string. Summary field (column name) if summary type is `area_weighted_mean`. For example, if calculating the upstream basin elevation the summary field would likely consist of a user column named 'elev' or 'el'. `summary_field` is not relevant for other summary methods.
* **rca_polygons**: RCA (reach contributing area) polygons with a unique ID field rca_id. rca_polygons must be supplied as an `sf` object with a unique ID field `rca_id`. See example data `.\network\NICA_rca.gpkg` in the Dropbox link.
* **rca_env_data**: Environmental input data layer. Either a `data.frame` or `sf` object with environmental input data summarized to the `rca_polygons`. The `rca_env_data` must have the field `rca_id`. Preliminary GIS summaries (intersections) with the RCA polygons should be done before running this function.
* **utm_zone**: I am forcing everyone to input an EPSG code for their local UTM zone (e.g., 26910). Too many biologists calculate length and area with the wrong spatial projection...
* **output_fieldname**: Character. User-defined output field name (e.g., `upstream_basin_elevation`)
 

## SSN Model Object


<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

<!-- ACKNOWLEDGMENTS -->
## License

The model is licensed under an [MIT license](https://github.com/mattjbayly/nicola_ssn/blob/main/LICENSE.txt).


<!-- CONTACT -->
## Contact

Please don't be shy to reach out

Matthew Bayly - mjbayly@mjbayly.com
Project Link: [https://github.com/mattjbayly/nicola_ssn](https://github.com/mattjbayly/nicola_ssn)

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[issues-url]: https://github.com/mattjbayly/nicola_ssn/issues
[data-model]: www/img/data-model.png
[ssn-components]: www/img/preview.png
[app-screenshot]: www/img/strm_walk.gif
[app-screenshot2]: www/img/enviro_metrics.gif
[ssn-components2]: www/img/demo_line.png
[ssn-components3]: www/img/demo_polygon.png