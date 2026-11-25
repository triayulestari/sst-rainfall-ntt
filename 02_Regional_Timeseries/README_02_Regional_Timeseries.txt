STEP 02 - REGIONAL SST AND RAINFALL TIME SERIES (2016-2025)
==========================================================

1. PURPOSE AND SCOPE
--------------------
This step extracts monthly regional-mean sea surface temperature (SST) and
precipitation from the cropped Himawari and CHIRPS NetCDF products produced
in Step 01. The study uses three predefined geographic regions: Flores,
Sumba, and Timor. The period is January 2016 through December 2025.

Two MATLAB scripts generate (a) raw regional time series and grid/availability
metadata, and (b) calendar-month means, overall-mean anomalies, deseasonalized
anomalies, and linearly detrended deseasonalized anomalies.

The geographic selections are rectangular analysis domains, not island
polygons or administrative boundaries. This step performs neither statistical
significance testing nor independent validation against in situ observations.

2. SOFTWARE AND INPUT DATA
--------------------------
Software: MATLAB R2021a (version used for these scripts).

Required local inputs from Step 01:
- Himawari SST: 01_Crop_SST_NTT/sst_YYYYMM.nc
  One NetCDF file per available month; variable 'sst', in degrees Celsius.
- CHIRPS v3.0 rainfall: 02_Crop_CHIRPS_NTT/prec_YYYY.NTT.nc
  One NetCDF file per year, with 12 monthly time slices;
  variable 'prec', in millimeters per calendar month (mm/month).

The cropped NetCDF files and original provider data are not distributed in
this GitHub repository. See the Step 01 README for source products, processing,
and data access information.

3. REQUIRED DIRECTORY RELATIONSHIP
----------------------------------
The MATLAB scripts construct input paths relative to their own locations.
The following sibling-folder relationship must be preserved, regardless of
the name of the parent directory:

<parent-directory>/
  01_SST_Rainfall_NTT_2016_2025/
    01_Crop_SST_NTT/
      sst_YYYYMM.nc                    [local input; not uploaded]
    02_Crop_CHIRPS_NTT/
      prec_YYYY.NTT.nc                 [local input; not uploaded]
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

The two .m files are designed to run from any MATLAB current folder, provided
that they have been saved to the specified sibling-folder layout. Do not
rename the input NetCDF files or the MAT files required by later steps.

4. EXECUTION ORDER
------------------
1. Run a_extract_regional_timeseries.m.
   Inputs: cropped SST and CHIRPS NetCDFs from Step 01.
   Outputs: regional_timeseries_raw.mat, regional_timeseries_raw.csv,
            regional_grid_check.csv, regional_domain_grid_metadata.csv,
            regional_data_availability.csv.

2. Inspect the output coverage and availability records.

3. Run b_compute_regional_anomalies.m.
   Input: regional_timeseries_raw.mat in this folder.
   Outputs: regional_anomalies.mat, regional_anomalies.csv,
            regional_calendar_month_means.csv,
            regional_detrending_summary.csv.

Both scripts write their outputs beside their own saved .m files. The
second script uses the first script's MAT file as its direct input; the CSV
alone is not a replacement for that MAT file.

5. GEOGRAPHIC DOMAINS
---------------------
All longitudes are degrees east. Latitudes are signed degrees north;
negative values indicate degrees south. Bounds below are requested
selection limits (lon_min, lon_max, lat_min, lat_max).

Region   Himawari SST box                    CHIRPS rainfall box
Flores   (119.0, 123.5, -9.2, -7.9)          (118.975, 123.525, -9.225, -7.875)
Sumba    (118.8, 121.2, -10.5, -9.2)         (118.775, 121.225, -10.525, -9.175)
Timor    (123.3, 126.0, -10.6, -8.6)         (123.275, 126.025, -10.625, -8.575)

The CHIRPS bounds include half-grid margins (0.025 degrees) around the
corresponding nominal rectangular boundaries. The actual selected grid
extents and numbers of grid cells are recorded in
regional_domain_grid_metadata.csv. Coordinates in that file may differ
slightly from requested bounds due to floating-point grid representation.

