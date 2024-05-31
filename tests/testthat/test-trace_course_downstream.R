test_that("Correct number of rows for fixed FWA code", {

  fwa_code = "200-948755-999851-274772-093336-000000-000000-000000-000000-000000-000000-000000-000000-000000-000000-000000-000000-000000-000000-000000-000000"
  zoo = trace_course_downstream(fwa_code = fwa_code)

  nrow(zoo)

  expect_equal(nrow(zoo), 21)

  })
