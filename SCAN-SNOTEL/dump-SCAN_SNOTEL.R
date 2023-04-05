library(soilDB)
library(purrr)

source('local-functions.R')


## TODO / ideas:
# * download / retain required data -> SQLite database
# * more robust error checking

# stations, only CONUS for now
m <- readRDS('data/station-data-with-PRISM.rds')
nrow(m)

## get data elements by site 
d <- map(m$Site, .f = .getSCAN, .progress = TRUE)
saveRDS(d, file = 'data/scan-dump.rds')


## TODO: add snowlite stations? 
# # snowlite
# x <- fetchSCAN(site.code = '1218', year = 2020)


## cleanup
rm(list = ls())
gc(reset = TRUE)

