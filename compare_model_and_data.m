%% Compare Second Moment Properties in Model and Data
%
% Compute and compare several second-moment properties of the estimated
% model and the data. Describe the data using an estimated VAR; this also
% allows to evaluate sampling uncertainty of the empirical estimates using
% bootstrap methods.

%% Clear Workspace
%
% Clear workspace, close all graphics figures, clear command window, and
% check the IRIS version.

clear; clc; close all
irisrequired 20151016

%% Load Estimated Model Object, and Historical Database
%
% Load the model object estimated in `estimate_params`, and the historical
% database created in `read_data`. Run `estimate_params` and
% `filter_hist_data` at least once before running this m-file.

load estimate_params.mat mest;
load read_data.mat d startHist endHist;

%% Estimate VAR and BVAR
%
% Estimate an unrestricted 2nd-order VAR, and a 2nd-order Bayesian VAR with
% Litterman-type priors. First, create an empty VAR object <?emptyvar?>
% specifying the names of the endogenous variables. The names are identical
% to the names of measurement variables in the DSGE model <?ylist?>.
% Second, call the function `estimate` with an input database. For bayesian
% VARs, create prior dummy observations before running `estimate`
% <?priordummy?>.

ylist = get(mest,'yList'); %?ylist?

p = 2;

v = VAR(ylist) %#ok<NOPTS> %?emptyvar?
[v,vdata] = estimate(v,d,startHist:endHist,'order=',p);
v %#ok<NOPTS>

X = BVAR.litterman(0,sqrt(30),0) %#ok<NOPTS> %?priordummy?

bv = VAR(ylist) %#ok<NOPTS>
[bv,bvdata] = estimate(bv,d,startHist:endHist,'order=',p, ...
    'BVAR=',X,'stdize=',true);
bv %#ok<NOPTS>

%% Compare Transition Matrices
%
% Get and print the transition matrices from the plain VAR and the BVAR
% objects. The transition matrices are Ny-by-Ny-by-P matrices, where Ny is
% the number of variables, and P is the order of the VAR.

A = get(v,'A*');
BA = get(bv,'A*');

disp('Unrestricted VAR transition matrix');
A(:,:,1)
A(:,:,2)
disp('BVAR transition matrix');
BA(:,:,1)
BA(:,:,2)

%% Compare Residuals
%
% Plot and compare the estimated residuals from the plain VAR and the BVAR.
% Use the output data, `vdata` and `bvdata` returned from `estimate`. These
% databases containing both the endogenous variables and estimated
% residuals. By default, the residuals are named `res_XXX` where `XXX` is
% the name of the respective variable,

elist = get(v,'eList');

figure();
for i = 1 : 4
    name = elist{i};
    subplot(2,2,i);
    plot(vdata.(name));
    hold all;
    plot(bvdata.(name));
    title(name,'interpreter','none');
    grid on;
    axis tight;
end
grfun.bottomlegend('Unrestricted VAR(2)','BVAR(2)');

%% Resample From Estimated VAR
%
% Use a wild bootstrap to generate `N=500` of VARs; a wild bootstrap is
% robust to potential heteroscedasticity of residuals. Note that some of
% the resampled VAR parameterisations may be explosive, and remove them
% from the VAR object.

N = 1000;
Y = resample(v,vdata,Inf,N,'wild=',true,'progress=',true);
size(Y)

Nv = VAR(ylist);
Nv = estimate(Nv,Y,Inf,'order=',p);

inx = isstationary(Nv);
sum(inx)
Nv = Nv(inx);

%% Compare ACF From Model and Data
%
% Compute and plot the autocovariance/autocorrelation functions (ACF)
% for the estimated VAR, the resampled VARs, and the model.
%
% Comments on the code below:
%
% * <?helper_plot_acf?> `helper_plot_acf` is a helper function (for
% plotting ACFs) created just for this exercise (it is not part of the IRIS
% toolbox).

[Cv,Rv] = acf(v,'order=',1);
[CNv,RNv] = acf(Nv,'order=',1);
[Cm,Rm] = acf(mest,'order=',1,'select=',ylist);

figure();
n = length(ylist);
for i = 1 : n
    for j = i : n
        subplot(n,n,(i-1)*n+j);
        helper_plot_acf(CNv(i,j,1,:),Cv(i,j,1),Cm(i,j,1)); %?helper_plot_acf?
        title(sprintf('%s x %s',ylist{i},ylist{j}),'Interpreter','none');
    end
end

grfun.bottomlegend( ...
    'VAR: Bootstrap','VAR: Point Estimate','Model: Asymptotic');
grfun.ftitle('Estimated Cross-covariances');

%% Compare Frequency Selective ACF
%
% Use the `'filter='` option to compute the ACF (both from the strucural
% model and the VAR) that corresponds to cyclical fluctuations with
% periodicity between 4 and 40 quarters (1 to 10 years).

[Cv1,Rv1] = acf(v,'order=',1,'filter=','per <= 40 & per > 4');
[Cv2,Rv2] = acf(v,'order=',1,'filter=','per > 40');
[Cv3,Rv3] = acf(v,'order=',1,'filter=','per <= 4');

maxabs(Cv1+Cv2+Cv3 - Cv)

[CNv1,RNv1] = acf(Nv,'filter=','per <= 40 & per > 4','progress=',true);

[Cm1,Rm1] = acf(mest,'filter=','per <= 40 & per > 4','select=',ylist);

figure();
for i = 1 : n
    for j = i : n
        subplot(n,n,(i-1)*n+j);
        helper_plot_acf(CNv1(i,j,1,:),Cv(i,j,1),Cm1(i,j,1));
        title(sprintf('%s x %s',ylist{i},ylist{j}));
    end
end

grfun.bottomlegend( ...
    'VAR: Bootstrap','VAR: Point Estimate','Model: Asymptotic');
grfun.ftitle( ...
    'Estimated Cross-covariances for Periodicities Below 40 Qtrs');

%% Compare VAR and Model Spectra
%
% Compute and plot the power spectra and spectral densities for the
% estimated VAR and for the model.
%
% Comments on the code below:
%
% * <?helper_plot_xsf?> `helper_plot_xsf` is a helper function (for
% plotting the spectral densities) created just for this exercise in this
% directory (it is not part of the IRIS toolbox); it can be opened and
% viewed in the Matlab editor.

freq = 0 : 0.05 : pi;
[Pv,Sv] = xsf(v,freq);
[Pm,Sm] = xsf(mest,freq,'select=',ylist);

figure();
k = floor(sqrt(9/16*n));
for i = 1 : n
    subplot(k,ceil(n/k),i);
    helper_plot_xsf(freq,Sv(i,i,:),Sm(i,i,:)); %?helper_plot_xsf?
    title(sprintf('Spect density %s',ylist{i}),'Interpreter','none');
end

grfun.bottomlegend('VAR: Point Estimate','Model: Asymptotic');
grfun.ftitle('Estimated Spectral Densities');

%% Help on IRIS Functions Used in This Files
%
% Use either `help` to display help in the command window, or `idoc`
% to display help in an HTML browser window.
%
%    help VAR
%    help VAR/estimate
%    help VAR/get
%    help VAR/isstationary
%    help VAR/resample
%    help VAR/subsasgn
%    help VAR/acf
%    help VAR/xsf
%    help model/acf
%    help model/xsf
%    help grfun/bottomlegend
%    help grfun/ftitle

