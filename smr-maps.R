library(terra)
library(RColorBrewer)

# rough approximation of SMR
smr <- readRDS('data/SSURGO-smr-by-mukey.rds')

# approximated gNATSGO mukey grid
mu <- rast('e:/gis_data/mukey-grids/gNATSGO-mukey-ML-450m.tif')

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
plot(mu, mar = c(1, 1, 1, 7), axes = FALSE, col = c('red', 'orange', 'blue', 'purple', 'green'))
