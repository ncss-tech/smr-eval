library(soilDB)
library(aqp)

## station data + overlapping mukey/cokey
x <- readRDS('data/component-data.rds')

## component plant available water storage, ignoring restrictive features
.is <- format_SQL_in_statement(x$cokey)
.sql <- sprintf("
-- convert cm to mm
SELECT co.cokey AS cokey, SUM((hzdepb_r - hzdept_r) * awc_r) * 10.0 AS paws_mm
FROM component AS co LEFT JOIN chorizon AS ch ON co.cokey = ch.cokey
WHERE co.cokey IN %s
GROUP BY co.cokey ;
", .is)

a <- SDA_query(.sql)
nrow(a)
head(a)


## merge / compute wt. mean by mukey
a <- merge(x[, c('mukey', 'cokey', 'comppct_r')], a, by = 'cokey', all.x = TRUE, sort = FALSE)
head(a, 20)

s <- split(a, a$mukey)
paws <- lapply(s, function(i) {
  # filter bad data
  i <- i[which(!is.na(i$comppct_r) & !is.na(i$paws_mm)), ]
  
  # short circuit if no rows remain
  if(nrow(i) < 1) {
    return(NULL)
  }
  
  # wt. mean
  .paws <- weighted.mean(i$paws_mm, w = i$comppct_r, na.rm = TRUE)
  
  .res <- data.frame(mukey = i$mukey[1], paws_mm = .paws)
  return(.res)
  
})

paws <- do.call('rbind', paws)
row.names(paws) <- NULL
nrow(paws)
head(paws)
summary(paws)


## save
saveRDS(paws, file = 'data/SSURGO-paws.rds')


### TODO: prepare PAWS from any available pedon / lab data


## cleanup
rm(list = ls())
gc(reset = TRUE)






