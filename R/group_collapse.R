#' Key group information
#'
#' @details
#' `group_collapse()` is similar to `dplyr::group_data()` but differs in 3 key regards:
#'
#' * The output tries to convey as much information about the groups as possible.
#' By default, like `dplyr`, the groups are ordered, but unlike `dplyr` they are not
#' sorted, which conveys information on order-of-first-appearance in the data.
#' In addition to group locations, group sizes and start indices are returned.
#'
#' * There is more flexibility in specifying how the groups are ordered and/or sorted.
#'
#' * `collapse` is used to obtain the grouping structure, which is very fast.
#'
#' There are 3 ways to specify the groups:
#'  *  Using `...` which utilises `tidy` `data-masking`.
#'  * Using `.by` which utilises `tidyselect`.
#'  * Using `.cols` which accepts a named character/integer vector.
#'
#' @param data A data frame or vector.
#' @param ... Additional groups using tidy `data-masking` rules. \cr
#' To specify groups using `tidyselect`, simply use the `.by` argument.
#' @param order Should the groups be ordered?
#' \bold{THE PHYSICAL ORDER OF THE DATA IS NOT CHANGED.} \cr
#' When order is `TRUE` (the default) the group IDs will be ordered but not sorted.
#' If `FALSE` the order of the group IDs will be based on first appearance.
#' @param sort Should the data frame be sorted by the groups?
#' @param ascending Should groups be ordered in ascending order?
#' Default is `TRUE` and only applies when `order = TRUE`.
#' @param .by Alternative way of supplying groups using `tidyselect` notation.
#' This is kept to be consistent with other functions.
#' @param .cols (Optional) alternative to `...` that accepts
#' a named character vector or numeric vector.
#' If speed is an expensive resource, it is recommended to use this.
#' @param id Should group IDs be added? Default is `TRUE`.
#' @param size Should group sizes be added? Default is `TRUE`.
#' @param loc Should group locations be added? Default is `TRUE`.
#' @param start Should group start locations be added? Default is `TRUE`.
#' @param end Should group end locations be added? Default is `TRUE`.
#' @param drop Should unused factor levels be dropped? Default is `TRUE`.
#'
#' @returns
#' A `tibble` of unique groups and an integer ID uniquely identifying each group.
#'
#' @examples
#' library(timeplyr)
#' library(dplyr)
#' \dontshow{
#' .n_dt_threads <- data.table::getDTthreads()
#' .n_collapse_threads <- collapse::get_collapse()$nthreads
#' data.table::setDTthreads(threads = 2L)
#' collapse::set_collapse(nthreads = 1L)
#' }
#' iris <- dplyr::as_tibble(iris)
#' group_collapse(iris) # No groups
#' group_collapse(iris, Species) # Species groups
#'
#' iris %>%
#'   group_by(Species) %>%
#'   group_collapse() # Same thing
#'
#' # Group entire data frame
#' group_collapse(iris, .by = everything())
#' \dontshow{
#' data.table::setDTthreads(threads = .n_dt_threads)
#' collapse::set_collapse(nthreads = .n_collapse_threads)
#'}
#' @rdname group_collapse
#' @export
group_collapse <- function(data, ..., order = TRUE, sort = FALSE,
                           ascending = TRUE,
                           .by = NULL, .cols = NULL,
                           id = TRUE,
                           size = TRUE, loc = TRUE,
                           # loc_order = TRUE,
                           start = TRUE, end = TRUE,
                           drop = TRUE){
  UseMethod("group_collapse")
}
#' @export
group_collapse.default <- function(data, ..., order = TRUE, sort = FALSE,
                                   ascending = TRUE,
                                   id = TRUE,
                                   size = TRUE, loc = TRUE,
                                   # loc_order = TRUE,
                                   start = TRUE, end = TRUE,
                                   drop = TRUE){
  g <- GRP2(safe_ungroup(data),
            sort = order,
            decreasing = !ascending,
            na.last = TRUE,
            return.groups = TRUE,
            return.order = order || loc,
            method = "auto",
            call = FALSE,
            drop = drop)
  out <- collapse::qDT(as.list(GRP_groups(g)))
  if (id){
    set_add_cols(out, list(.group = df_seq_along(out)))
  }
  include_loc <- loc ||
    (start && is.null(g[["group.starts"]])) ||
    end
  if (include_loc){
    GRP_loc <- GRP_loc(g)
    set_add_cols(out, list(.loc = structure(GRP_loc,
                                            ptype = integer(),
                                            class = c("vctrs_list_of",
                                                      "vctrs_vctr",
                                                      "list"))))
  } else {
    GRP_loc <- NULL
  }
  if (start){
    set_add_cols(out, list(.start = GRP_starts(g, loc = GRP_loc)))
  }
  if (end){
    set_add_cols(out, list(.end = GRP_ends(g, loc = GRP_loc)))
  }
  if (!loc && include_loc){
    set_rm_cols(out, ".loc")
  }
  if (size){
    set_add_cols(out, list(.size = GRP_group_sizes(g)))
  }
  if (!sort && order){
    unsorted_i <- collapse::funique(GRP_group_id(g), sort = FALSE)
    out <- df_row_slice(out, unsorted_i, reconstruct = FALSE)
  }
  # Method for when not dropping unused factor levels
  # At the moment a bit convoluted
  if (!drop){
    group_names <- names(out)[!names(out) %in%
                                c(".group", ".loc", ".start", ".end", ".size")]
    group_out <- fselect(out, .cols = group_names)
    is_factor <- vapply(group_out, is.factor, FALSE, USE.NAMES = FALSE)
    if (any(is_factor)){
      # If we have a mix of factors and non factors
      # Then we do not proceed
      if (sum(is_factor) < length(is_factor)){
        rlang::abort(c("There are a mix of factor and non-factor variables",
                       "and there is currently no method for dealing with this.",
                       "Please use dplyr::group_by for this behaviour."))
      }
      group_out <- fselect(group_out, .cols = which(is_factor))
      group_data_size <- prod(
        vapply(group_out, collapse::fnlevels, 0L)
      )
      num_missing_categories <- group_data_size - n_unique(
        fselect(group_out, .cols = names(group_out))
      )
      if (num_missing_categories > 0){
        # The below cross joins all factor categories
        # Removes existing category combinations
        missed_categories <- vctrs::vec_set_difference(
          list_to_tibble(
            crossed_join(
              lapply(group_out,
                     function(x) collapse::qF(levels(x), sort = FALSE)),
              as_dt = FALSE, unique = FALSE
            )
          ),
          df_as_tibble(group_out)
        )
        if (id){
          missed_categories[[".group"]] <- NA_integer_
        }
        # Bind the combinations that don't exist
        if (loc){
          missed_categories[[".loc"]] <- structure(
            list(integer()),
            ptype = integer(),
            class = c("vctrs_list_of",
                      "vctrs_vctr",
                      "list")
          )
        }
        if (start){
          missed_categories[[".start"]] <- 0L
        }
        if (end){
          missed_categories[[".end"]] <- 0L
        }
        if (size){
          missed_categories[[".size"]] <- 0L
        }
        out <- vctrs::vec_rbind(out, missed_categories)
        if (id){
          out[[".group"]] <- group_id(out, .cols = group_names,
                                      order = order)
        }
          if (order && sort){
            if (ascending){
              out <- farrange(out, .cols = group_names)
            } else {
              out <- farrange(out, across(all_of(group_names), desc))
            }
          }
      }
    }
  }
  df_as_tibble(out)
}
#' @export
group_collapse.factor <- function(data, ..., order = TRUE, sort = FALSE,
                                   ascending = TRUE,
                                   id = TRUE,
                                   size = TRUE, loc = TRUE,
                                   # loc_order = TRUE,
                                   start = TRUE, end = TRUE,
                                   drop = TRUE){
  # Doing this because collapse::GRP(x) coerces x
  # into character if it is a factor
  # whereas no coercion happens with collapse::GRP(data.frame(x))
  group_collapse(new_df(data = data),
                 .cols = "data",
                 order = order,
                 sort = sort,
                 id = id,
                 size = size,
                 loc = loc,
                 start = start,
                 end = end,
                 drop = drop)
}
#' @export
group_collapse.data.frame <- function(data, ..., order = TRUE, sort = FALSE,
                                      ascending = TRUE,
                                      .by = NULL, .cols = NULL,
                                      id = TRUE,
                                      size = TRUE, loc = TRUE,
                                      # loc_order = TRUE,
                                      start = TRUE, end = TRUE,
                                      drop = TRUE){
  N <- df_nrow(data)
  group_info <- tidy_group_info(data, ..., .by = {{ .by }},
                                .cols = .cols,
                                ungroup = TRUE,
                                rename = TRUE)
  data <- group_info[["data"]]
  vars <- group_info[["all_groups"]]
  if (length(vars) == 0L){
    rowids <- seq_len(N)
    ss <- min(N, 1L)
    rowids <- list(rowids)[ss]
    out <- new_tbl(".group" = integer(ss) + 1L)
    if (loc){
      out[[".loc"]] <- vctrs::new_list_of(rowids, ptype = integer(0))
    }
    # if (loc_order){
    #   out[[".order"]] <- vctrs::as_list_of(rowids, .ptype = integer(0))
    # }
    if (start){
      out[[".start"]] <- integer(ss) + 1L
    }
    if (end){
      out[[".end"]] <- integer(ss) + N
    }
    if (size){
      out[[".size"]] <- N[ss]
    }
    if (!id){
      out[[".group"]] <- NULL
    }
  } else {
    out <- group_collapse.default(fselect(data, .cols = vars),
                                  order = order, sort = sort,
                                  id = id,
                                  size = size, loc = loc,
                                  ascending = ascending,
                                  # loc_order = loc_order,
                                  start = start, end = end,
                                  drop = drop)
  }
  out
}
#' @export
group_collapse.grouped_df <- function(data, ..., order = TRUE, sort = FALSE,
                                      ascending = TRUE,
                                      .by = NULL, .cols = NULL,
                                      id = TRUE,
                                      size = TRUE, loc = TRUE,
                                      # loc_order = TRUE,
                                      start = TRUE, end = TRUE,
                                      drop = dplyr::group_by_drop_default(data)){
  n_dots <- dots_length(...)
  # Error checking on .by
  check_by(data, .by = {{ .by }})
  # Special conditions where if met,
  # we can use dplyr grouping structure
  if (n_dots == 0 &&
      is.null(.cols) &&
      order &&
      ascending &&
      sort &&
      drop == dplyr::group_by_drop_default(data)){
    out <- group_data(data)
    out_nms <- names(out)
    out <- frename(out, .cols = c(".loc" = ".rows"))

    if (id){
      out[[".group"]] <- df_seq_along(out, "rows")
      ncol <- ncol(out)
      out <- fselect(out, .cols = c(seq_len(ncol - 2L), ncol, ncol - 1L))
    }
    sizes <- collapse::vlengths(out[[".loc"]], use.names = FALSE)
    if (start){
      gstarts <- integer(length(sizes))
      gstarts[cpp_which(sizes != 0L)] <- GRP_loc_starts(out[[".loc"]])
      out[[".start"]] <- gstarts
    }
    if (end){
      gends <- integer(length(sizes))
      gends[cpp_which(sizes != 0L)] <- GRP_loc_ends(out[[".loc"]])
      out[[".end"]] <- gends
    }
    if (size){
      out[[".size"]] <- sizes
    }
    if (!loc){
      out[[".loc"]] <- NULL
    }
    # if (loc_order){
    #   g <- dplyr::group_indices(data)
    #   out[[".order"]] <- vctrs::as_list_of(collapse::gsplit(radix_order(g),
    #                                                         g = g, use.g.names = FALSE),
    #                                        .ptype = integer(0))
    # }
  } else {
    group_info <- tidy_group_info(data, ..., .by = {{ .by }},
                                  .cols = .cols,
                                  ungroup = TRUE,
                                  rename = TRUE)
    all_groups <- group_info[["all_groups"]]
    out <- group_collapse.default(fselect(group_info[["data"]], .cols = all_groups),
                                  order = order, sort = sort,
                                  id = id,
                                  size = size, loc = loc,
                                  ascending = ascending,
                                  # loc_order = loc_order,
                                  start = start, end = end,
                                  drop = drop)
    attr(out, ".drop") <- drop
  }
  out
}
