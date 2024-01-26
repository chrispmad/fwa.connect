library(data.table)

fwa_pattern = '200-948755-937012-678735.*'

test_that("Swimming upstream works", {
  expect_equal(
    length(fwa.connect::fwa_up_and_downstream_tbl[data.table::`%like%`(upstream_fwa_code, fwa_pattern)]$upstream_fwa_code),
    7
  )
})
