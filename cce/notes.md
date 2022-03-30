## Rerunning the 2020 southwest drought

Changes from Isla's ensemble:
 - model-based SST
   - LENS2, 2010-2030 climatology, members 51-100 (smbb)
 - SSP3-7.0 land forcings (2020)
   - fsurdat, flanduse, ndep

Previously:
 - flanduse_timeseries = '/glade/p/cesmdata/cseg/inputdata/lnd/clm2/surfdata_map/landuse.timeseries_0.9x1.25_hist_78pfts_CMIP6_simyr1850-2015_c170824.nc'
 - stream_fldfilename_lightng = '/glade/p/cesmdata/cseg/inputdata/atm/datm7/NASA_LIS/clmforc.Li_2012_climo1995-2011.T62.lnfm_Total_c140423.nc'
 - stream_fldfilename_urbantv = '/glade/p/cesmdata/cseg/inputdata/lnd/clm2/urbandata/CLM50_tbuildmax_Oleson_2016_0.9x1.25_simyr1849-2106_c160923.nc'
 - stream_fldfilename_popdens = '/glade/p/cesmdata/cseg/inputdata/lnd/clm2/firedata/clmforc.Li_2017_HYDEv3.2_CMIP6_hdm_0.5x0.5_AVHRR_simyr1850-2016_c180202.nc'
 - stream_fldfilename_ndep = '/glade/p/cesmdata/cseg/inputdata/lnd/clm2/ndepdata/fndep_clm_hist_b.e21.BWHIST.f09_g17.CMIP6-historical-WACCM.ensmean_1849-2015_monthly_0.9x1.25_c180926.nc'
 - fsurdat = '/glade/p/cesmdata/cseg/inputdata/lnd/clm2/surfdata_map/release-clm5.0.18/surfdata_0.9x1.25_hist_78pfts_CMIP6_simyr1850_c190214.nc'

Dave recommends keep all. Update landuse and ndep for 2090


Copying and adapting Isla's setupcase.sh
 - /glade/u/home/islas/MAPP/runscripts/2020/setupcase.sh
Copying and adapting Isla's transferrestarts.sh
 - /glade/u/home/islas/MAPP/runscripts/2020/transferrestarts.sh
 - I don't have LENS2 restarts access
 - Isla re-synced the restarts to her scratch
 - She needed to also chmod
Copying the namelists and sourcemods
 - /glade/u/home/islas/MAPP/runscripts/2020/
Editing the SST xmlchanges
 - ./xmlchange SSTICE_YEAR_ALIGN='2020'
 - ./xmlchange SSTICE_YEAR_START='0'
 - ./xmlchange SSTICE_YEAR_END='0'
Update the SSTFILE
 - /glade/work/islas/inputdata/MAPP/SSTs/sstice_LENS2_second50_clim2010to2030_diddled_ts.nc
Move nudging files
 - from /glade/campaign/cgd/cas/islas/MAPP/ERA5_2020_nudginginput
 - update user_nl_cam to find them in my scratch space

