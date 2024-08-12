import regionmask
import numpy as np
import xarray as xr
import glob
from dask_jobqueue import PBSCluster
from dask.distributed import Client
import os

def get_foco(ds):
    states = regionmask.defined_regions.natural_earth_v5_0_0.us_states_50
    mask = states.mask(ds.lon,ds.lat)
    az=3;co=5;nm=32;ut=44
    foco=mask==np.inf
    for s in [az,co,nm,ut]:
        foco= (foco)|(mask==s)
    return foco

def fix_time(ds):
    yr0=str(ds['time.year'][0].values)
    ds['time']=xr.cftime_range(yr0,periods=len(ds.time),freq='MS',calendar='noleap')
    return ds
def gmean(da,la):
    x=1/la.sum()*(la*da).sum(dim=['lat','lon'])
    return x.compute()
def amean(da,m1=1,m2=12):
    ix=(da['time.month']>=m1)&(da['time.month']<=m2)
    dpm=da['time.daysinmonth']
    ndays=dpm.isel(time=ix).groupby('time.year').sum().mean()
    x=1/ndays*(dpm*da).isel(time=ix).groupby('time.year').sum()
    return x.compute()

def get_jas(da,la):
    dpm=da['time.daysinmonth']
    ix = (da['time.month']>=7)&(da['time.month']<=9)
    cfv = 1/92
    jas=cfv*gmean((dpm*da).isel(time=ix).groupby('time.year').sum(),la)
    return jas

def get_ds(exp,dvs,cmp='/lnd/',tape='h0',a=slice(10,60),o=slice(225,300),parallel=True):

    if 'lens' in exp:
        yr = int(exp.split('_')[0])
        ds=get_lens(dvs,cmp[1:-1],tape,yr,a=a,o=o,parallel=parallel)
    else:
        files = get_files(exp,cmp=cmp,tape=tape)
        def preprocess(ds):
            return ds[dvs].sel(lat=a,lon=o)
        ds = xr.open_mfdataset(files,combine='nested',concat_dim=['ens','time'],
                               parallel=parallel,preprocess=preprocess)
        if tape=='h0':
            yr = ds['time.year'][0].values
            m0 = 12-len(ds.time)
            ds['time'] = xr.cftime_range(str(yr),periods=12,freq='MS')[m0:]
        if cmp=='/lnd/':
            tmp = xr.open_dataset(files[0][0]).sel(lat=a,lon=o)
            ds['la']=tmp.area*tmp.landfrac
    
    if 'RAIN' in dvs:
        if 'SNOW' in dvs:
            ds['PREC']=ds.RAIN+ds.SNOW


    if 'QSOIL' in dvs:
        ds['ET']=ds.QVEGT+ds.QVEGE+ds.QSOIL
            
    if 'TSA' in dvs:
        if 'RH2M' in dvs:
            t=ds.TSA-273.15
            rh=ds.RH2M/100
            es=0.61094*np.exp(17.625*t/(t+234.04))
            ds['VPD']=((1-rh)*es).compute()
            ds['VPD'].attrs={'long_name':'vapor pressure deficit','units':'kPa'}
            ds['VP']=(rh*es).compute()
            ds['VP'].attrs={'long_name':'vapor pressure','units':'kPa'}
         
    return ds

def get_lens(dvs,cmp,tape,yr,a=slice(10,60),o=slice(225,300),parallel=True):
    
    if type(dvs)==str:
        dvs=[dvs]
    
    nts={'h0':12,'h1':365,'h5':365,'h7':2920}
    nt = nts[tape]

    files = lens_files(dvs[0],cmp,tape,yr)
    ds = xr.open_dataset(files[0]).sel(lat=a,lon=o)
      
    for dv in dvs:
        files = lens_files(dv,cmp,tape,yr)
        def preprocess(ds):
            return ds[dv].sel(lat=a,lon=o)
        da = xr.open_mfdataset(files,combine='nested',concat_dim='ens',
                             parallel=parallel,preprocess=preprocess)
        ds[dv]=da

    if cmp=='lnd':
        tmp = xr.open_dataset(files[0]).sel(lat=a,lon=o)
        ds['la']=tmp.area*tmp.landfrac

    
    if tape=='h0':
        nmonths = len(ds.time)
        yr0 = ds['time.year'].values[0]
        ds['time'] = xr.cftime_range(str(yr0),periods=nmonths,freq='MS')
        
    if 'RAIN' in dvs:
        if 'SNOW' in dvs:
            ds['PREC']=ds.RAIN+ds.SNOW
    
    
    return ds
    

