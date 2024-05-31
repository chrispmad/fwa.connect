#' Get a list of all FWA WATERSHED CODE'ss that are upstream of target code
#'
#' @param fwa_code Target FWA WATERSHED CODE
#'
#' @return A vector of FWA WATERSHED CODE's
#' @export
#'
#' @examples
#'   fwa_pattern = '200-948755-937012-.*'
#'   fwa.connect::fwa_up_and_downstream_tbl[data.table::`%like%`(fwa.connect::fwa_up_and_downstream_tbl$upstream_fwa_code, fwa_pattern)]$upstream_fwa_code

get_upstream_fwa_codes = function(fwa_code){
  requireNamespace(data.table)
  # browser()
  fwa_pattern = paste0(sub(x = fwa_code, pattern = '-000000.*', replacement = '-'),'.*')
  rows_to_keep = data.table::`%like%`(fwa.connect::fwa_up_and_downstream_tbl$upstream_fwa_code, fwa_pattern)
  tidyr::as_tibble(fwa.connect::fwa_up_and_downstream_tbl[rows_to_keep,1])
}
