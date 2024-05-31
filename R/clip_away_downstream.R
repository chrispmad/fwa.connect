#' Clip Away Downstream
#'
#' @param stream_networks An {sf} table describing stream network(s)
#' @param points An {sf} table describing one or more obstacle points
#'
#' @return The submitted stream network(s) minus their geometries downstream of the obstacle points
#' @export
#'
#' @examples \dontrun
clip_away_downstream = function(stream_networks,points){

  # Get downstream stream(s) - whichever of the two obstructed stream
  # pieces that touches the downstream stream is the piece that we will clip
  # away.
  fwa_list = unique(as.character(na.omit(points$FWA_WATERSHED_CODE)))

  fwa_query = paste0(sapply(fwa_list, \(x) {
    full_query = sub(x = x, pattern = "-[0-9]{6}-0{6}.*", replacement = '')
    full_query = paste0(full_query,"-000000-%'")
    full_query = paste0("FWA_WATERSHED_CODE like '",full_query)
  }), collapse = ' or ')

  ds_streams = bcdata::bcdc_query_geodata('freshwater-atlas-stream-network') |>
    bcdata::filter(bcdata:::CQL(fwa_query)) |>
    bcdata::collect() |>
    sf::st_zm() |>
    # dplyr::group_by(FWA_WATERSHED_CODE) |>
    dplyr::summarise() |>
    dplyr::mutate(id = 'downstream')

  # stream_networks_u = sf::st_as_sf(sf::st_union(stream_networks))

  # ggplot2::ggplot() +
  #   ggplot2::geom_sf(data = stream_networks_u) +
  #   ggplot2::geom_sf(data = points, col = 'red') +
  #   ggplot2::coord_sf(xlim = c(1205291,1220000),
  #                      ylim = c(1080000,1095000))

  # Do the points already have FWA codes? If so, could just cut the
  # stream that matches the FWA code. This could avoid messy network
  # Use the obstacle point(s) to split the obstructed stream into two pieces.
  stream_networks_cut = cut_stream_with_point(points, stream_networks)

  # stream_networks_cut = sf::st_as_sf(stream_networks_cut)
  # stream_networks_cut = dplyr::rename(stream_networks_cut, geometry = x)
  # stream_networks_graph = igraph::graph_from_adj_list(sf::st_intersects(stream_networks_cut$geometry))
  # stream_networks_cut$comps = igraph::components(stream_networks_graph)$membership
  # obstr_two_lines = stream_networks_cut |>
  #   # dplyr::group_by(FWA_WATERSHED_CODE, BLUE_LINE_KEY, comps) |>
  #   dplyr::group_by(comps) |>
  #   dplyr::summarise()
  # stream_networks_cut = stream_networks_cut |> dplyr::bind_rows()

  # This isn't working for multiple points and bit stream networks...
  ggplot2::ggplot() +
    ggplot2::geom_sf(data = points, col = 'grey') +
    ggplot2::geom_sf(data = stream_networks_cut) +
    ggplot2::coord_sf(xlim = c(1205291,1220000),
                      ylim = c(1080000,1095000))

  # # Obstructed stream is now cut into 2 pieces. Separate those into two rows.
  # stream_networks_cut = stream_networks_cut |> sf::st_cast("LINESTRING")
  #
  # # Use igraph to group touching stream networks
  # stream_networks_graph = igraph::graph_from_adj_list(sf::st_intersects(stream_networks_cut))
  # stream_networks_cut$comps = igraph::components(stream_networks_graph)$membership
  # obstr_two_lines = stream_networks_cut |>
  #   # dplyr::group_by(FWA_WATERSHED_CODE, BLUE_LINE_KEY, comps) |>
  #   dplyr::group_by(comps) |>
  #   dplyr::summarise()

  # ggplot() +
  #   geom_sf(data = obstr_two_lines, aes(col = comps))

  # stream_networks_cut_ds = stream_networks_cut |>
  #   dplyr::filter(sf::st_intersects(geometry, ds_streams, sparse = F))

  # stream_networks_final = stream_networks |>
  #   sf::st_difference(stream_networks_cut_ds)

  # ggplot() +
  #   geom_sf(data = stream_networks_final) +
  #   geom_sf(data = point, col = 'red')
  output = stream_networks_cut |>
    sf::st_join(ds_streams) |>
    dplyr::filter(is.na(id)) |>
    dplyr::select(-id)

  return(output)
}
