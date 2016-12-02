%% More Complex Simulation Experiments
%
% Simulate the differences between anticipated and unanticipated future
% shocks, run experiments with temporarily exogenised variables, and show
% how easy it is to examine simulations with mutliple different
% parameterisations.

%% Clear Workspace
%
% Clear workspace, close all graphics figures, clear command window, and
% check the IRIS version.

clear; clc; close all
irisrequired 20151016

%% Load Solved Model Object
%
% Load the solved model object built in `read_linear_model`. Run `read_linear_model` at
% least once before running this m-file.

load read_linear_model.mat m;

%% Define Dates and Ranges

startDate = 1;
endDate = 40;
plotRng = startDate-1 : startDate+19;

%% Simulate Unanticipated Government Spending Shock

d = zerodb(m,startDate-3:startDate);
d.g_sh(startDate) = log(1.1);
s = simulate(m,d,startDate:endDate,'deviation',true);
s = dbextend(d,s);

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
dbplot(s,plotRng,plotList,'tight=',true,'transform=',@(x) 100*(exp(x)-1));
grfun.ftitle('Responses to Unanticipated Government Spending Shock');

%% Anticipated vs Unanticipated Government Spending Shock
%
% Simulate a future (3 quarters ahead) aggregate demand shock twice: as
% anticipated and unanticipated.

d = zerodb(m,startDate-3:startDate);
d.g_sh(startDate+3) = log(1.1);
s1 = simulate(m,d,startDate:endDate,'deviation=',true,'anticipate=',true);
s1 = dbextend(d,s1);

s2 = simulate(m,d,startDate:endDate,'deviation=',true,'anticipate=',false);
s2 = dbextend(d,s2);

dbplot(s1 & s2,plotRng,plotList, ...
    'tight=',true,'transform=',@(x) 100*(exp(x)-1));
grfun.ftitle('Government Spending Shock: Anticipated vs Unanticipated');
grfun.bottomlegend('Anticipated','Unanticipated');

%% Simulate Government Spending Shock with Delayed Policy Reaction
%
% Simulate a demand shock and, at the same time, delay the policy
% reaction (by exogenising the policy rate to its pre-shock level for 3
% periods). Again, this can be done in an anticipated mode and
% unanticipated mode.
%
% * <?immediate?> Simulates demand shocks with immediate policy
% reaction.
% * <?delayedanticipated?> Simulates the same shock with delayed policy
% reaction that is announced and anticipated from the beginning.
% * <?delayedunanticipated?> Simulates the same shock with delayed policy
% reaction that takes everyone by surprise every quarter.

nPer = 3;

d = zerodb(m,startDate-3:startDate);
d.g_sh(startDate) = log(1.1);

p = plan(m,startDate:endDate);
p = exogenise(p,'R_s',startDate:startDate+nPer-1);
p = endogenise(p,'rm_sh',startDate:startDate+nPer-1);
d.R_s(startDate:startDate+nPer-1) = 0;

s1 = simulate(m,d,startDate:endDate, ... %?immediate?
   'deviation',true);
s1 = dbextend(d,s1);

s2 = simulate(m,d,startDate:endDate, ... %?delayedanticipated?
   'deviation',true,'plan',p);
s2 = dbextend(d,s2);

s3 = simulate(m,d,startDate:endDate, ... %?delayedunanticipated?
   'deviation',true,'plan',p,'anticipate',false);
s3 = dbextend(d,s3);

dbplot(s1 & s2 & s3,plotRng,plotList, ...
    'tight=',true,'transform=',@(x) 100*(exp(x)-1));
grfun.ftitle('Government Spending Shock with Delayed Policy Reaction');
grfun.bottomlegend('No delay','Anticipated','Unanticipated');

%% Simulate Government Spending Shock with Desired Impact
%
% Find the size of a government spending shock such that it leads to exactly
% a 1 pct increase in government spending in the first period.

d = zerodb(m,startDate-3:startDate);
d.c_s(startDate) = 0.01;

p = plan(m,startDate:endDate);
p = exogenise(p,'c_s',startDate);
p = endogenise(p,'g_sh',startDate);
s = simulate(m,d,startDate:endDate,'deviation=',true,'plan=',p);
s = dbextend(d,s);

disp(s.g_sh{1:10});

dbplot(s,plotRng,plotList,'tight=',true,'transform=',@(x) 100*(exp(x)-1));
grfun.ftitle('Government Spending Shock with Exact Impact');

%% Simulate Government Spending Shocks with Multiple Parameterisations
%
% Within the same model object, expand the number of its parameterisations,
% and assign different sets of values to some (or all) of the parameters
% (here, only the values for `xi` vary, i.e. the price adjustment costs).
% Solve and simulate all these different parameterisations at once. Note
% that virtually all IRIS functions support multiple parameterisations.

m(1:8) = m;
m.zeta_p = 0.1:0.1:0.8;
if islinear(m)
    m = solve(m);
    m = sstate(m);
else
    m = sstate(m);
    m = solve(m);
end
disp(m);

d = zerodb(m,startDate-3:startDate);
d.g_sh(1,:) = log(1.1);

s = simulate(m,d,startDate:endDate,'deviation=',true);
s = dbextend(d,s);

dbplot(s,plotRng,plotList,'tight=',true,'transform=',@(x) 100*(exp(x)-1));
grfun.ftitle('Government Spending Shock with Mutliple Parameterisations');
legend(sprintfc('\\zeta_p=%g',m.zeta_p),'location','northWest');

%% Help on IRIS Functions Used in This File
%
% Use either `help` to display help in the command window, or `idoc`
% to display help in an HTML browser window.
%
%    help model/dbextend
%    help model/simulate
%    help model/solve
%    help model/subsasgn
%    help model/zerodb
%    help qreport/qplot
%    help grfun/ftitle
%    help dbextend
