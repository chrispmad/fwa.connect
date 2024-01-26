
set.seed(1234)

eg_graph = igraph::graph_from_literal(10-11,9-8-6-5,1-3-2,5-8-1,12-2) |>
  tidygraph::as_tbl_graph()

test_that("variable added to nodes", {
  expect_equal(
    ncol(
      eg_graph |>
        add_attr_to_graph('group_id') |>
        tidygraph::activate(nodes) |>
        as.data.frame()),
    2)
})

test_that("multiple variables can be added", {
  expect_equal(
    ncol(
      eg_graph |>
        add_attr_to_graph(c('group_id','centrality_degree')) |>
        tidygraph::activate(nodes) |>
        as.data.frame()),
    3)
})
