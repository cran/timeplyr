#' Fast count time at higher time units.
#'
#' @description This function operates like `dplyr::count()`
#' but with emphasis on
#' a specified time variable.
#'
#' @param data A data frame.
#' @param time Time variable.
#' @param ... Additional variables to include.
#' @param time_by Time unit. \cr
#' Must be one of the three:
#' * string, specifying either the unit or the number and unit, e.g
#' `time_by = "days"` or `time_by = "2 weeks"`
#' * named list of length one, the unit being the name, and
#' the number the value of the list, e.g. `list("days" = 7)`.
#' For the vectorized time functions, you can supply multiple values,
#' e.g. `list("days" = 1:10)`.
#' * Numeric vector. If time_by is a numeric vector and x is not a date/datetime,
#' then arithmetic is used, e.g `time_by = 1`.
#' @param from Time series start date. If `NULL` then min time is used.
#' @param to Time series end date. If `NULL` then max time is used.
#' @param complete \bold{Deprecated}.
#' Use `time_complete()` after `time_count()` to
#' complete missing gaps in time (as well as optionally expand groups).
#' @param wt Frequency weights.
#' `dplyr` "data-masking" is used for variable selection.
#'   Can be `NULL` or a variable:
#'
#'   * If `NULL` (the default), counts the number of rows in each group.
#'   * If a variable, computes `sum(wt)` for each group.
#' @param sort If `TRUE` the groups with largest counts will be sorted first.
#' If `FALSE` the result is sorted by groups + time + ... groups.
#' @param name Character vector of length 1, specifying the name of
#' the new column in the output.
#' @param .by (Optional). A selection of columns to group by for this operation.
#' Columns are specified using tidy-select.
#' @param time_floor Should `from` be floored to the nearest unit
#' specified through the `time_by`
#' argument? This is particularly useful for starting
#' sequences at the beginning of a week
#' or month for example.
#' @param week_start day on which week starts following ISO conventions - 1
#' means Monday (default), 7 means Sunday.
#' This is only used when `time_floor = TRUE`.
#' @param time_type If "auto", `periods` are used for
#' the time expansion when days, weeks, months or
#' years are specified, and `durations`
#' are used otherwise.
#' @param roll_month Control how impossible dates are handled when
#' month or year arithmetic is involved.
#' Options are "preday", "boundary", "postday", "full" and "NA".
#' See `?timechange::time_add` for more details.
#' @param roll_dst See `?timechange::time_add` for the full list of details.
#' @param include_interval Logical. If `TRUE` then
#' a column "interval" of the form `time_min <= x < time_max` is added
#' showing the time interval in which the respective counts belong to.
#' The rightmost interval will always be closed.
#' @returns
#' An object of class `data.frame`
#' containing the aggregate time variable and corresponding counts.
#'
#' @details
#' `time_count` Creates an
#' aggregated frequency time series where time
#' can be aggregated to
#' both lower and higher time units.
#'
#' An important note is that when the data are grouped, time ranges are expanded
#' on a group-by-group basis. \cr
#' When groups are supplied through
#' `...`, the time range of the entire data is used
#' to aggregate the time variable.
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
#' df <- flights %>%
#'   mutate(date = as_date(time_hour)) %>%
#'   select(year, month, day, origin, dest, date, time_hour)
#'
#' # By default time_count() guesses the time granularity
#' df %>%
#'   time_count(time_hour)
#' # Aggregated to week level
#' df %>%
#'   time_count(time = date, time_by = "2 weeks")
#' df %>%
#'   time_count(time = date, time_by = list("months" = 3),
#'              from = dmy("15-01-2013"),
#'              time_floor = TRUE,
#'              include_interval = TRUE)
#' \dontshow{
#' data.table::setDTthreads(threads = .n_dt_threads)
#' collapse::set_collapse(nthreads = .n_collapse_threads)
#' }
#' @export
time_count <- function(data, time = NULL, ..., time_by = NULL,
                       from = NULL, to = NULL,
                       complete = FALSE,
                       wt = NULL, name = NULL,
                       sort = FALSE,
                       .by = NULL,
                       time_floor = FALSE,
                       week_start = getOption("lubridate.week.start", 1),
                       time_type = getOption("timeplyr.time_type", "auto"),
                       roll_month = getOption("timeplyr.roll_month", "preday"),
                       roll_dst = getOption("timeplyr.roll_dst", "boundary"),
                       include_interval = FALSE){
  int_nm <- character()
  original_groups <- get_groups(data, {{ .by }})
  by_groups <- tidy_select_pos(data, {{ .by }})
  # Determine common bounds
  from_info <- mutate_summary_grouped(data, !!enquo(from), .keep = "none")
  to_info <- mutate_summary_grouped(data, !!enquo(to), .keep = "none")
  from_var <- from_info[["cols"]]
  to_var <- to_info[["cols"]]
  check_length_lte(from_var, 1)
  check_length_lte(to_var, 1)
  from_data <- fselect(safe_ungroup(from_info[["data"]]), .cols = from_var)
  to_data <- fselect(safe_ungroup(to_info[["data"]]), .cols = to_var)
  out <- fgroup_by(data, ..., order = FALSE, .add = TRUE,
                   .by = {{ .by }})
  group_vars <- group_vars(out)
  extra_groups <- setdiff(group_vars, original_groups)
  # # #
  from_nm <- character()
  if (length(from_var) > 0){
    out <- df_add_cols(out, add_names(list(from_data[[from_var]]), from_var))
  }
  to_nm <- character()
  if (length(to_var) > 0){
    out <- df_add_cols(out, add_names(list(to_data[[to_var]]), to_var))
  }
  # Ungroup and use the .by to avoid reconstruction..
  out <- fcount(safe_ungroup(out), !!enquo(time), wt = !!enquo(wt),
                across(all_of(c(from_var, to_var))),
                order = FALSE,
                name = name,
                .by = all_of(group_vars))
  out <- fgroup_by(out, .cols = original_groups, order = FALSE)
  n_nm <- names(out)[length(names(out))]
  time_var <- setdiff2(names(out), c(group_vars, n_nm, from_var, to_var))
  if (!missing(complete) || complete){
    rlang::warn(c("x" = "'complete' has been deprecated and will not be applied",
                  "Please use `time_complete()`",
                  "",
                  "For example:",
                  "data %>%",
                  " " = paste0("time_count(", time_var, ")", " %>%"),
                  " " = paste0("time_complete(", time_var, ", fill = list(n = 0))")),
                use_cli_format = TRUE)
  }
  if (length(time_var) > 0){
    time_by <- time_by_get(out[[time_var]], time_by = time_by)
    groups <- df_to_GRP(out, .cols = original_groups, order = TRUE)
    if (length(from_var) == 0L){
      from_var <- new_var_nm(out, ".from")
      out <- df_add_cols(out, add_names(list(gmin(out[[time_var]], g = groups)),
                                        from_var))
    }
    if (length(to_var) == 0L){
      to_var <- new_var_nm(out, ".to")
      out <- df_add_cols(out, add_names(list(gmax(out[[time_var]], g = groups)),
                                        to_var))
    }
    out <- df_add_cols(out, add_names(list(time_cast(out[[from_var]],
                                                     out[[time_var]])),
                                           from_var))
    out <- df_add_cols(out, add_names(list(time_cast(out[[to_var]],
                                                     out[[time_var]])),
                                           to_var))

    time_agg <- time_aggregate_left(out[[time_var]],
                                    time_by = time_by,
                                    start = out[[from_var]],
                                    end = out[[to_var]],
                                    g = groups,
                                    time_type = time_type,
                                    roll_month = roll_month,
                                    roll_dst = roll_dst,
                                    time_floor = time_floor,
                                    week_start = week_start,
                                    as_int = include_interval)
    time_int_end <- time_int_end(time_agg)
    time_agg <- time_int_rm_attrs(time_agg)
    int_end_nm <- new_var_nm(names(out), "int_end")
    out <- df_add_cols(out, add_names(list(time_agg, time_int_end), c(time_var, int_end_nm)))
    groups2 <- df_to_GRP(safe_ungroup(out), .cols = c(original_groups, time_var, extra_groups))
    # groups2 <- GRP2(list(out[[time_var]], group_id(groups)), sort = TRUE)
    counts <- collapse::fsum(out[[n_nm]], g = groups2, use.g.names = FALSE, na.rm = FALSE)
    group_start_locs <- GRP_starts(groups2)
    out <- df_row_slice(out, group_start_locs)
    out <- df_add_cols(out, add_names(list(counts), n_nm))
    if (include_interval){
      int_nm <- new_var_nm(out, "interval")
      out <- df_add_cols(out, add_names(
        list(
          time_interval2(out[[time_var]], out[[int_end_nm]])
        ), int_nm
      ))
    }
  }
  out <- fselect(out, .cols = c(original_groups, time_var, int_nm, extra_groups, n_nm))
  if (sort){
    out <- df_row_slice(out, radix_order(desc(out[[n_nm]])), reconstruct = FALSE)
  }
  if (length(by_groups) > 0 || sort){
    out <- df_reconstruct(out, data)
  }
  out
}
# PREVIOUS VERSION.
# More efficient with completing implicit time gaps
# time_count2 <- function(data, time = NULL, ..., time_by = NULL,
#                        from = NULL, to = NULL,
#                        complete = TRUE,
#                        wt = NULL, name = NULL,
#                        sort = FALSE,
#                        .by = NULL,
#                        time_floor = FALSE,
#                        week_start = getOption("lubridate.week.start", 1),
#                        time_type = getOption("timeplyr.time_type", "auto"),
#                        roll_month = getOption("timeplyr.roll_month", "preday"),
#                        roll_dst = getOption("timeplyr.roll_dst", "boundary"),
#                        include_interval = FALSE){
#   check_is_df(data)
#   time_type <- match_time_type(time_type)
#   reconstruct <- TRUE
#   ts_data <- mutate2(data,
#                      ...,
#                      !!enquo(time),
#                      !!enquo(from),
#                      !!enquo(to),
#                      !!enquo(wt),
#                      .by = {{ .by }},
#                      .keep = "none")
#   group_info <- get_group_info(data, ..., type = "data-mask",
#                                .by = {{ .by }})
#   # Transformed variable names
#   # It is important to maintain the first-evaluated result of the expression,
#   # As done above
#   time_var <- tidy_transform_names(data, !!enquo(time))
#   from_var <- tidy_transform_names(data, !!enquo(from))
#   to_var <- tidy_transform_names(data, !!enquo(to))
#   wt_var <- tidy_transform_names(data, !!enquo(wt))
#   if (length(wt_var) > 0L) wtv <- ts_data[[wt_var]]
#   group_vars <-  group_info[["dplyr_groups"]]
#   extra_group_vars <- group_info[["extra_groups"]]
#   all_group_vars <- group_info[["all_groups"]]
#   N <- df_nrow(ts_data)
#   if (length(time_var) > 0){
#     ts_data <- as_DT(ts_data)
#     # Add variable to keep track of group IDs
#     grp_nm <- new_var_nm(ts_data, ".group.id")
#     ts_data[, (grp_nm) := group_id(data, .by = {{ .by }}, as_qg = TRUE)]
#     n_groups <- attr(ts_data[[grp_nm]], "N.groups")
#     data.table::set(ts_data, j = grp_nm, value = qg_to_integer(ts_data[[grp_nm]]))
#     # Determine common bounds
#     from_nm <- new_var_nm(names(ts_data), ".from")
#     to_nm <- new_var_nm(c(names(ts_data), from_nm), ".to")
#     ts_data[, c(from_nm, to_nm) := get_from_to(ts_data, time = time_var,
#                                                from = from_var,
#                                                to = to_var,
#                                                .by = all_of(grp_nm))]
#     start_end_tbl <- fdistinct(ts_data, .cols = c(grp_nm, from_nm, to_nm))
#     if (!isTRUE(df_nrow(start_end_tbl) == n_groups)){
#       warning("Multiple start-end values detected.
#               Please supply one pair per group",
#               immediate. = TRUE)
#     }
#     ts_data <- df_row_slice(ts_data,
#                             data.table::between(ts_data[[time_var]],
#                                                 ts_data[[from_nm]],
#                                                 ts_data[[to_nm]],
#                                                 incbounds = TRUE, NAbounds = NA))
#     # User supplied unit
#     if (!is.null(time_by)){
#       time_by <- time_by_list(time_by)
#     } else {
#       # Function to determine implicit time units
#       granularity <- time_granularity(ts_data[[time_var]], msg = TRUE)
#       time_by <- add_names(list(granularity[["num"]]), granularity[["unit"]])
#     }
#     # Frequency table
#     out <- ts_data %>%
#       fcount(.cols = c(grp_nm, group_vars, time_var,
#                        from_var, to_var,
#                        extra_group_vars),
#              wt = across(all_of(wt_var)),
#              name = name)
#     name <- names(out)[length(names(out))]
#     time_agg <- time_aggregate_switch(out[[time_var]],
#                                       time_by = time_by,
#                                       g = out[[grp_nm]],
#                                       start = fpluck(out, from_var),
#                                       end = fpluck(out, to_var),
#                                       time_type = time_type,
#                                       roll_month = roll_month,
#                                       roll_dst = roll_dst,
#                                       time_floor = time_floor,
#                                       week_start = week_start,
#                                       as_int = include_interval)
#     int_end_nm <- character(0)
#     time_int_end <- time_int_end(time_agg)
#     out[, (time_var) := time_int_rm_attrs(time_agg)]
#     if (include_interval){
#       out[, ("int_end") := time_int_end]
#       int_end_nm <- "int_end"
#     }
#     out <- fcount(out, .cols = c(grp_nm, group_vars,
#                                  time_var, extra_group_vars, int_end_nm),
#                   wt = across(all_of(name)),
#                   name = name)
#     # If complete, full-join time sequence df onto ts data
#     if (complete){
#       # message("\nFilling in implicit gaps in time, counts are replaced with 0
#       #         to disable this set complete = FALSE")
#       out[start_end_tbl, (c(from_nm, to_nm)) := mget(c(from_nm, to_nm)),
#           on = grp_nm, allow.cartesian = FALSE]
#       # Expanded time sequences for each group
#       out <- time_complete(out,
#                            time = across(all_of(time_var)),
#                            across(all_of(extra_group_vars)),
#                            from = across(all_of(from_nm)),
#                            to = across(all_of(to_nm)),
#                            time_by = time_by,
#                            time_type = time_type,
#                            sort = TRUE,
#                            .by = all_of(c(grp_nm, group_vars)),
#                            time_floor = time_floor, week_start = week_start,
#                            keep_class = FALSE,
#                            expand_type = "nesting",
#                            fill = add_names(list(0L), name))
#       set_rm_cols(out, c(from_nm, to_nm))
#       if (include_interval){
#         out[is.na(get(int_end_nm)) & !is.na(get(time_var)),
#             (int_end_nm) := time_add2(get(time_var), time_by = time_by,
#                                       roll_dst = roll_dst,
#                                       roll_month = roll_month,
#                                       time_type = time_type)]
#       }
#     }
#     int_nm <- character(0)
#     if (include_interval){
#       out <- df_as_tibble(out)
#       if (inherits(data, "data.table")){
#         reconstruct <- FALSE
#         message("data.table converted to tibble as data.table cannot include interval class")
#       }
#
#       int_nm <- new_var_nm(out, "interval")
#       out[[int_nm]] <- time_interval2(out[[time_var]],
#                                      out[[int_end_nm]])
#     }
#     out <- fselect(out, .cols = c(grp_nm,
#                                   group_vars,
#                                   time_var,
#                                   extra_group_vars,
#                                   int_nm,
#                                   name))
#     if (sort){
#       out <- farrange(out, desc(.data[[name]]))
#     }
#     out <- df_rm_cols(out, grp_nm) # Remove group ID
#   } else {
#     out <- ts_data %>%
#       fcount(.cols = c(group_vars, extra_group_vars),
#              wt = across(all_of(wt_var)),
#              name = name,
#              sort = sort)
#     name <- names(out)[length(names(out))]
#   }
#   if (include_interval && !is_interval(out[[int_nm]])){
#     attr(out[[int_nm]], "start") <- out[[time_var]]
#   }
#   if (reconstruct){
#     out <- df_reconstruct(out, data)
#   }
#   out
# }
#
