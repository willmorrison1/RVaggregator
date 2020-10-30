args <- commandArgs(trailingOnly = TRUE)
#wip
if (length(args) != 1 | !file.exists(args[1])) {
  print(paste("No arguments provided"))
} else {
  library(processx)

  paramsFileFull <- args[1]
  setwd(dirname(paramsFileFull))
  paramsFileName <- basename(paramsFileFull)
  params <- read.table(file = paramsFileName, sep = ";", header = TRUE, colClasses = "character")
  pList <- list()
  for (i in 1:nrow(params)) {
    pList[[i]] <- process$new(command = "Rscript",
                              args = c("RVaggregator.R", params$input_raster_file[i], params$aggregation_file[i],
                                       params$aggregation_type[i], params$output_directory[i]),
                              stdout = paste0(i, ".o"), stderr = paste0(i, ".e"))
  }

  alive <- sapply(pList, function(x) x$is_alive())

  while (any(alive)) {
    alive <- sapply(pList, function(x) x$is_alive())
    Sys.sleep(1)
  }

  exit_status <- sapply(pList, function(x) x$get_exit_status())

  if (all(exit_status == 0)) {
    message("All finished OK")
  } else {
    message("Finished with issues")
  }
}
