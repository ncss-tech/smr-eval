library(jNSMR)

## station data + PRISM extractions
x <- readRDS('data/station-data-with-PRISM.rds')

## PAWS data
# SSURGO0-derived
paws <- readRDS('data/SSURGO-paws.rds')

## MAAT - MAST offsets, computed from sensor data when possible
# bad data ore-filtered
o <- readRDS('data/MAAT-MAST-offset.rds')


## launder names for Newhall batch
x$latDD <- x$Latitude
x$lonDD <- x$Longitude
x$elev <- x$elev_m
x$stationName <- x$Name
x$stationID <- as.character(x$Site)

x$pdType <- 'Normal'
x$pdStartYr <- 2022
x$pdEndYr <- 2022
x$cntryCode <- 'US'
x$stProvCode <- 'PA'
x$notes <- NA

## AWC (mm) from SSURGO data
x <- merge(x, paws, by = 'mukey', all.x = TRUE, sort = FALSE)
x$awc <- x$paws_mm

## TODO: document assumptions
# back-fill with an estimate
x$awc[is.na(x$awc)] <- 150

## TODO: compute station-specific offsets

## setup station-specific MAAT -- MAST offset
x <- merge(x, o, by = 'Site', all.x = TRUE, sort = FALSE)
x$maatmast <- x$offset
# back-fill with estimate
x$maatmast[is.na(x$maatmast)] <- 2.5


## simulation with default MAAT - MAST offset
# < 1 second
nh <- newhall_batch(x, unitSystem = 'metric', toString = FALSE)

# sanity check
stopifnot(nrow(nh) == nrow(x))

## normalize names
nh$moistureRegime <- tolower(nh$moistureRegime)
nh$temperatureRegime <- tolower(nh$temperatureRegime)

# adjust names to make provenance clear
nh$smr.newhall <- nh$moistureRegime
nh$str.newhall <- nh$temperatureRegime

nh$moistureRegime <- NULL
nh$temperatureRegime <- NULL

# copy site code
nh$Site <- x$Site

## save
saveRDS(nh, file = 'data/station-prism-newhall-results.rds')


## cleanup
rm(list = ls())
gc(reset = TRUE)


