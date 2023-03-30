## Get SMR related info from SSURGO/STATSGO via SDA, by SSA
## If only working with CONUS, then more efficient to use the gNATSGO tables

library(soilDB)
library(SoilTaxonomy)
library(furrr)
library(purrr)

source('local-functions.R')


## TODO:
# * keep track of KST edition


## SSURGO + STATSGO via SDA

# exclude AK for now
# does not include RSS

# 3238 surveys
.ssa <- SDA_query("SELECT DISTINCT areasymbol FROM legend WHERE areasymbol NOT LIKE 'AK%';")
nrow(.ssa)

# simple data getting function
# major components only
# no misc. areas
.getData <- function(i) {
  .sql <- sprintf("
                  SELECT areasymbol AS ssa, co.mukey, co.cokey AS cokey, comppct_r, taxclname, taxsubgrp, taxmoistscl, taxmoistcl 
                  FROM legend INNER JOIN mapunit ON legend.lkey = mapunit.lkey
                  INNER JOIN component AS co ON mapunit.mukey = co.mukey
                  LEFT JOIN cotaxmoistcl AS tx ON co.cokey = tx.cokey 
                  WHERE areasymbol = '%s'
                  AND majcompflag = 'Yes'
                  AND compkind != 'Miscellaneous area'
                  ", i)
  
  x <- suppressMessages(SDA_query(.sql))
  
  if(inherits(x, 'try-error')) {
    # print(i)
    return(NULL)
  }
  
  return(x)
}

plan(multisession)

# ~ 2.4 minutes
system.time(z <- future_map(.ssa$areasymbol, .f = safely(.getData), .progress = TRUE))

plan(sequential)




## check for errors
e <- lapply(z, pluck, 'error')
idx <- which(!is.null(e))

# AK600 may be too big, too many records?
# AL001, why?
.ssa[idx, ]

## results
d <- lapply(z, pluck, 'result')

## NULL results?
# AL001, why?
idx <- which(!is.null(d))
.ssa[idx, ]


# flatten
d <- do.call('rbind', d)

str(d)
head(d, 20)


## extract SMR to unique values
sg <- data.frame(taxsubgrp = unique(na.omit(d$taxsubgrp)))
nrow(sg)

# ~ 15 seconds
system.time(sg$smr <- extractSMR(sg$taxsubgrp))


## merge back into component data
d <- merge(d, sg, by = 'taxsubgrp', all.x = TRUE, sort = FALSE)

# ok
head(d)


## records missing subgroup
missing.subgroup.idx <- which(is.na(d$taxsubgrp) & is.na(d$smr))
length(missing.subgroup.idx)
head(d[missing.subgroup.idx, ])

# attempt estimating SMR from whatever is in taxclname
# ~ 40 seconds
system.time(d$smr[missing.subgroup.idx] <- extractSMR(d$taxclname[missing.subgroup.idx]))



## compare
table(d$taxmoistcl, d$taxmoistscl, useNA = 'always')

table(d$taxmoistcl, d$smr, useNA = 'always')


## develop rules for filling gaps
missing.cl <- which(is.na(d$taxmoistcl))

d[missing.cl[sample(1:length(missing.cl), size = 20)], ]


# try filling missing smr class with formative-element derived values
d$smr.final <- factor(d$taxmoistcl, levels = levels(d$smr), ordered = TRUE)

.idx <- which(is.na(d$smr.final))
d$smr.final[.idx] <- d$smr[.idx]

table(d$taxmoistcl, d$smr.final, useNA = 'always')


## TODO: investigate NA SMR, and possible solutions

knitr::kable(table(d$smr, useNA = 'always'))
knitr::kable(table(d$ssa, useNA = 'always'))


## save full data set for later
saveRDS(d, file = 'data/SSURGO-smr-data.rds')



# TODO: implement with data.table (fast)

# split + map = slow, but nice progress display
# ~ 1 minute
s <- split(d, d$mukey)
a <- map(s, .aggregateSMR, .progress = TRUE)
a <- do.call('rbind', a)

# re-apply factor details
a$smr <- factor(a$smr, levels = levels(d$smr.final), ordered = TRUE)

str(a)
head(a)


## tabulate map units
knitr::kable(table(a$smr, useNA = 'always'))

#   |Var1            |   Freq|
#   |:---------------|------:|
#   |aridic (torric) |  27347|
#   |ustic           |  44930|
#   |xeric           |  33436|
#   |udic            | 121779|
#   |perudic         |     57|
#   |aquic           |  37423|
#   |peraquic        |      0|
#   |NA              |  41822|


## TODO investigate NA, and aggregation function
# NA?
idx <- which(is.na(a$smr))

head(a[idx, ])

s[['52431']]

## save
saveRDS(a, file = 'data/SSURGO-smr-by-mukey.rds')