def lens_files(datavar,cmp,tape,yr):
    topdir = '/glade/campaign/cgd/cesm/CESM2-LE/timeseries/'+cmp+'/proc/tseries/'

    freqs={'atm':{'h0':'month_1','h1':'day_1'},
           'lnd':{'h0':'month_1','h5':'day_1','h7':'hour_3'}}
    freq=freqs[cmp][tape]
    s='/'
    d=topdir+freq+s+datavar+s
    files=np.array(sorted(glob.glob(d+'*f09_g17*'+tape+'*')))
    yr1s = np.array([int(f.split('.')[-2].split('-')[0][:4]) for f in files])
    yr2s = np.array([int(f.split('.')[-2].split('-')[1][:4]) for f in files])
    ix =(yr1s<=yr)&(yr2s>=yr)
    
    return files[ix]

def get_files(exp,cmp='/lnd/',tape='h0'):
    topdir='/glade/campaign/asp/djk2120/mapp/'
    key=eekey()

    matchme=topdir+key[exp]['dir']+'/*'+key[exp]['hash']+'*'
    mems=sorted(glob.glob(matchme))
    
    files = []
    for mem in mems:
        fs = sorted(glob.glob(mem+cmp+'hist/*'+tape+'*'))
        addme=True
        for f in fs:
            if os.path.getsize(f)<1e6:
                addme=False
                break
        if addme:
            files.append(fs)
    
    return files

def eekey(p=True):
    key={
     '2020_climo_i04': {'dir': '2020_climo', 'hash': 'i04'},
     '2020_era5_i04': {'dir': '2020_era5', 'hash': 'i04'},
     '2020_climo_i07': {'dir': '2020_climo', 'hash': 'i07'},
     '2020_wide': {'dir': '2020_wide', 'hash': 'wide_'},
     '2020_wider': {'dir': '2020_wider', 'hash': 'wider'},
     '2020_widest': {'dir': '2020_widest', 'hash': 'widest'},
     '2020_bssp_i04':{'dir':'2020_bnudge','hash':'nudge'},
     '2090_climo_i04': {'dir': '2090_climo', 'hash': 'i04'},
     '1850_climo_i04':{'dir':'1850_climo','hash':'i04'},
     '1850_era5_i04':{'dir':'1850_era5','hash':'i04'},
     '2090_era5_i04': {'dir': '2090_era5', 'hash': 'i04'},
     '2090_climo_i07': {'dir': '2090_climo', 'hash': 'i07'},
     '2090_wide': {'dir': '2090_wide', 'hash': 'wide_'},
     '2090_wider': {'dir': '2090_wider', 'hash': 'wider'},
     '2090_widest': {'dir': '2090_widest', 'hash': 'widest'},
     '2090_bssp_i04':{'dir':'2090_bnudge','hash':'nudge'}}
    
    if p:
        for i in [3,8,9,10,11]:
            exp='p'+str(i).zfill(2)
            key[exp]={'dir':'params','hash':exp}
    return key

def get_cluster(workers=30,project = 'P93300641'):

    cluster = PBSCluster(
        cores=1, # The number of cores you want
        memory='10GB', # Amount of memory
        processes=1, # How many processes
        queue='casper', # The type of queue to utilize (/glade/u/apps/dav/opt/usr/bin/execcasper)
        local_directory='$TMPDIR', # Use your local directory
        resource_spec='select=1:ncpus=1:mem=10GB', # Specify resources
        account=project, # Input your project ID here
        walltime='01:30:00', # Amount of wall time
    )
    
    # Scale up
    cluster.scale(workers)
    
    # Setup your client
    client = Client(cluster)
    return client