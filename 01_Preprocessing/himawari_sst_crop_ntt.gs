'reinit'
'c'

* loop
year = 2016
while (year <= 2025)

month = 1
while (month <= 12)
if (month < 10)
smonth = '0'%month
else
smonth = ''%month
endif

if (year<2022)
sat='H08'
prod='1MSST200'
endif

if (year=2022)
if (month<=9)
sat='H08'
prod='1MSST200'
else
sat='H09'
prod='1MSST201'
endif
endif

if (year>2022)
sat='H09'
prod='1MSST201'
endif

* file
infile = '..\0a-SST_Globe\'%sat'_'%year%smonth'01_0000_'%prod'_FLDK.06001_06001.nc'
outfile = 'sst_'%year%smonth'.nc'

say 'Processing : '%infile

*open file
'reinit'
'c'

'sdfopen 'infile

'set lon 118 127'
'set lat -11.5 -7.5'
'set t 1'

'define sst = sea_surface_tem-273.15'

'set sdfwrite 'outfile
'sdfwrite sst'

month = month + 1
endwhile
year=year+1
endwhile
say 'done'	