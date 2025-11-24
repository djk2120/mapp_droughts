import xarray as xr
import glob
import sys
import numpy as np

# inputs
year = int(sys.argv[1])
mem = sys.argv[2]

# data vars
avs = ['TMQ', 'TREFHTMX', 'PBLH', 'TREFHT', 'RHREFHT']
lvs = ['RAIN', 'SNOW', 'QVEGT', 'QVEGE', 'QSOIL', 'QRUNOFF',
       'SOILWATER_10CM', 'FSH', 'GPP', 'TLAI']
dvs = [*avs, *lvs]

# file key
lens2 = '/glade/campaign/cgd/cesm/CESM2-LE/'
lnd_dir = lens2 + 'timeseries/lnd/proc/tseries/day_1/'
atm_dir = lens2 + 'timeseries/atm/proc/tseries/day_1/'
afile = atm_dir+'{}/*{}*h1*{}*.nc'  # glob pattern
lfile = lnd_dir+'{}/*{}*h5*{}*.nc'
f0 = {v: afile for v in avs}
for v in lvs:
    f0[v] = lfile

# define subsetting patterns
a = slice(30, 45)
o = slice(240, 265)

# read data
dsout = xr.Dataset()
for v in dvs:
    g = f0[v].format(v, mem, year)
    files = glob.glob(g)
    if len(files) == 1:
        ds = xr.open_dataset(files[0])
        da = ds[v].sel(lat=a, lon=o).compute()
    else:
        print('empty glob: '+g)
        da = np.nan*da
    da['lat'] = np.round(da.lat.astype(float), 2)  # lnd/atm mismatch
    dsout[v] = da

# derived variables
t = dsout.TREFHT-273.15
rh = dsout.RHREFHT/100
es = 0.61094*np.exp(17.625*t/(t+234.04))
note = 'calc from daily TREFHT and RHREFHT'
dsout['VPD'] = ((1-rh)*es).compute()
dsout['VPD'].attrs = {'long_name': 'vapor pressure deficit',
                      'units': 'kPa', 'note': note}
dsout['VP'] = (rh*es).compute()
dsout['VP'].attrs = {'long_name': 'vapor pressure',
                     'units': 'kPa', 'note': note}
dsout['PREC'] = dsout['RAIN'] + dsout['SNOW']
dsout['ET'] = dsout['QVEGT'] + dsout['QSOIL'] + dsout['QVEGE']
dsout['mem'] = mem

# write
dout = '/glade/derecho/scratch/djk2120/postp/lens2/daily/'
fout = dout+'cesm2le.foco.daily.{}.{}.nc'.format(year, mem)
dsout.to_netcdf(fout)
