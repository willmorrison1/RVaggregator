# RVaggregator
Raster and Vector spatial aggregation tool

# Summary
# The idea behind RVaggregator is to easily take a high resolution raster and aggregate it over a lower resolution raster or polygon(s). 

This can obviously be done in R/python/gdal etc but not an "all in one" solution. Here you can:
- Define a flexible range of statistics (cf. gdal which has a finite number of pre-compiled functions and only had "sum introduced in 2019)
- Input a range of datasets and the program will parallelise the processing for you
- Output neat shapefiles/raster bricks.
- Work with ordinal (e.g. land cover class) and continuous (e.g. heights) input data
- Avoid the headache of having to make a specific bit of code for a specific aggregation
