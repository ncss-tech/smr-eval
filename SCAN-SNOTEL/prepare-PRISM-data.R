library(sf)
library(terra)

## PRISM
maat <- rast('e:/gis_data/prism/final_MAAT_800m.tif')
map <- rast('e:/gis_data/prism/final_MAP_mm_800m.tif')

tavg <- rast('e:/gis_data/prism/final_monthly_tavg_800m.tif')
ppt <- rast('e:/gis_data/prism/final_monthly_ppt_800m.tif')

## station data, sf object WGS84
s <- readRDS('data/station-data.rds')


## extractions
s$MAAT <- extract(maat, s, ID = FALSE)[, 1]
s$MAP <- extract(map, s, ID = FALSE)[, 1]

e.tavg <- extract(tavg, s, ID = FALSE)
e.ppt <- extract(ppt, s, ID = FALSE)


## prepare combined data for Newhall
.months <- c('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')
names(e.tavg) <- sprintf("t%s", .months)
names(e.ppt) <- sprintf("p%s", .months)

# combine station data + monthly PRISM
x <- cbind(st_drop_geometry(s), e.tavg, e.ppt)

# check
str(x)
nrow(s)

# filter NA
x <- x[which(!is.na(x$MAAT) & !is.na(x$elev_m) & !is.na(x$Latitude)), ]
nrow(x)
summary(x)


## save
saveRDS(x, file = 'data/station-data-with-PRISM.rds')


## cleanup
rm(list = ls())
gc(reset = TRUE)



