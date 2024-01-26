#' Title Load the FWA stream tidy graph built on the FWA watershed code field.
#'
#' @return Large tidygraph dataset of streams in British Columbia based on Freshwater Atlas.
#' @export
#'
#' @examples
#' fwa_graph()
#'
fwa_graph = function(){
  # Read in .RDS file from package
  fwa = fwa.connect::fwa_up_and_downstream_tbl
  # Convert to igraph graph object.
  fwa_graph = igraph::graph_from_data_frame(d = fwa)
  # Convert to tidygraph
  tidygraph::as_tbl_graph(fwa_graph)
}
