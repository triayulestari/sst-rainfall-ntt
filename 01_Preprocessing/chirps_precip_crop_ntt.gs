* loop tahun
year = 2016
while (year<=2025)

'reinit'
'c'

infile = '../0b-Precip_Globe/chirps-v3.0.'%year%'.monthly.nc'
outfile = 'prec_'%year%'.NTT.nc'


'sdfopen 'infile

'set lon 118 127'
'set lat -11.5 -7.5'
'set t 1 12'

'define prec = precip'

'set sdfwrite 'outfile
'sdfwrite prec'

year=year+1
endwhile