The Timor CHIRPS rectangle includes some land in Timor-Leste; the selected
regions are not restricted to the administrative territory of East Nusa
Tenggara (NTT), Indonesia. No additional island-polygon or coastline mask
is applied in this step.

6. EXTRACTION AND REGIONAL AVERAGING
-----------------------------------
For each available month and each study region:
- Extract the grid cells whose center coordinates fall within the specified
  longitude/latitude rectangle (with a 1e-4-degree comparison tolerance).
- Treat nonfinite values and extremely large fill-like values
  (absolute value greater than 1e7) as missing.
- Calculate the simple arithmetic mean of remaining finite cell values:

      X_region,t = sum(X_i,t over valid selected cells) / N_valid,t

- Record N_valid,t for each region, month, and product in
  regional_grid_check.csv.

The method does not apply an explicit coastal/island polygon mask, spatial
interpolation, or cosine-latitude/area weighting. The distinction between
marine SST and land precipitation arises from the source products' finite
value footprints, not from a new polygon mask implemented here. The set
of valid cells can vary by month, particularly for SST.

SST values are already in degrees Celsius after Step 01. CHIRPS values are
already monthly precipitation totals in mm; no multiplication or division
by 1,000 is performed.

7. TIME AXIS AND MISSING VALUES
------------------------------
The time axis contains 120 consecutive calendar-month positions from
2016-01 through 2025-12, including two months without SST data.

- SST: 118 available monthly files, with missing October and November 2025.
- CHIRPS rainfall: 120 available monthly time slices.
- SST in October and November 2025 remains NaN for Flores, Sumba, and Timor.
- Rainfall is retained for those two months.
- No missing values are interpolated, imputed, or replaced with zeros.
- December 2025 SST remains included.

The extraction script checks that exactly 118 SST files and 120 rainfall
months are present, that the expected missing-month pattern is preserved,
and that available region-month combinations have finite data. Additional
metadata/unit and grid-shape checks are implemented in the script; see the
source code for their exact scope.

8. STUDY-PERIOD MEANS AND ANOMALY DEFINITIONS
---------------------------------------------
For a regional monthly series X_t, let m(t) denote its calendar month
(January=1, ..., December=12). Means are calculated from the available
finite observations, separately for SST and rainfall.

A. Overall study-period mean:

      X_bar = mean(X_t over all available months in 2016-2025)

B. Overall-mean anomaly:

      A_overall(t) = X_t - X_bar

   Subtracting this single constant does not remove the annual cycle.
   Accordingly, Pearson correlation computed for paired raw SST/rainfall
   values is unchanged when both series are overall-mean centered.

C. Study-period calendar-month mean:

      X_bar(m) = mean(X_t for available observations with m(t) = m)

   Twelve separate monthly means are calculated for each region/product.
   These are 2016-2025 study-period monthly means, not 30-year
   climatological normals.

D. Deseasonalized anomaly:

      A_deseason(t) = X_t - X_bar(m(t))

   This subtracts the estimated mean seasonal cycle over the study period.
   It does not isolate or remove ENSO, IOD, or other climate-mode effects.

E. Deseasonalized and linearly detrended anomaly:

      A_detrended(t) = A_deseason(t) - (a*t + b)

   Here t is the original zero-based elapsed calendar-month position
   (0 for January 2016 through 119 for December 2025). Coefficients a
   and b are estimated by least squares using only finite observations,
   separately for each regional SST and rainfall series. Missing SST
   months remain gaps; the time axis is not compressed. The trend slope
   reported in regional_detrending_summary.csv is 12*a (per year).
   The reported intercept b belongs to the fitted DESEASONALIZED series
   at t=0, not to a fitted trend in the original raw variable.

IMPORTANT MATLAB VARIABLE NAMING:
The variables anom_sst_flores, anom_sst_sumba, anom_sst_timor and their
anom_prec_* counterparts in regional_anomalies.mat contain the
DESEASONALIZED anomalies (A_deseason), not the overall-mean anomalies.
The separate arrays SST_overall_anom and RAIN_overall_anom store the
A_overall values. Distinguish these representations in later analyses.

