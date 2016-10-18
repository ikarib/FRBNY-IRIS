% run this file at the end of loaddata.m
% set zerobound=0 in spec_990.m (line 23)
Range=datrange(qq(1959,2),qq(2014,4));
List={'obs_gdp','obs_hours','obs_wages','obs_gdpdeflator','obs_corepce','obs_nominalrate','obs_consumption','obs_investment','obs_spread','obs_longinflation','obs_longrate','obs_tfp'};
data=array2db(series,Range,List);
save data data
disp('saved data.mat')