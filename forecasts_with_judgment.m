%% Forecasts with Judgmental Adjustments
%
% Use the Kalman filtered data as the starting point for forecasts, both
% unconditional and conditional, i.e. with various types of judgmental
% adjustments.

%% Clear Workspace
%
% Clear workspace, close all graphics figures, clear command window, and
% check the IRIS version.

clear; clc; close all
irisrequired 20170320

%% Load Estimated Model Object, Filtered Data, and Historical Database
%
% Load the model object estimated in `estimate_params`, the filtered
% (smoothed) data from a Kalman filter in `filter_hist_data`, and the
% historical database created in `read_data`. Run `estimate_params` and
% `filter_hist_data` at least once before running this m-file.

load estimate_params.mat mest o;
load filter_hist_data.mat f;
load read_data.mat d startHist endHist;

%% Define Dates

startFcst = endHist + 1;
endFcst = startFcst + 3*4;
startPlot = startFcst - 12;
plotRng = startPlot:endFcst;
highRng = startPlot:endHist;

%% Define Graphics Styles
%
% The structs `sty1` and `sty2` are used in the option `'style='` in
% `qplot` to automatically style the graphs plotted.

sty1 = struct();
sty1.line.color = {'blue','blue','blue'};
sty1.line.lineStyle = {'-','--','--'};
sty1.line.lineWidth = 1.5;
sty1.line.marker = {'.','none','none'};
sty1.axes.fontSize = 7;
sty1.legend.fontSize = 7;

sty2 = sty1;
sty2.line.color = {'blue','red','blue','red','blue','red'};
sty2.line.lineStyle = {'-','-','--','--','--','--'};
sty2.line.lineWidth = 1.5;
sty2.line.marker = {'.','.','none','none','none','none'};
sty2.axes.fontSize = 7;
sty2.legend.fontSize = 7;

%% Run Unconditional Forecast
%
% Unconditional forecast runs from the initial condition supplied in the
% input database, `f`. The initial conditions consist of the mean and the
% root mean square error (initial uncertainty) for each variable. Directly
% observed variables have obviously RMSE zero, the unobservables (such as
% productivity) have non-zero initial uncertainty.

u = jforecast(mest,f,plotRng);

u %#ok<NOPTS>
u.mean

u.mean = dboverlay(f.mean,u.mean);
u.std = dboverlay(f.std,u.std);

%% Create Plot Lists
%
% Define variables and titles to appear in graphs created by `dbplot`
% functions after each forecast experiment.

plotList1 = { ...
    ' "Interest Rate, Q/Q PA" [mean.obs_nominalrate, mean.obs_nominalrate+std.obs_nominalrate, mean.obs_nominalrate-std.obs_nominalrate]*4', ...
    ' "Core PCE Inflation, Q/Q PA" [mean.obs_corepce, mean.obs_corepce+std.obs_corepce, mean.obs_corepce-std.obs_corepce]*4', ...
    ' "Output Growth, Q/Q PA" [mean.obs_gdp, mean.obs_gdp+std.obs_gdp, mean.obs_gdp-std.obs_gdp]*4', ...
    ' "Real Wage Growth, Q/Q PA" [mean.obs_wages, mean.obs_wages+std.obs_wages, mean.obs_wages-std.obs_wages]*4', ...
    };

plotList2 = { ...
	' "Government Spending Shocks" mean.g_sh', ...
    ' "Cost Push Shocks" mean.laf_sh', ...
    ' "Productivity Shocks" mean.z_sh', ...
    ' "Policy Shocks" mean.rm_sh', ...
    ' "Wage Shocks" mean.law_sh', ...
    ' mean.g_sh ', ...
    ' mean.b_sh ', ...
    ' mean.mu_sh ', ...
    ' mean.zp_sh ', ...
    ' mean.pist_sh ', ...
    ' mean.sigw_sh ', ...
    ' mean.mue_sh ', ...
    ' mean.gamm_sh ', ...
    ' mean.lr_sh ', ...
    ' mean.tfp_sh ', ...
    ' mean.gdpdef_sh ', ...
    ' mean.pce_sh ', ...
    };

%% Report Unconditional Forecast