9. OUTPUT FILES AND CONTENT
---------------------------
Extraction script (a_extract_regional_timeseries.m):
- regional_timeseries_raw.csv: 120 monthly rows with regional SST (deg C)
  and rainfall (mm per calendar month) for Flores, Sumba, and Timor.
- regional_timeseries_raw.mat: source regional series, MATLAB time axis,
  coordinate vectors, requested bounds, file-availability flags, and
  valid-grid-cell counts; direct input to script b.
- regional_grid_check.csv: number of finite selected cells for every
  region/product and month; these are VALID counts, not total box sizes.
- regional_domain_grid_metadata.csv: requested versus actual grid bounds
  and total numbers of coordinate-selected cells in each rectangle.
- regional_data_availability.csv: SST file and CHIRPS month presence flags
  for all 120 calendar-month positions.

Anomaly script (b_compute_regional_anomalies.m):
- regional_calendar_month_means.csv: 12 calendar-month means and sample
  counts for each regional SST and rainfall series.
- regional_anomalies.csv: three anomaly representations for each region
  and variable, retaining all 120 month positions.
- regional_anomalies.mat: MATLAB arrays for the overall-mean,
  deseasonalized and detrended analyses and downstream figure/statistics
  scripts; also contains the anom_sst_* and anom_prec_* aliases noted above.
- regional_detrending_summary.csv: fitted trend slopes per year and
  intercepts for the deseasonalized SST and rainfall series.

Retain BOTH MAT files in the repository when distributing the accompanying
analysis scripts: regional_timeseries_raw.mat feeds script b, while
regional_anomalies.mat is an input to later analysis/figure scripts.
Their companion CSV files permit independent inspection without MATLAB.
Figure_2_Plot_Data.mat, where generated in Step 08, is a figure-specific
output and does not replace regional_anomalies.mat.

10. QUALITY CONTROL AND VERIFIED FILE CONSISTENCY
-------------------------------------------------
Checks embedded in the scripts include:
- Input file/folder presence, initial unit metadata, and grid dimensions.
- CHIRPS negative-value rejection and expected file/time coverage.
- Finite selected-cell counts and expected SST missing-month pattern.
- A warning for regional SST outside the defined plausibility bounds.
- Equality (within numerical tolerance) of raw and overall-mean-centered
  Pearson correlation coefficients for paired SST/rainfall observations.

Independent inspection of the CSV and MAT outputs supplied with this step
confirmed the following for these specific files:
- Regional raw and anomaly tables each contain 120 monthly rows.
- SST is missing only in October and November 2025 (118 finite monthly
  values per region); rainfall contains 120 finite values per region.
- The availability table reports 118 SST files and 120 rainfall months.
- SST calendar-month means for October and November use n=9; all other
  SST calendar-month means use n=10. Rainfall monthly means use n=10.
- Recalculated overall-mean, deseasonalized, and detrended arrays agree
  with the supplied CSV outputs to floating-point precision.
- Compared regional raw and anomaly arrays agree between the associated
  MAT and CSV files to floating-point precision.

These checks establish consistency of the provided outputs with the
implemented formulas. They do NOT independently verify the original
provider NetCDF files, physical representativeness of the domains,
or any downstream significance tests.

11. LIMITATIONS AND LINKS TO LATER STEPS
---------------------------------------
- Geographic boxes are not exact island/coastline or national boundaries.
- Grid means are unweighted; neither cell-area correction nor a fixed
  per-region common-pixel mask is implemented in Step 02.
- SST valid-cell coverage can differ across months, and October-November
  2025 SST is not filled.
- Study-period monthly means are not long-term climate normals.
- The statistical sensitivity of later results to satellite transitions,
  domain choices, and alternative preprocessing must be assessed in the
  designated downstream steps rather than presumed resolved here.
- Separate scenario outputs from Step 09 should not be silently substituted
  for the Step 02 series used in the main analysis.

The downstream analyses should explicitly specify which anomaly arrays
are used and should be consistent with these documented definitions.
Complete reproduction from original provider products additionally requires
the raw/cropped Step 01 NetCDF files, which are not hosted here.
