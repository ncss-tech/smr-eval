library(corrplot)
library(viridisLite)
library(aqp)
library(e1071)
library(cluster)
library(ragg)
library(venn)
library(sf)

# Newhall doesn't use aquic, and has "undefined"
.smr.levels <- c('aridic', 'ustic', 'xeric', 'udic', 'perudic', 'aquic', 'undefined')

## prepared source data
x <- readRDS('data/station-data.rds')
x <- st_drop_geometry(x)

# nh.prism <- readRDS('data/station-prism-newhall-results.rds')

# sensor data, one record per site/year
nh.sensor <- readRDS('data/station-sensor-newhall-results.rds')

# proper tabulation via factors
nh.sensor$smr.newhall <- factor(nh.sensor$smr.newhall, levels = .smr.levels, ordered = TRUE)

# aggregate over years
s <- split(nh.sensor, nh.sensor$Site)
nh.sensor.agg <- lapply(s, function(i) {
  # proportions over years
  .tab <- prop.table(table(i$smr.newhall))
  
  # most frequent
  .smr <- names(sort(.tab, decreasing = TRUE))[1]
  
  # shanon entropy base 2
  .H <- shannonEntropy(.tab, b = 2)
  
  # compile results
  .res <- data.frame(
    Site = i$Site[1],
    smr.newhall = .smr,
    H = .H
  )
  
  return(.res)
  
})

# flatten
nh.sensor.agg <- do.call('rbind', nh.sensor.agg)
row.names(nh.sensor.agg) <- NULL

# combine
x <- merge(x, nh.sensor.agg, by = 'Site', all.x = TRUE, sort = FALSE)


## normalize names

# convert aridic (torric) -> aridic
# ssurgo
x$smr.ssurgo <- gsub(' (torric)', replacement = '', x = x$smr.ssurgo, fixed = TRUE)

# pedon
x$smr.pedon <- gsub(' (torric)', replacement = '', x = x$smr.pedon, fixed = TRUE)


## convert -> factors
x$smr.ssurgo <- factor(x$smr.ssurgo, levels = .smr.levels, ordered = TRUE)
x$smr.pedon <- factor(x$smr.pedon, levels = .smr.levels, ordered = TRUE)
x$smr.newhall <- factor(x$smr.newhall, levels = .smr.levels, ordered = TRUE)


## check for NA: none
table(ssurgo = x$smr.ssurgo, newhall = x$smr.newhall, useNA = 'always')

# there are many NA... > 1/2 stations not linked
table(ssurgo = x$smr.ssurgo, pedons = x$smr.pedon, useNA = 'always')

# there are many NA... not enough PPT data
table(ssurgo = x$smr.ssurgo, newhall = x$smr.newhall, useNA = 'always')



# for Dave
addmargins(table(ssurgo = x$smr.ssurgo, newhall.sensors = x$smr.newhall))
addmargins(table(ssurgo = x$smr.ssurgo, pedons = x$smr.pedon))


# cross-tabulate
tab <- xtabs(~ smr.ssurgo + smr.newhall, data = x)



ptab <- prop.table(tab, margin = 2)
ptab <- as.matrix(ptab)
ptab[is.na(ptab)] <- 0

.cols <- c('white', viridis(100))

agg_png(filename = 'figures/SMR-SSURGO-Newhall-sensors.png', width = 1000, height = 1000, scaling = 1.5)

corrplot(
  ptab, 
  is.corr = FALSE, 
  method = 'shade',
  order = 'original',
  col = .cols,
  addgrid.col = 'black',
  mar = c(2, 2, 2.5, 0),
  cl.cex = 1,
  addCoef.col = 'red',
  tl.col = 'black'
)

mtext('SSURGO', side = 2, font = 2, cex = 1.5, line = 2)
mtext('Newhall Simulation / Station Sensor Data', side = 3, font = 2, cex = 1.5, line = 2)
mtext(sprintf("%s SCAN/SNOTEL Stations", nrow(x[!is.na(x$smr.newhall), ])), side = 1, font = 1, cex = 1, line = 3)

dev.off()



## evaluation


classAgreement(tab)

.f <- data.frame(smr = factor(.smr.levels, levels = .smr.levels, ordered = TRUE))
row.names(.f) <- .f$smr
.w <- daisy(.f)
.w <- as.matrix(.w)
.w <- 1 - .w


tauW(tab, W = .w)

# how does this work with 0s in the prior?
tauW(tab, W = .w, P = prop.table(table(x$smr.ssurgo)))







