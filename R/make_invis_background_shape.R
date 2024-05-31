#' Make Invisible Background Shape
#'
#' @param stream Obstructed stream
#' @param upstream_network Network of streams upstream from obstruction
#'
#' @return A bounding box of equal height and width, the length of which is the longest dimension of the plotted objects
#'
#' @examples \dontrun
make_invis_background_shape = function(stream, upstream_network){

  plotted_obj_bbox = dplyr::bind_rows(stream, upstream_network) |>
    dplyr::summarise() |>
    sf::st_bbox()

  midpoint = tidyr::tibble(x = (plotted_obj_bbox[3] + plotted_obj_bbox[1])/2,
                           y = (plotted_obj_bbox[4] + plotted_obj_bbox[2])/2) |>
    sf::st_as_sf(coords = c('x','y'), crs = sf::st_crs(stream))

  width = abs(plotted_obj_bbox[3] - plotted_obj_bbox[1])
  height = abs(plotted_obj_bbox[4] - plotted_obj_bbox[2])

  longer_dimension = max(width, height)

  midpoint_coords = as.data.frame(sf::st_coordinates(midpoint))

  invis_background = tidyr::tibble(x = c(midpoint_coords$X - longer_dimension/2,
                                         midpoint_coords$X + longer_dimension/2),
                                   y = c(midpoint_coords$Y - longer_dimension/2,
                                         midpoint_coords$Y + longer_dimension/2)) |>
    sf::st_as_sf(coords = c('x','y'), crs = sf::st_crs(stream)) |>
    sf::st_bbox() |>
    sf::st_as_sfc()

  return(invis_background)
}
