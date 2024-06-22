#' Thin wrapper and slight modification of {bcmaps}'s data_dir()
#'
#' @return directory to store data
#'
#' @examples \dontrun
data_dir = function(){
  R_user_dir <- getNamespace("tools")$R_user_dir
  if (!is.null(R_user_dir)) {
    getOption("fwa.connnect.data_dir", default = R_user_dir("fwa.connect",
                                                      "cache"))
  }
  else {
    getOption("fwa.connnect.data_dir", default = rappdirs::user_cache_dir("fwa.connect"))
  }
}
