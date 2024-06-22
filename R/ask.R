#' Copy of {bcmaps}'s ask() function
#'
#' @param ... Unsure what this is
#'
#' @return Unsure
#'
#' @examples \dontrun
ask = function (...)
{
  choices <- c("Yes", "No")
  cat(paste0(..., collapse = ""))
  utils::menu(choices) == which(choices == "Yes")
}
