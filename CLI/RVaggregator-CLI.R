library(RVaggregator)

args <- getArgParser()
# p_parsed <- argparser::parse_args(args, c("C:/Users/willm/Dropbox/DSM_GLA_1m_EPSG_32631_crop.tif",
#                                           "C:/Users/willm/Dropbox/r_agg_tmploc1/vertsIn/slstr_IR_nadir_vertices.shp", "C:/Users/willm/Desktop"))
#
# p_parsed <- argparser::parse_args(args, c("data/sample/sample_input_raster_ordinal.tif",
#                                           "data/sample/sample_shapefile/sample_shapefile.shp",
#                                           "data/sample/output",
#                                           "--aggregate_ordinal", TRUE))

p_parsed <- argparser::parse_args(args)
print(p_parsed)
terraOptions(memfrac = p_parsed$memory_fraction)

if (!is.na(p_parsed$cache_directory)) {
  if (dir.exists(p_parsed$cache_directory)) {
    terraOptions(tempdir = p_parsed$cache_directory)
  }
}

aggregated_dat <- RVaggregator(input_file = p_parsed$input_file,
                               aggregation_file = p_parsed$aggregation_file,
                               aggregation_type = ifelse(p_parsed$aggregate_ordinal, "fraction", "distribution"),
                               output_directory = p_parsed$output_directory,
                               poly_chunk_size = p_parsed$aggregation_chunk_size)

