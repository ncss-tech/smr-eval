library(soilDB)

soil50cm <- readRDS(file = 'data/station-monthly-mean-soil50cm-temp.rds')

# develop MAST by station/year
soil50cm$MAST <- apply(soil50cm[, 3:14], 1, mean)

# attempt STR classification
soil50cm$STR <- estimateSTR(
  mast = soil50cm$MAST, 
  mean.summer = soil50cm$Summer, 
  mean.winter = soil50cm$Winter, 
  O.hz = FALSE, 
  saturated = FALSE, 
  permafrost = FALSE
)

# eval
table(soil50cm$STR, useNA = 'always')
table(soil50cm$Site, soil50cm$STR, useNA = 'always')



