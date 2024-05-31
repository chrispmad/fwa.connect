#' Delineate Component Groups
#'
#' @param wbs Stream, river, lake, etc - it must have a FWA_WATERSHED_CODE column
#'
#' @return Returns input water body table with an additional column: comp_group
#' @export
#'
#' @examples \dontrun
delineate_comps = function(wbs){

  gr = fwa_graph()

  comps = igraph::components(gr |> dplyr::filter(name %in% wbs$FWA_WATERSHED_CODE))

  comp_tbl = dplyr::tibble(
    FWA_WATERSHED_CODE = names(comps$membership),
    comp_group = as.character(comps$membership)
  )
  # If wbs object already has a comp_group column, assuming its from running
  # this function previously, overwire that column
  if('comp_group' %in% names(wbs)){
    wbs$comp_group = NULL
  }

  wbs |>
    dplyr::left_join(comp_tbl)
}
