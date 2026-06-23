# Offline tests for the config constants — no database or network needed.

test_that("oc_bbox() is a well-formed WGS84 bounding box", {
  b <- oc_bbox()
  expect_named(b, c("xmin", "ymin", "xmax", "ymax"))
  expect_length(b, 4)
  expect_lt(b[["xmin"]], b[["xmax"]])
  expect_lt(b[["ymin"]], b[["ymax"]])
  # Concord, NH sits in the northeast US quadrant.
  expect_true(b[["xmin"]] < 0 && b[["xmax"]] < 0)
  expect_true(b[["ymin"]] > 40 && b[["ymax"]] < 45)
})

test_that("oc_region_bbox() contains the city bbox", {
  city <- oc_bbox()
  region <- oc_region_bbox()
  expect_lte(region[["xmin"]], city[["xmin"]])
  expect_lte(region[["ymin"]], city[["ymin"]])
  expect_gte(region[["xmax"]], city[["xmax"]])
  expect_gte(region[["ymax"]], city[["ymax"]])
})

test_that("oc_centroid() returns lon/lat near downtown Concord", {
  cc <- oc_centroid()
  expect_named(cc, c("lon", "lat"))
  expect_equal(cc[["lon"]], -71.538, tolerance = 0.1)
  expect_equal(cc[["lat"]], 43.207, tolerance = 0.1)
})

test_that("oc_school_leaids() names the two serving districts", {
  ids <- oc_school_leaids()
  expect_named(ids, c("concord", "merrimack_valley"))
  expect_type(ids, "character")
  expect_length(ids, 2)
})