dbplot(u,startPlot:endFcst,plotList1, ...
    'tight=',true,'style=',sty1,'highlight=',highRng);
grfun.ftitle('Unconditional Forecasts');
grfun.bottomlegend('Mean','Mean +/- 1 Std');

dbplot(u,startPlot:endFcst,plotList2, ...
    'tight=',true,'style=',sty1,'highlight=',highRng, ...
    'transform=',@(x) 100*x);
grfun.ftitle('Unconditional Forecasts');

%% Exogenise Interest Rates
%
% In this judgmentally adjusted forecast, swap the endogeneity and
% exogeneity of the short rates and the policy shocks. In other words, the
% short rates are kept fixed at a specified level (here, it is the last
% observed value), and the policy shocks become a new "endogenous variable"
% that adjust exactly so to make the policy rule consistent with the fixed
% interest rates.
%
% The forecast with exogenised interest rates is run in an anticipated
% mode.

p1 = plan(mest,startFcst:endFcst);
p1 = exogenize(p1,'obs_nominalrate',startFcst:startFcst+3);
p1 = endogenize(p1,'rm_sh',startFcst:startFcst+3);

f1 = f;
f1.mean.obs_nominalrate(startFcst:startFcst+3,1) = f.mean.obs_nominalrate(endHist);

detail(p1,f1);

j1 = jforecast(mest,f1,startFcst:endFcst,'plan=',p1);

%% Compare Exogenised Forecasts with Unconditional Forecasts

dbplot(u & j1,startPlot:endFcst,plotList1, ...
    'tight=',true,'style=',sty2,'highlight=',highRng);
grfun.ftitle('Unconditional vs Exogenized Short Rate');
grfun.bottomlegend('Uncond Mean','Exogen Mean', ...
    'Uncond Mean +/- 1 Std','Exogen Mean +/- 1 Std');

dbplot(u & j1,startPlot:endFcst,plotList2, ...
    'tight=',true,'style=',sty2,'highlight=',highRng, ...
    'transform=',@(x) 100*x);
grfun.ftitle('Unconditional vs Exogenized Short Rate');

%% Condition on Anticipated Interest Rates
%
% In this exercise, keep the interest rates fixed, but use a very different
% mechanism to do that. Compute the most likely combination of all possible
% shocks, except the monetary policy shocks, and changes in the initial
% conditions to reproduce a given path for the interest rates (it is again
% a flat track). The forecast is produced in an anticipated mode, which
% means that all agents know the future shocks from the very beginning.

mest1 = mest;
mest1.std_rm_sh = 0;

get(mest,'std') & get(mest1,'std') %#ok<NOPTS>

p2 = plan(mest1,startFcst:endFcst);
p2 = condition(p2,'obs_nominalrate',startFcst:startFcst+3);

f2 = f;
f2.mean.obs_nominalrate(startFcst:startFcst+3) = f2.mean.obs_nominalrate(endHist);

c = struct();
c.obs_nominalrate = f2.mean.obs_nominalrate;

detail(p2,f2);

j2 = jforecast(mest1,f2,startFcst:endFcst,c,'plan=',p2);

%% Compare Anticipated Conditional Forecasts with Unconditional Forecasts

dbplot(u & j2,startPlot:endFcst,plotList1, ...
    'tight=',true,'style=',sty2,'highlight=',highRng);
grfun.ftitle('Unconditional vs Conditional on Anticipated Short Rate');
grfun.bottomlegend('Uncond Mean','Cond Mean', ...
    'Uncond Mean +/- 1 Std','Cond Mean +/ 1 Std');

dbplot(u & j2,startPlot:endFcst,plotList2, ...
    'tight=',true,'style=',sty2,'highlight=',highRng, ...
    'transform=',@(x) 100*x);
grfun.ftitle('Unconditional vs Conditional on Anticipated Short Rate');

%% Condition on Unanticipated Interest Rates
%
% Do the same as above, but with the conditioning interest rate
% unanticipated.

p3 = p2;
f3 = f2;

j3 = jforecast(mest1,f3,startFcst:endFcst+50, ...
    'plan=',p3,'anticipate=',false);

