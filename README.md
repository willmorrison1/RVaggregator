# RVaggregator
Raster and Vector spatial aggregation tool

## Summary

RVaggregator aims to ease aggregation of spatial data. Aggregation involves the coarsening of a high resolution dataset (raster) across a lower resolution raster or polygon(s). 

This can obviously be done in R/python/gdal etc but not an "all in one" and relatively fast solution. Here you can:
- Define a flexible range of statistics (cf. e.g. gdal which has a finite number of pre-compiled functions - it  only had "sum" introduced in ~2019)
- Input a range of datasets and the program will parallelise the processing for you
- Output neat shapefiles/raster bricks.
- Work with ordinal (e.g. land cover class) and continuous (e.g. heights) input data
- Avoid the headache of having to make a specific bit of code for a specific aggregation

The backend is a bit clunky but it means you don't have to mess with any of the code, becuase it uses command line options only. 

## Install

## Command line use 

## R use

If you really want to use it in R you can call
```
RVaggregator()
```
