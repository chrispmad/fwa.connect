#' Cut Stream with Point
#'
#' @param points An {sf} table of obstacle points
#' @param streams As {sf} table of one or more streams
#'
#' @return Geometries of submitted stream(s) clip at the obstacle point(s) and merged by igraph component group
#'
#' @examples \dontrun
cut_stream_with_point = function(points, streams){


  # Optional? Merge points that are touching into single points.
  # points = sf::st_intersection(points)
  streams_u = sf::st_union(streams)

  # Find nearest points for each obstacle point and the obstructed stream.
  p_s_nearest_points = sf::st_buffer(sf::st_nearest_points(points, streams_u), 100)
  # Union nearest points to facilitate st_difference.
  p_s_nearest_points_u = sf::st_union(p_s_nearest_points)

  # p_s_nearest_points = sf::st_union(p_s_nearest_points)
  # stream_split = suppressWarnings(sf::st_difference(streams, p_s_nearest_points))
  streams_cut = sf::st_difference(streams_u, p_s_nearest_points_u) |>
    sf::st_cast('LINESTRING') |>
    st_as_sf() |>
    dplyr::rename(geometry = x)

  # Use igraph to group touching stream networks
  streams_graph = igraph::graph_from_adj_list(sf::st_intersects(streams_cut), mode = 'out')
  streams_cut$comps = igraph::components(streams_graph)$membership
  streams_cut_members = streams_cut |>
    dplyr::group_by(comps) |>
    dplyr::summarise(.groups = 'drop')

  return(streams_cut_members)

#   output = list()
#   for(i in 1:nrow(points)){
#
#     point = points[i,]
#     obstructed_stream = streams[i,]
#
#     # Do the points and streams touch already?
#     p_s_intersect = suppressWarnings(sf::st_intersection(point, obstructed_stream))
#
#   # If they do not, find nearest point and then split stream at that point.
#   if(nrow(p_s_intersect) == 0){
#     # Point and stream do not overlap. Find nearest points.
#       p_s_nearest_points = sf::st_buffer(sf::st_nearest_points(point, obstructed_stream), 100)
#       # stream_split = suppressWarnings(sf::st_difference(obstructed_stream, p_s_nearest_points))
#       obstructed_stream_cut = sf::st_difference(obstructed_stream, p_s_nearest_points)
#
#     if('FWA_WATERSHED_CODE' %in% names(obstructed_stream_cut)){
#       obstructed_stream_cut = obtructed_stream_cut |>
#       dplyr::select(FWA_WATERSHED_CODE, BLUE_LINE_KEY)
#     }
#   } else {
#     # stream_split = suppressWarnings(sf::st_difference(obstructed_stream, point))
#     obstructed_stream_cut = sf::st_difference(obstructed_stream, sf::st_buffer(points,100))
#     if('FWA_WATERSHED_CODE' %in% names(obstructed_stream_cut)){
#       obstructed_stream_cut = obtructed_stream_cut |>
#         dplyr::select(FWA_WATERSHED_CODE, BLUE_LINE_KEY)
#     }
#   }
#   output[[i]] <- obstructed_stream_cut
#   }
#   dplyr::bind_rows(output)
}
