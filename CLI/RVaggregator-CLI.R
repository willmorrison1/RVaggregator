library(ncdf4)
library(raster)
library(terra)
library(gdalUtils)
library(RVaggregator)

args <- commandArgs(trailingOnly = TRUE)

args1 <- c("D:/LondonSpatialDatasets/raster/DSM_AGL_GLA_1m_EPSG_32631.tif",
           "C:/Users/micromet/Desktop/slstr_IR_oblique_vertices.shp",
           "distribution",
           "C:/Users/micromet/Dropbox/r_agg_tmploc2")
args2 <- c("D:/LondonSpatialDatasets/raster/LC_MMGLA_4m_EPSG_32631.tif",
           "C:/Users/micromet/Desktop/slstr_IR_oblique_vertices_subsample.shp",
           "fraction",
           "C:/Users/micromet/Dropbox/r_agg_tmploc2")
args3 <- c("D:/LondonSpatialDatasets/raster/DSM_AGL_GLA_1m_EPSG_32631.tif",
           "C:/Users/micromet/Desktop/agg_rast_ex.tif",
           "fraction",
           "C:/Users/micromet/Dropbox/r_agg_tmploc2") #should fail
args4 <- c("D:/LondonSpatialDatasets/raster/DSM_AGL_GLA_1m_EPSG_32631.tif",
           "C:/Users/micromet/Desktop/agg_rast_ex.tif",
           "distribution",
           "C:/Users/micromet/Dropbox/r_agg_tmploc2")
args5 <- c("D:/LondonSpatialDatasets/raster/LC_MMGLA_4m_EPSG_32631.tif",
           "C:/Users/micromet/Desktop/slstr_IR_nadir_vertices.shp",
           "fraction",
           "C:/Users/micromet/Dropbox/r_agg_tmploc2")
args6 <- c("C:/Users/micromet/Desktop/DSM_GLA_1m_EPSG_32631_crop.tif",
           "C:/Users/micromet/Desktop/slstr_IR_nadir_vertices.shp",
           "distribution",
           "C:/Users/micromet/Dropbox/r_agg_tmploc2")

args <- args7

print(args)

terraOptions(memfrac = 0.25, tempdir = "D:/r_tmp/")
rasterOptions(tmpdir = "D:/r_tmp/", maxmemory = 3.5e+10)
RVaggregator(input_file = args[1],
             aggregation_file = args[2],
             aggregation_type = args[3],
             output_directory = args[4],
             poly_chunk_size = 15)


