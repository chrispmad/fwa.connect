cut_stream_with_point = function(point, obstructed_stream){
  # Do the point and stream touch already?
  p_s_intersect = suppressWarnings(sf::st_intersection(point, obstructed_stream))

  # If they do not, find nearest point and then split stream at that point.
  if(nrow(p_s_intersect) == 0){
    # Point and stream do not overlap. Find nearest points.
    p_s_nearest_points = sf::st_buffer(sf::st_nearest_points(point, obstructed_stream), 100)
    # stream_split = suppressWarnings(sf::st_difference(obstructed_stream, p_s_nearest_points))
    obstructed_stream_cut = sf::st_difference(obstructed_stream, p_s_nearest_points) |>
      dplyr::select(FWA_WATERSHED_CODE, BLUE_LINE_KEY)
  } else {
    # stream_split = suppressWarnings(sf::st_difference(obstructed_stream, point))
    obstructed_stream_cut = sf::st_difference(obstructed_stream, sf::st_buffer(point,100)) |>
      dplyr::select(FWA_WATERSHED_CODE, BLUE_LINE_KEY)
  }
}
