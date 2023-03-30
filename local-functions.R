

# single value per mukey
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

