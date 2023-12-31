# Generated by cpp11: do not edit by hand

cpp_gcd2 <- function(x, y, tol, na_rm) {
  .Call(`_timeplyr_cpp_gcd2`, x, y, tol, na_rm)
}

cpp_lcm2 <- function(x, y, tol, na_rm) {
  .Call(`_timeplyr_cpp_lcm2`, x, y, tol, na_rm)
}

cpp_gcd <- function(x, tol, na_rm, break_early, round) {
  .Call(`_timeplyr_cpp_gcd`, x, tol, na_rm, break_early, round)
}

cpp_lcm <- function(x, tol, na_rm) {
  .Call(`_timeplyr_cpp_lcm`, x, tol, na_rm)
}

cpp_is_whole_num <- function(x, tol, na_rm) {
  .Call(`_timeplyr_cpp_is_whole_num`, x, tol, na_rm)
}

cpp_roll_lag <- function(x, k, fill) {
  .Call(`_timeplyr_cpp_roll_lag`, x, k, fill)
}

cpp_roll_lead <- function(x, k, fill) {
  .Call(`_timeplyr_cpp_roll_lead`, x, k, fill)
}

cpp_roll_lag_grouped <- function(x, k, o, sizes, fill) {
  .Call(`_timeplyr_cpp_roll_lag_grouped`, x, k, o, sizes, fill)
}

cpp_roll_lead_grouped <- function(x, k, o, sizes, fill) {
  .Call(`_timeplyr_cpp_roll_lead_grouped`, x, k, o, sizes, fill)
}

cpp_roll_diff <- function(x, k, fill) {
  .Call(`_timeplyr_cpp_roll_diff`, x, k, fill)
}

cpp_roll_diff_grouped <- function(x, k, o, sizes, fill) {
  .Call(`_timeplyr_cpp_roll_diff_grouped`, x, k, o, sizes, fill)
}

cpp_roll_na_fill <- function(x, fill_limit) {
  .Call(`_timeplyr_cpp_roll_na_fill`, x, fill_limit)
}

cpp_roll_na_fill_grouped <- function(x, o, sizes, fill_limit) {
  .Call(`_timeplyr_cpp_roll_na_fill_grouped`, x, o, sizes, fill_limit)
}

cpp_num_na <- function(x) {
  .Call(`_timeplyr_cpp_num_na`, x)
}

cpp_row_id <- function(order, group_sizes, ascending) {
  .Call(`_timeplyr_cpp_row_id`, order, group_sizes, ascending)
}

before_sequence <- function(size, k) {
  .Call(`_timeplyr_before_sequence`, size, k)
}

after_sequence <- function(size, k) {
  .Call(`_timeplyr_after_sequence`, size, k)
}

cpp_int_sequence <- function(size, from, by) {
  .Call(`_timeplyr_cpp_int_sequence`, size, from, by)
}

cpp_dbl_sequence <- function(size, from, by) {
  .Call(`_timeplyr_cpp_dbl_sequence`, size, from, by)
}

cpp_window_sequence <- function(size, k, partial, ascending) {
  .Call(`_timeplyr_cpp_window_sequence`, size, k, partial, ascending)
}

cpp_lag_sequence <- function(size, k, partial) {
  .Call(`_timeplyr_cpp_lag_sequence`, size, k, partial)
}

cpp_lead_sequence <- function(size, k, partial) {
  .Call(`_timeplyr_cpp_lead_sequence`, size, k, partial)
}

cpp_list_which_not_null <- function(l) {
  .Call(`_timeplyr_cpp_list_which_not_null`, l)
}

list_has_interval <- function(l) {
  .Call(`_timeplyr_list_has_interval`, l)
}

list_item_is_interval <- function(l) {
  .Call(`_timeplyr_list_item_is_interval`, l)
}

cpp_sorted_group_starts <- function(group_sizes) {
  .Call(`_timeplyr_cpp_sorted_group_starts`, group_sizes)
}

roll_time_threshold <- function(x, threshold, switch_on_boundary) {
  .Call(`_timeplyr_roll_time_threshold`, x, threshold, switch_on_boundary)
}

cpp_df_group_indices <- function(rows, size) {
  .Call(`_timeplyr_cpp_df_group_indices`, rows, size)
}

cpp_r_obj_address <- function(x) {
  .Call(`_timeplyr_cpp_r_obj_address`, x)
}

cpp_any_address_changed <- function(x, y) {
  .Call(`_timeplyr_cpp_any_address_changed`, x, y)
}

cpp_lengths <- function(x) {
  .Call(`_timeplyr_cpp_lengths`, x)
}

cpp_bin <- function(x, breaks, codes, right, include_lowest, include_oob) {
  .Call(`_timeplyr_cpp_bin`, x, breaks, codes, right, include_lowest, include_oob)
}

cpp_bin_grouped <- function(x, y, codes, right, include_lowest, include_oob) {
  .Call(`_timeplyr_cpp_bin_grouped`, x, y, codes, right, include_lowest, include_oob)
}

cpp_list_subset <- function(x, ptype, i, default_value) {
  .Call(`_timeplyr_cpp_list_subset`, x, ptype, i, default_value)
}

cpp_new_list <- function(size, default_value) {
  .Call(`_timeplyr_cpp_new_list`, size, default_value)
}

cpp_which_ <- function(x, invert) {
  .Call(`_timeplyr_cpp_which_`, x, invert)
}
