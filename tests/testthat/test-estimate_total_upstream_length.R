# PSCIS layer from BC Data Catalogue
fp = bcdata::bcdc_query_geodata('7ecfafa6-5e18-48cd-8d9b-eae5b5ea2881') |>
  bcdata::filter(RESPONSIBLE_PARTY_NAME == 'WEST FRASER MILLS LTD.',
         STREAM_NAME == 'Nass River',
         ROAD_NAME == 'Warren Road') |>
  bcdata::collect()

test_that("function returns expected result for specific fish passage barrier", {
  expect_equal(
      estimate_total_upstream_length(
        obstacles = fp,
        make_plot = T,
        save_plot = F)$total_length_m,
    13908
  )
})
