find_stream_network_above_obstacle = function(point, obstructed_stream){

  # Drop the chunks of 0's and add a regex-style wildcard.
  ds_p_g = sub(x = point$fwa_code, pattern = '-000000.*', replacement = '-.*')

  # Note: we should probably not attempt the upstream length estimation for any
  # stream below the third node, e.g. XXX-XXXXXX-XXXXXX as a minimum.
  ds_p_g_no_giants = ds_p_g[stringr::str_count(ds_p_g, '-') >= 2]

  if(length(ds_p_g_no_giants) < length(ds_p_g)) {
    print("Note: The following FWA code(s) was/were removed as they are very large river systems and would require huge data downloads: ")
    print(ds_p_g[!ds_p_g %in% ds_p_g_no_giants])
    ds_p_g = ds_p_g_no_giants
  }

  # Turn regex query into CQL-type query
  ds_p_g_cql = stringr::str_replace(ds_p_g,'.{2}$','%')

  cql_query = paste0("FWA_WATERSHED_CODE like '",paste0(ds_p_g_cql,collapse="' or FWA_WATERSHED_CODE like '"),"'")

  # Download all streams upstream of point(s)
  dl_test = bcdata::bcdc_query_geodata('freshwater-atlas-stream-network') |>
    bcdata::filter(bcdata:::CQL(cql_query)) |>
    bcdata::collect() |>
    sf::st_zm()

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

  output = list()

  for(i in 1:nrow(point)){
  # Cut stream into two linestring pieces with input obstacle point
  obstructed_stream_cut = cut_stream_with_point(point[1,], obstructed_stream[1,])

  # Obstructed stream is now cut into 2 pieces. Separate those into two rows.
  obstructed_stream_cut = obstructed_stream_cut |> sf::st_cast("LINESTRING")

  output[[i]] <- obstructed_stream_cut
  }

  str_cut_output = output |> dplyr::bind_rows()

  # Get downstream stream(s)
  full_query = sub(x = ds_p_g, pattern = "-[0-9]{6}-\\.\\*", replacement = '')
  number_hyphens = stringr::str_count(full_query, pattern = '-')
  hyphens_needed = 20 - number_hyphens
  full_query = paste0(full_query,paste0(rep('-000000',hyphens_needed),collapse=''))

  ds_streams = bcdata::bcdc_query_geodata('freshwater-atlas-stream-network') |>
    # bcdata::filter(bcdata:::CQL(full_query)) |>
    bcdata::filter(FWA_WATERSHED_CODE %in% full_query) |>
    bcdata::collect() |>
    sf::st_zm() |>
    dplyr::group_by(FWA_WATERSHED_CODE) |>
    dplyr::summarise()

  str_cut_output_upstream_bit = suppressWarnings(str_cut_output |>
                                                    dplyr::filter(!sf::st_touches(geometry, ds_streams, sparse = F)))

  # This isn't working, I don't think... needs more work!

  # Add cut obstructed streams back into large stream network
  # of all upstream streams
  dl_test = dl_test |>
    dplyr::filter(!LINEAR_FEATURE_ID %in% obstructed_stream$LINEAR_FEATURE_ID) |>
    dplyr::bind_rows(str_cut_output_upstream_bit)

  plot(dl_test)

  dl_test
}
