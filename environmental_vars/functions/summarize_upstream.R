#' Summarize Metric to Upstream Basin
#'
#' Creates a plot of the crayon colors in \code{\link{brocolors}}
#'
#' @param method2order method to order colors (\code{"hsv"} or \code{"cluster"})
#' @param cex character expansion for the text
#' @param mar margin parameters; vector of length 4 (see \code{\link[graphics]{par}})
#'
#' @return None
#'
#' @examples
#' plot_crayons()
#'
#' @export
#'
summarize_upstream <- function(
    target_group = NA,   # ELKR
    dsum = NA,           # Variable set to batch process for group
    utm_zone = NA,       # epsg code
    net = NA,            # 04_poly_stream_network_us_index
    out_dir = NA,        # 1_bcfwa_attributes
    rca_weights = NA     # ELKR_drainage_area.csv
) {

  # Make the network a data.table - remove duplicates (just to be safe)
  print("Building network data table")
  net <- net[which(!(duplicated(net))),]
  setDT(net); class(net)

  # Index keys to improve speed
  keycols = c("rca_id","rid")
  setkeyv(net,keycols)
  key(net)

  all_variables <- list()

  reach_out <- data.frame(
    rid = unique(net$rid)
  )
  reach_out$group <- target_group


  # Loop through variables in set
  for(i in 1:nrow(dsum)) {

    # Load the RCA data
    this_var <- dsum[i, ]
    fname <- gsub("REPLACE", target_group, this_var$fname)

    if(!(file.exists(fname))) {
      reach_out$new_var <- NA
      colnames(reach_out)[ncol(reach_out)] <- this_var$dat_col_names_out
      next
    }

    dat <- read.csv(fname)
    print(this_var$dat_col_names_in)

    # Fix first colname if not rca_id
    if(!("rca_id" %in% colnames(dat))) {
      colnames(dat)[1] <- "rca_id"
    }

    # Fix name of target column
    dat$rcavals <- as.numeric(dat[, c(this_var$dat_col_names_in)])
    dat <- dat[, c("rca_id", "rcavals")]
    mydt <- dat

    # Convert RCA data to simple data.table object for speed.
    # from data.frame to data.table
    setDT(mydt); class(mydt)
    setkey(mydt, rca_id)
    key(mydt)



    # ----------------------------------------------------
    # Simple area based summary - total upstream area - sum
    if(this_var$dat_us_method == "sum") {

      # SECRET MAGIC TRICK PART 1: Next merge to the entire streamline index table
      # This merge will make a giant table for each streamline of all the
      # RCA polygons US and their associated values
      my_merge <- merge(mydt, net, key="rca_id")

      # speed magic of data.table
      head(my_merge)
      nrow(my_merge); nrow(net) # These table should be close to each other...

      # SECRET MAGIC TRICK PART 2:
      # Summarize the total upstream values for each stream segment.
      # Use data.table group-by/summarize function instead of dplyr due to speed
      # rid is streamline edge id
      my_summary <- my_merge[,.(ussum=sum(rcavals)),.(rid)]

      #head(my_merge)
      #nrow(my_summary); nrow(dat) # These table should be close to each other...
      # Save object for later...
    }


    # ----------------------------------------------------
    # Add on weights if method is mean
    if(this_var$dat_us_method == "wmean") {

      # Need to add on weights
      w_weights <- merge(mydt, rca_weights, key="rca_id")

      # Next merge to the entire streamline index table
      my_merge <- merge(w_weights, net, key="rca_id") # speed magic

      # For this metric we want to do a weighted mean based on the RCA polygon area
      my_summary <- my_merge[,.(ussum=weighted.mean(rcavals, area_m2)),.(rid)];

    }


    # Perform some basic QA checks
    if(colnames(my_summary)[2] != "ussum") { stop("Bad column name") }
    if(any(is.infinite(my_summary$ussum))) { stop("Inf in column") }

    # Set NAs to zero... actually don't might be meaningful NA vs 0



    # ----------------------------------------------------
    # QA PLOT
    # ----------------------------------------------------
    if(FALSE) {
      # Inspect in plot window to confirm results
      # merge these summaries of rid back to stream lines
      strm <- st_read(dsn=paste0(out_dir, "/01b_streamline_geometry/",target_group,"_strm.gpkg"))
      this_strm <- merge(strm, my_summary, by.x="rid", by.y="rid", all.x=TRUE, all.y=FALSE)

      # plot(st_geometry(strm))
      # print(nrow(strm))
      # rca <- st_read(dsn=paste0(out_dir, "/02_rca_polygons/",target_group,"_rca.gpkg"))
      # plot(st_geometry(rca))
      # plot(st_geometry(rca), col = "yellow", border = NA)
      # plot(st_geometry(strm), add = TRUE)


      #plot(this_strm["ussum"])
      # try log trans
      temp <- this_strm
      temp <- this_strm %>% filter(STREAM_ORDER>1)
      temp$logda <- log(temp$ussum + 1)
      plot(temp["logda"], lwd=temp$STREAM_ORDER/3, main = this_var$dat_col_names_out)
      print("READY....")
      print(this_var$dat_col_names_out)
      Sys.sleep(5)
      print("--- next set ---")
    }


    # Add value to master dataframe
    reach_out$new_var <- my_summary$ussum[match(reach_out$rid, my_summary$rid)]

    # Relabel and export
    colnames(reach_out)[ncol(reach_out)] <- this_var$dat_col_names_out

    print(head(reach_out, 2))



  } # end of dsum variable set


  return(reach_out)




}

