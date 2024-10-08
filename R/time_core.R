#' Vector date and datetime functions
#'
#' @description These are atomic vector-based functions
#' of the tidy equivalents which all have a "v" suffix to denote this.
#' These are more geared towards programmers and allow for working with date and
#' datetime vectors.
#'
#' @param x Time variable. \cr
#' Can be a `Date`, `POSIXt`, `numeric`, `integer`, `yearmon`, `yearqtr`,
#' `year_month` or `year_quarter`.
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
#' @param from Time series start date.
#' @param to Time series end date.
#' @param unique Should the result be unique or match the length of the vector?
#' Default is `TRUE`.
#' @param sort Should the output be sorted? Default is `TRUE`.
#' @param time_type If "auto", `periods` are used for
#' the time expansion when days, weeks, months or years are specified,
#' and `durations` are used otherwise.
#' @param time_floor Should `from` be floored to the nearest unit specified
#' through the `time_by` argument?
#' This is particularly useful for starting sequences at the
#' beginning of a week or month for example.
#' @param week_start day on which week starts following ISO conventions - 1
#' means Monday (default), 7 means Sunday.
#' This is only used when `time_floor = TRUE`.
#' @param roll_month Control how impossible dates are handled when
#' month or year arithmetic is involved.
#' Options are "preday", "boundary", "postday", "full" and "NA".
#' See `?timechange::time_add` for more details.
#' @param roll_dst See `?timechange::time_add` for the full list of details.
#' @param complete Logical. If `TRUE` implicit gaps in time are filled
#' before counting and after time aggregation (controlled using `time_by`).
#' The default is `FALSE`.
#' @param g Grouping object passed directly to `collapse::GRP()`.
#' This can for example be a vector or data frame.
#' @param use.g.names Should the result include group names?
#' Default is `TRUE`.
#' @param as_interval Should result be a `time_interval`?
#' Default is `FALSE`. \cr
#' This can be controlled globally through `options(timeplyr.use_intervals)`.
#'
#' @returns
#' Vectors (typically the same class as `x`) of varying lengths depending
#' on the arguments supplied.
#' `time_countv()` returns a `tibble`.
#'
#' @examples
#' library(timeplyr)
#' library(dplyr)
#' library(lubridate)
#' library(nycflights13)
#' \dontshow{
#' .n_dt_threads <- data.table::getDTthreads()
#' .n_collapse_threads <- collapse::get_collapse()$nthreads
#' data.table::setDTthreads(threads = 2L)
#' collapse::set_collapse(nthreads = 1L)
#' }
#' x <- unique(flights$time_hour)
#'
#' # Number of missing hours
#' time_num_gaps(x)
#'
#' # Same as above
#' time_span_size(x) - length(unique(x))
#'
#' # Time sequence that spans the data
#' length(time_span(x)) # Automatically detects hour granularity
#' time_span(x, time_by = "month")
#' time_span(x, time_by = list("quarters" = 1),
#'              to = today(),
#'              # Floor start of sequence to nearest month
#'              time_floor = TRUE)
#'
#' # Complete missing gaps in time using time_completev
#' y <- time_completev(x, time_by = "hour")
#' identical(y[!y %in% x], time_gaps(x))
#'
#' # Summarise time using time_summarisev
#' time_summarisev(y, time_by = "quarter")
#' time_summarisev(y, time_by = "quarter", unique = TRUE)
#' flights %>%
#'   fcount(quarter = time_summarisev(time_hour, "quarter"))
#' # Alternatively
#' time_countv(flights$time_hour, time_by = "quarter")
#' # If you want the above as an atomic vector just use tibble::deframe
#' \dontshow{
#' data.table::setDTthreads(threads = .n_dt_threads)
#' collapse::set_collapse(nthreads = .n_collapse_threads)
#'}
#' @rdname time_core
#' @export
time_expandv <- function(x, time_by = NULL, from = NULL, to = NULL,
                         g = NULL, use.g.names = TRUE,
                         time_type = getOption("timeplyr.time_type", "auto"),
                         time_floor = FALSE,
                         week_start = getOption("lubridate.week.start", 1),
                         roll_month = getOption("timeplyr.roll_month", "preday"),
                         roll_dst = getOption("timeplyr.roll_dst", "NA")){
  check_is_time_or_num(x)
  check_length_lte(from, 1)
  check_length_lte(to, 1)
  time_by <- time_by_get(x, time_by = time_by)
  if (time_by_length(time_by) > 1L){
    stop("time_by must be a time unit containing a single numeric increment")
  }
  g <- GRP2(g)
  check_data_GRP_size(x, g)
  has_groups <- !is.null(g)
  if (is.null(from)){
    from <- collapse::fmin(x, g = g, use.g.names = FALSE, na.rm = TRUE)
  }
  if (is.null(to)){
    to <- collapse::fmax(x, g = g, use.g.names = FALSE, na.rm = TRUE)
  }
  # Make sure from/to are datetimes if x is datetime
  from <- time_cast(from, x)
  to <- time_cast(to, x)
  if (time_floor){
    from <- time_floor2(from, time_by, week_start = week_start)
  }
  seq_sizes <- time_seq_sizes(from, to, time_by, time_type = time_type)
  out <- time_seq_v2(seq_sizes,
                     from = from,
                     time_by = time_by,
                     time_type = time_type,
                     time_floor = FALSE,
                     week_start = week_start,
                     roll_month = roll_month,
                     roll_dst = roll_dst)
  if (has_groups && use.g.names){
    group_names <- GRP_names(g)
    if (!is.null(group_names)){
      names(out) <- rep.int(group_names, times = seq_sizes)
    }
  }
  out
}
#' @rdname time_core
#' @export
time_span <- time_expandv
#' @rdname time_core
#' @export
time_completev <- function(x, time_by = NULL, from = NULL, to = NULL,
                           sort = TRUE,
                           time_type = getOption("timeplyr.time_type", "auto"),
                           time_floor = FALSE,
                           week_start = getOption("lubridate.week.start", 1),
                           roll_month = getOption("timeplyr.roll_month", "preday"),
                           roll_dst = getOption("timeplyr.roll_dst", "NA")){
  time_full <- time_expandv(x, time_by = time_by,
                            from = from, to = to,
                            time_type = time_type,
                            time_floor = time_floor,
                            week_start = week_start,
                            roll_month = roll_month,
                            roll_dst = roll_dst)
  out <- time_cast(x, time_full)
  gaps <- cheapr::setdiff_(time_full, out)
  if (length(gaps) > 0){
    out <- c(out, gaps)
  }
  if (sort){
    out <- sort(out)
  }
  out
}
#' @rdname time_core
#' @export
time_summarisev <- function(x, time_by = NULL, from = NULL, to = NULL,
                            sort = FALSE, unique = FALSE,
                            time_type = getOption("timeplyr.time_type", "auto"),
                            time_floor = FALSE,
                            week_start = getOption("lubridate.week.start", 1),
                            roll_month = getOption("timeplyr.roll_month", "preday"),
                            roll_dst = getOption("timeplyr.roll_dst", "NA"),
                            as_interval = getOption("timeplyr.use_intervals", TRUE)){
  check_is_time_or_num(x)
  check_length_lte(from, 1)
  check_length_lte(to, 1)
  if (is.null(from)){
    from <- collapse::fmin(x, na.rm = TRUE)
  }
  if (is.null(to)){
    to <- collapse::fmax(x, na.rm = TRUE)
  }
  # set_time_cast(from, to)
  from <- time_cast(from, x)
  to <- time_cast(to, x)
  if (isTRUE(from > to)){
    stop("from must be <= to")
  }
  time_by <- time_by_get(x, time_by = time_by)
  # Time sequence
  time_breaks <- time_expandv(x, time_by = time_by,
                              from = from, to = to,
                              time_type = time_type,
                              time_floor = time_floor,
                              week_start = week_start,
                              roll_month = roll_month,
                              roll_dst = roll_dst)
  x <- time_cast(x, time_breaks)
  to <- time_cast(to, x)
  out <- cut_time(x, breaks = c(unclass(time_breaks), unclass(to)), codes = FALSE)
  if (unique){
    out <- collapse::funique(out, sort = sort)
  }
  if (sort && !unique){
    out <- sort(out)
  }
  if (as_interval){
    out <- time_by_interval(out, time_by = time_by,
                            time_type = time_type,
                            roll_month = roll_month,
                            roll_dst = roll_dst)
  }
  out
}
#' @rdname time_core
#' @export
time_countv <- function(x, time_by = NULL, from = NULL, to = NULL,
                        sort = TRUE, unique = TRUE,
                        complete = FALSE,
                        time_type = getOption("timeplyr.time_type", "auto"),
                        time_floor = FALSE,
                        week_start = getOption("lubridate.week.start", 1),
                        roll_month = getOption("timeplyr.roll_month", "preday"),
                        roll_dst = getOption("timeplyr.roll_dst", "NA"),
                        as_interval = getOption("timeplyr.use_intervals", TRUE)){
  check_is_time_or_num(x)
  time_by <- time_by_get(x, time_by = time_by)
  if (is.null(from)){
    from <- collapse::fmin(x, na.rm = TRUE, use.g.names = FALSE)
  }
  if (is.null(to)){
    to <- collapse::fmax(x, na.rm = TRUE, use.g.names = FALSE)
  }
  from <- time_cast(from, x)
  to <- time_cast(to, x)
  # Time sequence
  time_breaks <- time_seq_v(from = from, to = to,
                            time_by = time_by,
                            time_type = time_type,
                            time_floor = time_floor,
                            week_start = week_start,
                            roll_month = roll_month,
                            roll_dst = roll_dst)
  x <- time_cast(x, time_breaks)
  from <- time_cast(from, x)
  to <- time_cast(to, x)
  out_len <- length(x)
  # Aggregate time/cut time
  x <- cut_time(x, breaks = c(unclass(time_breaks), unclass(to)), codes = FALSE)
  # Counts
  out <- group_sizes(x, expand = TRUE)
  # (Optionally) complete time data
  if (complete){
    time_missed <- cheapr::setdiff_(time_breaks, x)
    if (length(time_missed) > 0L){
      x <- c(x, time_missed) # Complete time sequence
    }
    out <- c(out, integer(length(time_missed)))
  }
  out <- new_tbl(x = x, n = out)
  if (unique){
    out <- fdistinct(out, .cols = "x", sort = sort, .keep_all = TRUE)
  }
  if (sort && !unique){
    out <- farrange(out, .cols = "x")
  }
  if (as_interval){
    out[["x"]] <- time_by_interval(out[["x"]], time_by = time_by,
                                   time_type = time_type,
                                   roll_month = roll_month,
                                   roll_dst = roll_dst)
  }
  out
}
#' @rdname time_core
#' @export
time_span_size <- function(x, time_by = NULL, from = NULL, to = NULL,
                           g = NULL, use.g.names = TRUE,
                           time_type = getOption("timeplyr.time_type", "auto"),
                           time_floor = FALSE,
                           week_start = getOption("lubridate.week.start", 1)){
  check_is_time_or_num(x)
  check_length_lte(from, 1)
  check_length_lte(to, 1)
  time_by <- time_by_get(x, time_by = time_by)
  if (time_by_length(time_by) > 1L){
    stop("time_by must be a time unit containing a single numeric increment")
  }
  g <- GRP2(g)
  check_data_GRP_size(x, g)
  has_groups <- is.null(g)
  if (is.null(from)){
    from <- collapse::fmin(x, g = g, use.g.names = FALSE, na.rm = TRUE)
  }
  if (is.null(to)){
    to <- collapse::fmax(x, g = g, use.g.names = FALSE, na.rm = TRUE)
  }
  # Make sure from/to are datetimes if x is datetime
  from <- time_cast(from, x)
  to <- time_cast(to, x)
  if (time_floor){
    from <- time_floor2(from, time_by = time_by, week_start = week_start)
  }
  out <- time_seq_sizes(from = from, to = to,
                        time_by = time_by,
                        time_type = time_type)
  if (has_groups && use.g.names){
    group_names <- GRP_names(g)
    if (!is.null(group_names)){
      names(out) <- group_names
    }
  }
  out
}
# time_group <- function(x, width = time_gcd_diff(x), from = NULL){
#   check_is_time_or_num(x)
#   time_by <- time_by_get(x, width)
#   if (length(from) <= 1 &&
#       time_span_size(x, time_by, from = from) <= 5e05){
#     return(time_summarisev(
#       x, time_by = time_by, from = from,
#       as_interval = TRUE
#     ))
#   }
#   num <- time_by_num(time_by)
#   units <- time_by_unit(time_by)
#   if (is.null(from)){
#     index <- gmin(x, na.rm = TRUE)
#   } else {
#     if (length(from) %!in_% c(1, length(x))){
#       stop("length of from must be 1 or length(x)")
#     }
#     index <- time_cast(from, x)
#     x[cheapr::which_(x < index)] <- NA
#   }
#   tdiff <- time_diff(index, x, time_by = time_by)
#   time_to_add <- add_names(list(trunc2(tdiff) * num), units)
#   out <- time_add2(index, time_by = time_to_add)
#   time_by_interval(out, time_by = time_by)
# }
time_by_interval <- function(x, time_by = NULL,
                             # bound_range = FALSE,
                             time_type = getOption("timeplyr.time_type", "auto"),
                             roll_month = getOption("timeplyr.roll_month", "preday"),
                             roll_dst = getOption("timeplyr.roll_dst", "NA")){
  time_by <- time_by_get(x, time_by = time_by)
  check_time_by_length_is_one(time_by)
  direction <- time_by_sign(time_by)
  if (isTRUE(direction < 0)){
    stop("Right-closed and left-open intervals are currently unsupported")
  }
  end <- time_add2(x, time_by,
                   time_type = time_type,
                   roll_month = roll_month,
                   roll_dst = roll_dst)
  start <- time_cast(x, end)
  out <- time_interval(start, end)
  # if (bound_range){
  #   right_bound <- time_cast(collapse::fmax(x, na.rm = TRUE), end)
  #   which_closed <- which_(cppdoubles::double_gt(unclass(end), unclass(right_bound)))
  #   # end[which_closed] <- right_bound
  #   out[which_closed] <- time_interval(start[which_closed],
  #                                      time_add2(right_bound,
  #                                                time_by = time_by,
  #                                                roll_month = roll_month,
  #                                                roll_dst = roll_dst))
  # }
  out
}
