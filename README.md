RVaggregator
============

Raster and Vector spatial aggregation tool

Summary
-------

RVaggregator aims to ease aggregation of spatial data. Aggregation
involves the coarsening of a high resolution dataset (raster) across a
lower resolution raster or polygon(s).

I have not found an “all in one” and relatively fast aggregation
solution in e.g. R/python/gdal etc that I like. RVaggregator allows you
to: - Define a flexible range of statistics (cf. e.g. gdal which has a
finite number of pre-compiled functions - it only had “sum” introduced
in ~2019) - Parallelise processing across a range of input datasets -
Output neat shapefiles and 2D/3D rasters. - Work with ordinal (e.g. land
cover class) and continuous (e.g. heights) inputs - Avoid the headache
of having to make a specific bit of code for a specific aggregation

Also comes with command line interface wrapper in
`CLI/RVaggregator-CLI.R`.

Install
-------

wip

Command line use
----------------

wip

R use
-----

wip

If you want to use it in R you can call

    RVaggregator()


    wip - example

    library(RVaggregator)


    RVaggregator(input_file = "data/sample/sample_input_raster_ordinal.tif",
                 aggregation_file = "data/sample/sample_shapefile/sample_shapefile.shp",
                 aggregation_type = "fraction",
                 output_directory = "data/sample/output",
                 poly_chunk_size = 5)
