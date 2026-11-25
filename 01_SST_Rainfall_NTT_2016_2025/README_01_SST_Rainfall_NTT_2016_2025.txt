STEP 01 — SATELLITE DATA PREPARATION AND GEOGRAPHIC CROPPING (2016–2025)
=======================================================================

1. PURPOSE AND SCOPE
--------------------
This stage prepares monthly sea surface temperature (SST) and precipitation
inputs for the study "Satellite-Based Seasonal and Spatial Sea Surface
Temperature–Rainfall Relationships across Tropical Drylands of East Nusa
Tenggara: Flores, Sumba, and Timor."

Two GrADS scripts crop the original Himawari SST and CHIRPS v3.0 NetCDF
products to a common geographic bounding box around East Nusa Tenggara
(NTT). The resulting files serve as inputs to subsequent MATLAB processing.

This step performs geographic subsetting and, for SST, unit conversion.
It does NOT calculate island-specific means, SST/rainfall anomalies,
correlations, land–sea masks, or spatial significance tests. Those operations
must be documented in their respective downstream steps.

2. SOFTWARE AND DATA SOURCES
----------------------------
Processing software:
  - GrADS 2.2.1 (version reported for the original .gs scripts).

Original SST data:
  - Provider: JAXA Himawari Monitor / P-Tree.
  - Access information: https://www.eorc.jaxa.jp/ptree/registration_top.html
  - Himawari-8 Level-3 monthly SST, product version 2.0 (1MSST200):
    January 2016–September 2022.
  - Himawari-9 Level-3 monthly SST, product version 2.1 (1MSST201):
    October 2022–December 2025, except October and November 2025,
    which are skipped in the processing script because they are absent
    from the study's processed SST inventory.

Original precipitation data:
  - Provider: Climate Hazards Center, CHIRPS v3.0.
  - Product: monthly global NetCDF files, January 2016–December 2025.
  - Access directory:
    https://data.chc.ucsb.edu/products/CHIRPS/v3.0/monthly/global/netcdf/by_year/

The original README recorded 29 July 2026 as the initial download date.
This is a researcher-reported provenance detail, not a date verified from
file timestamps or download logs in this repository.

3. SPATIAL AND TEMPORAL COVERAGE
--------------------------------
Requested geographic bounding box in both GrADS scripts:
  - Longitude: 118.0° E to 127.5° E.
  - Latitude:  11.5° S to 7.0° S (−11.5° to −7.0°).

These values define the requested crop boundaries. The actual first and
last output grid coordinates depend on the source grid and should be
checked in the generated NetCDF metadata.

No explicit regridding, spatial interpolation, temporal interpolation, or
missing-data infilling is coded in this step. The original SST and CHIRPS
products have different grids; this script does not force them onto a
common spatial resolution.

4. LOCAL FILE STRUCTURE AND REPOSITORY CONTENT
-----------------------------------------------
The GitHub repository contains the README and .gs scripts. Original and
cropped NetCDF datasets are stored locally and are NOT distributed here.

sst-rainfall-ntt/
  01_SST_Rainfall_NTT_2016_2025/
    README_01_SST_Rainfall_NTT_2016_2025.txt
    00_Raw_Data/                                  [LOCAL ONLY]
      Himawari_SST_L3_FullDisk/
        H08_YYYYMM01_0000_1MSST200_FLDK.06001_06001.nc
        H09_YYYYMM01_0000_1MSST201_FLDK.06001_06001.nc
      CHIRPS_v3_Monthly_Global/
        chirps-v3.0.YYYY.monthly.nc
    01_Crop_SST_NTT/
      01_crop_himawari_sst_ntt.gs
      sst_YYYYMM.nc                               [LOCAL OUTPUT]
    02_Crop_CHIRPS_NTT/
      02_crop_chirps_v3_ntt.gs
      prec_YYYY.NTT.nc                            [LOCAL OUTPUT]

"00_Raw_Data" must be located directly inside the Step 01 folder for the
relative paths in both scripts to work. It may be present in the researcher's
local working copy but is not expected in the published GitHub tree.

5. EXECUTION INSTRUCTIONS
-------------------------
Both scripts read raw files from ../00_Raw_Data/ relative to their OWN
working directory, and write results into the current GrADS working
directory. Do not launch them from the repository root unless their paths
are adapted accordingly.

A. SST:
  1. Place the original SST NetCDF files in
     01_SST_Rainfall_NTT_2016_2025/00_Raw_Data/Himawari_SST_L3_FullDisk/.
  2. Change the operating-system working directory to
     01_SST_Rainfall_NTT_2016_2025/01_Crop_SST_NTT/.
  3. Launch GrADS and run:
       run 01_crop_himawari_sst_ntt.gs
  4. Inspect the run messages and generated sst_YYYYMM.nc files.

