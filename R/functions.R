getRunParams <- function(input_file, aggregation_file, aggregation_type,
                         output_directory, poly_chunk_size = 5) {

  runParams <- list()
  runParams$input_file <- input_file
  runParams$input_aggregator_format <- getAggregationFileType(aggregation_file)
  runParams$input_aggregator_file <- aggregation_file
  runParams$aggregation_type <- aggregation_type
  runParams$output_directory <- output_directory
  runParams$manual_functions <- getManualFunctions(aggregation_type)
  runParams$poly_chunk_size <- poly_chunk_size

  return(runParams)
}

getManualFunctions <- function(aggregation_type) {

  manualFunctions <- c(
    "mean" = function(x, ...) mean(x, na.rm = TRUE),
    "n_NaN" = function(x) sum(is.na(x)),
    "n_px" = function(x) length(x),
    "min" = function(x, ...) min(x, na.rm = TRUE),
    "max" = function(x, ...) max(x, na.rm = TRUE),
    "median" = function(x, ...) median(x, na.rm = TRUE),
    "Q1" = function(x, ...) quantile(x, 0.25, na.rm = TRUE),
    "Q3" = function(x, ...) quantile(x, 0.75, na.rm = TRUE),
    "sd" = function(x, ...) sd(x, na.rm = TRUE))

  return(manualFunctions)
}


getAggregationFileType <- function(aggregation_file) {

  if (tools::file_ext(aggregation_file) == "shp") {
    input_aggregator_format <- "shp"
  } else {
    checkRast <- try(terra::rast(aggregation_file))
    if (class(checkRast) == "try-error") stop("aggregation_file should be raster or .shp shapefile")
    input_aggregator_format <- "rast"
  }
  return(input_aggregator_format)
}

readAggregator <- function(runParams) {
  if (runParams$input_aggregator_format == "rast") {
    input_aggregator <- terra::rast(runParams$input_aggregator_file)
  }
  if (runParams$input_aggregator_format == "shp") {
    input_aggregator <- terra::vect(runParams$input_aggregator_file)
  }
  input_aggregator <- terra::project(input_aggregator, terra::crs(terra::rast(runParams$input_file)))
}

getAggregatorSpatVector <- function(runParams) {
  raw_aggregator_dat <- readAggregator(runParams)
  if (runParams$input_aggregator_format == "rast") {
    raw_aggregator_dat[][is.na(raw_aggregator_dat[])] <- 0
    input_aggregator_shp <- terra::as.polygons(raw_aggregator_dat,
                                               dissolve = FALSE, values = FALSE)
  }
  if (runParams$input_aggregator_format == "shp") {
    input_aggregator_shp <- raw_aggregator_dat
  }
  return(input_aggregator_shp)
}


make_seq_chunks <- function(input_aggregator_shp, runParams) {
  seq_chunks <- split(1:length(input_aggregator_shp),
                      ceiling(seq_along(1:length(input_aggregator_shp)) / runParams$poly_chunk_size))

  return(seq_chunks)
}

aggregate_distribution <- function(input_rast, input_aggregator_shp, runParams) {

  summaryVals_list <- list()
  seq_chunks <- make_seq_chunks(input_aggregator_shp, runParams)
  tStart <- Sys.time()
  values_found <- FALSE
  for (v in 1:length(seq_chunks)) {
    print(paste(v, "/", length(seq_chunks)))
    extractedVals <- terra::extract(x = input_rast,
                                    y = input_aggregator_shp[seq_chunks[[v]]], touches = FALSE)
    if (nrow(extractedVals) > 0) values_found <- TRUE
    colnames(extractedVals) <- c("ID", "val")

    summaryVals_list[[v]] <- tibble::as_tibble(extractedVals) %>%
      dplyr::right_join(data.frame(ID = 1:length(seq_chunks[[v]])), by = "ID") %>%
      dplyr::mutate(ID = ID + min(seq_chunks[[v]]) - 1) %>%
      dplyr::group_by(ID) %>%
      dplyr::summarise_at(.funs = runParams$manual_functions, .vars = "val")
    rm(extractedVals); gc()
    print(paste(round(difftime(Sys.time(), tStart, units = "min"), 2), "min"))
  }
  if (!values_found) stop("No values found. Likely that datasets do not intersect")
  dplyr::bind_rows(summaryVals_list)

}

