#' Estimate the total length (in meters) of stream upstream of a spatial point or stream (identified by FWA_WATERSHED_CODE)
#'
#' @param point An {sf} table that describes one or more points that intersect with streams in B.C.
#' @param fwa_code A character string, or vector of character strings, that are FWA_WATERSHED_CODES (consult Freshwater Atlas User Guide if this is unfamiliar to you)
#' @param keep_streams_separate If true, result table retains streams as rows and just adds a new column that is total length (in m); if false, just returns estimate length.
#' @param make_plot If true, will make a simple ggplot figure.
#' @param save_plot_location Where to save the above plot to?
#'
#' @return The total length of streams upstream of a point or stream; if a point is used, the portion of the stream it rests on will be added to this estimate.
#' @export
#'
#' @examples \dontrun

estimate_total_upstream_length = function(obstacles = NULL,
                                          # fwa_code = NULL,
                                          stream_snap_dist = 50,
                                          min_obstacles_separation = 100,
                                          keep_streams_separate = F,
                                          make_plot = F,
                                          save_plot = F,
                                          save_plot_location = NULL) {
  # Create output list.
  output_l = list()

  # Ascertain if we are working with point data or fwa codes.
  # point_or_fwa_code = ifelse(!is.null(obstacles))

  # Feedback on number of points to assess.
  cat('\n',paste0(nrow(obstacles), ' point',ifelse(nrow(obstacles)>1,'s',''),' to assess...'))

  # Determine which obstacle points are within some minimum distance; drop duplicated points.

  # Calculate distance between obstacle points
  dist_matrix = sf::st_is_within_distance(obstacles, dist = min_obstacles_separation)

  obstacles_b = sf::st_buffer(obstacles, dist = min_obstacles_separation) |>
    dplyr::summarise() |>
    sf::st_cast("POLYGON") |>
    dplyr::mutate(group_id = dplyr::row_number())

  obstacles_reduced = sf::st_join(obstacles, obstacles_b) |>
    dplyr::group_by(group_id) |>
    dplyr::mutate(obstacle_id = dplyr::row_number()) |>
    dplyr::slice_min(obstacle_id)

  if(nrow(obstacles) > nrow(obstacles_reduced)){
    cat(paste0('\nSome barriers were within minimum separation distance (',
               min_obstacles_separation,
               'm)\nFirst barrier in each "group" of proximal points retained. \nNumber of barriers reduced to ',
               nrow(obstacles_reduced), '\n'))
  }

  obstacles = obstacles_reduced

  # Calculate number or iterations to run.
  n_iter <- nrow(obstacles)

  if(n_iter > 1){
    pb <- progress::progress_bar$new(format = "(:spin) [:bar] :percent [Elapsed time: :elapsedfull || Estimated time remaining: :eta]",
                           total = n_iter,
                           complete = "=",   # Completion bar character
                           incomplete = "-", # Incomplete bar character
                           current = ">",    # Current bar character
                           clear = FALSE,    # If TRUE, clears the bar when finish
                           width = 100)      # Width of the progress bar
  }

  # Run below function, one per point or fwa code.
  for(i in 1:nrow(obstacles)){

    point = obstacles[i,]
    # Breakpoint logic
    # if(sum(is.null(point)) != 0 & sum(is.null(fwa_code)) != 0) stop("Error: Please provide either a spatial point (sf object) or a FWA code string.")
    if(sum(is.null(point)) != 0) stop("Error: Please provide a spatial table (sf object) of 1+ rows.")

    if(!is.null(save_plot_location)) make_plot = T

    # Find FWA code, if there is a stream near enough to the barrier.
      if(!is.null(point)){
        # Try to find the nearest stream; if none, skip to next round of loop!
        stream = tryCatch(
          expr = find_nearest_stream(point, stream_snap_dist)$streams,
          error = function(e) {
            'no_stream_found'
          }
        )
        # stream = find_nearest_stream(point, stream_snap_dist)$streams
        if(is.data.frame(stream)){
          fwa_code = stream$FWA_WATERSHED_CODE
        }
      }

    # Early break in loop - no stream was found close enough to the barrier.
    if(!is.data.frame(stream)){
      output = point
      output$total_length_m = NA
      output$search_outcome = paste0('no stream found within ',stream_snap_dist,' of barrier')
      output_l[[i]] = output
      # Update progress bar
      if(n_iter > 1) pb$tick()
      next
    }

    # Are there multiple rows in the streams object? If so, maybe take the first one?
    stream = stream |> dplyr::group_by(FWA_WATERSHED_CODE) |> dplyr::slice(1)

    if(nrow(stream) > 1) browser()
    # # If no stream returned, skip to next iteration of loop.
    # if(nrow(stream) == 0) {
    #   output = data.frame(total_length_m = NA)
    #   if('id' %in% names(point)){
    #     output$id = point$id
    #   }
    #   output$search_outcome = paste0('No stream found within ',stream_snap_dist,' meters of obstacle')
    #   # Add to results list
    #   output_l[[i]] = output
    #   # Update progress bar
    #   if(n_iter > 1) pb$tick()
    #   next
    # }

    fwa_code_trunc = sub(x = fwa_code, pattern = '000000.*', replacement = '')

    #Download all streams upstream from point
    cql_pattern = paste0("FWA_WATERSHED_CODE like '",fwa_code_trunc,"%'")

    # If cql pattern is NULL, skip to next iteration; otherwise,
    # this function would attempt to download the whole stream network!
    if(is.null(cql_pattern)) next

    query_test = tryCatch(
      bcdata::bcdc_query_geodata('92344413-8035-4c08-b996-65a9b3f62fca') |>
        bcdata::select('FWA_WATERSHED_CODE','LENGTH_METRE') |>
        bcdata::filter(bcdata:::CQL(cql_pattern)),
      error = function(e) stop("Error: Looks like the BC Data Catalogue, or your connection to it, is not working.")
    )

    stream_dl = query_test |>
      bcdata::collect() |>
      sf::st_zm()

    # Remove the stream piece we used to search for this upstream network
    # from the network - this simplifies measurements later for total stream
    # length
    stream_dl = stream_dl |>
      dplyr::filter(LINEAR_FEATURE_ID != stream$LINEAR_FEATURE_ID)

    stream_split = suppressWarnings(cut_stream_with_point(point, stream, buffer_point_amount = 50))

    # Which portion touches upstream?
    upstream_network = find_stream_network_above_obstacle(stream_split, stream_dl)

    # Measure length of upstream network
    upstream_network = upstream_network |>
      dplyr::mutate(LENGTH_METRE = as.numeric(sf::st_length(geometry)))

    if(keep_streams_separate){
      output = upstream_network |>
        dplyr::mutate(total_length_m = round(sum(LENGTH_METRE,na.rm=T),0))

      length_measure = unique(upstream_network$total_length_m)[1]
    } else {
      length_measure = upstream_network |>
        sf::st_drop_geometry() |>
        dplyr::summarise(total_length_m = round(sum(LENGTH_METRE,na.rm=T),0)) |>
        dplyr::select(total_length_m)

      # output = length_measure
    }

    if(make_plot){

      # Make 'invisible background' to expand plot margins based on longest dimension
      # of the plotted object.

      invis_background = make_invis_background_shape(stream, upstream_network)

      p = ggplot2::ggplot() +
        ggplot2::geom_sf(data = invis_background, col = 'transparent', fill = 'transparent') +
        ggplot2::geom_sf(data = stream, col = 'grey') +
        ggplot2::geom_sf(data = upstream_network, col = 'orange')

      if(!is.null(point)){
        p = p +
          ggplot2::geom_sf(data = point, col = 'red', fill = 'red')
      } #else {
      #   p = p +
      #     ggplot2::geom_sf(data = upstream_network[upstream_network$FWA_WATERSHED_CODE == fwa_code,],
      #                      col = 'orange', fill = 'orange')
      # }
      # Make bounding box of stream in bc albers.
      albers_bbox = upstream_network |> sf::st_transform(crs = 3005) |> sf::st_bbox()

      # Set that as central point, make quite a large bounding box.
      mid_x = mean(albers_bbox[1],albers_bbox[3])
      mid_y = mean(albers_bbox[2],albers_bbox[4])

      inset_highlight_square = data.frame(
        point = c("lower_left","top_right"),
        lat = c((mid_x - 100000),(mid_x + 100000)),
        lng = c((mid_y - 100000),(mid_y + 100000))
      ) |>
        sf::st_as_sf(coords = c('lng','lat'),
                     crs = 3005) |>
        sf::st_bbox() |>
        sf::st_as_sfc()

      # Formulate length measure units.
      if(length_measure >= 1000){
        length_measure_label = paste0(round(length_measure, 0),' KM')
      } else {
        length_measure_label = paste0(round(length_measure, 0), 'M')
      }
      # Add labels to figure.
      p = p +
        ggplot2::labs(
          title = paste0(length_measure_label,' of Stream above Obstacle'),
          subtitle = paste0('FWA code: ',fwa_code_trunc,"000000...")
        )

      bc = suppressMessages(bcmaps::bc_bound())
      # Create map inset for plot.
      map_inset = ggplot2::ggplot() +
        ggplot2::geom_sf(data = bc, fill = 'transparent', col = 'purple') +
        ggplot2::geom_sf(data = inset_highlight_square, col = 'red', fill = 'transparent', size = 5) +
        ggplot2::theme(axis.text = ggplot2::element_blank(),
                       panel.background = ggplot2::element_rect(fill = 'transparent'),
                       plot.background = ggplot2::element_rect(fill = 'transparent'),
                       panel.grid = ggplot2::element_blank(),
                       axis.ticks = ggplot2::element_blank()
        )

      # Add inset to plot.
      suppressWarnings(requireNamespace('patchwork'))
      p = p + patchwork::inset_element(map_inset, left = 0, right = 0.3, top = 0.225, bottom = 0.025)

      print(p)
    }

    if(save_plot){
      if(is.null(save_plot_location)) save_plot_location = here::here()
      ggplot2::ggsave(filename = paste0(save_plot_location,'/streams_above_',fwa_code_trunc,'.png'),
                      plot = p,
                      width = 6, height = 6)
    }

    # Establish the output dataframe for this point.
    output = point

    output$total_length_m = length_measure
    output$search_outcome = 'stream(s) found and measured'

    # Add to results list
    output_l[[i]] = output

    # Update progress bar
    if(n_iter > 1) pb$tick()
  }
  # Bind list into single table
  output = dplyr::bind_rows(output_l)
  return(output)
}
