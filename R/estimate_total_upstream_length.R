#' Title Estimate the total length (in meters) of stream upstream of a spatial point or stream (identified by FWA_WATERSHED_CODE)
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

estimate_total_upstream_length = function(point = NULL,
                                          fwa_code = NULL,
                                          max_buffer_dist = 50,
                                          keep_streams_separate = F,
                                          make_plot = F,
                                          save_plot = F,
                                          save_plot_location = NULL) {
  # Breakpoint logic
  if(sum(is.null(point)) != 0 & sum(is.null(fwa_code)) != 0) stop("Error: Please provide either a spatial point (sf object) or a FWA code string.")

  if(!is.null(fwa_code)){
    if(typoef(fwa_code) != 'character') stop("Error: the supplied FWA code must be a character string or a vector of character strings.")
  }

  if(!is.null(save_plot_location)) make_plot = T

  # If user supplies a FWA code, just use that.
  if(is.null(fwa_code)){
  # Otherwise, find nearest stream and pull its FWA code.
    if(!is.null(point)){
      stream = find_nearest_stream(point, max_buffer_dist)
      fwa_code = stream$FWA_WATERSHED_CODE
    }
  }

  fwa_code_trunc = sub(x = fwa_code, pattern = '000000.*', replacement = '')

  #Download all streams upstream from point
  cql_pattern = paste0("FWA_WATERSHED_CODE like '",fwa_code_trunc,"%'")

  query_test = tryCatch(
    bcdata::bcdc_query_geodata('freshwater-atlas-stream-network') |>
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
  # Calculate portion of stream overlaid by point to add to length estimate
  # Note: only possible if point is input rather than FWA code.

  # Do the point and stream touch already?
  p_s_intersect = suppressWarnings(sf::st_intersection(point, stream))

  # If they do not, find nearest point and then split stream at that point.
  if(nrow(p_s_intersect) == 0){
    # Point and stream do not overlap. Find nearest points.
    p_s_nearest_points = sf::st_buffer(sf::st_nearest_points(point, stream), 1)
    stream_split = sf::st_difference(stream, p_s_nearest_points)
  } else {
    stream_split = sf::st_difference(stream, point)
  }
  # Split MULTIPOLYGON into its 2 constituent LINESTRING pieces.
  stream_split = suppressWarnings(sf::st_cast(stream_split, 'LINESTRING'))

  # Which portion touches upstream?
  stream_upstream_portion_row = suppressWarnings(unique(as.data.frame(sf::st_intersects(stream_split, stream_dl))[,1]))

  # Select upstream portion of stream and remeasure length in meters.
  stream_split = stream_split[stream_upstream_portion_row,] |>
    dplyr::mutate(LENGTH_METRE = as.numeric(sf::st_length(geometry)))

  # Combine upstream portion of split focal stream with the rest of the
  # stream network.
  stream_dl = stream_dl |>
    dplyr::bind_rows(stream_split)

  if(keep_streams_separate){
    output = stream_dl |>
      dplyr::mutate(total_length_m = sum(LENGTH_METRE,na.rm=T))

    length_measure = unique(stream_dl$total_length_m)[1]
  } else {
    length_measure = stream_dl |>
      sf::st_drop_geometry() |>
      dplyr::summarise(total_length_m = sum(LENGTH_METRE,na.rm=T)) |>
      dplyr::pull(total_length_m)

    output = length_measure
  }

  if(make_plot){
    p = ggplot2::ggplot() +
      ggplot2::geom_sf(data = stream_dl)
    if(!is.null(point)){
      p = p +
        ggplot2::geom_sf(data = point, col = 'orange', fill = 'orange')
    } else {
      p = p +
        ggplot2::geom_sf(data = stream_dl[stream_dl$FWA_WATERSHED_CODE == fwa_code,],
                         col = 'orange', fill = 'orange')
    }
    # Make bounding box of stream in bc albers.
    albers_bbox = stream_dl |> sf::st_transform(crs = 3005) |> sf::st_bbox()

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
      length_measure_label = paste0(round(length_measure, 0),' km')
    } else {
      length_measure_label = paste0(round(length_measure, 0), 'm')
    }
    # Add labels to figure.
    p = p +
      ggplot2::labs(
        title = paste0(length_measure_label,' meters above obstacle (orange) to stream flow'),
        subtitle = paste0('FWA code: ',fwa_code_trunc,"000000...")
      )

    # Create map inset for plot.
    map_inset = ggplot2::ggplot() +
      ggplot2::geom_sf(data = bcmaps::bc_bound(), fill = 'transparent', col = 'purple') +
      ggplot2::geom_sf(data = inset_highlight_square, col = 'red', fill = 'transparent', size = 5) +
      ggplot2::theme(axis.text = ggplot2::element_blank(),
            panel.background = ggplot2::element_rect(fill = 'transparent'),
            plot.background = ggplot2::element_rect(fill = 'transparent', color = 'white', size = 3),
            panel.grid = ggplot2::element_blank(),
            axis.ticks = ggplot2::element_blank()
      )

    # Add inset to plot.
    library(patchwork)
    p = p + patchwork::inset_element(map_inset, left = 0, right = 0.3, top = 0.225, bottom = 0.025)

    print(p)
  }

  if(save_plot){
    if(is.null(save_plot_location)) save_plot_location = here::here()
    ggplot2::ggsave(filename = paste0(save_plot_location,'/streams_above_',fwa_code_trunc,'.png'),
                    plot = p,
                    width = 6, height = 6)
  }
  # Round output
  output = round(output, 0)
  return(output)
}
