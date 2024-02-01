#' Title Trace course of flow downstream from a given FWA WATERSHED CODE
#'
#' @param fwa_code The FWA_WATERSHED_CODE of a target stream
#' @param merge_by_BLK Merge resulting stream table by BLUE_LINE_KEY?
#' @param make_plot Make ggplot of results?
#' @param add_map_insert Add a little insert of BC to give spatial context of main plot?
#' @param save_plot Save .PNG file of plot to local machine?
#' @param save_plot_location Where to save plot; defaults to current working directory
#'
#' @return An {sf} spatial table of stream with submitted FWA code plus downstream streams
#' @export
#'
#' @examples if(FALSE){
#' paul_river_upstream = trace_course_downstream(fwa_code = "200-948755-999851-274772-000000-000000-000000-000000-000000-000000-000000-000000-000000-000000-000000-000000-000000-000000-000000-000000-000000",
#' make_plot = T, add_map_insert = T)
#' paul_river_upstream
#' }
trace_course_downstream = function(fwa_code,
                                   merge_by_BLK = T,
                                   make_plot = F,
                                   add_map_insert = F,
                                   save_plot = F,
                                   save_plot_location = NULL){

  if(is.null(fwa_code)) stop("Error: FWA CODE is null; please enter one!")

  if(!is.character(fwa_code)) stop("Error: FWA CODE must be a string, e.g. '100-239102-023910-...', etc")

  # If plot save location is provided, make_plot should be TRUE.
  if(!is.null(save_plot_location)) make_plot = T

  # Get target stream for inputted FWA code.
  query_test = tryCatch(
    bcdata::bcdc_query_geodata('freshwater-atlas-stream-network') |>
      bcdata::filter(FWA_WATERSHED_CODE == fwa_code),
    error = function(e) stop("Error: Looks like the BC Data Catalogue, or your connection to it, is not working.")
  )

  target_stream = query_test |>
    bcdata::collect() |>
    sf::st_zm() |>
    # Change data type of all columns to character, except geometry; fill NA with 'NA'
    dplyr::mutate(dplyr::across(!dplyr::contains('geom'), as.character)) |>
    dplyr::mutate(dplyr::across(!dplyr::contains('geom'), \(x) ifelse(is.na(x),'NA',x)))

  # Remove empty 0s
  fwa_code_no_blanks = stringr::str_remove(fwa_code, '-00000.*')

  # Find number of stream connections
  num_st_con = stringr::str_count(fwa_code_no_blanks,'-')

  # Start log of number of streams successfully dl'd from BC FWA.
  streams_dl = 1

  downstream_course = list(target_stream)

  for(i in 1:num_st_con){
    print(paste0('working on stream juncture ',i,' of ',num_st_con))
    if(i == 1){
      dr_stream = target_stream
      dr_fwa_code = fwa_code_no_blanks
    } else {
      # Use the receiving stream from prior loop as new draining stream
      dr_stream = rec_stream
      dr_fwa_code = rec_fwa_code
    }

    # Find suffix id for draining stream
    dr_fwa_code_suffix = stringr::str_extract(stringr::str_remove(dr_fwa_code,'-00000.*'),'[0-9]{6}$')

    # Find receiving stream id
    rec_fwa_code = stringr::str_remove(dr_fwa_code, '-[0-9]*$')

    # Formulate CQL query to find receiving stream
    cql_query = paste0("FWA_WATERSHED_CODE like '",rec_fwa_code,"-000000%'")

    rec_stream = bcdata::bcdc_query_geodata('freshwater-atlas-stream-network') |>
      bcdata::filter(bcdata:::CQL(cql_query)) |>
      bcdata::collect() |>
      sf::st_zm()

    if(nrow(rec_stream) > 0){
      # Running record of what stream order we are on. We are always going to go up.
      max_st_order = max(rec_stream$STREAM_ORDER)

      # Find min and max route measures for receiving stream.
      max_downstream_measure = max(rec_stream$DOWNSTREAM_ROUTE_MEASURE)
      min_downstream_measure = min(rec_stream$DOWNSTREAM_ROUTE_MEASURE)

      # Find where along (%) receiving stream the draining stream intersects
      percent_downstream_intersection = as.numeric(dr_fwa_code_suffix)/1000000

      # Convert % to meter measure.
      downstream_cutoff_m = percent_downstream_intersection * max_downstream_measure

      # Find the most likely BLUE_LINE_KEY; i.e., the most numerous one.
      likely_blk = rec_stream |>
        sf::st_drop_geometry() |>
        dplyr::count(BLUE_LINE_KEY) |>
        dplyr::arrange(dplyr::desc(n)) |>
        dplyr::slice(1) |>
        dplyr::pull(BLUE_LINE_KEY)

      # Only keep portion of receiving stream that is downstream of
      # juncture with draining stream

      rec_stream = rec_stream |>
        dplyr::filter(DOWNSTREAM_ROUTE_MEASURE <= downstream_cutoff_m) |>
        # Filter for rows where stream order is at least the max we've encountered so far
        # and the BLK is the same as the most numerous BLK (to trim away little single streams)
        # from a big river, OR rows that are 'lake-def skelet'.
        # dplyr::filter((STREAM_ORDER >= max_st_order & BLUE_LINE_KEY == likely_blk) | FEATURE_SOURCE == 'lake-def skelet') |>
        # dplyr::filter((STREAM_ORDER >= max_st_order) | FEATURE_SOURCE == 'lake-def skelet') |>
        dplyr::filter(STREAM_ORDER >= max_st_order-1) |>
        # Convert all rows minus geometry to character type; fill NA with 'NA'
        dplyr::mutate(dplyr::across(!dplyr::contains('geom'), as.character)) |>
        dplyr::mutate(dplyr::across(!dplyr::contains('geom'), \(x) ifelse(is.na(x),'NA',x)))
        # dplyr::group_by(FWA_WATERSHED_CODE,GNIS_NAME,BLUE_LINE_KEY) |>
        # dplyr::summarise(.groups = 'drop')

      downstream_course = append(downstream_course, list(rec_stream))
      streams_dl = streams_dl + 1
    }
  }

  # Package up results
  downstream_course_b = dplyr::bind_rows(downstream_course)

  if(make_plot){
    colours = RColorBrewer::brewer.pal(num_st_con+1, 'Dark2')
    p = ggplot2::ggplot()
    for(y in 1:(streams_dl)) {
      p = p + ggplot2::geom_sf(data = downstream_course[[y]], col = colours[y])
    }
    p = p +
      ggplot2::theme(panel.background = ggplot2::element_blank())
  }

  if(add_map_insert){
    # Make bounding box of stream in bc albers.
    albers_bbox = downstream_course_b |>
      sf::st_transform(crs = 3005) |>
      sf::st_bbox()

    # Set that as central point, make quite a large bounding box.
    mid_x = (albers_bbox[1] + albers_bbox[3])/2
    mid_y = (albers_bbox[2] + albers_bbox[4])/2

    # bbox_area = as.numeric(sf::st_area(sf::st_as_sfc(albers_bbox)))

    # If sufficiently large bounding box, use dimensions of bbox
    # to inform size of inset map red highlight box.
    # if(bbox_area >= 10000000000){
    if((albers_bbox[3] - albers_bbox[1]) >= 200000){

      # the_coordinates = sf::st_as_sfc(albers_bbox) |> sf::st_coordinates() |> as.data.frame()
      the_width = albers_bbox[3] - albers_bbox[1]
      the_height = albers_bbox[4] - albers_bbox[2]

      inset_highlight_square = data.frame(
        point = c("lower_left","top_right"),
        lng = c((mid_x - the_width/2),(mid_x + the_width/2)),
        lat = c((mid_y - the_height/2),(mid_y + the_height/2))
      )
    } else {
      inset_highlight_square = data.frame(
        point = c("lower_left","top_right"),
        lng = c((mid_x - 100000),(mid_x + 100000)),
        lat = c((mid_y - 100000),(mid_y + 100000))
      )
    }

    inset_highlight_square = inset_highlight_square |>
      sf::st_as_sf(coords = c('lng','lat'),
                   crs = 3005) |>
      sf::st_bbox() |>
      sf::st_as_sfc()

    # Create map inset for plot.
    map_inset = ggplot2::ggplot() +
      ggplot2::geom_sf(data = bcmaps::bc_bound(), fill = 'transparent', col = 'purple') +
      ggplot2::geom_sf(data = inset_highlight_square, col = 'red', fill = 'transparent', size = 5) +
      ggplot2::theme(axis.text = ggplot2::element_blank(),
                     panel.background = ggplot2::element_rect(fill = 'transparent'),
                     plot.background = ggplot2::element_rect(fill = 'transparent'),
                     panel.grid = ggplot2::element_blank(),
                     axis.ticks = ggplot2::element_blank()
      )

    # Add inset to plot.
    library(patchwork)
    p = p + patchwork::inset_element(map_inset, left = 0, right = 0.3, top = 0.225, bottom = 0.025)
  }

  if(merge_by_BLK){

    # The following columns are not distinct for each portion of a given stream / river.
    # So, we will group by them.
    cols_to_group_by = c("WATERSHED_GROUP_ID", "BLUE_LINE_KEY", "WATERSHED_KEY", "FWA_WATERSHED_CODE",
                         "WATERSHED_GROUP_CODE", "GNIS_ID", "GNIS_NAME", "LEFT_RIGHT_TRIBUTARY",
                         "BLUE_LINE_KEY_50K", "WATERSHED_CODE_50K",
                         "WATERSHED_KEY_50K", "WATERSHED_GROUP_CODE_50K", "GRADIENT")


    downstream_course_b = downstream_course_b |>
      dplyr::mutate(dplyr::across(c("LENGTH_METRE","DOWNSTREAM_ROUTE_MEASURE",
                                    "STREAM_MAGNITUDE","STREAM_ORDER"), \(x) as.numeric(x))) |>
      dplyr::group_by(across(all_of(cols_to_group_by))) |>
      dplyr::summarise(LENGTH_METRE = sum(LENGTH_METRE,na.rm=T),
                       DOWNSTREAM_ROUTE_MEASURE = max(DOWNSTREAM_ROUTE_MEASURE,na.rm=T),
                       STREAM_MAGNITUDE = max(STREAM_MAGNITUDE,na.rm=T),
                       STREAM_ORDER = max(STREAM_ORDER,na.rm=T),
                       .groups = 'drop')
  }

  output = downstream_course_b

  if(make_plot){
    output = list(output)
    names(output) = 'downstream_course'
    output$plot = p
  }
  return(output)
}
