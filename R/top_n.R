#' Top N most/least frequent values
#'
#' @description
#' Inspired by `forcats::fct_lump_n` and by the lack of a good alternative. \cr
#' These are very fast and memory efficient.
#'
#' @param x [vector]
#' @param n [integer] Number of categories to include.
#' @param na_rm [logical] Should `NA` values be removed? Default is `FALSE`.
#' @param with_ties [logical] Should ties be kept? Default is `FALSE`.
#' @param as_factor [logical] Should the result be a factor? Default is `TRUE`.
#' @param other_category [character] Name of the other category. Default is "Other".
#'
#' @details
#' `top_n` returns a vector of the most frequent values, with an
#' added attribute of counts named "n". \cr
#' `top_n_tbl` returns a data frame of top n values and associated counts. \cr
#' `lump_top_n` returns a factor such that any values not in the top n values are
#' placed into a separate category "Other".
#'
#' @returns
#' `top_n`/`bottom_n` return a vector the same class as `x`. \cr
#' `top_n_tbl`/`bottom_n_tbl` return a 2-col `data.frame`. \cr
#' `lump_top_n`/`lump_bottom_n` return a `factor` (or `character` vector).
#'
#' @examples
#' library(dplyr)
#' library(timeplyr)
#' \dontshow{
#' .n_dt_threads <- data.table::getDTthreads()
#' .n_collapse_threads <- collapse::get_collapse()$nthreads
#' data.table::setDTthreads(threads = 2L)
#' collapse::set_collapse(nthreads = 1L)
#' }
#' ### Top 3 hair colours
#' timeplyr::top_n(starwars$hair_color, n = 3)
#'
#' starwars %>%
#'   count(hair_col = lump_top_n(hair_color, n = 3))
#'
#' top_n_tbl(starwars$hair_color, n = 3)
#' \dontshow{
#' data.table::setDTthreads(threads = .n_dt_threads)
#' collapse::set_collapse(nthreads = .n_collapse_threads)
#'}
#' @rdname top_n
#' @export
top_n_tbl <- function(x, n = 5, na_rm = FALSE, with_ties = FALSE){
  check_length(n, 1L)
  g <- GRP2(x, sort = FALSE, return.order = FALSE)
  g_names <- GRP_names(g)
  N <- GRP_data_size(g)
  out <- GRP_group_sizes(g)
  df <- new_tbl(value = g_names, n = out)
  if (na_rm){
    df <- df_row_slice(df, cpp_which(is.na(df[["value"]]), invert = TRUE))
  }
  # Sort by freq (descending order)
  df <- df_row_slice(df, radix_order(desc(df[["n"]])))
  first_n_seq <- seq_len(min(min(n, N), length(out)))
  if (with_ties){
    keep <- df[["n"]] %in% df[["n"]][first_n_seq]
  } else {
    keep <- first_n_seq
  }
  df_row_slice(df, keep)
}
#' @rdname top_n
#' @export
top_n <- function(x, n = 5, na_rm = FALSE, with_ties = FALSE){
  top_n_df <- top_n_tbl(x, n = n, na_rm = na_rm, with_ties = with_ties)
  counts <- top_n_df[["n"]]
  add_attr(top_n_df[["value"]], "n", counts)
}
#' @rdname top_n
#' @export
bottom_n_tbl <- function(x, n = 5, na_rm = FALSE, with_ties = FALSE){
  check_length(n, 1L)
  g <- GRP2(x, sort = FALSE, return.order = FALSE)
  g_names <- GRP_names(g)
  N <- GRP_data_size(g)
  out <- GRP_group_sizes(g)
  df <- new_tbl(value = g_names, n = out)
  if (na_rm){
    df <- df_row_slice(df, cpp_which(is.na(df[["value"]]), invert = TRUE))
  }
  # Sort by freq (ascending order)
  df <- df_row_slice(df, radix_order(df[["n"]]))
  first_n_seq <- seq_len(min(min(n, N), length(out)))
  if (with_ties){
    keep <- df[["n"]] %in% df[["n"]][first_n_seq]
  } else {
    keep <- first_n_seq
  }
  df_row_slice(df, keep)
}
#' @rdname top_n
#' @export
bottom_n <- function(x, n = 5, na_rm = FALSE, with_ties = FALSE){
  bottom_n_df <- bottom_n_tbl(x, n = n, na_rm = na_rm, with_ties = with_ties)
  counts <- bottom_n_df[["n"]]
  add_attr(bottom_n_df[["value"]], "n", counts)
}
#' @rdname top_n
#' @export
lump_top_n <- function(x, n = 5, na_rm = FALSE, with_ties = FALSE,
                       as_factor = TRUE,
                       other_category = "Other"){
  top_n_vals <- top_n(x, n = n, na_rm = na_rm, with_ties = with_ties)
  out <- collapse::fmatch(x, top_n_vals, nomatch = length(top_n_vals) + 1L,
                          overid = 2L)
  factor_levels <- as.character(top_n_vals)
  if (length(top_n_vals) < n_unique(x, na.rm = na_rm)){
    factor_levels <- c(factor_levels, other_category)
  }
  if (as_factor){
    attr(out, "levels") <- factor_levels
    class(out) <- "factor"
  } else {
    out <- factor_levels[out]
  }
  out
}
#' @rdname top_n
#' @export
lump_bottom_n <- function(x, n = 5, na_rm = FALSE, with_ties = FALSE,
                          as_factor = TRUE,
                          other_category = "Other"){
  bottom_n_vals <- bottom_n(x, n = n, na_rm = na_rm, with_ties = with_ties)
  out <- collapse::fmatch(x, bottom_n_vals, nomatch = length(bottom_n_vals) + 1L,
                          overid = 2L)
  factor_levels <- as.character(bottom_n_vals)
  if (length(bottom_n_vals) < n_unique(x, na.rm = na_rm)){
    factor_levels <- c(factor_levels, other_category)
  }
  if (as_factor){
    attr(out, "levels") <- factor_levels
    class(out) <- "factor"
  } else {
    out <- factor_levels[out]
  }
  out
}
