
## Notes:
# SCAN / SNOTEL temperature values are reported as deg. C
# SCAN / SNOTEL precip. and snow data are reported as inches
#
# can we use / abuse soilDB::summarizeSoilTemperature()
#


## 
source('dump-SCAN_SNOTEL.R')


## 
source('prepare-station-data.R')

##
source('prepare-AWC-data.R')

##
source('prepare-PRISM-data.R')

##
source('run-Newhall-PRISM.R')


##
source('SMR-eval-Newhall-PRISM.R')



##
source('estimate-temp-offset.R')
source('prepare-monthly-summaries.R')