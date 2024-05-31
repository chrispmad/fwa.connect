#' Add one of a handful of graph attributes from the {tidygraph} package to your graph
#'
#' @param graph A tidygraph object
#' @param attr One of 'centrality_degree', 'group_id', and 'centrality_edges'
#'
#' @return A tidygraph object with one or more added attributes
#' @export
#'
#' @examples if(FALSE){
#'
#' # Add all of the available attributes.
#' add_attr_to_graph(my_graph)
#' # Or just add one / some of them.
#' add_attr_to_graph(my_graph, attr = c("group_id"))
#'}
#'
add_attr_to_graph = function(graph,
                             attr = c("centrality_degree",
                                      "group_id",
                                      "centrality_edges")){

  if(sum(!attr %in% c("centrality_degree","group_id","centrality_edges")) > 0){
    error("Please choose one of the preset attributes")
  }

  # Add attributes
  if("centrality_degree"%in%attr){
    graph = graph |>
      dplyr::mutate(degree = tidygraph::centrality_degree(mode = 'in'))
  }
  if("group_id"%in%attr){
    components = igraph::components(graph)
    graph = graph |>
      dplyr::mutate(group_id = as.numeric(components$membership))
  }
  if("centrality_edges"%in%attr){
    graph = graph |>
      tidygraph::activate(edges) |>
      dplyr::mutate(centrality = tidygraph::centrality_edge_betweenness())
  }
  return(graph)
}
