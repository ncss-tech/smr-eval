## ideas here:
# https://ncss-tech.github.io/jNSMR/reference/newhall_batch.html
# https://ncss-tech.github.io/jNSMR/articles/newhall-prism.html

## TODO: finish warping / saving results



library(terra)
library(jNSMR)
library(viridisLite)

# GCS
ppt <- rast('e:/gis_data/prism/final_monthly_ppt_800m.tif')
tavg <- rast('e:/gis_data/prism/final_monthly_tavg_800m.tif')
elev <- rast('e:/gis_data/prism/PRISM_us_dem_800m.tif')

# EPSG:5070
aws <- rast('e:/gis_data/FY2023-800m-rasters/rasters/water_storage.tif')

# convert AWS from cm -> mm
aws <- aws * 10

## TODO: convert this to pre-processing step
# warp aws -> GCS
aws <- project(aws, ppt, method = 'bilinear')

# fix raster layer names
.months <- c('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')
names(tavg) <- sprintf("t%s", .months)
names(ppt) <- sprintf("p%s", .months)
names(elev) <- 'elev'
names(aws) <- 'awc'

# combine all data into single collection
x <- c(tavg, ppt, elev, aws)

# extract cell coordinates (WGS84)
xy <- terra::xyFromCell(x[[1]], 1:ncell(x[[1]]))

# add WGS84 coordinates as new bands
x$lonDD <- xy[, 1]
x$latDD <- xy[, 2]

# check: OK
names(x)

# cleanup
rm(xy)
gc(reset = TRUE)

# try at coarser resolution
a <- aggregate(x, fact = 5)


## full res: 
#   Error in checkForRemoteErrors(val) : 
#   12 nodes produced errors; first error: java.lang.OutOfMemoryError: Java heap space
#
#
# --> use fewer cores, or fewer rows / chunk


## full res
# 3105 x 7025
# * 8 cores, 1000 rows --> out of memory
# * 8 cores, 20 rows --> ~ 100 minutes
# * 8 cores, 10 rows --> seems to work

## 5x reduced res.
# 621 x 1405
# * 8 cores, 1000 rows --> out of memory
# * 8 cores, 100 rows --> 4 minutes




system.time(
  sim <- newhall_batch(
    x,
    unitSystem = "metric",
    soilAirOffset = 2,
    amplitude = 0.66,
    verbose = TRUE,
    toString = FALSE,
    checkargs = TRUE,
    cores = 8,
    file = paste0(tempfile(), ".tif"),
    overwrite = TRUE, 
    nrows = 20
  )
)

# check
sim

plot(sim[[1:4]], col = mako(25))
plot(sim[[5:8]], col = mako(25))
plot(sim[[9:12]], col = mako(25))
plot(sim[[13:16]], col = mako(25))

plot(sim[[3:4]], col = mako(25), axes = FALSE, legend = 'topright')

plot(sim[[c(8,10)]], col = mako(25), axes = FALSE, legend = 'topright')

.cols <- c(rev(RColorBrewer::brewer.pal(9, 'Spectral')), 'grey')
plot(sim[[18]], col = .cols, axes = FALSE, legend = 'topright', mar = c(0, 0, 0, 1), maxcell = 1e5)

.cols <- c(RColorBrewer::brewer.pal(9, 'Spectral'), 'grey')
plot(sim[[19]], col = .cols, axes = FALSE, legend = 'topright', mar = c(0, 0, 0, 1), maxcell = 1e5)

.cols <- rev(RColorBrewer::brewer.pal(9, 'Spectral'))
plot(sim[[16]], col = .cols, axes = FALSE, legend = 'topright', mar = c(0, 0, 1, 0), maxcell = 1e5)

.cols <- RColorBrewer::brewer.pal(4, 'Spectral')
.cols <- c(.cols, 'purple', 'grey')
plot(sim[[17]], col = .cols, axes = FALSE, legend = 'topright', mar = c(0, 0, 1, 0), maxcell = 1e5)


# EPSG:5070 for a better looking map
smr <- project(sim[[17]], 'EPSG:5070', method = 'near')
str <- project(sim[[16]], 'EPSG:5070', method = 'near')




# not bad
ragg::agg_png(filename = 'figures/SMR-800-2deg-offset.png', width = 1400, height = 800, scaling = 1.25, res = 120)

plot(smr, col = .cols, axes = FALSE, legend = 'topright', mar = c(0, 0, 1, 0), maxcell = 1e6)

dev.off()


.cols <- rev(RColorBrewer::brewer.pal(9, 'Spectral'))
plot(str, col = .cols, axes = FALSE, legend = 'topright', mar = c(0, 0, 1, 0), maxcell = 1e5)




# save pieces
writeRaster(smr, file = 'results/SMR-800-2deg-offset.tif', overwrite = TRUE)
writeRaster(str, file = 'results/STR-800-2deg-offset.tif', overwrite = TRUE)




