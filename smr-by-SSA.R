## Get SMR related info from SSURGO via SDA, by SSA
## If only working with CONUS, then more efficient to use the gNATSGO tables

library(soilDB)
library(SoilTaxonomy)
library(furrr)
library(purrr)

## TODO:
# * keep track of KST edition


## SSURGO SDA

# exclude STATSGO for now
# exclude AK for now
# does not include RSS

.ssa <- SDA_query("SELECT DISTINCT areasymbol FROM legend WHERE areasymbol != 'US' AND areasymbol NOT LIKE 'AK%';")
nrow(.ssa)

# simple data getting function
.getData <- function(i) {
  .sql <- sprintf("
                  SELECT areasymbol AS ssa, co.mukey, co.cokey AS cokey, comppct_r, taxclname, taxsubgrp, taxmoistscl, taxmoistcl 
                  FROM legend INNER JOIN mapunit ON legend.lkey = mapunit.lkey
                  INNER JOIN component AS co ON mapunit.mukey = co.mukey
                  LEFT JOIN cotaxmoistcl AS tx ON co.cokey = tx.cokey 
                  WHERE areasymbol = '%s'
                  ", i)
  
  x <- suppressMessages(SDA_query(.sql))
  
  if(inherits(x, 'try-error')) {
    print(i)
    return(NULL)
  }
  
  return(x)
}

plan(multisession)

z <- future_map(.ssa$areasymbol, .f = safely(.getData), .progress = TRUE)

plan(sequential)




## check for errors
e <- lapply(z, pluck, 'error')
idx <- which(!is.null(e))

# AK600 may be too big, too many records?
.ssa[idx, ]

## results
d <- lapply(z, pluck, 'result')

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

# save full data set for later
saveRDS(d, file = 'data/SSURGO-smr-data.rds')

## single value per mukey

.aggregateSMR <- function(i) {
  
  # tabulate SMR
  # implicit factor -> character conversion
  .a <- tapply(i$comppct_r, i$smr.final, FUN = sum, na.rm = TRUE)
  
  # select the most frequent by component pct
  .a <- sort(.a, decreasing = TRUE)
  .smr <- names(.a)[1]
  
  # TODO
  # test for NA, and use 2nd place
  
  .res <- data.frame(mukey = i$mukey[1], smr = .smr)
  return(.res)
}

# TODO: implement with data.table (fast)

# split + map = slow, but nice progress display
s <- split(d, d$mukey)
a <- map(s, .aggregateSMR, .progress = TRUE)
a <- do.call('rbind', a)

# re-apply factor details
a$smr <- factor(a$smr, levels = levels(d$smr.final), ordered = TRUE)

str(a)
head(a)

table(a$smr, useNA = 'always')

## save
saveRDS(a, file = 'data/SSURGO-smr-by-mukey.rds')



