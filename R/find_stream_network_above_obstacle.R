find_stream_network_above_obstacle = function(stream_split, stream_dl){

  # Find the downstream neighbour of our split stream.
  the_fwa = unique(stream_split$FWA_WATERSHED_CODE)

  dn_fwa = stringr::str_replace(the_fwa, '[0-9]{6}-(?=000000)', '000000-')

  dn = bcdata::bcdc_query_geodata('92344413-8035-4c08-b996-65a9b3f62fca') |>
    bcdata::filter(FWA_WATERSHED_CODE == dn_fwa) |>
    bcdata::collect() |>
    sf::st_zm() |>
    dplyr::group_by(FWA_WATERSHED_CODE) |>
    dplyr::summarise()

  # If the stream_dl touches the dn at all, remove the piece(s) that does/do so.
  # stream_dl
  # browser()
  # Measure which portion of the split stream is closer to this downstream neighbour piece.
  # This is our upstream stream split.
  us_stream_split = stream_split |>
    dplyr::mutate(dist_to_dn = as.numeric(sf::st_distance(stream_split, dn))) |>
    dplyr::arrange(dplyr::desc(dist_to_dn)) |>
    dplyr::slice(1) |>
    dplyr::select(-dist_to_dn)

  # If there are any unconnected pieces in the stream_dl, drop those.

  stream_dl_comps = separate_network_geometry_into_components(stream_dl)

  if(nrow(stream_dl_comps) > 1){
  # Which stream_dl touches the us_stream_split portion of the obstructed stream?
  stream_dl_main_bit = stream_dl_comps |>
    dplyr::mutate(touches_us_stream_split = as.numeric(sf::st_touches(geometry, us_stream_split))) |>
    dplyr::filter(!is.na(touches_us_stream_split))
  } else {
    stream_dl_main_bit = stream_dl
  }

  upstream_network = dplyr::bind_rows(
    us_stream_split,
    stream_dl_main_bit
  )

  return(upstream_network)
}
