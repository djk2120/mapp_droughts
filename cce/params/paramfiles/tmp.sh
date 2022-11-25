for i in {01..06}; do
    f='p'$i'.nc'
    ncks -A -v d_max base.nc $f
    ncks -A -v frac_sat_soil_dsl_init base.nc $f
done
