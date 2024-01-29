#' Title Get all streams (and their geometries) upstream of a given FWA code.
#'
#' @param fwa_code The FWA_WATERSHED_CODE of a target stream
#' @param merge_by_BLK Merge resulting stream table by BLUE_LINE_KEY?
#' @param make_plot Make ggplot of results?
#' @param add_map_insert Add a little insert of BC to give spatial context of main plot?
#' @param save_plot Save .PNG file of plot to local machine?
#' @param save_plot_location Where to save plot; defaults to current working directory
#'
#' @return An {sf} spatial table of stream with submitted FWA code plus all upstream streams
#' @export
#'
#' @examples if(FALSE){
#' paul_river_upstream = trace_course_upstream(fwa_code = "200-948755-999851-274772-000000-000000-000000-000000-000000-000000-000000-000000-000000-000000-000000-000000-000000-000000-000000-000000-000000",
#' make_plot = T, add_map_insert = T)
#' paul_river_upstream
#' }

trace_course_upstream = function(fwa_code,
                                 merge_by_BLK = T,
                                 make_plot = F,
                                 add_map_insert = F,
                                 save_plot = F,
                                 save_plot_location = NULL){

  # If plot save location is provided, make_plot should be TRUE.
  if(!is.null(save_plot_location)) make_plot = T

  # Truncate the FWA WATERSHED CODE to remove all occurrences of '-000000-'
  fwa_code_trunc = sub(x = fwa_code, pattern = '000000.*', replacement = '')

  #Download all streams upstream from point
  cql_pattern = paste0("FWA_WATERSHED_CODE like '",fwa_code_trunc,"%'")

  # If cql pattern is NULL, skip to next iteration; otherwise,
  # this function would attempt to download the whole stream network!
  if(is.null(cql_pattern)) stop('Error: the submitted FWA code produced a NULL search pattern; please try again!')

  query_test = tryCatch(
    bcdata::bcdc_query_geodata('freshwater-atlas-stream-network') |>
      bcdata::filter(bcdata:::CQL(cql_pattern)),
    error = function(e) stop("Error: Looks like the BC Data Catalogue, or your connection to it, is not working.")
  )

  stream_dl = query_test |>
    bcdata::collect() |>
    sf::st_zm()

  if(make_plot){

    p = ggplot2::ggplot() + ggplot2::geom_sf(data = stream_dl) +
      ggplot2::theme(panel.background = ggplot2::element_blank()) +
      ggplot2::labs(title = '')

    if(add_map_insert){
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

    if(save_plot){
      if(is.null(save_plot_location)) save_plot_location = here::here()
      ggplot2::ggsave(filename = paste0(save_plot_location,'/streams_above_',fwa_code_trunc,'.png'),
                      plot = p,
                      width = 6, height = 6)
    }
  } # End of make_plot section

  if(merge_by_BLK){

    print("Merging stream geometries by BLUE_LINE_KEY and a handful of other columns.")

    # The following columns are not distinct for each portion of a given stream / river.
    # So, we will group by them.
    cols_to_group_by = c("WATERSHED_GROUP_ID", "BLUE_LINE_KEY", "WATERSHED_KEY", "FWA_WATERSHED_CODE",
                         "WATERSHED_GROUP_CODE", "GNIS_ID", "GNIS_NAME", "LEFT_RIGHT_TRIBUTARY",
                         "STREAM_MAGNITUDE", "BLUE_LINE_KEY_50K", "WATERSHED_CODE_50K",
                         "WATERSHED_KEY_50K", "WATERSHED_GROUP_CODE_50K", "GRADIENT")


    stream_dl = stream_dl |>
      dplyr::group_by(across(all_of(cols_to_group_by))) |>
      dplyr::summarise(LENGTH_METRE = sum(LENGTH_METRE,na.rm=T),
                       DOWNSTREAM_ROUTE_MEASURE = max(DOWNSTREAM_ROUTE_MEASURE,na.rm=T),
                       STREAM_MAGNITUDE = max(STREAM_MAGNITUDE,na.rm=T),
                       STREAM_ORDER = max(STREAM_ORDER,na.rm=T),
                       .groups = 'drop')
  }

  output = stream_dl

  if(make_plot){
    output = list(output)
    names(output) = 'upstream_streams'
    output$plot = p
  }
  return(output)
}
