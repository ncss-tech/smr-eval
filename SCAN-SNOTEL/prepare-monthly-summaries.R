library(soilDB)
library(reshape2)
library(purrr)
library(lattice)
library(tactile)

source('local-functions.R')


## TODO: can we use / abuse soilDB::summarizeSoilTemperature()


## load data dump
d <- readRDS('data/scan-dump.rds')

## temperature

# iterate over cached data, compute above / below ground summaries by month and season
m <- map(d, .progress = TRUE, .f = .SCAN_MonthlyTempSummary)

air <- do.call('rbind', map(m, pluck, 'air'))
soil50cm <- do.call('rbind', map(m, pluck, 'soil50cm'))

## precipitation
# source data are inches
# results are in mm
p <- map(d, .progress = TRUE, .f = .SCAN_monthlyPPT)
p <- do.call('rbind', p)


# check
head(air)
head(soil50cm)
head(p)

## save
saveRDS(air, file = 'data/station-monthly-mean-air-temp.rds')
saveRDS(soil50cm, file = 'data/station-monthly-mean-soil50cm-temp.rds')
saveRDS(p, file = 'data/station-monthly-total-ppt.rds')


