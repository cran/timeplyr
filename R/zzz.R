.onLoad <- function(libname, pkgname){
  register_all_s3_methods()
}
register_s3_method <- function(pkg, generic, class, fun = NULL){
  stopifnot(is.character(pkg), length(pkg) == 1)
  stopifnot(is.character(generic), length(generic) == 1)
  stopifnot(is.character(class), length(class) == 1)

  if (is.null(fun)) {
    fun <- get(paste0(generic, ".", class), envir = parent.frame())
  } else {
    stopifnot(is.function(fun))
  }

  if (pkg %in% loadedNamespaces()){
    registerS3method(generic, class, fun, envir = asNamespace(pkg))
  }

  # Always register hook in case package is later unloaded & reloaded
  setHook(
    packageEvent(pkg, "onLoad"),
    function(...) {
      registerS3method(generic, class, fun, envir = asNamespace(pkg))
    }
  )
}

register_all_s3_methods <- function(){
  register_s3_method("collapse", "GRP", "Interval")
  register_s3_method("collapse", "GRP", "NULL")
  register_s3_method("zoo", "rep", "yearmon")
  register_s3_method("zoo", "rep.int", "yearmon")
  register_s3_method("zoo", "rep_len", "yearmon")
  register_s3_method("zoo", "rep", "yearqtr")
  register_s3_method("zoo", "rep.int", "yearqtr")
  register_s3_method("zoo", "rep_len", "yearqtr")
  register_s3_method("pillar", "tbl_sum", "time_tbl_df")
  register_s3_method("timeplyr", "rep", "year_month")
  register_s3_method("timeplyr", "rep.int", "year_month")
  register_s3_method("timeplyr", "rep_len", "year_month")
  register_s3_method("timeplyr", "print", "year_month")
  register_s3_method("timeplyr", "+", "year_month")
  register_s3_method("timeplyr", "-", "year_month")
  register_s3_method("timeplyr", "c", "year_month")
  register_s3_method("timeplyr", "format", "year_month")
  register_s3_method("timeplyr", "as.character", "year_month")
  register_s3_method("timeplyr", "unique", "year_month")
  register_s3_method("timeplyr", "as.Date", "year_month")
  register_s3_method("timeplyr", "as.POSIXct", "year_month")
  register_s3_method("timeplyr", "as.POSIXlt", "year_month")
  register_s3_method("timeplyr", "[", "year_month")
  register_s3_method("timeplyr", "[[", "year_month")
  register_s3_method("timeplyr", "rep", "year_quarter")
  register_s3_method("timeplyr", "rep.int", "year_quarter")
  register_s3_method("timeplyr", "rep_len", "year_quarter")
  register_s3_method("timeplyr", "print", "year_quarter")
  register_s3_method("timeplyr", "+", "year_quarter")
  register_s3_method("timeplyr", "-", "year_quarter")
  register_s3_method("timeplyr", "c", "year_quarter")
  register_s3_method("timeplyr", "format", "year_quarter")
  register_s3_method("timeplyr", "as.character", "year_quarter")
  register_s3_method("timeplyr", "unique", "year_quarter")
  register_s3_method("timeplyr", "as.Date", "year_quarter")
  register_s3_method("timeplyr", "as.POSIXct", "year_quarter")
  register_s3_method("timeplyr", "as.POSIXlt", "year_quarter")
  register_s3_method("timeplyr", "[", "year_quarter")
  register_s3_method("timeplyr", "[[", "year_quarter")
}

on_package_load <- function(pkg, expr){
  if (isNamespaceLoaded(pkg)){
    expr
  } else {
    thunk <- function(...) expr
    setHook(packageEvent(pkg, "onLoad"), thunk)
  }
}
.onAttach <- function(...){
  options("timeplyr.time_type" = getOption("timeplyr.time_type", "auto"),
          "timeplyr.roll_month" = getOption("timeplyr.roll_month", "preday"),
          "timeplyr.roll_dst" = getOption("timeplyr.roll_dst", "boundary"))
}