%% Compare Unanticipated Conditional Forecasts with Uncondtional Forecasts

dbplot(u & j3,startPlot:endFcst,plotList1, ...
    'tight=',true,'style=',sty2,'highlight=',highRng);
grfun.ftitle('Unconditional vs Conditional on Unanticipated Short Rate');
grfun.bottomlegend('Uncond Mean','Cond Mean', ...
    'Uncond Mean +/- 1 Std','Cond Mean +/ 1 Std');

dbplot(u & j3,startPlot:endFcst,plotList2, ...
    'tight=',true,'style=',sty2,'highlight=',highRng, ...
    'transform=',@(x) 100*x);
grfun.ftitle('Unconditional vs Conditional on Unanticipated Short Rate');


%% Exogenised Interest Rates and Condition on Inflation
%
% Combine two techniques together: exogenizing and conditioning.

p4 = plan(mest,startFcst:endFcst);

p4 = exogenise(p4,'obs_nominalrate',startFcst:startFcst+3);
p4 = endogenise(p4,'rm_sh',startFcst:startFcst+3);

p4 = condition(p4,'obs_corepce',startFcst:startFcst+3);

f4 = f;
f4.mean.obs_nominalrate(startFcst:startFcst+3) = f4.mean.obs_nominalrate(endHist);
f4.mean.obs_corepce(startFcst:startFcst+3) = f4.mean.obs_corepce(endHist);

j4 = jforecast(mest1,f4,startFcst:endFcst+50,'plan=',p4);

%% Verify Exogenised and Conditioned Data Points
%
% Print the forecasts for the interest rate and inflation, and compare the
% forecasts with the values we supplied in the input database.

disp('Interest rate forecast and tunes');
[j4.mean.obs_nominalrate{startFcst:startFcst+3}, ...
    f4.mean.obs_nominalrate{startFcst:startFcst+3}] %#ok<NOPTS>

disp('Inflation forecast and conditions');
[j4.mean.obs_corepce{startFcst:startFcst+3}, ...
    f4.mean.obs_corepce{startFcst:startFcst+3}] %#ok<NOPTS>

%% Compare Exogenised/Conditional Forecasts with Unconditional Forecasts

dbplot(u & j4,startPlot:endFcst,plotList1, ...
    'tight=',true,'style=',sty2,'highlight=',highRng);
grfun.ftitle(['Unconditional vs ', ...
    'Anticipated Exogenised Short Rate and Conditional on Inflation']);
grfun.bottomlegend('Uncond Mean','Cond Mean', ...
    'Uncond Mean +/- 1 Std','Cond Mean +/ 1 Std');

dbplot(u & j4,startPlot:endFcst,plotList2, ...
    'tight=',true,'style=',sty2,'highlight=',highRng, ...
    'transform=',@(x) 100*x);
grfun.ftitle(['Unconditional vs ', ...
    'Anticipated Exogenised Short Rate and Conditional on Inflation']);

%% Resimulate Point Forecasts
%
% The function `simulate` only uses the input database for initial
% condition and in-sample shocks. The shocks backed out by `jforecast` are
% such that they exactly reproduce the exogenised and/or conditioned data
% points.
%
% * <?maxabs?> Use the function `maxabs` to report the max abs differences
% between the fields of the same name in two structs (databases).

s1 = simulate(mest1,j1.mean,startFcst:endFcst); 
s2 = simulate(mest1,j2.mean,startFcst:endFcst);
s3 = simulate(mest1,j3.mean,startFcst:endFcst,'anticipate=',false);
s4 = simulate(mest1,j4.mean,startFcst:endFcst);

maxabs(s1,j1.mean) ... %?maxabs?
    & maxabs(s2,j2.mean) ...
    & maxabs(s3,j3.mean) ...
    & maxabs(s4,j4.mean) %#ok<NOPTS>

%% Help on IRIS Functions Used in This Files
%
% Use either `help` to display help in the command window, or `idoc`
% to display help in an HTML browser window.
%
%    help data/dbextend
%    help model/jforecast
%    help model/subsasgn
%    help qreport/qplot
%    help grfun/ftitle
%    help maxabs
