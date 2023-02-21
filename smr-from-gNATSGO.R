##
##
##

library(sf)
library(SoilTaxonomy)


## gNATSGO

# using local copies, re-packaged into gzipped CSV
# careful with NA handling

# 1136011 rows
g <- read.csv('E:/gis_data/mukey-grids/component.csv.gz', stringsAsFactors = FALSE, na.strings = '')
nrow(g)


