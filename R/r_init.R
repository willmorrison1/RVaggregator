setwd("C:/Users/micromet/Dropbox/r_agg_tmploc1/")
params <- read.table(file = "params.txt", sep = ";", header = TRUE, colClasses = "character")
library(processx)
pList <- list()
for (i in 1:nrow(params)) {
  pList[[i]] <- process$new(command = "Rscript",
                            args = c("r.R", params$input_raster_file[i], params$aggregation_file[i], 
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
