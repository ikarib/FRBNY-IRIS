%% Monte-Carlo Stochatic Simulations
%
% Draw random time series from the model distribution, and compare their
% sample properties against the unconditional model-implied models. Keep in
% mind that this is a purely simulation exercise, and no observed data
% whatsoever are involved.

%% Clear Workspace
%
% Clear workspace, close all graphics figures, clear command window, and
% check the IRIS version.

clear; clc; close all
irisrequired 20151016
%#ok<*NOPTS>
 
%% Load Solved model
%
% Load the solved model object built in `read_linear_model`. Run `read_linear_model` at
% least once before running this m-file.

load read_linear_model.mat m;

%% Define Dates

startDate = qq(1991,1);
endDate = qq(2020,4);

%% Set Standard Deviations of Shocks
%
% No std deviations or cross-correlation coefficients have been assigned
% yet -- in that case, std devs are 0.01 and corr coeffs are 0 by default.
% Later on, these will be estimated; now, simply pick some values for them.
% Note the double underscore separating the names of shocks when referring
% to a corr coeff.
%
% In general, after changing some parameters the steady state and model
% solution need to be re-calculated. However, std devs and corr coeff have
% no impact on the steady state or solution so go ahead without running
% `sstate` or `solve`.
%
% <?getstd?> This `get` command returns a database with the currently
% assigned std deviations.
%
% <?getstd?> This `get` command returns a database with the currently
% assigned non-zero cross-correlations.

get(m,'std') %?getstd?
get(m,'nonzerocorr') %?getnonzerocorr?

% m.std_g_sh = 2.5;
% m.corr_g_sh__rm_sh = 0.25;

% get(m,'std') %?getstd?
% get(m,'nonzerocorr') %?getnonzerocorr?

%% Draw Random Time Series from Model Distribution
%
% A total of `N` = 1,000 different time series samples for each variables
% will be generated from the model distribution, each 30 years (120
% quarters) long.

J = struct();
J.std_g_sh = tseries();
J.std_g_sh(startDate+(1:3)) = 3;

N = 1000;
d = resample(m,[],startDate:endDate,N,J,'progress=',true);

%% Re-Simulate Data
%
% If the resampled database, `d`, is used as an input database in
% `simulate`, the simulated database will simply reproduce the paths. Note
% that only initial condition and shocks are taken from the input
% database. The paths for the endogenous variables contained in the input
% database are completely ignored, and not used at all.
%
% Also, remember to set `'anticipate=' false` because `resample` produces
% unanticipated shocks.

d1 = simulate(m,d,startDate:endDate,'anticipate=',false,'progress=',true);

maxabs(d,d1)

%% Compute Sample Properties of Simulated Time Series
%
% Calculate the sample mean, and use the `acf` function to calculate the
% std dev and autocorrelation coefficients for the twelve measurement
% variables.

smean = struct();
sstd = struct();
sauto = struct();

v = get(m,'yList');
nv = numel(v);
for i = 1 : nv
    smean.(v{i}) = mean(d.(v{i}));
    [c,r] = acf(d.(v{i}),Inf,'order',1);
    sstd.(v{i}) = sqrt(diag(c(:,:,1)).');
    sauto.(v{i}) = diag(r(:,:,2));
end

smean
sstd
sauto

%% Compute Corresponding Asymptotic Properties Analytically

amean = struct();
astd = struct();
aauto = struct();

[C,R] = acf(m,'order',1,'select=',v,'matrixFmt=','plain');

for i = 1 : nv
    amean.(v{i}) = m.(v{i});
    astd.(v{i}) = sqrt(C(i,i,1));
    aauto.(v{i}) = R(i,i,2);
end

amean
astd
aauto

%% Plot Sample and Asymptotic Properties

maxplots = 2;
ncols = ceil(nv/maxplots);
for plotnum = 1 : maxplots
    figure
    for i = 1 : min(ncols,nv-ncols*(plotnum-1))
        vi = v{i+ncols*(plotnum-1)};

        subplot(3,ncols,i);
        [y,x] = hist(smean.(vi),20);
        bar(x,y,1);
        hold('all');
        stem(amean.(vi),1.1*max(y),'color','red','lineWidth',2);
        title(vi,'Interpreter','none');
        if i==1; ylabel('Mean'); end

        subplot(3,ncols,i+ncols);
        [y,x] = hist(sstd.(vi),20);
        bar(x,y,1);
        hold('all');
        stem(astd.(vi),1.1*max(y),'color','red','lineWidth',2);
        title(vi,'Interpreter','none');
        if i==1; ylabel('Std Dev'); end

        subplot(3,ncols,i+2*ncols);
        [y,x] = hist(sauto.(vi),20);
        bar(x,y,1);
        hold('all');
        stem(aauto.(vi),1.1*max(y),'color','red','lineWidth',2);
        title(vi,'Interpreter','none');
        if i==1; ylabel('Autocorr'); end
    end
end

%% Compute Contributions of Individual Shocks to ACFs Analytically

cstd = struct();
cauto = struct();

[C_,R_] = acf(m,'order',1,'select=',v,'matrixFmt=','plain','contributions=',true);

for i = 1 : nv
    cstd.(v{i}) = squeeze(C_(i,i,1,:))/C(i,i,1);
    cauto.(v{i}) = squeeze(R_(i,i,2,:));
end

cstd
cauto

%% Plot Contributions to ACFs

figure
labels = strrep(get(m,'eList'),'_sh','');
explode = strcmpi(labels,'g');
cap=autocaption(m,v,'$descript$');
for i=1:nv
    subplot(3,4,i)
    pie(cstd.(v{i}),explode,labels)
    title(cap{i})
end



%% Help on IRIS Functions Used in This File
%
% Use either `help` to display help in the command window, or `idoc`
% to display help in an HTML browser window.
%
%   help model/acf
%   help model/get
%   help model/resample
%   help model/subsasgn
%   help tseries/acf
%   help select