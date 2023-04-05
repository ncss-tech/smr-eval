library(soilDB)
library(aqp)
library(sf)
library(elevatr)
library(SoilTaxonomy)
library(spData)

library(ragg)
library(terra)


data("us_states")

## TODO:
# update soilDB cached metadata
# check mukey--station association
# associate component with each station
# convert site code -> character

## load metadata from soilDB
m <- SCAN_site_metadata()
head(m)

## upgrade to spatial obj
# save coordinates
m$x <- m$Longitude
m$y <- m$Latitude

# init sf obj
m <- st_as_sf(m, coords = c('x', 'y'), crs = 4326)

# check, ok
plot(st_geometry(m))

## get elevation in meters
# ~ 5 minutes
e <- get_elev_point(m)
m$elev_m <- e$elevation

# check: ok
plot(Elevation_ft ~ elev_m, data = m, las = 1)

## get current classification from SSURGO
# intersecting map unit keys
# ~ 5 minutes
s <- SDA_spatialQuery(m, what = 'mukey', db = 'SSURGO', byFeature = TRUE)

# copy intersecting mukey -> sf obj 
# row-order should be preserved
m$mukey <- s$mukey

# what does it mean to have some mu sampled > 1 time?
# errors, NOTCOM?
head(sort(table(m$mukey), decreasing = TRUE))


# mukey set
.is <- format_SQL_in_statement(s$mukey)

# get subgroup + SMR, will extract SMR from those missing 
.sql <- sprintf(
  "
SELECT
mukey, co.cokey, comppct_r, compname, taxclname, taxsubgrp, taxmoistcl
FROM component AS co
LEFT JOIN cotaxmoistcl AS tx ON co.cokey = tx.cokey 
WHERE mukey IN %s
AND majcompflag = 'Yes'
AND compkind != 'Miscellaneous area'", .is
)

# component data
co <- SDA_query(.sql)

nrow(co)
head(co)

# extract SMR
co$smr.e <- extractSMR(co$taxsubgrp, as.is = TRUE)

# note NA...
table(co$smr.e, useNA = 'always')
table(co$taxmoistcl, useNA = 'always')

# use populated, unless missing
co$smr.ssurgo <- co$taxmoistcl
idx <- which(is.na(co$smr.ssurgo))
co$smr.ssurgo[idx] <- as.character(co$smr.e[idx])

# normalize
co$smr.ssurgo <- tolower(co$smr.ssurgo)

# check
table(co$smr.ssurgo, useNA = 'always')

# save for later
saveRDS(co, file = 'data/component-data.rds')


# select most frequent by map unit
co.split <- split(co, co$mukey)

smr <- lapply(co.split, function(i) {
  
  # short-circuit
  if(all(is.na(i$smr.ssurgo))) {
    return(NULL)
  }
  
  # sum component pct by smr
  .a <- aggregate(comppct_r ~ smr.ssurgo, data = i, FUN = sum, na.rm = TRUE)
  
  # if there are data, then keep the most frequent by component percent
  if(nrow(.a) > 0) {
    .a <- .a[order(.a$comppct_r, decreasing = TRUE), ]
    
    .res <- data.frame(mukey = i$mukey[1], smr.ssurgo = .a$smr.ssurgo[1])
  } else {
    .res <- data.frame(mukey = i$mukey[1], smr.ssurgo = NA)
  }
  
  return(.res)
})

smr <- do.call('rbind', smr)


## re-assemble key site data
m <- merge(m, smr, by = 'mukey')

m$Elevation_ft <- NULL


## quick viz
plot(m['smr.ssurgo'], key.width = lcm(5), pch = 15, cex = 0.85)

plot(st_geometry(us_states))
plot(m['smr.ssurgo'], key.width = lcm(5), add = TRUE, pch = 15)


## get pedon classification / SMR via pedlabsampnum via SDA


.is <- format_SQL_in_statement(na.omit(m$pedlabsampnum))
.sql <- sprintf("
SELECT * FROM lab_combine_nasis_ncss WHERE pedlabsampnum IN %s ;
", .is)

# 209 records
z <- SDA_query(.sql)
nrow(z)

## format / extract SMR and taxonname
# use correlated if available, otherwise sampled

# new columns
z$taxonname.pedon <- z$corr_name
z$taxsubgrp.pedon <- z$corr_taxsubgrp

# taxonname
.idx <- which(is.na(z$taxonname.pedon))
z$taxonname.pedon[.idx] <- z$samp_name[.idx]

# subgroup
.idx <- which(is.na(z$taxsubgrp.pedon))
z$taxsubgrp.pedon[.idx] <- z$samp_taxsubgrp[.idx]

# attempt to extract from subgroup
z$smr.pedon <- extractSMR(z$taxsubgrp.pedon, as.is = TRUE)


# subset
z <- z[, c('pedlabsampnum', 'taxonname.pedon', 'taxsubgrp.pedon', 'smr.pedon')]

# join
m <- merge(m, z, by = 'pedlabsampnum', all.x = TRUE, sort = FALSE)


## save
saveRDS(m, file = 'data/station-data.rds')


## cleanup
rm(list = ls())
gc(reset = TRUE)




