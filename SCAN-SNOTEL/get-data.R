library(soilDB)
library(purrr)

source('local-functions.R')


## TODO / ideas:
# * download / retain required data -> SQLite database
# * more robust error checking

# only CONUS for now
m <- readRDS('data/station-data-with-PRISM.rds')
nrow(m)

# get data elements by site 
d <- map(m$Site, .f = .getSCAN, .progress = TRUE)
saveRDS(d, file = 'data/scan-dump.rds')



# iterate over cached data, compute MAAT - MAST offset
o <- map(d, .progress = TRUE, .f = function(i) {
  
  ## TODO: sanity checks / reporting
  
  # test for missing pieces
  if(nrow(i$STO) < 1 || nrow(i$TAVG) < 1) {
    return(NULL)
  }
  
  .res <- .SCAN_TempOffset(s)
  return(.res)
})


o <- do.call('rbind', o)

head(o)

## enforce reasonable values / inspect strange values ~ abs(o) > 6

saveRDS(o, file = 'data/example-SCAN-data.rds')


## TODO: add snowlite stations? 
# # snowlite
# x <- fetchSCAN(site.code = '1218', year = 2020)
