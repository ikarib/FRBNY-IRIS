%% Simulate Permanent Change in Inflation Target
%
% Simulate a permanent change in the inflation target, calculate the
% sacrifice ratio, and run a simple parameter sensitivity exercise using
% model objects with multiple parameterizations.

%% Clear Workspace
%
% Clear workspace, close all graphics figures, clear command window, and
% check the IRIS version.

clear; clc; close all
irisrequired 20151016
%#ok<*NASGU>
%#ok<*NOPTS>
 
%% Load Solved Model Object
%
% Load the solved model object built in `read_nonlin_model`; run `read_nonlin_model` at
% least once before running this m-file.

load read_nonlin_model.mat m;

%% Define dates

startDate = qq(2009,2);
endDate = startDate + 39;
plotRng = startDate-5 : startDate+19;

%% Create Model with Higher Steady State Inflation
%
% Set the steady-state rate of inflation to 3 pct, and check that the new
% steady state of real variables remain unchanged.

m1 = m;
m1.pistar_ = (1.03^(1/4)-1)*100; % quarterly percentage
if islinear(m1)
    m1 = solve(m1);
    m1 = sstate(m1);
else
    m1 = sstate(m1);
    m1 = solve(m1);
end
chksstate(m1);

ss = get(m,'sstateLevel');
ss1 = get(m1,'sstateLevel');
ss & ss1

%% Simulate Disinflation
%
% Simulate the low-inflation model, `m`, starting from the steady state of
% the high-inflation model, `m1`.

d1 = sstatedb(m1,startDate-3:endDate);
s = simulate(m,d1,startDate:endDate);
s = dboverlay(d1,s);
s = dbminuscontrol(m,s,d1);

plotList = { ...
    ' "Output Growth" obs_gdp ', ...
    ' "Hours Worked" obs_hours ', ...
	' "Labor Share" obs_wages ', ...
    ' "Core PCE Inflation" obs_corepce ', ...
	' "Nominal Interest Rate" obs_nominalrate ', ...
    ' "Consumption Growth" obs_consumption ', ...
    ' "Investment Growth" obs_investment ', ...
	' "Spread" obs_spread ', ...
    ' "Total Factor Productivity" obs_tfp ', ...
   };
dbplot(s,plotRng,plotList,'tight=',true,'highlight=',startDate-5:startDate-1);
grfun.ftitle('Disinflation');

%% Sacrifice Ratio
%
% Sacrifice ratio is the cumulative output loss after a 1% PA disinflation.
% Divide by 4 to get an annualised figure (reported in the literature).

sacRat = -cumsum(100*(s.y-1))/4

%% Change Price and Wage Stickiness and Compare to Baseline
%
% Create a model object with 8 parameterisations, and assign a range of
% values to the price stickiness parameter.

m(1:8) = m;
m.zeta_p = linspace(0.76,0.9,8);
m = solve(m)

s = simulate(m,d1,startDate:endDate);
s = dboverlay(d1,s);
s = dbminuscontrol(m,s,d1);

dbplot(s,plotRng,plotList,'tight=',true);
grfun.ftitle('Disinflation with More Flexible Prices');

disp('Cumulative output gap (sacrifice ratio):');
sacRat = -cumsum(100*(s.y-1))/4;

figure();
plot(sacRat);
grid('on');
title('Sacrifice ratio');
legend(sprintfc('\\zeta_p=%g',m.zeta_p),'location','northWest');
sacRat{startDate:endDate}

%% Help on IRIS Functions Used in This File
%
% Use either `help` to display help in the command window, or `idoc`
% to display help in an HTML browser window.
%
%    help model/subsasgn
%    help model/solve
%    help model/sstate
%    help model/sstatedb
%    help model/simulate
%    help dbase/dbplot
%    help dbase/dboverlay
    
