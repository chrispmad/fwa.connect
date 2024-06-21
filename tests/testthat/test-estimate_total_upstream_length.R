# PSCIS layer from BC Data Catalogue
fp = bcdata::bcdc_query_geodata('7ecfafa6-5e18-48cd-8d9b-eae5b5ea2881') |>
  bcdata::filter(RESPONSIBLE_PARTY_NAME == 'WEST FRASER MILLS LTD.',
         STREAM_NAME == 'Nass River',
         ROAD_NAME == 'Warren Road') |>
  bcdata::collect()

dpg = bcmaps::nr_districts() |>
  dplyr::filter(ORG_UNIT_NAME == 'Prince George Natural Resource District')

fps_DPG = bcdata::bcdc_query_geodata('7ecfafa6-5e18-48cd-8d9b-eae5b5ea2881') |>
  bcdata::filter(INTERSECTS(dpg)) |>
  bcdata::filter(ASSESSMENT_DATE > as.Date('2023-09-01') & ASSESSMENT_DATE < as.Date('2024-12-31')) |>
  bcdata::collect() #|>
  # dplyr::filter(BARRIER_RESULT_CODE != 'PASSABLE')

test_1 = estimate_total_upstream_length(
  fp,
  make_plot = F,
  stream_snap_dist = 80,
  min_obstacles_separation = 40,
  save_plot = TRUE,
  save_plot_location = 'C:/Users/CMADSEN/Downloads'
)

test_2 = estimate_total_upstream_length(
  fps_DPG[c(1:10),],
  make_plot = F,
  stream_snap_dist = 80,
  min_obstacles_separation = 40
)

test_that("function returns expected result for specific fish passage barrier", {
  expect_equal(
    test_1$total_length_m,
    13859
  )
})

test_that("function returns expected results for multiple fish passage barriers", {
  expect_equal(
    test_2$total_length_m,
    c(22564, 3378, NA, 288, 420, 2336, 37498)
  )
})
