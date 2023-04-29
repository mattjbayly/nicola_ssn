<a name="readme-top"></a>

[![Contributors][contributors-shield]][contributors-url]
[![Issues][issues-shield]][issues-url]

<!-- PROJECT LOGO -->
<br />


<h1 align="center">Nicola Basin Spatial Stream Network SSN Model</h1>

<div align="center">
  <a href="https://github.com/mattjbayly/nicola_ssn">
    <img src="/www/img/logos.png" alt="Logo" height="80">
  </a>

  <p align="center">
  Nicola Basin Spatial Stream Network SSN Model
    <br />
    ·
    <a href="https://github.com/mattjbayly/issues">Report Bugs</a>
    ·
    <a href="https://www.fs.usda.gov/rm/boise/AWAE/projects/SSN_STARS/downloads/SSN/SSNvignette2014.pdf">SSN Model Tutorial (Ver Hoef, 2014)</a>
    ·
    <a href="https://www.fs.usda.gov/rm/boise/AWAE/projects/SpatialStreamNetworks.shtml">
SSN & STARS</a>
  </p>
</div>



<!-- ABOUT THE MODEL -->
## Overview

Spatial Statistical Modeling on Stream Networks (SSN) consists of a set of functions for modeling stream network data. In many cases, basin-scale environmental variables are spatially decoupled upstream or downstream in a hydrological network. For example, consider a large forest fire or cut block that may result in sedimentation and runoff issues many kilometers downstream. How do we capture these effects with classical GIS functions like intersections and zonal statistics? These effects may also dissipate (from the source) as we travel further downstream and pass major confluence points with larger systems. Similarly, an upstream barrier to fish passage may block access to fish habitat and all stream reaches upstream of a point.

## Upstream and Downstream Effects

Until recently, working with vectorized stream network data was extremely challenging. Researchers had to first generate their own network models and then deal with numerous issues to make node and edge junctions hydrologically relevant. GIS analysts were then faced with the challenge of trying to integrate different types of environmental input data in various formats in the network. While some tools were available to support this process, it was intractable and computationally challenging. This forced many groups to resort to generating watershed summaries with large polygon units (subbasins or pseudo-watersheds) to develop various area-based indicator metrics (e.g., road density, forest harvest % etc.). In British Columbia, the BC Freshwater Atlas ‘Assessment Watersheds’ layer was the most commonly used spatial unit for various watershed assessments. In USA, different groups would use hydrological unit code (HUC) polygons at different scales from the National Hydrography Dataset (NHD). These large polygon summaries were convenient to generate heatmaps, but they didn’t consider upstream or downstream effects. Furthermore, when reviewing various indicator metrics (e.g., stream crossing density) for a target stream reach, the Assessment Watersheds (and other larger spatial units) would often capture spatial data from neighbouring basins inflating or underestimating each metric for a specific location.

[![App Screen Shot][app-screenshot]](www/img/strm_walk.gif)

## SSN & STARS

