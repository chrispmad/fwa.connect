find_nearest_stream = function(point, max_buffer_dist = 50){
  is_spatial = tryCatch(!is.null(sf::st_geometry(point)),
                       error = function(e) FALSE)
  if(!is_spatial){
    stop("Error: supplied point coordinate seems to not be spatial. Does it have a geometry column?")
  }
  if(!is.numeric(max_buffer_dist)){
    stop("Error: max_buffer_dist must be numeric.")
  }

  # Set to BC Albers projection
  if(sf::st_crs(point)[[1]] != "NAD83 / BC Albers"){
    point = sf::st_transform(point, crs = 3005)
  }

  # Test connection to BC Data Catalogue
  query_test = tryCatch(
    bcdata::bcdc_query_geodata('freshwater-atlas-stream-network') |>
      bcdata::filter(bcdata::DWITHIN(point, distance = max_buffer_dist, units = 'meters')),
    error = function(e) stop("Error: Looks like the BC Data Catalogue, or your connection to it, is not working.")
  )
  stream_dl = query_test |> bcdata::collect() #|>

  # Ensure name of geometry column.
  names(stream_dl)[ncol(stream_dl)] <- 'geometry'

  # Search BC Data Catalogue for nearest stream within max buffer distance
  stream_dl |>
    dplyr::mutate(dist_to_point = as.numeric(sf::st_distance(geometry, point))) |>
    dplyr::slice_min(dist_to_point)
}
