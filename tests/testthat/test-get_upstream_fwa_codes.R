test_that("Swimming upstream works", {

  suppressWarnings(requireNamespace('data.table'))

  fwa_pattern = '200-948755-937012-678735.*'

  dat = fwa.connect::fwa_up_and_downstream_tbl

  expect_equal(
    length(dat[data.table::`%like%`(dat$upstream_fwa_code, fwa_pattern),]$upstream_fwa_code),
    7
  )
})
