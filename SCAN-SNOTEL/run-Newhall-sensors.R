library(jNSMR)
library(sf)

## station data
x <- readRDS('data/station-data.rds')
x <- st_drop_geometry(x)

## PAWS data
# SSURGO0-derived
paws <- readRDS('data/SSURGO-paws.rds')

## MAAT - MAST offsets, computed from sensor data when possible
# bad data pre-filtered
o <- readRDS('data/MAAT-MAST-offset.rds')

## monthly air temperature and ppt, computed from sensor data when possible
# bad data pre-filtered
tavg <- readRDS('data/station-monthly-mean-air-temp.rds')
ppt <- readRDS('data/station-monthly-total-ppt.rds')



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

## setup station-specific MAAT -- MAST offset
x <- merge(x, o, by = 'Site', all.x = TRUE, sort = FALSE)
x$maatmast <- x$offset
# back-fill with estimate
x$maatmast[is.na(x$maatmast)] <- 2.5

## merge monthly sensor data
## this will increase nrow(x) by number of years / station

# monthly mean air temperature
.vars <- c("Site", "year", "tJan", "tFeb", "tMar", "tApr", "tMay", "tJun", "tJul", "tAug", "tSep", "tOct", "tNov", "tDec")
x <- merge(x, tavg[, .vars], by = 'Site', all.x = TRUE, sort = FALSE)

# monthly total ppt
.vars <- c("Site", "year", "pJan", "pFeb", "pMar", "pApr", "pMay", "pJun", "pJul", "pAug", "pSep", "pOct", "pNov", "pDec")
x <- merge(x, ppt[, .vars], by = c('Site', 'year'), all.x = TRUE, sort = FALSE)

## filter missing data
.idx <- which(!is.na(x$awc) & !is.na(x$maatmast) & !is.na(x$pJan) & !is.na(x$tJan))
x <- x[.idx, ]

# only 176 stations...
nrow(x)
length(unique(x$Site))


# ~1 second
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

# copy year
nh$year <- x$year

## save
saveRDS(nh, file = 'data/station-sensor-newhall-results.rds')


## cleanup
rm(list = ls())
gc(reset = TRUE)



