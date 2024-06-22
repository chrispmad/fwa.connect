#' Get a list of all FWA WATERSHED CODEs that are upstream of target code
#'
#' @param fwa_code Target FWA WATERSHED CODE
#'
#' @return A vector of FWA WATERSHED CODEs
#' @export
#'
#' @examples \dontrun

get_upstream_fwa_codes = function(fwa_code){
  requireNamespace(data.table)
  fwa_pattern = paste0(sub(x = fwa_code, pattern = '-000000.*', replacement = '-'),'.*')
  rows_to_keep = data.table::`%like%`(fwa.connect::fwa_up_and_downstream_tbl$upstream_fwa_code, fwa_pattern)
  tidyr::as_tibble(fwa.connect::fwa_up_and_downstream_tbl[rows_to_keep,1])
}
