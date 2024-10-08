#' Fast greatest common divisor of time differences
#'
#' @param x Time variable. \cr
#' Can be a `Date`, `POSIXt`, `numeric`, `integer`, `yearmon`, or `yearqtr`.
#' @param time_by Time unit. \cr
#' Must be one of the following:
#' * string, specifying either the unit or the number and unit, e.g
#' `time_by = "days"` or `time_by = "2 weeks"`
#' * named list of length one, the unit being the name, and
#' the number the value of the list, e.g. `list("days" = 7)`.
#' For the vectorized time functions, you can supply multiple values,
#' e.g. `list("days" = 1:10)`.
#' * Numeric vector. If time_by is a numeric vector and x is not a date/datetime,
#' then arithmetic is used, e.g `time_by = 1`.
#' @param time_type If "auto", `periods` are used if `x` is a Date and
#' durations are used if `x` is a datetime.
#' Otherwise numeric differences are calculated.
#' @param tol Numeric tolerance for gcd algorithm.
#'
#' @returns
#' A list of length 1.
#'
#' @examples
#' library(timeplyr)
#' library(lubridate)
#' library(cppdoubles)
#' \dontshow{
#' .n_dt_threads <- data.table::getDTthreads()
#' .n_collapse_threads <- collapse::get_collapse()$nthreads
#' data.table::setDTthreads(threads = 2L)
#' collapse::set_collapse(nthreads = 1L)
#' }
#' time_gcd_diff(1:10)
#' time_gcd_diff(seq(0, 1, 0.2))
#'
#' time_gcd_diff(time_seq(today(), today() + 100, time_by = "3 days"))
#' time_gcd_diff(time_seq(now(), len = 10^2, time_by = "125 seconds"))
#'
#' # Monthly gcd using lubridate periods
#' quarter_seq <- time_seq(today(), len = 24, time_by = months(4))
#' time_gcd_diff(quarter_seq, time_by = months(1), time_type = "period")
#' time_gcd_diff(quarter_seq, time_by = "months", time_type = "duration")
#'
#' # Detects monthly granularity
#' double_equal(time_gcd_diff(as.vector(time(AirPassengers))), 1/12)
#' \dontshow{
#' data.table::setDTthreads(threads = .n_dt_threads)
#' collapse::set_collapse(nthreads = .n_collapse_threads)
#'}
#' @export
time_gcd_diff <- function(x, time_by = 1L,
                          time_type = getOption("timeplyr.time_type", "auto"),
                          tol = sqrt(.Machine$double.eps)){
   if (tby_missing <- is.null(time_by)){
    time_unit <- get_time_unit(x)
  }
  x <- collapse::funique(x, sort = FALSE)
  time_by <- time_by_get(x, time_by = time_by)
  if (!tby_missing){
    time_unit <- time_by_unit(time_by)
  }
  if (length(x) == 1L && is.na(x)){
    return(add_names(list(NA_real_), time_unit))
  }
  if (length(x) == 1L ||
      # Check that the first value is NA since
      # time_elapsed with rolling = F compares to first value
      (length(x) == 2 && is.na(x[1L]))){
    return(add_names(list(1), time_unit))
  }
  tdiff <- time_elapsed(x, rolling = FALSE,
                        time_by = time_by,
                        time_type = time_type,
                        g = NULL,
                        na_skip = TRUE)
  tdiff <- diff_(tdiff, 1L, fill = 0)
  gcd <- cheapr::gcd(tdiff, tol = tol, na_rm = TRUE, round = FALSE)
  add_names(list(time_by_num(time_by) * gcd), time_unit)
}

# More accurate version?
# time_gcd_diff2 <- function(x, tol = sqrt(.Machine$double.eps)){
#   x <- collapse::funique(x, sort = FALSE)
#   if (is_time(x)){
#     unit <- get_time_unit(x)
#     for (per in c("years", "months", "weeks")){
#       tdiff <- time_elapsed(x, rolling = FALSE, time_by = per, na_skip = TRUE)
#       is_whole_num <- is_whole_number(tdiff, na.rm = TRUE)
#       if (is_whole_num){
#         unit <- per
#         break
#       }
#     }
#     if (!is_whole_num){
#       tdiff <- time_elapsed(x, rolling = TRUE, time_by = unit, na_skip = TRUE)
#     } else {
#       tdiff <- roll_diff(tdiff, fill = 0)
#     }
#   } else {
#     unit <- "numeric"
#     tdiff <- time_elapsed(x, rolling = TRUE,
#                           time_by = 1L,
#                           time_type = time_type,
#                           g = NULL,
#                           na_skip = TRUE)
#   }
#   gcd <- cheapr::gcd(tdiff, tol = tol, na_rm = TRUE, round = FALSE)
#   add_names(list(gcd), unit)
# }

# Previous method
# time_gcd_diff2 <- function(x, time_by = 1,
#                           time_type = getOption("timeplyr.time_type", "auto"),
#                           is_sorted = FALSE,
#                           tol = sqrt(.Machine$double.eps)){
#   x <- collapse::funique(x, sort = FALSE)
#   if (!is_sorted && !is_sorted(x)){
#     x <- sort(x, na.last = TRUE)
#   }
#   if (length(x) == 1L && is.na(x)){
#     return(NA_real_)
#   }
#   x <- collapse::na_rm(x)
#   if (length(x) == 0L){
#     return(numeric())
#   }
#   if (length(x) == 1L){
#     return(1)
#   }
#   tdiff <- time_elapsed(x, rolling = FALSE,
#                         time_by = time_by,
#                         time_type = time_type,
#                         g = NULL,
#                         na_skip = FALSE)
#   tdiff <- cpp_roll_diff(tdiff, k = 1L, fill = Inf)
#   log10_tol <- ceiling(abs(log10(tol)))
#   tdiff <- collapse::funique.default(
#     round(
#       abs(tdiff), digits = log10_tol
#     )
#   )
#   tdiff <- tdiff[which_(double_gt(tdiff, 0, tol = tol))]
#   if (length(tdiff) == 1 && tdiff == Inf){
#     return(10^(-log10_tol))
#   }
#   collapse::vgcd(tdiff)
# }
