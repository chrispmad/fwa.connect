#' Copy of {bcmaps}'s same function
#'
#' @param dir Directory
#'
#' @return TRUE or FALSE
#'
#' @examples \dontrun
check_write_to_data_dir = function (dir, ask)
{

  if (ask) {
    ans <- ask(paste("fwa.connect would like to store this data file in the directory:",
                     dir, "Is that okay?", sep = "\n"))
    if (!ans)
      stop("Exiting...", call. = FALSE)
  }
  if (!dir.exists(dir)) {
    message("Creating directory to hold stream connectivity data at ",
            dir)
    dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  }
  else {
    message("Saving to fwa.connect data directory at ", dir)
  }
}
