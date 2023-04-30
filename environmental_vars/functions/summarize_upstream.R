#' Summarize Metric to Upstream Basin
#'
#' Accumulator function to calculate values upstream from each stream reach.
#'
#' @param net Streamline to rca network object (large file). Load from the external Dropbox link: `./network/NICA_rid_us_rca.csv`.
#' @param summary_type Options include `percent_coverage`, `linear_density`, `feature_count`, or `area_weighted_mean`. `percent_coverage` is the simple upstream summary evaluating the polygon area of an environmental variable divided by the upstream basin area. `percent_coverage` is most useful for metrics such as a land cover class, % agriculture etc. summary units are (km2/km2) or (0 – 1, portion of the upstream basin area covered by the layer of interest). `linear_density` is similar to `percent_coverage` but is used when the input layer consists of lines rather than polygons. The output metric is expressed as upstream density as upstream kilometers of the layer of interest divided by the upstream basin area. A common example for `linear_density` is road density (km of road / km2 of the watershed area. `feature_count` is similar to the other two metrics, but consists of an upstream density count of features. An example of `feature_count` could include upstream water licenses (#/km2 of water licenses issued upstream / divided by the upstream basin area) or stream cross density (#/km2). The final option `area_weighted_mean` is reserved for cases when the upstream summary metric is a numeric value for each RCA polygon. For example, consider elevation, mean annual temperature, PET etc. These metrics will all have estimates for each RCA. It’s necessary to summarize these metrics using an area-weighted mean where the size of the RCA unit is used as the weight in the upstream summary. `area_weighted_mean` is most useful when the metric of interest consists of a continuous numeric variable.
#' @param summary_field Character. Summary field (column name) if summary type is `area_weighted_mean`. For example, if calculating the upstream basin elevation the summary field would likely consist of a user column named 'elev' or 'el'. `summary_field` is not relevant for other summary methods.
#' @param rca_polygons RCA (reach contributing area) polygons with a unique ID field rca_id. rca_polygons must be supplied as an `sf` object with a unique ID field `rca_id`. See example data `.\network\NICA_rca.gpkg` in the Dropbox link.
#' @param rca_env_data Environmental input data layer. Either a `data.frame` or `sf` object with environmental input data summarized to the `rca_polygons`. The `rca_env_data` must have the field `rca_id`. GIS summaries with the RCA polygons should be done before running this function.
#' @param utm_zone EPSG code for local UTM zone (e.g., 26910).
#' @param output_fieldname Character. User-defined output field name (e.g., `upstream_basin_elevation`)
#'
#' @return a data.frame with input values summarized to the stream network
#'
#'
#' @export
#'
summarize_upstream <- function(net = NA,
                               summary_type = NA,
                               summary_field = NA,
                               rca_polygons = NA,
                               rca_env_data = NA,
                               utm_zone = NA,
                               output_fieldname = "field_name") {
  # Make the network a data.table - remove duplicates (just to be safe)
  print("Building network data table")
  setDT(net)
  class(net)

  # Index keys to improve speed
  keycols = c("rca_id", "rid")
  setkeyv(net, keycols)
  key(net)

  all_variables <- list()

  reach_out <- data.frame(rid = unique(net$rid))


  # RCA summary data
  dat <- rca_env_data

  # Fix first colname if not rca_id
  if (!("rca_id" %in% colnames(dat))) {
    stop("rca_env_data must have an rca_id column...")
  }


  # ===================================================
  # ===================================================

  # Run simple area-based summary for percent coverage
  if (summary_type %in% c("percent_coverage", "linear_density")) {

    # Look at area or length of target layer
    print("Converting to utm projection...")
    dat <- st_transform(dat, utm_zone)

    # Calculate area as m2
    if (summary_type == "percent_coverage") {
      dat$area_m2 <- round(as.numeric(st_area(dat)), 6)
    }
    if (summary_type == "linear_density") {
      # note this variable is actually length
      # but stored here for convenience
      dat$area_m2 <- as.numeric(st_length(dat))
    }

    area_metric <- sum(dat$area_m2, na.rm = TRUE)

    # Summarize area by RCA id
    dat_df <- dat
    st_geometry(dat_df) <- NULL
    dat_sum <-
      dat_df %>% group_by(rca_id) %>% summarise(rcavals = sum(area_m2, na.rm = TRUE))
    mydt <- dat_sum

    # Convert RCA data to simple data.table object for speed.
    # from data.frame to data.table
    setDT(mydt)
    class(mydt)
    setkey(mydt, rca_id)
    key(mydt)

    # Merge to the stream to rid index table
    # A giant summary table will be produced to group-by
    # (rca polygons us and their associated values)
    my_merge <- merge(mydt, net, key = "rca_id")

    # Note the speed of data.table - takes 100X longer in base or dplyr

    # Calculate the total sum for each stream reach (total upstream area)
    # data.table group-by/summarize function (dplyr slow)
    # rid is streamline edge id
    metric_summary <- my_merge[, .(ussum_metric = sum(rcavals)), .(rid)]

    # head(my_merge)
    # This object includes the total area coverage upstream
    # of each stream ID

    # -------------------------------------------------
    print("Re-running summary for full RCA polygons...")

    # Also calculate area of RCA polygons as m2
    rca_polygons <- st_transform(rca_polygons, utm_zone)
    rca_polygons$area_m2 <-
      as.numeric(st_area(rca_polygons))
    rca_polygons <- rca_polygons[, c("rca_id", "area_m2")]

    area_rca <- sum(rca_polygons$area_m2, na.rm = TRUE)

    if (area_metric > area_rca) {
      warning("Metric area exceeds rca area...")
    }

    rca_polygons_df <- rca_polygons

    st_geometry(rca_polygons_df) <- NULL

    # Redo above steps for full RCA polygons
    mydt <- rca_polygons_df
    setDT(mydt)
    class(mydt)
    setkey(mydt, rca_id)
    key(mydt)
    # Merge to the stream to rid index table
    my_merge <- merge(mydt, net, key = "rca_id")

    # Full RCA summary
    full_rca_summary <- my_merge[, .(ussum_full = sum(area_m2)), .(rid)]

    # This table includes the full drainage area upstream for
    # each rca polygon
    # head(full_rca_summary)

    # Calculate upstream percent coverage by merging and
    # dividing areas
    fsum <- merge(
      full_rca_summary,
      metric_summary,
      by.x = "rid",
      by.y = "rid",
      all.x = TRUE,
      all.y = FALSE
    )

    if (summary_type == "linear_density") {
      print("Units are km per km2...")
      # Convert from m/m2 to km/km2
      fsum$coverage <-
        (fsum$ussum_metric / 1000) / (fsum$ussum_full * 0.000001)

      fsum$coverage <- ifelse(fsum$ussum_metric == 0, 0, fsum$coverage)

    } else {
      # Area based m2/m2 = km2/km2
      fsum$coverage <- fsum$ussum_metric / fsum$ussum_full
    }

    fsum$coverage <- ifelse(is.na(fsum$coverage), 0, fsum$coverage)

    # Update variable name
    colnames(fsum)[colnames(fsum) == "coverage"] <- output_fieldname

    # Export and return
    ret_obj <- as.data.frame(fsum)
    ret_obj <- ret_obj[, c("rid", output_fieldname)]

    return(ret_obj)

  }




  # ===================================================
  # ===================================================

  # Run area-weighted mean summary
  if (summary_type == "area_weighted_mean") {

    # Covert to data frame
    print("Prepping data...")
    if (any(class(dat) == "sf")) {
      # Pre-summarize across RCAs
      dat$tmp_area <- as.numeric(st_area(dat))
      st_geometry(dat) <- NULL

      # summarize across RCAs (if duplicated)
      if(any(duplicated(dat$rca_id))) {
        dat_new <- dat %>% group_by(rca_id) %>% summarise(output = weighted.mean(.data[[summary_field]], w = tmp_area, na.rm = TRUE))
        colnames(dat_new)[2] <- summary_field
        dat <- dat_new
      }

    }



    # Filter to target fields
    dat <- dat[, c("rca_id", summary_field)]
    colnames(dat) <- c("rca_id", "sfield")
    dat$sfield <- as.numeric(as.character(dat$sfield))

    # Need to get area of each RCA ID polygon
    rca_polygons <- st_transform(rca_polygons, utm_zone)
    rca_polygons$area_m2 <-
      round(as.numeric(st_area(rca_polygons)), 4)
    rca_polygons <- rca_polygons[, c("rca_id", "area_m2")]
    rca_polygons_df <- rca_polygons
    st_geometry(rca_polygons_df) <- NULL

    # Need to add on weights (rca polygon area)
    mydt <- merge(
      rca_polygons_df,
      dat,
      by.x = "rca_id",
      by.y = "rca_id",
      all.x = TRUE,
      all.y = FALSE
    )

    # Need to deal with duplicated per RCA

    # Convert RCA data to simple data.table object for speed.
    # from data.frame to data.table
    setDT(mydt)
    class(mydt)
    setkey(mydt, rca_id)
    key(mydt)

    # Next merge to the entire streamline index table
    my_merge <- merge(mydt, net, key = "rca_id")

    # For this metric we want to do a
    # weighted mean based on the RCA polygon area
    my_summary <-
      my_merge[, .(ussum = weighted.mean(sfield, area_m2)), .(rid)]


    mout <- as.data.frame(my_summary)

    # Update variable name
    colnames(mout)[colnames(mout) == "ussum"] <- output_fieldname

    # Export and return
    ret_obj <- as.data.frame(mout[, c("rid", output_fieldname)])

    return(ret_obj)

  }

  # ===================================================
  # ===================================================

  # Run feature count summary
  if (summary_type == "feature_count") {
    # Covert to data frame
    print("Prepping data...")
    if (any(class(dat) == "sf")) {
      st_geometry(dat) <- NULL
    }

    if (!("rca_id" %in% colnames(dat))) {
      stop("column rca_id must be in environmental inputs")
    }

    dat$row_id <- seq(1, nrow(dat))
    dat <- dat[, c("row_id", "rca_id")]

    # Summarize area by RCA id (count)
    dat_df <- dat
    dat_sum <-
      dat_df %>% group_by(rca_id) %>% summarise(rcavals = n())
    mydt <- dat_sum

    # Convert RCA data to simple data.table object for speed.
    # from data.frame to data.table
    setDT(mydt)
    class(mydt)
    setkey(mydt, rca_id)
    key(mydt)

    # Merge to the stream to rid index table
    # A giant summary table will be produced to group-by
    # (rca polygons us and their associated values)
    my_merge <- merge(mydt, net, key = "rca_id")

    # Note the speed of data.table - takes 100X longer in base or dplyr

    # Calculate the total sum for each stream reach (total upstream area)
    # data.table group-by/summarize function (dplyr slow)
    # rid is streamline edge id
    metric_summary <- my_merge[, .(ussum_metric = sum(rcavals)), .(rid)]

    # head(my_merge)
    # This object includes the total area coverage upstream
    # of each stream ID

    # -------------------------------------------------
    print("Re-running summary for full RCA polygons...")

    # Also calculate area of RCA polygons as m2
    rca_polygons <- st_transform(rca_polygons, utm_zone)
    rca_polygons$area_m2 <-
      round(as.numeric(st_area(rca_polygons)), 4)
    rca_polygons <- rca_polygons[, c("rca_id", "area_m2")]

    rca_polygons_df <- rca_polygons
    st_geometry(rca_polygons_df) <- NULL

    # Redo above steps for full RCA polygons
    mydt <- rca_polygons_df
    setDT(mydt)
    class(mydt)
    setkey(mydt, rca_id)
    key(mydt)
    # Merge to the stream to rid index table
    my_merge <- merge(mydt, net, key = "rca_id")

    # Full RCA summary
    full_rca_summary <- my_merge[, .(ussum_full = sum(area_m2)), .(rid)]

    # This table includes the full drainage area upstream for
    # each rca polygon
    # head(full_rca_summary)

    # Calculate upstream percent coverage by merging and
    # dividing areas
    fsum <- merge(
      full_rca_summary,
      metric_summary,
      by.x = "rid",
      by.y = "rid",
      all.x = TRUE,
      all.y = FALSE
    )

    fsum$coverage <- fsum$ussum_metric / fsum$ussum_full

    fsum$coverage <- ifelse(is.na(fsum$coverage), 0, fsum$coverage)

    # Update variable name
    colnames(fsum)[colnames(fsum) == "coverage"] <- output_fieldname

    print("Count is in #/meters squared")

    # Export and return
    ret_obj <- as.data.frame(fsum)
    ret_obj <- ret_obj[, c("rid", output_fieldname)]

    return(ret_obj)

  }



}
