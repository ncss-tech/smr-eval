library(terra)
library(RColorBrewer)
library(ragg)
library(spData)

data("us_states")
us_states <- vect(us_states)
us_states <- project(us_states, 'EPSG:5070')


# SMR by mukey, SSURGO, STATSGO -- not AK
smr <- readRDS('data/SSURGO-smr-by-mukey.rds')

## STATSGO
mu <- rast('e:/gis_data/mukey-grids/gSTATSGO-mukey.tif')

# integer grid -> grid + RAT
mu <- as.factor(mu)

# extract rat
rat <- cats(mu)[[1]]
str(rat)

# merge RAT + SMR
rat <- merge(rat, smr, by.x = 'label', by.y = 'mukey', all.x = TRUE, sort = FALSE)


# re-pack RAT
levels(mu) <- rat

# select attribute for plotting
activeCat(mu) <- 'smr'

# why are factors in the wrong order?

agg_png('figures/STASTGO-SMR.png', width = 1200, height = 850, scaling = 0.75, res = 200)

plot(mu, mar = c(1, 1, 1, 7), axes = FALSE, col = c('red', 'orange', 'blue', 'purple', 'green'), main = 'Soil Moisture Regime\nSTASTGO')

lines(us_states)

dev.off()


## ahah... STATSGO is missing A LOT of SMR records
##         possibly due to lack of major components

## why doesn't this work as expected? NaNs ?

## save -> geotiff
# ~ 6.5 minutes
system.time(statsgo.smr <- catalyze(mu))

# writeRaster(statsgo.smr[['smr']], filename = 'results/STATSGO-SMR.tif', overwrite = TRUE)



## gNATSGO grid

# approximated gNATSGO mukey grid
mu <- rast('e:/gis_data/mukey-grids/gNATSGO-mukey-ML-300m.tif')

# integer grid -> grid + RAT
mu <- as.factor(mu)

# extract rat
rat <- cats(mu)[[1]]
str(rat)

# merge RAT + SMR
rat <- merge(rat, smr, by.x = 'label', by.y = 'mukey', all.x = TRUE, sort = FALSE)

# re-pack RAT
levels(mu) <- rat

# select attribute for plotting
activeCat(mu) <- 'smr'

# ugly colors

agg_png('figures/SSURGO-SMR.png', width = 1200, height = 850, scaling = 0.75, res = 200)

plot(mu, mar = c(1, 1, 1, 7), axes = FALSE, col = c('red', 'orange', 'blue', 'purple', 'green'), main = 'Soil Moisture Regime\nFY23 SSURGO')

lines(us_states)

dev.off()


## save -> geotiff
# ~ 
system.time(ssurgo.smr <- catalyze(mu)[['smr']])
# writeRaster(ssurgo.smr)

