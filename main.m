%% Clear Workspace
%
% Clear workspace, close all graphics figures, clear command window, and
% check the IRIS version.

clear; clc; close all
irisrequired 20151016

%% Read and Solve Model

o = struct; o.kimball = true; o.bgg = true; o.nant = 0;
m = model('frbny.model','assign=',o,'linear=',true);
m = steady_state(m,o.bgg);
m = solve(m);
m = sstate(m);
chksstate(m);

%% Load Historical Database
load Data
Range = dbrange(Data);
Range(1) = []; % drop 1959Q2
% Data = dbload('data_151127.csv','freq=',4,'dateFormat=','YYYY-MM-DD','nameRow=','date');

%% Define and Visualise Prior Distributions
% The function `plotpp` plots the prior distributions (this function can
% also plot the priors together with posteriors obtained from a posterior
% simulator -- see below).
E = priors(o);
% [~,~,h] = plotpp(E,[],[],'axes=',{'fontsize=',8},'title=',{'fontsize=',8},'subplot=',[4,7]);
% ftitle(h.figure,'Prior Distributions'); 
mp=get(0,'MonitorPositions');
% for i=1:numel(h.figure); h.figure(i).Position=mp(i,:); end

%% Maximise Posterior Distribution to Locate Its Mode
%
% The main output arguments are the following (these remain the same
% whatever the set-up of the estimation):
%
% * `est` -- Struct with point estimates.
% * `pos` -- Initialised posterior simulator object. The object `pos` will
% be used later in this file to run a posterior simulator.
% * `C` -- Covariance matrix of the parameter estimates based on the
% asymptotical hessian of the posterior density at its mode.
% * `H` -- Cell array 1-by-2: H{1} is the hessian of the objective function
% returned by the Optim Tbx (should be close to `C`); H{2} is a diagonal
% matrix with the contributions of the priors to the total hessian.
% * `mest` -- Model object with the new estimated parameters.

filterOpt = {'relative=',false,'objRange=',qq(1960,1):qq(2014,4)};
optimSet = {'MaxFunEvals=',10000,'MaxIter=',100,'TolFun=',1e-10,'UseParallel=',false};
tic
[est,pos,C,H,mest] = estimate(m,Data,Range,E,'filter=',filterOpt,'optimSet=',optimSet,'sstate=',{@steady_state,o.bgg},'chksstate=',true);
toc

%% User Supplied Optimisation Routine
% tic
% [PStar1,Pos1,PCov1,Hess1,mest1] = estimate(m,d,startHist:endHist,E,'filter=',filterOpt,'solver=',@mycsminwel);
% toc

%% Save and Print Estimation Results
load est P
disp('Point estimates');
disp(dbfun(@(x,y) [x,y,y-x],P,est))
P=est; save est P
disp('Parameters in the estimated model object');
disp(get(mest,'parameters')-fields(est))
%% Visualise Prior Distributions and Posterior Modes
[~,~,h] = plotpp(E,est,[], ...
    'title=',{'fontsize=',8}, ...
    'axes=',{'fontsize=',8}, ...
    'plotInit=',{'color=','red','marker=','*'}, ...
    'subplot=',[4,7]);
ftitle(h.figure,'Prior Distributions and Posterior Modes');
for i=1:numel(h.figure); h.figure(i).Position=mp(i,:); end
legend('Prior Density','Starting Value','Posterior Mode','Lower Bound','Upper Bound');

%% Covariance Matrix of Parameter Estimates
%
% Compute the std deviations of the parameter estimates by taking the
% square roots of the diagonal entries in the Hessian returned by the
% optimisation routine.

plist = fieldnames(E);
std = sqrt(diag(inv(H{1})));
disp('Std deviations of parameter estimates');
[char(plist), num2str(std,': %-g') ] %#ok<NOPTS>

%% Examine Neighbourhood Around Optimum
%
% The function `neighbourhood` evaluates the posterior density (accessible
% through the poster object `pos`) at a number of points around the optimum
% for each parameter. In the code below, each parameter estimate is
% examined within the range of +/- 5 % of the posterior mode (i.e.,
% `0.95 : 0.01 : 1.05` times the value of the estimate).
%
% The `plotneigh` function then plots graphs depicting the local
% behaviour of both the overall objective funtion (minus log posterior
% density) and the data likelihood (minus log likelihood). Note that the
% likelihood curve is shifted up or down by an arbitrary constant to make
% it fit in the graph.
%
% The option `'linkaxes'` makes the y-axes identical in all graphs to help
% compare the curvature of the posterior density around the individual
% parameter estimates. This indicates the degree of identification.

n = neighbourhood(mest,pos,0.95:0.005:1.05, ...
    'progress=',true,'plot=',false);

plotneigh(n,'linkaxes=',true,'subplot=',[4,7], ...
    'plotobj=',{'linewidth=',2}, ...
    'plotest=',{'marker=','o','linewidth=',2}, ...
    'plotbounds=',{'lineStyle','--','lineWidth',2});

%% Run Metropolis Random Walk Posterior Simulator
%
% Run 5,000 draws from the posterior distribution using an adaptive version
% of the random-walk Metropolis algorithm. The number of draws, `N=1000`,
% should be obviously much larger in practice (such as 100,000 or
% 1,000,000). Use then the function `stats` to calculate some statistics of
% the simulated parameter chains -- by default, the simulated chains, their
% means, std errors, high probability density intervals, and the marginal
% data density are returned. Feel free to change the list of requested
% characteristics; see help on `poster/stats` for details.
%
% The output argument `ar` monitors the evolution of the acceptance ratio.
% The default target acceptance ratio is 0.234 (can be modified using the
% option `'targetAR'` in `arwm`), the covariance of the proposal
% distribution is gradually adapted to achieve this target.

N = 1000

tic;
[theta,logpost,ar] = arwm(pos,N, ...
    'progress=',true,'adaptScale=',2,'adaptProposalCov=',1,'burnin=',0.20);
toc;

disp('Final acceptance ratio');
ar(end)

s = stats(pos,theta,logpost)

%% Visualise Priors and Posteriors
%
% Because the number of draws from the posterior distribution is very low,
% `N=1000`, the posterior graphs are far from being smooth, and may visibly
% change if another posterior chain is generated.

[~,~,h] = plotpp(E,est,theta, ...
    'plotprior=',{'linestyle=','--'}, ...
    'title=',{'fontsize=',8}, ...
    'subplot=',[4,7]);
ftitle(h.figure,'Prior Distributions and Posterior Distributions'); 
for i=1:numel(h.figure); h.figure(i).Position=mp(i,:); end
legend('Prior Density','Posterior Mode','Posterior Density','Lower Bound','Upper Bound');

%% Save Model Object with Estimated Parameters

save estimation mest pos E theta logpost;