B. Precipitation:
  1. Place the original CHIRPS NetCDF files in
     01_SST_Rainfall_NTT_2016_2025/00_Raw_Data/CHIRPS_v3_Monthly_Global/.
  2. Change the operating-system working directory to
     01_SST_Rainfall_NTT_2016_2025/02_Crop_CHIRPS_NTT/.
  3. Launch GrADS and run:
       run 02_crop_chirps_v3_ntt.gs
  4. Inspect the run messages and generated prec_YYYY.NTT.nc files.

The scripts print messages when a file cannot be opened or written, but
continue their year/month loops. The final "loop completed" message by
itself does NOT confirm that all expected files were successfully created.

6. PROCESSING DETAILS: HIMAWARI SST
----------------------------------
Script: 01_Crop_SST_NTT/01_crop_himawari_sst_ntt.gs

  - Input variable: sea_surface_tem.
  - Assumed input units: kelvin (K); confirm in the source NetCDF metadata.
  - Conversion: sst = sea_surface_tem − 273.15.
  - Output variable: sst.
  - Output units attribute: degree_Celsius.
  - Crop commands: set lon 118 127.5; set lat -11.5 -7.
  - Time selection: set t 1 for each monthly input file.
  - NetCDF output: one file per included month, sst_YYYYMM.nc.
  - The GrADS -3dt option retains longitude, latitude, and time dimensions.

The script uses Himawari-8 through September 2022 and Himawari-9 from
October 2022 onward. October and November 2025 are explicitly skipped;
December 2025 is retained. Expected output: 118 monthly files if all
required source files open and all output writes succeed (81 H08 months
and 37 H09 months). No missing SST months are interpolated by the script.

7. PROCESSING DETAILS: CHIRPS PRECIPITATION
------------------------------------------
Script: 02_Crop_CHIRPS_NTT/02_crop_chirps_v3_ntt.gs

  - Input variable: precip.
  - Input time selection: set t 1 12 (12 months per annual source file).
  - Output variable: prec.
  - Output units attribute: mm.
  - Interpretation: accumulated precipitation per calendar month.
  - Crop commands: set lon 118 127.5; set lat -11.5 -7.
  - NetCDF output: one file per year, prec_YYYY.NTT.nc.
  - The GrADS -3dt option retains longitude, latitude, and time dimensions.

Expected output: 10 annual files (2016–2025), each containing 12 monthly
time steps, for a total of 120 months, provided the original datasets
contain the expected records and the output writes succeed. The script
performs no multiplication or division by 1,000 and no temporal summing;
it writes the cropped monthly values from the source product.

8. OUTPUT VERIFICATION CHECKLIST (TO BE EXECUTED / DOCUMENTED)
--------------------------------------------------------------
The following checks are recommended. Expected quantities are based on
the code, not on an independent inspection of generated NetCDF files.

  [ ] All expected raw input files exist and are readable.
  [ ] The logs contain no unresolved "ERROR opening" or "ERROR writing".
  [ ] SST output inventory contains exactly 118 sst_YYYYMM.nc files.
  [ ] SST output months exclude 202510 and 202511 but include 202512.
  [ ] CHIRPS output inventory contains exactly 10 prec_YYYY.NTT.nc files.
  [ ] Every CHIRPS output contains the intended 12 monthly time steps.
  [ ] Variables sst and prec have appropriate dimensions, coordinates,
      values, and units attributes.
  [ ] Output timestamps match the intended months and years.
  [ ] Output lon/lat extent is consistent with the requested bounding box.
  [ ] Source SST units are confirmed as kelvin before conversion.
  [ ] Valid values and missing-value handling are checked (no unexpected
      empty outputs or anomalous values).
  [ ] A run log and/or machine-readable output inventory is archived.

These checks should be marked as completed only after inspecting the actual
output files and logs. No QC completion is asserted in this README.

9. REPRODUCIBILITY NOTES AND LIMITATIONS
---------------------------------------
  - Raw and cropped NetCDF files are not included in this repository;
    reconstruction requires access to the original providers.
  - Files must follow the exact naming pattern used by the scripts.
  - The original source grids are not harmonized in this preprocessing step.
  - Cropping alone does not apply an island mask, ocean mask, or land mask.
    Regional averaging and other spatial treatments must be documented
    in subsequent analysis folders.
  - No checksums or raw-file version snapshots are embedded in the scripts;
    an inventory and execution logs would strengthen reproducibility.
  - The H08/H09 product transition is treated separately under
    09_Transition_Sensitivity/. That analysis should be described according
    to its actual completed outputs; sensitivity testing should not be
    presented as independent observational validation.

10. DOWNSTREAM USE
------------------
The cropped SST and CHIRPS NetCDF files provide starting inputs for the
regional time-series and other subsequent processing stages. The later
scripts must be consulted for the exact data selection, masks, aggregation,
anomaly definitions, seasonal calculations, and statistical tests.

This document describes the behavior of the supplied Step 01 GrADS scripts;
it does not by itself certify successful execution or validate later results.
