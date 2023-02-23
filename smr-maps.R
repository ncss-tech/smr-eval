library(terra)

mu <- rast('e:/gis_data/mukey-grids/gNATSGO-mukey-ML-450m.tif')

# integer grid -> grid + RAT
mu <- as.factor(mu)
names(mu) <- 'mukey'
