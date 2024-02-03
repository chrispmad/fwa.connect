find_stream_network_above_obstacle = function(point, obstructed_stream){

  output = list()

  for(i in 1:nrow(point)){
  # Cut stream into two linestring pieces with input obstacle point
  obstructed_stream_cut = cut_stream_with_point(point[1,], obstructed_stream[1,])

  # Obstructed stream is now cut into 2 pieces. Separate those into two rows.
  obstructed_stream_cut = obstructed_stream_cut |> sf::st_cast("LINESTRING")

  output[[i]] <- obstructed_stream_cut
  }
  return(output |> dplyr::bind_rows())
}
