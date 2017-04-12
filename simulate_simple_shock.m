%% Simulate Simple Shock Responses
%
% Simulate a simple shock both as deviations from control and in full
% levels, and report the simulation results.

%% Clear Workspace
%
% Clear workspace, close all graphics figures, clear command window, and
% check the IRIS version.

clear; clc; close all
irisrequired 20170320

%% Load Solved Model Object
%
% Load the solved model object built in `read_linear_model`. Run `read_linear_model` at
% least once before running this m-file.

load read_linear_model.mat m;

%% Define Dates
%
% Define the start and end dates as plain numbered periods here.

startDate = 1;
endDate = 40;

% ...
%
% Alternatively, use the IRIS functions `yy`, `hh`, `qq`, `bb`, or
% `mm` to create and use proper dates (with yearly, half-yearly, quarterly,
% bi-monthly, or monthly frequency, respectively).
%
%    startdate = qq(2010,1);
%    enddate = startdate + 39;

%% Simulate Government Spending Shock (Figure 7 of Staff Report 647)
% Figure 7 reports the IRFs of the government spending shock, which plays a very
% limited quantitative role in the model, accounting for less than 5% of the fluctuations of all
% variables, except at very short forecast horizons. In terms of dynamics, this shock boosts
% GDP growth in the very short run, and hours for a few quarters, generating some mild
% inflationary pressures that are kept in check by a rise in interest rates.
%
% Simulate the shock as deviations from control (e.g. from the steady
% state or balanced-growth path). To this end, set the option
% `'deviation='` to true. Both the input and output database are then
% interpreted as deviations from control:
%
% * the deviations for linearised variables are defined as $x_t -
% x_t$: hence, 0 means the variable is on its steady state.
% * the deviations for log-linearised variables are defined as $x_t / \Bar
% x_t$: hence, 1 means the variable is on its steady state, or 1.05 means
% it is 5 % above it.
%
% The function `zerodb` automatically detects the maximum lag in the model,
% and creates the input database accordingly so that it includes all
% necessary initial conditions.

d = zerodb(m,startDate:endDate);
d.g_sh(startDate) = log(1.1);
s1 = simulate(m,d,1:endDate,'deviation=',true);

%% Report Simulation Results
%
% Use the `dbplot` function to create a quick report of simulation results.

plotRng = startDate : startDate+14;
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
dbplot(s1,plotRng,plotList,'tight=',true);
grfun.ftitle('Responses to Government Spending Shock -- Deviations from Control');

%% Simulate Shock in Full Levels
%
% Instead of deviations from control, simulate now the same shocks in full
% levels. To that end, create an input dabase with the steady state
% (balanced-growth path) using `sstatedb`, and keep the option
% `'deviation='` false (default). When reporting the results, plot both the
% simulated shock against the steady-state (balanced-growth path) database:
% The `&` operator <?at?> combines two databases so that every time series
% has two columns.

d = sstatedb(m,startDate:endDate);
d.g_sh(startDate) = log(1.1);
s = simulate(m,d,1:endDate);
s = dboverlay(d,s);

dbplot(d & s,plotRng,plotList,'tight=',true);
grfun.ftitle('Responses to Government Spending Shock -- Full Levels');

%% Help on IRIS Functions Used in This File
%
% Use either `help` to display help in the command window, or `idoc`
% to display help in an HTML browser window.
%
%    help model/simulate
%    help model/sstatedb
%    help model/zerodb
%    help dbase/dbplot
%    help grfun/ftitle
%    help dbase/dboverlay
