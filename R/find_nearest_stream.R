#' Title Find nearest stream to a given point
#'
#' @param point Point to search with
#' @param max_buffer_dist How far to look for stream, in meters
#'
#' @return A single stream in an {sf} table
#' @export
#'
#' @examples \dontrun
find_nearest_stream = function(points, max_buffer_dist = 50){

  is_spatial = tryCatch(!is.null(sf::st_geometry(points)),
                       error = function(e) FALSE)
  if(!is_spatial){
    stop("Error: supplied point coordinate seems to not be spatial. Does it have a geometry column?")
  }
  if(!is.numeric(max_buffer_dist)){
    stop("Error: max_buffer_dist must be numeric.")
  }

  # Set to BC Albers projection
  if(sf::st_crs(points)[[1]] != "NAD83 / BC Albers"){
    points = sf::st_transform(points, crs = 3005)
  }
  # Test to see if points table is below bcdata size limit for queries.
  point_size = as.numeric(utils::object.size(sf::st_geometry(points)))
  points_too_large = point_size > 5e5

  if(points_too_large){
    # Number of groups into which to split point data
    num_groups_to_make = ceiling(point_size / 5e5)

    points = points |>
      dplyr::mutate(group_num = ceiling(dplyr::row_number() / (nrow(points)/num_groups_to_make))) |>
      dplyr::group_by(group_num) |>
      dplyr::group_split()
  }

  # Test to see if 'points' object has been converted into a list of 2+ elements
  if(points_too_large){
    # Deal with as list
    query_test = tryCatch(
      points |>
        lapply(\(x) {
          bcdata::bcdc_query_geodata('freshwater-atlas-stream-network') |>
            bcdata::filter(bcdata::DWITHIN(x, distance = max_buffer_dist, units = 'meters'))
        }),
      error = function(e) stop("Error: Looks like the BC Data Catalogue, or your connection to it, is not working.")
    )

    stream_piece_dl = query_test |> lapply(\(x) bcdata::collect(x)) |> sf::st_zm() |> dplyr::bind_rows()


  } else {
    # Deal with as table
    query_test = tryCatch(
          bcdata::bcdc_query_geodata('freshwater-atlas-stream-network') |>
            bcdata::filter(bcdata::DWITHIN(points, distance = max_buffer_dist, units = 'meters')
        ),
      error = function(e) stop("Error: Looks like the BC Data Catalogue, or your connection to it, is not working.")
    )
    stream_piece_dl = query_test |> bcdata::collect() |> sf::st_zm() |> dplyr::bind_rows()
  }

  stream_full_dl = bcdata::bcdc_query_geodata('freshwater-atlas-stream-network') |>
    bcdata::filter(FWA_WATERSHED_CODE %in% stream_piece_dl$FWA_WATERSHED_CODE) |>
    bcdata::collect() |>
    sf::st_zm() |>
    dplyr::group_by(FWA_WATERSHED_CODE,BLUE_LINE_KEY) |>
    dplyr::summarise()

  # If no stream matched, quit
  if(nrow(stream_full_dl) == 0) stop("No streams matched to points... sorry!")

  # Ensure name of geometry column.
  names(stream_full_dl)[ncol(stream_full_dl)] <- 'geometry'
  # Confirm that stream_full_dl is an {sf} table, not just a tibble...
  stream_full_dl = sf::st_as_sf(stream_full_dl)

  # Match streams to obstacle points by finding the nearest stream for each obstacle.
  point_stream_match = as.data.frame(sf::st_nearest_feature(points, stream_full_dl))
  point_stream_match$point_row = as.numeric(row.names(point_stream_match))
  names(point_stream_match)[1] = 'stream_row'

  # Verify that the matched stream is within the searching buffer.
  point_stream_distances = as.numeric(sf::st_distance(points, stream_full_dl[point_stream_match$stream_row,], by_element = T))

  # For matches beyond the max buffer distance (i.e. spurious matches), make stream_row NA
  if(sum(point_stream_distances > max_buffer_dist) > 0){
    point_stream_match[point_stream_distances > max_buffer_dist,]$stream_row = NA
  }
  # Pull the FWA_WATERSHED_CODE from matched streams and add as new column to points table
  points$FWA_WATERSHED_CODE = stream_full_dl[point_stream_match$stream_row,]$FWA_WATERSHED_CODE

  # Filter streams downloaded for just those present in list of points' fwa codes
  stream_full_dl = stream_full_dl[stream_full_dl$FWA_WATERSHED_CODE %in% unique(points$FWA_WATERSHED_CODE),]

  return(list(
    points = points,
    streams = stream_full_dl)
  )
}

