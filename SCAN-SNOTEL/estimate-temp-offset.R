library(soilDB)
library(purrr)
library(lattice)
library(tactile)

source('local-functions.R')


## TODO / ideas:
# * download / retain required data -> SQLite database
# * more robust error checking

## load data dump
d <- readRDS('data/scan-dump.rds')


# iterate over cached data, compute MAAT, MAST, and standard offset
o <- map(d, .progress = TRUE, .f = function(i) {
  
  ## TODO: sanity checks / reporting
  
  # test for missing pieces
  if(nrow(i$STO) < 1 || nrow(i$TAVG) < 1) {
    return(NULL)
  }
  
  .res <- .SCAN_TempSummary(i)
  return(.res)
})


o <- do.call('rbind', o)
o <- na.omit(o)

head(o)
quantile(o$offset, na.rm = TRUE)

o.sub <- o[abs(o$offset) < 5.5, ]

ragg::agg_png(filename = 'figures/maat-mast-offset-conus-hist.png', width = 800, height = 400, scaling = 1.25)

histogram(o.sub$offset, breaks = 50, par.settings = tactile.theme(), xlab = 'MAAT - MAST Offset (deg. C)', scales = list(tick.number = 10), main = 'SCAN/SNOTEL Stations (CONUS)', sub = sprintf("%s Stations", nrow(o.sub)))

dev.off()


ragg::agg_png(filename = 'figures/mast-conus-hist.png', width = 800, height = 400, scaling = 1.25)

histogram(o.sub$MAST, breaks = 50, par.settings = tactile.theme(), xlab = 'Mean Annual Soil Temperature (deg. C) at 50cm,', scales = list(tick.number = 10), main = 'SCAN/SNOTEL Stations (CONUS)', sub = sprintf("%s Stations", nrow(o.sub)))

dev.off()



## enforce reasonable values / inspect strange values ~ abs(o) > 6

# odd values
o[abs(o$offset) >= 5.5, ]

## keep only reasonable values for now
saveRDS(o.sub, file = 'data/MAAT-MAST-offset.rds')

