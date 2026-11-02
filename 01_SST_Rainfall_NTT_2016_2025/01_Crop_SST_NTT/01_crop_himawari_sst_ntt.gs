* ============================================================
* 01_crop_himawari_sst_ntt.gs
* Study area: NTT context frame, 118-127.5 E, 11.5-7 S
* Source: Himawari-8 L3 monthly v200, Himawari-9 L3 monthly v201
* Expected working directory: 01_Preprocessing
* Raw files: ../00_Raw_Data/Himawari_SST_L3_FullDisk/
* Output directory (create first): ../02_Cropped_Data/SST_NTT/
* SST variable sea_surface_tem is assumed in K; convert to degree C.
* Missing H09 months Oct-Nov 2025 are SKIPPED; Dec 2025 is kept.
* ============================================================

'reinit'
year = 2016
while (year <= 2025)
  month = 1
  while (month <= 12)
    if (month < 10)
      smonth = '0'%month
    else
      smonth = ''%month
    endif

    skip = 0
    if (year = 2025)
      if (month = 10 | month = 11)
        skip = 1
      endif
    endif

    if (skip = 1)
      say 'SKIP missing SST month: '%year%smonth
    else
      sat  = 'H09'
      prod = '1MSST201'
      if (year < 2022)
        sat  = 'H08'
        prod = '1MSST200'
      endif
      if (year = 2022 & month <= 9)
        sat  = 'H08'
        prod = '1MSST200'
      endif

      infile = '../00_Raw_Data/Himawari_SST_L3_FullDisk/'%sat'_'%year%smonth'01_0000_'%prod'_FLDK.06001_06001.nc'
      outfile = 'sst_'%year%smonth'.nc'

      'reinit'
      say 'Opening: '%infile
      'sdfopen 'infile
      if (rc = 0)
        'set lon 118 127.5'
        'set lat -11.5 -7'
        'set t 1'
        'define sst = sea_surface_tem - 273.15'
        'set sdfattr sst String units degree_Celsius'
        'set sdfattr sst String long_name Sea_surface_temperature'
        'set sdfwrite -3dt 'outfile
        'sdfwrite sst'
        if (rc = 0)
          say 'Saved: '%outfile
        else
          say 'ERROR writing: '%outfile
        endif
      else
        say 'ERROR opening: '%infile
      endif
    endif
    month = month + 1
  endwhile
  year = year + 1
endwhile
say 'Himawari cropping loop completed.'
