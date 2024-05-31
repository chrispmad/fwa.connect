separate_network_geometry_into_components = function(stream_network = NULL){
  # Find components using {igraph}
  com = igraph::components(igraph::graph_from_adj_list(sf::st_intersects(stream_network)))

  # Identify membership of graph nodes (i.e. streams)
  stream_network$group_id = com$membership

  # Summarise geometry by group ID
  stream_network |>
    dplyr::group_by(group_id) |>
    dplyr::summarise()
}
