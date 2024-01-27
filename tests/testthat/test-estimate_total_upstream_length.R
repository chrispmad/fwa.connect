fp = bcdata::bcdc_query_geodata("pscis-assessments") |>
  bcdata::filter(RESPONSIBLE_PARTY_NAME == 'WEST FRASER MILLS LTD.',
         STREAM_NAME == 'Nass River',
         ROAD_NAME == 'Warren Road') |>
  bcdata::collect()

test_that("function returns expected result for specific fish passage barrier", {
  expect_equal(
    suppressWarnings(
      estimate_total_upstream_length(
        point = fp,
        make_plot = T,
        save_plot = T)
    ),
    13908
  )
})
