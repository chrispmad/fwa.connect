find_stream_network_above_obstacle = function(points){

  browser()
  # Compose a CQL query string from the FWA codes of the point(s) submitted.
  cql_query = compose_cql_search(points$fwa_code, multi = T)

  # Download all streams upstream of point(s)
  dl_test = bcdata::bcdc_query_geodata('freshwater-atlas-stream-network') |>
    bcdata::filter(bcdata:::CQL(cql_query)) |>
    bcdata::collect() |>
    sf::st_zm()

  # Probably should remove - if leaflet is loaded, make a little plot #
  if("leaflet" %in% loadedNamespaces()){
  l = leaflet() |>
    addPolylines(
      label = ~labels,
      data = dl_test |>
        sf::st_transform(crs = 4326) |>
        dplyr::mutate(labels = stringr::str_remove_all(FWA_WATERSHED_CODE, '-000000.*'))
    ) |>
    addCircleMarkers(
      color = 'purple',
      data = sf::st_transform(fps_single_p, 4326)
    )

  print(l)
}
  dl_test
  # output = list()
  #
  # browser()
  # for(i in 1:nrow(point)){
  #   # Pull out the entire stream that matches the FWA_WATERSHED_CODE
  #   # of the obstructed stream. This is because 'obstructed_stream' can be
  #   # just a single LINESTRING piece of the entire stream.
  #   obst_str_full = dl_test |>
  #     dplyr::filter(FWA_WATERSHED_CODE == obstructed_stream$FWA_WATERSHED_CODE)
  #
  # # Cut stream into two linestring pieces with input obstacle point
  # obstructed_stream_cut = cut_stream_with_point(point[1,], obst_str_full)
  #
  # # Obstructed stream is now cut into 2 pieces. Separate those into two rows.
  # obstructed_stream_cut = obstructed_stream_cut |> sf::st_cast("LINESTRING")
  #
  # output[[i]] <- obstructed_stream_cut
  # }
  #
  # str_cut_output = output |> dplyr::bind_rows()
  #
  # # Get downstream stream(s) - whichever of the two obstructed stream
  # # pieces that touches the downstream stream is NOT the portion of
  # # the obstructed stream that we want to keep.
  # full_query = sub(x = ds_p_g, pattern = "-[0-9]{6}-\\.\\*", replacement = '')
  # number_hyphens = stringr::str_count(full_query, pattern = '-')
  # hyphens_needed = 20 - number_hyphens
  # full_query = paste0(full_query,paste0(rep('-000000',hyphens_needed),collapse=''))
  #
  # ds_streams = bcdata::bcdc_query_geodata('freshwater-atlas-stream-network') |>
  #   # bcdata::filter(bcdata:::CQL(full_query)) |>
  #   bcdata::filter(FWA_WATERSHED_CODE %in% full_query) |>
  #   bcdata::collect() |>
  #   sf::st_zm() |>
  #   dplyr::group_by(FWA_WATERSHED_CODE) |>
  #   dplyr::summarise()
  #
  # browser()
  # ggplot() +
  #   geom_sf(data = str_cut_output |>
  #             dplyr::filter(!sf::st_touches(geometry, ds_streams, sparse = F)))
  # str_cut_output_upstream_bit = suppressWarnings(str_cut_output |>
  #                                                   dplyr::filter(!sf::st_touches(geometry, ds_streams, sparse = F)))
  #
  # # This isn't working, I don't think... needs more work!
  #
  # # Add cut obstructed streams back into large stream network
  # # of all upstream streams
  # dl_test = dl_test |>
  #   dplyr::filter(!LINEAR_FEATURE_ID %in% obstructed_stream$LINEAR_FEATURE_ID) |>
  #   dplyr::bind_rows(str_cut_output_upstream_bit)
  #
  # plot(dl_test)
  #
  # dl_test
}
