library(soilDB)
library(SoilTaxonomy)
library(furrr)
library(purrr)

## TODO: alternative approach via gNATSGO tables


## SSURGO + STATSGO via SDA

.ssa <- SDA_query("SELECT DISTINCT areasymbol FROM legend;")
nrow(.ssa)

## TODO: trap errors / bad requests

.getData <- function(i) {
  .sql <- sprintf("
                  SELECT areasymbol AS ssa, co.mukey, co.cokey AS cokey, taxclname, taxsubgrp, taxmoistscl, taxmoistcl 
                  FROM legend INNER JOIN mapunit ON legend.lkey = mapunit.lkey
                  INNER JOIN component AS co ON mapunit.mukey = co.mukey
                  LEFT JOIN cotaxmoistcl AS tx ON co.cokey = tx.cokey 
                  WHERE areasymbol = '%s'
                  ", i)
  
  x <- suppressMessages(SDA_query(.sql))
  
  return(x)
}

plan(multisession)

z <- future_map(.ssa$areasymbol, .f = safely(.getData), .progress = TRUE)

plan(sequential)

z <- do.call('rbind', z)

str(z)
head(z, 20)


## extract SMR to unique values
d <- data.frame(taxsubgrp = unique(na.omit(z$taxsubgrp)))
nrow(d)

# ~ 18 seconds
system.time(d$smr <- extractSMR(d$taxsubgrp))


## merge back into component data
z <- merge(z, d, by = 'taxsubgrp', all.x = TRUE, sort = FALSE)


head(z)



## TODO
## RSS via geodatabases


