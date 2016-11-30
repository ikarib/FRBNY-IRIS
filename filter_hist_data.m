%% Kalman Filtering and Historical Simulations
% by Iskander Karibzhanov
%
% Run the Kalman filter on the historical data to back out unobservable
% variables (such as the productivity process) and shocks, and perform a
% number of analytical exercises that help understand the inner workings of
% the FRBNY model.

%% Clear Workspace
%
% Clear workspace, close all graphics figures, clear command window, and
% check the IRIS version.

clear; clc; close all
irisrequired 20151016
%#ok<*EVLC> 

%% Load Estimated Model Object and Historical Database
%
% Load the model object estimated in `estimate_params.m`, and the
% historical database created in `read_data`. Run `estimate_params` at
% least once before running this m-file.

% load estimate.mat mest;

o = struct; o.kimball = true; o.bgg = true; o.nant = 6;
m = model('frbny.model','assign=',o,'linear=',false);
if exist('P.mat','file'); load P; m=refresh(assign(m,P)); end
if islinear(m)
    m = solve(m);
    m = sstate(m);
else
    m = sstate(m);
    m = solve(m);
end
chksstate(m);

mest = m;

%% Load Historical Database
load data
Range = dbrange(Data);
Range(1) = []; % drop 1959Q2
objRange = Range(3:end); % sample
startHist = Range(1);
endHist = Range(end);
% Data = dbload('data_151127.csv','freq=',4,'dateFormat=','YYYY-MM-DD','nameRow=','date');

%% Run Kalman Filter
%
% The output data struct returned from the Kalman filter, `f`, consist by
% default of three sub-databases:
%
% * `mean` with point estimates of all model variables as tseries objects,
% * `std` with std dev of those estimates as tseries objects,
% * `mse` with the MSE matrix for backward-looking transition variables.
%
% Use the options `'output='`, `'meanOnly='`, `'returnStd='` and
% `'returnMse='` to control what is reported in the output data struct.

[~,f,v,~,pe,co] = filter(mest,Data,startHist:endHist+10,'relative=',false,'objRange=',objRange);

%% Plot Estimated Shocks
%
% The measurement shocks are kept turned off in our exercises (i.e. their
% standard errors are zero), and hence their estimates are zero throughout
% the historical sample.

list = get(mest,'elist');

dbplot(f.mean,startHist:endHist,list, ...
    'tight=',true,'zeroline=',true,'transform=',@(x) 100*x);
ftitle('Estimated shocks');

dbplot(f.mean,startHist:endHist,list, ...
    'tight=',true,'zeroLine=',true,'plotfunc=',@hist, ...
    'title',get(mest,'eDescript'),'transform=',@(x) 100*x);
ftitle('Histograms of Estimated Transition Shocks');

%% K-Step-Ahead Kalman Predictions
%
% Re-run the Kalman filter requesting now also prediction step data (see
% the option `'output='`) extended to 5 quarters ahead (see the option
% `'ahead='`). Each row of the time series returned in the `.pred`
% sub-database contains t|t-1, t|t-2, ..., t|t-k predictions.
%
% Because of the option `'meanOnly=' true` <?meanOnly?>, the filter output
% struct, `g`, only containes mean databases directly under `.pred` and
% `.smooth`, and no subdatabases `.mean` are created <?nomeansubdb?>.
%
% Use the function `plotpred` <?plotpred?> to organise and plot the data in
% a user-convenient way.

k = 8;

[~,g] = filter(mest,Data,startHist:endHist, ...
    'output=','pred,smooth','meanOnly=',true,'ahead=',k); %?meanOnly?

g %#ok<NOPTS>
g.pred %?nomeansubdb?
g.smooth

figure();
[h1,h2] = plotpred(startHist:endHist,[Data.obs_nominalrate,g.pred.obs_nominalrate]); %?plotpred?
set(h1,'marker','.');
set(h2,'linestyle',':','linewidth',1.5);
grid on;
title('Short Rates: 1- to 5-Qtr-Ahead Kalman Predictions');

%% Resimulate Filtered Data
%
% This is to illustrate that running a simulation with the initial
% conditions and shocks estimated by the Kalman filter exactly reproduces
% the historical paths of the observables.

s = simulate(mest,f.mean,startHist:endHist,'anticipate=',false);

dbfun(@(x,y) max(abs(x-y)),f.mean,s)

%% Run Counterfactual
%
% Remove the cost-push shocks from the filtered database, and re-simulate
% the historical data. This experiment shows what the data would have
% looked like if inflation had been determeined exactly by the Phillips
% curve without any cost-push shocks.

f1 = f.mean;
f1.Ep(:) = 0;

s1 = simulate(mest,f1,startHist:endHist,'anticipate=',false);

figure();
plot([s.obs_corepce,s1.obs_corepce]);
grid on;
title('Inflation, Q/Q PA');
legend('Actual Data','Counterfactual without Cost Push Shocks');