The SSN & STARS: Tools for Spatial Statistical Modeling on Stream Networks (https://www.fs.usda.gov/rm/boise/AWAE/projects/SpatialStreamNetworks.shtml) is an ongoing development from the US Forest Service, the US Geological Survey, and the Oregon State Office of the Bureau of Land Management. The STARs toolset takes an existing stream network and converts it into a specialized format to facilitate stream network summaries. The SSN R-package (https://github.com/jayverhoef/SSN, Jay Ver Hoef and Erin Peterson) is a statistical framework to improve predictions of physical, chemical, and biological characteristics on stream networks. SSN models account for patterns of spatial autocorrelation among locations based on both Euclidean and in-stream distances. They also have practical applications for the design of monitoring strategies and the derivation of information from databases with non-random sample locations.

[![SSN components][ssn-components]](www/img/preview.png)

## SSN Model for the Nicola Basin

The nicola_ssn GitHub repository provides an analysis-ready sample SSN model structure for the Nicola Basin in British Columbia. The idea 


<!-- GETTING STARTED -->
## Getting Started

...


### Prerequisites and Installation

...

```r
# TODO update this..
install.packages("shiny")
install.packages("shinydashboard")
install.packages("shinydashboardPlus")
install.packages("dplyr")
install.packages("R.utils")
install.packages("readxl")
install.packages("sf")
install.packages("leaflet")
```
....

```r
shiny::runApp()
```


## Input Data

...

[input_data.xlsx](folder/data/)


...

...

...


### Relational Database:

...

[![Data Model][data-model]](www/img/data-model.png)

### Junction Tables (Associative Entity):

...

...

...

....


### Data Tables:
* **watersheds**: Primary data table for watershed listing the watershed_id (primary key) and Gazette name. Other attributes can be added to this table but watershed stressor metrics should not be included as columns in this table.
nations: Basic table for nations with nation_id (primary key), name, description, and other attributes (to be added where appropriate).
* **watershed_nation**: (junction table) defining many-to-many relationships between watersheds (watershed_id) and nations (nation_id). Each watershed may be associated with one or more nations. Nation-specific app instances will use relationships in this table to filter out watersheds not relevant to a given nation.
name_custom: A `name_custom` field is included to specify nation-specific names for a given watershed (where appropriate). If values are included in this field, the default Gazette name of the watershed will be updated with the nation-specific value.
* **fish**: Table of all target fish species. Attribute fields include `species_fiss_code` (for simplified reference to DFO/provincial datasets), `species_common_name` and `species_latin_name`. 
    * target_species: A special field `target_species` (TRUE/FALSE) is included to identify target fish species. If the `target_species` is set to TRUE, the species will appear in the filter list in the map view of the application. The presence of other non-target species will only appear in the watershed detail view.
* **watershed_fish**: (junction table) defining many-to-many relationships between watersheds (watershed_id) and fish (fish_id). Each watershed may be associated with one or more fish species.
    * spawning (TRUE/FALSE): A special field used as a flag to specify whether there is significant spawning habitat for species X in watershed Y. Additional attributes may be included at a later date (depending on data availability) for rearing habitat and/or quantity of spawning habitat (e.g., kilometers of stream etc.).
* **metrics**: A table for each metric (stressor variable). This table lists all the watershed metrics. Fields are included for the `metric_id` (primary key), `metric_name` (for display purposes), `units` (e.g., km/km2), `description` (describing what it is and why it is important) and `source` (a note on the source and ideally a description of the calculation method).
    * hide_in_app (TRUE/FALSE): A special flag to specify whether the metric should appear in the list of stressors to visualize on the map view.
    * default_threshold_moderate: The threshold value, on the original scale of the metric (e.g., km/km2), at which the general risk level is expected to change from low to moderate. For example, road density (km/km2) within a watershed is considered to be at low risk at values under 0.6 kilometers of road per km2 of watershed area. Customized thresholds can be defined for each stressor category relationship (described below) to supersede these default thresholds.
    * default_threshold_high: The threshold value, on the original scale of the metric (e.g., km/km2), at which the general risk level is expected to change from moderate to high. For example, road density (km/km2) within a watershed is considered to be at high risk at values above 1.2 kilometers of road per km2 of watershed area. Customized thresholds can be defined for each stressor category relationship (described below) to supersede these default thresholds.
* **watershed_metric**: (junction table) Containing the raw metric value for each watershed (watershed_id) and metric (metric_id). The `value` field is the raw value of metric X in watershed Y. A `note` (if specified) will appear in the watershed detailed view.
* **categories**: Unique stressor categories (e.g., channel habitat, sedimentation, and peak flows) specifying various impact pathways. id, name, and description fields can be modified as needed.
* **metric_category**: (junction table) Defining the relationships between each metric (metric_id) and stressor category (category_id). Each metric may be linked to one or more categories.
    * custom_threshold_moderate / custom_threshold_high: Fields specifying the custom threshold applied to metric_id X and category_id Y. Note that the metrics table already includes default threshold benchmarks. In many cases the default values can be applied globally to all categories and this field can be left blank. However, in certain circumstances benchmark stressors may have custom values for specific impact pathways. For example, road density threshold values may change depending on impact pathways for peak flows vs sedimentation. If a value is specified here, it will superspeed the threshold benchmark defined in the metrics table.
    * metric_weight_for_category: Custom weighting factor for each metric in each category. If summary calculations involve a roll-up or creation of an index, this field can be used to weight individual metrics within each category.
* **observations**: This table is intended to record observations, insights or other restoration projects. This table is not linked to the other tables; however, points appear on the map with latitude and longitude coordinates.
    * photo_url: The photo url specifies the file path to the photo resource. Photos are stored within `./data/photos/`. Photo urls should look like the following with no quotation marks `./data/photos/photo_1.jpg`. Photos can also be referenced from the internet (provided links are public). If a photo url begins with `http` the tool will reference photos from online sources. Example:`https://www.website.com/photo_1.jpeg`. File size of photos should be small and optimized for web viewing.

### Other inputs:

GIS file of watershed polygons: Watershed polygons must be available in the data directory of the app. The watersheds GIS file must contain polygon geometry data for each watershed. The file must be a geopackage and must be named `watersheds.gpkg`. It is also necessary that the file includes an attribute field for `watershed_id` of type integer (linking watersheds with a 1:1 relationship to the watershed table in the Excel file) and a field for the watershed name `name_gazette`. The GIS data must also meet the following additional criteria:
File format: geopackage
File name: `.\data\watersheds.gpkg`
Geometry type: polygon data (single layer)
Coordinate Reference System (CRS): EPSG:4326 - WGS 84 (Latitude/Longitude)
Mandatory fields:
watershed_id (of type integer, with no duplicate values).
name_gazette (string, values optional)
File size: Simplify geometry such that the file size is less than 7MB.
Ensure geometries are valid.
Ensure that watershed_id match values in the Excel workbook.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

<!-- CONTACT -->
## Contact

Matthew Bayly - mjbayly@mjbayly.com
Project Link: [https://github.com/mattjbayly/nicola_ssn](https://github.com/mattjbayly/nicola_ssn)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

TODO...

* []()
* []()
* []()

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[issues-url]: https://github.com/mattjbayly/nicola_ssn/issues
[data-model]: www/img/data-model.png
[ssn-components]: www/img/preview.png
[app-screenshot]: www/img/strm_walk.gif
