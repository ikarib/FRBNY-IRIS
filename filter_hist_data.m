%% Kalman Filtering and Historical Simulations
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
irisrequired 20170320
%#ok<*EVLC> 

%% Load Estimated Model Object and Historical Database
%
% Load the model object estimated in `estimate_params.m`, and the
% historical database created in `read_data`. Run `estimate_params` at
% least once before running this m-file.

load estimate_params.mat mest o;
load read_data.mat d startHist endHist;

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

J = struct;
for v=sprintfc('std_rm_sh%d',1:o.nant)
    J.(v{1})=tseries(startHist-1:qq(2008,3),0);
end
filterOpt = {'relative=',false,'objRange=',startHist+2:endHist,'vary=',J};
[~,f] = filter(mest,d,startHist:endHist+10,filterOpt);

%% Plot Estimated Shocks
%
% The shocks to spread and net worth are kept turned off in our exercises
% (i.e. their standard errors are zero), and hence their estimates are zero
% throughout the historical sample.

list = get(mest,'elist');
[list,ilist] = setdiff(list,['mue_sh','gamm_sh',sprintfc('rm_sh%d',3:o.nant)],'stable');
list_title = get(mest,'eDescript');
list_title = list_title(ilist);

dbplot(f.mean,startHist:endHist,list, ...
    'tight=',true,'zeroline=',true, ...
    'title',list_title,'DateFormat=','yy');
ftitle('Estimated shocks');

dbplot(f.mean,startHist:endHist,list, ...
    'tight=',true,'zeroLine=',true,'plotfunc=',@hist, ...
    'title',list_title);
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

[~,g] = filter(mest,d,startHist:endHist,filterOpt{:}, ...
    'output=','pred,smooth','meanOnly=',true,'ahead=',k); %?meanOnly?

g %#ok<NOPTS>
g.pred %?nomeansubdb?
g.smooth

figure();
[h1,h2] = plotpred(startHist:endHist,[d.obs_nominalrate,g.pred.obs_nominalrate]); %?plotpred?
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
f1.laf_sh(:) = 0;

s1 = simulate(mest,f1,startHist:endHist,'anticipate=',false);

figure();
dbplot(s&s1,inf,{'obs_corepce*4'});
grid on;
title('Core PCE Inflation, Q/Q PA');
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
plotrange = qq(2007,1):endHist;
ftitle('Shock Decomposition');
nz=any(c.obs_gdp)|any(c.obs_corepce)|any(c.obs_nominalrate); nz(end-1)=0;
colormap([hsv(sum(nz)-7);0 0 0;ones(6,3)])

subplot(1,3,1);
barcon(plotrange,c.obs_gdp{:,nz}*4); grid on; hold all; % ,'evenlySpread=',false
plot(plotrange,(s.obs_gdp-c.obs_gdp{:,end-1})*4,{'k-'},'LineWidth',2);
title('Output Growth, Q/Q PA');
edescript = get(mest,'eDescript');
legend(edescript{nz},'location','southEast');

subplot(1,3,2);
barcon(plotrange,c.obs_corepce{:,nz}*4); grid on; hold all;
plot(plotrange,(s.obs_corepce-c.obs_corepce{:,end-1})*4,{'k-'},'LineWidth',2);
title('Core PCE Inflation, Q/Q PA');

subplot(1,3,3);
barcon(plotrange,c.obs_nominalrate{:,nz}*4); grid on; hold all;
plot(plotrange,(s.obs_nominalrate-c.obs_nominalrate{:,end-1})*4,{'k-'},'LineWidth',2);
title('Interest Rate, Q/Q PA');

%% Plot Grouped Contributions
%
% Use a `grouping` object to define groups of shocks whose contributions
% will be added together and plotted as one category. Run `eval` to create
% a new database with the contributions grouped accordingly <?groupeval?>.
% Otherwise, the information content of this figure window is the same as
% the previous one.

g = grouping(mest,'shock');
g = addgroup(g,'Policy','g_sh,rm_sh,pist_sh');
g = addgroup(g,'TFP','z_sh,zp_sh,mu_sh');
g = addgroup(g,'Cost & wage push','laf_sh,law_sh');
g = addgroup(g,'Financial','b_sh,sigw_sh,mue_sh,gamm_sh');
g = addgroup(g,'Measurement','lr_sh,tfp_sh,gdpdef_sh,pce_sh');
g = addgroup(g,'Anticipated MP shocks','rm_sh1,rm_sh2,rm_sh3,rm_sh4,rm_sh5,rm_sh6');
detail(g)

[cg,leg] = eval(g,c); %?groupeval?
leg = [leg 'Actual Data (ss dev)'];

figure();
plotrange = qq(2007,1):endHist;
ftitle('Shock Decomposition');
colormap([hsv(numel(leg)-2); 1 1 1])

subplot(1,3,1);
barcon(plotrange,cg.obs_gdp{:,1:end-2}*4); grid on; hold all;
plot(plotrange,(s.obs_gdp-c.obs_gdp{:,end-1})*4,{'k-'},'LineWidth',2);
title('Output Growth, Q/Q PA');
legend(leg,'location','southEast');

subplot(1,3,2);
barcon(plotrange,cg.obs_corepce{:,1:end-2}*4); grid on; hold all;
plot(plotrange,(s.obs_corepce-c.obs_corepce{:,end-1})*4,{'k-'},'LineWidth',2);
title('Core PCE Inflation, Q/Q PA');

subplot(1,3,3);
barcon(plotrange,cg.obs_nominalrate{:,1:end-2}*4); grid on; hold all;
plot(plotrange,(s.obs_nominalrate-c.obs_nominalrate{:,end-1})*4,{'k-'},'LineWidth',2);
title('Interest Rate, Q/Q PA');

%% Save Output Data for Future Use
%
% Save the output database `f` from the basic run of the filter in a
% mat-file (binary file) for future use.

save filter_hist_data.mat f;

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