%% Simulate Contributions of Shocks
%
% Re-simulate the filtered data with the `'contributions='` option set to
% true. This returns each variable as a multivariate time series with $n+1$
% columns, where $n$ is the number of model shocks. The first $n$ columns
% are contributions of individual shocks (in order of their appearance in
% the `!transition_shocks` declaration block in the model file), the last,
% $n+1$-th column is the contribution of the initial condition and/or the
% deterministic drift.

c = simulate(mest,s,startHist:endHist+8, ...
    'anticipate=',false,'contributions=',true,'dboverlay=',true);

c %#ok<NOPTS>
c.obs_corepce

% ...
%
% To plot the shock contributions, use the function `conbar`. Plot first
% the actual data and the effect of the initial condition and deterministic
% constant (i.e. the last, $n+1$-th column in the database `c`) in the
% upper panel, and then the contributions of individual shocks, i.e. the
% first $n$ columns.

figure();

subplot(2,1,1);
plot(startHist:endHist,[s.obs_corepce,c.obs_corepce{:,end}]);
grid on;
title('Inflation, Q/Q PA');
legend('Actual data','Steady State + Init Cond', ...
    'location','northWest');

subplot(2,1,2);
barcon(startHist:endHist,c.obs_corepce{:,1:end-2});
grid on;
title('Contributions of shocks');

edescript = get(mest,'eDescript');
legend(edescript{:},'location','northWest');

%% Plot Grouped Contributions
%
% Use a `grouping` object to define groups of shocks whose contributions
% will be added together and plotted as one category. Run `eval` to create
% a new database with the contributions grouped accordingly <?groupeval?>.
% Otherwise, the information content of this figure window is the same as
% the previous one.

g = grouping(mest,'shock');
g = addgroup(g,'Measurement','lr_sh,tfp_sh,gdpdef_sh,pce_sh');
g = addgroup(g,'Demand','g_sh,rm_sh,pist_sh');
g = addgroup(g,'Supply','z_sh,zp_sh,mu_sh,laf_sh,law_sh');
g = addgroup(g,'Financial','b_sh,,sigw_sh,mue_sh,gamm_sh');

[cg,leg] = eval(g,c); %?groupeval?

figure();

subplot(2,1,1);
plot(startHist:endHist,[s.obs_corepce,c.obs_corepce{:,end-1}]);
grid on;
title('Inflation, Q/Q PA');
legend('Actual Data','Steady state + Init Cond','location','northWest');

subplot(2,1,2);
conbar(cg.obs_corepce{:,1:end-2});
grid on;
title('Contributions of Shocks');
legend(leg,'location','northWest');

%% Save Output Data for Future Use
%
% Save the output database `f` from the basic run of the filter in a
% mat-file (binary file) for future use.

save filter_hist_data.mat f;

%% Evaluate Likelihood Function and Contributions of Individual Time Periods
%
% Run the function `loglik` to evaluate the likelihood function. This
% function calls the very same Kalman filter as the function `filter`. The
% first output argument returned by `loglik` is minus the logarithm of the
% likelihood function; this value is also used as a criterion to be
% minimized (which means maximizing likelihood) within the function
% `estimate`.
%
% Set the option `'objDecomp='` to `true` <?objDecomp?> to obtain not only
% the overall likelihood, but also the contributions of individual time
% periods. They are stowed in a column vector with the overall likelihood
% at the top; the length of the vector is therefore nPer+1 <?length?> where
% nPer is the number of periods over which the filter is run.

Range = startHist:endHist+10;
nPer = length(Range)

mll = loglik(mest,Data,Range,'relative=',false,'objDecomp=',true); %?objDecomp?

size(mll) %?length?

% ...
%
% Because there were no observations available in the input database `d` in
% the last 10 periods of the filter range, i.e. `endHist+1:endHist+10`, the
% contributions of these last 10 periods are zero.

mll 

% ...
%
% Adding up the individual contributions reproduces, of course, the overall
% likelihood. The following two numbers are the same (up to rounding
% errors):

mll(1)    
sum(mll(2:end))


% ...
%
% Visualize the contributions by converting them to a tseries object, and
% plotting as a bar graph. Large bars denote periods where the model
% performed poorly (rememeber, this is MINUS the log likelihood, ie. the
% larger the number the smaller the actual likelihood). Again, the last 10
% periods are zeros because no observations were available in the input
% database in those.

x = tseries(Range,mll(2:end));
figure()
bar(x);
grid on;
title('Contributions of Individual Time Periods to (Minus Log) Likelihood');

%% Help on IRIS Functions Used in This Files
%
% Use either `help` to display help in the command window, or `idoc`
% to display help in an HTML browser window.
%
%    help model/filter
%    help model/simulate
%    help tseries/conbar
%    help tseries/plotpred
%    help grfun/movetosubplot
%    help data/dbfun
