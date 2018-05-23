%% Simulate Simple Shock Responses
%
% Simulate a simple shock both as deviations from control, and report
% the simulation results.

%% Clear Workspace
%
% Clear workspace, close all graphics figures, clear command window, and
% check the IRIS version.

clear; clc; close all
irisrequired 20170320

%% Load Estimated Model Object
%
% Load the model object estimated in `estimate_params.m`.
% Run `estimate_params` at least once before running this m-file.

load estimate_params.mat mest;

%% Define Dates
%
% Define the start and end dates as plain numbered periods here.

startDate = 0;
endDate = 40;

%% Simulate Shocks (Figures 2-8 of Staff Report 647)
if exist('irf.ps','file'); delete('irf.ps'); end
shock_list=[get(mest,'eList');get(mest,'eDesc')];
for sh = shock_list(:,[10 3 4 8 6 1 7])
    % the impulse responses of the variables used in the estimation to a onestandard-
    % deviation innovation in the spread shock.
    d = zerodb(mest,startDate:endDate);
    d.(sh{1})(startDate) = mest.(['std_' sh{1}]);
    s = simulate(mest,d,startDate:endDate,'deviation=',true);

    %% Report Simulation Results
    %
    % Use the `dbplot` function to create a quick report of simulation results.

    plotRng = startDate : startDate+14;
    plotList = { ...
        ' "Output Growth" 4*obs_gdp ', ...
        ' "Aggregate Hours" obs_hours ', ...
        ' "Labor Share" 4*obs_wages ', ...
        ' "Core PCE Inflation" 4*obs_corepce ', ...
        ' "Nominal Interest Rate" 4*obs_nominalrate ', ...
        ' "Consumption Growth" 4*obs_consumption ', ...
        ' "Investment Growth" 4*obs_investment ', ...
        ' "Spread" 4*obs_spread ', ...
        ' "TFP" 4*obs_tfp ', ...
       };
    dbplot(s,plotRng,plotList,'tight=',true,'figure=',{'position=',get(0,'ScreenSize')},'zeroline=',true);
    title=['Responses to ' sh{2}];
    ftitle(title);
    print('irf.ps', '-dpsc', '-append', '-fillpage')
end