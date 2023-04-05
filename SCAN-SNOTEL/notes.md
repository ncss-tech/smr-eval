There are multiple sources of data and comparisons to make when asked "is this SMR reasonable?". In order to fully answer this question, the following details are important.




I've attached an updated and higher-res version of the table / figure. This is a comparison between SMR as populated in SSURGO vs. estimated by the Newhall model, at each of 714 SCAN or SNOTEL stations in CONUS. The Newhall model was parameterized with monthly PRISM data extracted from station locations. Representative plant-available water storage (PAWS) values were derived from SSURGO components at each SCAN/SNOTEL station. A constant MAAT-MAST offset of 2.5 deg. C was used until I have a better, sensor-derived value for each station.


Notes / commentary:
  1.	The Newhall model does not predict "aquic" SMR, hence the 0s in that column.
  2.	Thew Newhall model cannot determine and SMR in some cases, listed as "undefined".
  3.	There are no "perudic" SMR associated with SCAN/SNOTEL station location in SSURGO.
  4.	The best agreement seems to be within "xeric" and "udic" SMR.


Also attached are two rough maps of SMR, as populated in SSURGO and as derived from the Newhall model (PRISM data 1981-2010).



Next steps:

  1.	Lookup SMR as classified at pedons associated with each SCAN/SNOTEL station.
  2.	Run Newhall model using monthly mean air temperature and total precipitation as derived from above ground SCAN/SNOTEL sensor data.
  3.	Derive MAAT-MAST offset for each SCAN/SNOTEL station from sensor data.
  4.	Classify SMR using below-ground sensor data at each SCAN/SNOTEL station.







Data Elements required:
  *	plant available water storage
  *	water retention function for each soil horizon
  *	monthly air temperature (PRISM or sensor)
  *	monthly precipitation (PRISM or sensor)
  *	MAAT (PRISM or sensor)
  *	MAST (PRISM or sensor)
  *	MAAT – MAST
  *	daily volumetric water content (sensor)
  *	daily soil temperature (sensor)

SMR Classification or Authority:
  *	as populated in SSURGO
  *	as classified at SCAN/SNOTEL site (pedon)
  *	Newhall Simulation via PRISM (PRISM data 1981-2010)
  *	Newhall Simulation via aggregate sensor data
  *	direct interpretation of sensor data (above/below ground)

Interesting Comparisons:
  *	SSURGO vs. pedon
  *	SSURGO vs. Newhall
  *	Newhall vs. sensor data
  *	... any combination of the above

Important Considerations:
  *	Newhall cannot identify aquic SMR
  *	Newhall often identifies perudic SMR, though not often used in SSURGO
  *	sensor data are noisy and period of record varies