aggregate_fraction <- function(input_rast, input_aggregator_shp, runParams) {
  if (terra::ncell(input_rast) > 2000) {
    uniqueVals <- unique(input_rast[sample(1:terra::ncell(input_rast), 2000)])
  } else {
    uniqueVals <- unique(input_rast)
  }

  if (length(uniqueVals) > 20) stop("This isn't an appropriate raster for fraction calculations.
  It has too many unique values. It should have a few values that represent different classes")

  uniqueVals <- sort(uniqueVals)
  summaryVals_list <- list()
  seq_chunks <- make_seq_chunks(input_aggregator_shp, runParams)
  tStart <- Sys.time()
  values_found <- FALSE
  for (v in 1:length(seq_chunks)) {
    print(paste(v, "/", length(seq_chunks)))
    extractedVals <- terra::extract(x = input_rast,
                                    y = input_aggregator_shp[seq_chunks[[v]]],
                                    touches = FALSE)
    if (nrow(extractedVals) > 0) values_found <- TRUE
    colnames(extractedVals) <- c("ID", "val")

    oVal_cell_sum <- tibble::as_tibble(extractedVals) %>%
      dplyr::right_join(data.frame(ID = 1:length(seq_chunks[[v]])), by = "ID") %>%
      dplyr::mutate(ID = ID + min(seq_chunks[[v]]) - 1) %>%
      dplyr::group_by(ID) %>%
      dplyr::summarise("npx" = length(val[!is.na(val)]), .groups = "keep")
    for (i in 1:length(uniqueVals)) {
      oVal <- tibble::as_tibble(extractedVals) %>%
        dplyr::right_join(data.frame(ID = 1:length(seq_chunks[[v]])), by = "ID") %>%
        dplyr::mutate(ID = ID + min(seq_chunks[[v]]) - 1) %>%
        dplyr::group_by(ID) %>%
        dplyr::summarise("fpx" = sum(val == uniqueVals[i]) / length(val[!is.na(val)]), .groups = "keep")

      colnames(oVal)[2] <- paste0("fpx_", uniqueVals[i])
      #do not do this - robust (because always joining "by" correct column) but slow and bad mem usage.
      if (i == 1) {
        summaryVals_list[[v]] <- oVal
      } else {
        summaryVals_list[[v]] <- dplyr::left_join(summaryVals_list[[v]], oVal, by = "ID")
      }
      rm(oVal); gc()
    }
    rm(extractedVals); gc()
    print(paste(round(difftime(Sys.time(), tStart, units = "min"), 2), "min"))
  }
  if (!values_found) stop("No values found. Likely that datasets do not intersect")
  dplyr::bind_rows(summaryVals_list) %>%
    dplyr::left_join(oVal_cell_sum, by = "ID") %>%
    replace(is.na(.), 0)

}

aggregate_rast <- function(input_rast, input_aggregator_shp, runParams) {

  if (runParams$aggregation_type == "distribution") {
    summaryVals <- aggregate_distribution(input_rast, input_aggregator_shp, runParams)
  }

  if (runParams$aggregation_type == "fraction") {
    summaryVals <- aggregate_fraction(input_rast, input_aggregator_shp, runParams)
  }

  return(summaryVals)
}

assign_aggregated_values <- function(summaryValsDF, runParams) {

  if (runParams$input_aggregator_format == "shp") {
    assignedData <- assign_aggregated_values_vect(summaryValsDF, runParams)
  }

  if (runParams$input_aggregator_format == "rast") {
    assignedData <- assign_aggregated_values_rast(summaryValsDF, runParams)
  }

  return(assignedData)

}

assign_aggregated_values_rast <- function(summaryValsDF, runParams) {
  raw_aggregator_dat <- readAggregator(runParams)
  if (terra::ncell(raw_aggregator_dat) != nrow(summaryValsDF)) {
    stop("ncell and summary stats size mismatch")
  }
  rList <- vector(mode = "list", length = ncol(summaryValsDF))
  names(rList) <- colnames(summaryValsDF)
  for (i in 1:ncol(summaryValsDF)) {
    rList[[i]] <- terra::setValues(raw_aggregator_dat, dplyr::pull(summaryValsDF, i))
  }
  r_out <- terra::rast(rList)
  names(r_out) <- colnames(summaryValsDF)
  return(r_out)
}

assign_aggregated_values_vect <- function(summaryValsDF, runParams) {
  raw_aggregator_dat <- readAggregator(runParams)
  if (length(raw_aggregator_dat) != nrow(summaryValsDF)) {
    stop("ncell and summary stats size mismatch")
  }
  summaryValsDF_names <- names(summaryValsDF)
  values(raw_aggregator_dat) <- summaryValsDF

  return(raw_aggregator_dat)
}

write_aggregated_shp <- function(runParams, assignedDat) {
  oFile <- makeOutputFileName(runParams, assignedDat)
  dir.create(dirname(oFile), showWarnings = FALSE)
  terra::writeVector(x = assignedDat, filename = oFile, overwrite = TRUE)
  return(oFile)
}

write_aggregated_rast <- function(runParams, assignedDat) {
  oFile <- makeOutputFileName(runParams, assignedDat)
  terra::writeRaster(x = assignedDat, filename = oFile, overwrite = TRUE, compression = "lzw")
  return(oFile)
}

write_aggregated <- function(runParams, assignedDat) {

  if (class(assignedDat) == "SpatVector") {
    oFile <- write_aggregated_shp(runParams, assignedDat)
  }
  if (class(assignedDat) == "SpatRaster") {
    oFile <- write_aggregated_rast(runParams, assignedDat)
  }

  return(oFile)
}

makeOutputFileName <- function(runParams, assignedDat) {
  input_aggregator_file_name <-  tools::file_path_sans_ext(basename(runParams$input_aggregator_file))
  input_file <-  tools::file_path_sans_ext(basename(runParams$input_file))

  if (class(assignedDat) == "SpatVector") {
    out_file_name <- file.path(runParams$output_directory, input_file,
                               paste0(input_aggregator_file_name, ".shp"))
  }

  if (class(assignedDat) == "SpatRaster") {
    base_out_file <- paste0(input_file, "_", input_aggregator_file_name)
    out_file_name <- file.path(runParams$output_directory, paste0(base_out_file, ".tif"))
  }

  return(out_file_name)

}

#main
RVaggregator <- function(input_file,
                         aggregation_file,
                         aggregation_type,
                         output_directory = NULL,
                         poly_chunk_size = 10) {

  runParams <- getRunParams(input_file = input_file,
                            aggregation_file = aggregation_file,
                            aggregation_type = aggregation_type,
                            output_directory = output_directory,
                            poly_chunk_size = poly_chunk_size)
  require(terra)
  require(tools)
  require(dplyr)
  require(tidyr)
  #prepare input raster
  input_rast <- terra::rast(runParams$input_file)
  #prepare aggregation space
  input_aggregator_shp <- getAggregatorSpatVector(runParams)
  #aggregate
  aggregated_df <- aggregate_rast(input_rast, input_aggregator_shp, runParams)
  #assign
  assignedDat <- assign_aggregated_values(aggregated_df, runParams)
  #write
  if (!is.null(output_directory)) {
    if (!dir.exists(output_directory)) {
      dir.create(output_directory, recursive = TRUE)
    }
    write_aggregated(runParams, assignedDat)
  }
  return(assignedDat)
}

getArgParser <- function() {
  require(argparser)

  default_memory_fraction <- 0.2
  default_chunk_size <- 20
  p <- argparser::arg_parser("RVaggregator. https://github.com/willmorrison1/RVaggregator")
  p$name <- "RVaggregator"
  p <- argparser::add_argument(parser = p,
                               arg = c("input_file",
                                       "aggregation_file",
                                       "output_directory"),
                               help = c("Input raster file",
                                        "Input aggregation file (lower res than raster, can be raster or .shp)",
                                        "Output directory: base output directory"),
                               flag = c(FALSE, FALSE, FALSE))

  p <- argparser::add_argument(p,
                               arg = c("--cache_directory",
                                       "--memory_fraction",
                                       "--aggregation_chunk_size",
                                       "--aggregate_ordinal"),
                               help =
                                 c("Cache directory: full path to temporary cache location (deleted after exit)",
                                   "Memory fraction: how much of total system memory to use for pre-aggregation raster operations? [0-1]",
                                   "Aggregation chunk size: how many polygons to aggregate over at one time?
                                        Only the input_file raw pixels within aggregation_chunk_size number of polygons will be loaded into system memory.
                                   More important than memory_fraction. Choose 1 for least memory footprint. Memory fooprint varies with raster resolution, polygon size, and chunk size.",
                                   "Aggregate ordinal: Aggregate as fraction (for ordinal, discrete data) or as distribution (continuous data)"),
                               default = list("R internal", default_memory_fraction, default_chunk_size, FALSE))

  return(p)

}
