#' Download and load in the FWA stream connectivity table.
#'
#' @return Table showing connectivity of streams in British Columbia based on the Freshwater Atlas Stream Network.
#' @export
#'
#' @examples
#' str_tbl = stream_conn_tbl()
#' str_tbl
#'

stream_conn_tbl = function(ask = interactive(), force = FALSE){
  dir <- data_dir()
  fpath <- file.path(dir, "freshwater-atlas-stream-connectivity.rds")
  if (!file.exists(fpath) | force) {
    check_write_to_data_dir(dir, ask)
    url = "https://github.com/chrispmad/FWA_stream_data/raw/main/freshwater-atlas-stream-connectivity.rds"
    download.file(url = url, destfile = fpath)
    ret = readRDS(fpath)
  }
  else {
    ret <- readRDS(fpath)
  }
  ret
}
