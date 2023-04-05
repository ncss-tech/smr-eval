

.getSCAN <- function(i) {
  
  suppressMessages(s <- fetchSCAN(site.code = i, year = 2010:2023))
  
  .res <- list(SMS = s$SMS, STO = s$STO, TAVG = s$TAVG, PRCP = s$PRCP, PREC = s$PREC)
  return(.res)
}


## TODO: deal with multiple sensors
.SCAN_meanTemp <- function(x, nm, thresh = 350) {
  
  # keep only required fields
  x <- x[, c('Site', 'Date', 'value')]
  
  # short-circuit for 0 remaining records
  if(nrow(x) < 1) {
    return(NULL)
  }
  
  # prepare required fields
  x$year <- format(x$Date, "%Y")
  x$month <- format(x$Date, "%b")
  
  # iterate over years
  xs <- split(x, x$year)
  
  xs <- lapply(xs, function(i) {
    
    # summary stats, only over non-NA values
    i <- i[which(!is.na(i$value)), ]
    
    # short-circuit for 0 remaining records
    if(nrow(i) < 1) {
      return(NULL)
    }
    
    # compute summaries
    .res <- data.frame(
      Site = i$Site[1],
      year = i$year[1],
      n = length(i$value),
      m = mean(i$value)
    )
    
    return(.res)
  })
  
  xs <- do.call('rbind', xs)
  
  # keep only years with n days > thresh
  xs <- xs[xs$n > thresh, ]
  
  # adjust summary name
  names(xs)[4] <- nm
  
  return(xs)
}



.SCAN_TempOffset <- function(x) {
  
  # MAAT
  .maat <- .SCAN_meanTemp(x$TAVG, nm = 'MAAT')
  
  # MAST at 50cm depth
  .mast <- .SCAN_meanTemp(x$STO[x$STO$depth == 51, ], nm = 'MAST')
  
  # combine
  .g <- merge(.maat, .mast, by = c('Site', 'year'), all.x = TRUE, sort = FALSE)
  
  # remove any years with missing data, caused by join
  .g <- na.omit(.g)
  
  # compile results, summarize with mean
  .res <- data.frame(
    Site = .maat$Site[1],
    offset = mean(.g$MAST - .g$MAAT, na.rm = TRUE),
    nyr = nrow(.g)
  )
  
  return(.res)
}

