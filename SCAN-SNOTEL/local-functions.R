
# really dumb function to get data, a station at a time, by Site code
# keeping only:
# soil moisture + soil temperature
# mean air temperature
# instantaneous and cumulative PPT
.getSCAN <- function(i) {
  
  suppressMessages(s <- fetchSCAN(site.code = i, year = 2010:2023))
  
  # subset
  .res <- list(SMS = s$SMS, STO = s$STO, TAVG = s$TAVG, PRCP = s$PRCP, PREC = s$PREC)
  return(.res)
}



## TODO: deal with multiple sensors
## TODO: adapt to use PREC (cumulative) data when PRCP not available
## TODO: maybe include annual aggregate

# use PRCP data, native units are inches
# x: single list of SCAN data
.SCAN_monthlyPPT <- function(x, thresh = 350) {
  
  
  ## TODO: select data source when PRCP is NULL
  #  --> this will depend on water year? or whenever the cumulative values are reset?
  # for now, give up
  if(nrow(x$PRCP) < 1) {
    return(NULL)
  }
  
  # select data source
  x <- x$PRCP
  
  # keep only required fields
  x <- x[, c('Site', 'Date', 'value')]
  
  # short-circuit for 0 remaining records
  if(nrow(x) < 1) {
    return(NULL)
  }
  
  # convert inches -> mm
  x$value <- x$value * 25.4
  
  # prepare required fields
  x$year <- format(x$Date, "%Y")
  x$month <- format(x$Date, "%b")
  
  # encode months as factor, classify season for ST
  .months <- c('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')
  x$month <- factor(x$month, levels = .months)
  x$season <- soilDB::month2season(x$month)
  
  # compute summaries, some may be NA
  # non-NA records / year
  .n <- aggregate(value ~ Site + year, data = x, FUN = function(.x) {length(na.omit(.x))})
  names(.n)[3] <- 'n'
  
  # monthly total
  .monthly <- aggregate(value ~ Site + year + month, data = x, FUN = sum, na.rm = TRUE)
  
  # seasonal total
  .seasonal <- aggregate(value ~ Site + year + season, data = x, FUN = sum, na.rm = TRUE)
  
  # reshape: long -> wide
  .monthly <- reshape2::dcast(.monthly, Site + year ~ month, value.var = 'value')
  .seasonal <-reshape2::dcast(.seasonal, Site + year ~ season, value.var = 'value')
  
  # re-name for Newhall and clarity
  names(.monthly)[-c(1:2)] <- sprintf("p%s", names(.monthly)[-c(1:2)])
  names(.seasonal)[-c(1:2)] <- sprintf("p%s", names(.seasonal)[-c(1:2)])
  
  # combine
  .g <- merge(.monthly, .seasonal, by = c('Site', 'year'), all.x = TRUE, sort = FALSE)
  .g <- merge(.g, .n, by = c('Site', 'year'), all.x = TRUE, sort = FALSE)
  
  
  # keep only years with n days > thresh
  .g <- .g[which(.g$n > thresh), ]
  
  return(.g)
}


## TODO: deal with multiple sensors

# use air temp (TAVG) or soil temp (STO) at 51cm
.SCAN_monthlyTemp <- function(x, thresh = 350) {
  
  # keep only required fields
  x <- x[, c('Site', 'Date', 'value')]
  
  # short-circuit for 0 remaining records
  if(nrow(x) < 1) {
    return(NULL)
  }
  
  # prepare required fields
  x$year <- format(x$Date, "%Y")
  x$month <- format(x$Date, "%b")
  
  # encode months as factor, classify season for ST
  .months <- c('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')
  x$month <- factor(x$month, levels = .months)
  x$season <- soilDB::month2season(x$month)
  
  # compute summaries, some may be NA
  # non-NA records / year
  .n <- aggregate(value ~ Site + year, data = x, FUN = function(.x) {length(na.omit(.x))})
  names(.n)[3] <- 'n'
  
  # monthly mean
  .monthly <- aggregate(value ~ Site + year + month, data = x, FUN = mean, na.rm = TRUE)
  
  # seasonal mean
  .seasonal <- aggregate(value ~ Site + year + season, data = x, FUN = mean, na.rm = TRUE)
  
  # reshape: long -> wide
  .monthly <- reshape2::dcast(.monthly, Site + year ~ month, value.var = 'value')
  .seasonal <-reshape2::dcast(.seasonal, Site + year ~ season, value.var = 'value')
  
  # re-name for Newhall and clarity
  names(.monthly)[-c(1:2)] <- sprintf("t%s", names(.monthly)[-c(1:2)])
  names(.seasonal)[-c(1:2)] <- sprintf("t%s", names(.seasonal)[-c(1:2)])
  
  .g <- merge(.monthly, .seasonal, by = c('Site', 'year'), all.x = TRUE, sort = FALSE)
  .g <- merge(.g, .n, by = c('Site', 'year'), all.x = TRUE, sort = FALSE)
  
  
  # keep only years with n days > thresh
  .g <- .g[which(.g$n > thresh), ]
  
  return(.g)
}



## TODO: deal with multiple sensors
## TODO: convert to aggregate

# use for air and soil temperature at 50cm
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



.SCAN_TempSummary <- function(x) {
  
  # short-circuit for missing STO at 51cm
  .sto50cm <- na.omit(x$STO[x$STO$depth == 51, ])
  if(nrow(.sto50cm) < 1) {
    return(NULL)
  }
  
  if(nrow(x$TAVG) < 1) {
    return(NULL)
  }
  
  # MAAT
  .maat <- .SCAN_meanTemp(x$TAVG, nm = 'MAAT')
  
  # MAST at 50cm depth
  .mast <- .SCAN_meanTemp(.sto50cm, nm = 'MAST')
  
  # combine
  .g <- merge(.maat, .mast, by = c('Site', 'year'), all.x = TRUE, sort = FALSE)
  
  # remove any years with missing data, caused by join
  .g <- na.omit(.g)
  
  # compile results, summarize with mean
  .res <- data.frame(
    Site = .maat$Site[1],
    MAAT = mean(.maat$MAAT, na.rm = TRUE),
    MAST = mean(.mast$MAST, na.rm = TRUE),
    offset = mean(.g$MAST - .g$MAAT, na.rm = TRUE),
    nyr = nrow(.g)
  )
  
  return(.res)
}



.SCAN_MonthlyTempSummary <- function(x) {
  
  # short-circuit for missing STO at 51cm
  .sto50cm <- na.omit(x$STO[x$STO$depth == 51, ])
  if(nrow(.sto50cm) < 1) {
    return(NULL)
  }
  
  if(nrow(x$TAVG) < 1) {
    return(NULL)
  }
  
  # air temperature
  .above <- .SCAN_monthlyTemp(x$TAVG)
  # soil temperature at 50cm
  .below <- .SCAN_monthlyTemp(.sto50cm)
  
  .res <- list(
    air = .above,
    soil50cm = .below
  )
  
  return(.res)
}


