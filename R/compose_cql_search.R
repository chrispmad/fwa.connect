#' Compose CQL Search
#'
#' @return A single character string that encodes either a single match or a multiple match
#'
#' @examples \dontrun
compose_cql_search = function(fwa_codes,
                              multi = F){

  # Drop the chunks of 0's and add a regex-style wildcard.
  ds_p_g = sub(x = fwa_codes, pattern = '-000000.*', replacement = '-.*')

  # Note: we should probably not attempt the upstream length estimation for any
  # stream below the third node, e.g. XXX-XXXXXX-XXXXXX as a minimum.
  ds_p_g_no_giants = ds_p_g[stringr::str_count(ds_p_g, '-') >= 2]

  if(length(ds_p_g_no_giants) < length(ds_p_g)) {
    print("Note: One or more FWA code(s) were removed as they are very large river systems and would require huge data downloads: ")
    # print(ds_p_g[!ds_p_g %in% ds_p_g_no_giants])
    ds_p_g = ds_p_g_no_giants
  }

  # Turn regex query into CQL-type query
  cql_query = stringr::str_replace(ds_p_g,'.{2}$','%')

  if(multi){
    cql_query = paste0("FWA_WATERSHED_CODE like '",paste0(cql_query,collapse="' or FWA_WATERSHED_CODE like '"),"'")
  }

  return(cql_query)
}
