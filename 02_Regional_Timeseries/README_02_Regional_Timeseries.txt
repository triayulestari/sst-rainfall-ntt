STEP 02 - REGIONAL TIME SERIES AND DESEASONALIZED ANOMALIES
==========================================================

PURPOSE
-------
Construct monthly regional-mean marine SST and land rainfall time series
for the three predefined study regions (Flores, Sumba and Timor) during
January 2016-December 2025. Calculate study-period monthly means,
overall-mean anomalies, deseasonalized anomalies, and linearly detrended
anomalies. Output MATLAB MAT and human-readable CSV files for later stages.

REQUIRED SOFTWARE
-----------------
MATLAB R2021a. Source NetCDF files are generated locally in Step 01.

DIRECTORY AND INPUTS
--------------------
Data/
  01_SST_Rainfall_NTT_2016_2025/
    01_Crop_SST_NTT/sst_YYYYMM.nc            [LOCAL, NOT ON GITHUB]
    02_Crop_CHIRPS_NTT/prec_YYYY.NTT.nc      [LOCAL, NOT ON GITHUB]
  02_Regional_Timeseries/
    README_02_Regional_Timeseries.txt
    a_extract_regional_timeseries.m
    b_compute_regional_anomalies.m
    regional_timeseries_raw.mat
    regional_timeseries_raw.csv
    regional_grid_check.csv
    regional_domain_grid_metadata.csv
    regional_data_availability.csv
    regional_anomalies.mat
    regional_anomalies.csv
    regional_calendar_month_means.csv
    regional_detrending_summary.csv

RUN IN THIS ORDER
-----------------
1. Run a_extract_regional_timeseries.m.
   Reads Step 01 cropped SST and CHIRPS NetCDFs.
   Outputs: regional_timeseries_raw.mat, regional_timeseries_raw.csv,
   regional_grid_check.csv, regional_domain_grid_metadata.csv, and
   regional_data_availability.csv.
2. Run b_compute_regional_anomalies.m.
   Reads regional_timeseries_raw.mat in this same folder.
   Outputs: regional_anomalies.mat, regional_anomalies.csv,
   regional_calendar_month_means.csv, regional_detrending_summary.csv.

The scripts locate their inputs relative to their own saved .m file
locations. Keep the directory and exact filenames unchanged.

GEOGRAPHIC STUDY REGIONS
------------------------
Region   Marine SST longitude/latitude       CHIRPS longitude/latitude
Flores   119.0-123.5 E; 9.2-7.9 S            118.975-123.525 E; 9.225-7.875 S
Sumba    118.8-121.2 E; 10.5-9.2 S           118.775-121.225 E; 10.525-9.175 S
Timor    123.3-126.0 E; 10.6-8.6 S           123.275-126.025 E; 10.625-8.575 S

The rectangular study regions are geographical selections, not
administrative masks. The Timor CHIRPS box includes some Timor-Leste land.

REGIONAL MEAN AND VALID DATA
----------------------------
- SST is averaged from available finite ocean-grid values in each box;
  CHIRPS rainfall is averaged from available finite land-grid values.
- The code checks availability using isfinite (thereby excluding NaN and
  other nonfinite values). No extra coastline/polygon mask is applied.
- Arithmetic averages are unweighted. No interpolation or area weighting.
- SST units are degrees Celsius; monthly rainfall totals are in mm.

TERMINOLOGY
-----------
- Raw time series: original monthly regional values.
- Study-period mean SST/rainfall: mean of available monthly values over
  the study period (2016-2025).
- Study-period monthly means: twelve means, one for each calendar month,
  calculated over the available observations in 2016-2025.
- Overall-mean anomaly: each monthly value minus the overall study-period mean.
- Deseasonalized anomaly: each monthly value minus the corresponding
  study-period calendar-month mean (January vs January, etc.).
- Deseasonalized and detrended anomaly: the deseasonalized anomaly after
  removal of a fitted linear trend using the original calendar positions.
These 10-year means remove the study-period mean annual cycle; they are
not a 30-year climatological normal and do not remove all ENSO/IOD effects.

DATA AVAILABILITY AND REPRODUCIBILITY
------------------------------------
- Time axis: 120 consecutive calendar-month positions.
- SST: 118 observed months; October and November 2025 remain NaN.
- CHIRPS rainfall: 120 observed months. No missing months are filled.
- SST October/November study-period means use 9 years each; other SST
  calendar-month means and all rainfall means use 10 years each.
- Upload BOTH regional_timeseries_raw.mat and regional_anomalies.mat.
  The first is directly loaded by script b; the second supplies required
  variable arrays to Steps 03-07 and the Figure 2 plotting script.
- Corresponding CSVs make the numerical values accessible without MATLAB.
- Figure_2_Plot_Data.mat is a separate OUTPUT of Figure 2, not a substitute
  for regional_anomalies.mat used as its INPUT.
- Reconstructing the original time series from raw provider data requires
  the Step 01 NetCDF files, which are not redistributed on GitHub.
