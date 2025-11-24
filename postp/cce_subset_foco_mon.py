import xarray as xr
from utils import get_files
import sys

# inputs
year = int(sys.argv[1])
mem = int(sys.argv[2])
exp = str(year) + '_era5_i04'

# subsetting paradigm
a = slice(30, 45)
o = slice(240, 265)
dvs = ['RAIN', 'SNOW', 'QVEGT', 'QVEGE', 'QSOIL', 'QRUNOFF',
       'RH2M', 'TSA', 'SOILWATER_10CM']
advs = ['TMQ', 'PBLH']

# land data
files = get_files(exp)
mstr = files[mem][0].split('clm2')[0][-4:-1]
dsets = [xr.open_dataset(f, decode_timedelta=False)[dvs].sel(lat=a, lon=o)
         for f in files[mem]]
ds = xr.concat(dsets, dim='time').compute()
ds['time'] = xr.date_range(str(year), freq='MS', periods=12)[3:]
tmp = xr.open_dataset(files[mem][0], decode_timedelta=False)
ds['landarea'] = tmp.area*tmp.landfrac

# atm data
afiles = get_files(exp, cmp='/atm/')
dsets = [xr.open_dataset(f, decode_timedelta=False)[advs].sel(lat=a, lon=o)
         for f in afiles[mem]]
ds_atm = xr.concat(dsets, dim='time').compute()
ds_atm['lat'] = ds.lat
ds_atm['time'] = ds.time
for v in ds_atm.data_vars:
    ds[v] = ds_atm[v]

# write to file
dout = '/glade/derecho/scratch/djk2120/postp/cce/'
fout = 'cce.{}.foco.gridded.mon.{}.nc'.format(exp, mstr)
ds.to_netcdf(dout + fout)