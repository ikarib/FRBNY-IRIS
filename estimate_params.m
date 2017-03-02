%% Run Bayesian Parameter Estimation
%
% Use bayesian methods to estimate some of the parameters. First, set up
% our priors about the individual parameters, and locate the posterior
% mode. Then, run a posterior simulator (adaptive random-walk Metropolis)
% to obtain the whole distributions of the parameters.

%% Clear Workspace
%
% Clear workspace, close all graphics figures, clear command window, and
% check the IRIS version.

clear; clc; close all
irisrequired 20170224
%#ok<*NOPTS>

%% Load Solved Model Object and Historical Database
%
% Load the solved model object built `read_linear_model`, and the example database
% created in `read_data`. Run `read_linear_model` and `read_data` at least once
% before running this m-file.

load read_linear_model.mat;
load read_data.mat d startHist endHist;

%% Set Up Estimation Input Structure
reoptimize = 0;
if reoptimize
    init = get(m,'parameters');
else
    load estimate_params.mat est
    init = est;
end
E = priors(init,o);
disp(E)

%% Visualise Prior Distributions
%
% The function `plotpp` plots the prior distributions (this function can
% also plot the priors together with posteriors obtained from a posterior
% simulator -- see below).
[~,~,h] = plotpp(E,[],[],'subplot=',[4,7],'figure=',{'position=',get(0,'ScreenSize')});
ftitle(h.figure,'Prior Distributions');

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

J = struct;
for v=sprintfc('std_rm_sh%d',1:o.nant)
    J.(v{1})=tseries(startHist:qq(2008,3),0);
end
filterOpt = {'relative=',false,'objRange=',startHist+2:endHist,'vary=',J};
optimSet = optimset('Algorithm','interior-point','Display','iter','TolFun',1e-16,'MaxFunEvals',20000,'UseParallel',false);
tic
[est,pos,C,H,mest] = estimate(m,d,startHist:endHist,E,'filter=',filterOpt,'optimSet=',optimSet,'sstate=',true,'nosolution=','penalty','optimiser=',{@knitronlp,'knitronlp.opt'});
toc

%% Print Estimation Results
disp('Point estimates');
disp(dbfun(@(x,y) [x,y,y-x],init,est))

disp('Parameters in the estimated model object');
disp(get(mest,'parameters')-fields(est))

%% Visualise Prior Distributions and Posterior Modes
%
% Use the function `plotpp` again supplying now the struct `est` with the
% estimated posterior modes as the second input argument. The posterior
% modes are added as stem graphs, and the estimated values are included in
% the graph titles.

[~,~,h] = plotpp(E,est,[], ...
    'plotInit=',{'color=','red','marker=','*'}, ...
    'figure=',{'position=',get(0,'ScreenSize')}, ...
    'subplot=',[4,7]);
ftitle(h.figure,'Prior Distributions and Posterior Modes');
legend('Prior Density','Starting Value','Posterior Mode','Lower Bound','Upper Bound');

%% Covariance Matrix of Parameter Estimates
%
% Compute the std deviations of the parameter estimates by taking the
% square roots of the diagonal entries in the Hessian returned by the
% optimisation routine.

plist = fieldnames(E);
std = sqrt(diag(C));
disp('Std deviations of parameter estimates');
[char(plist), num2str(std,': %-g') ]

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
% [theta,logpost,ar] = arwm(pos,N, ...
%     'progress=',true,'adaptScale=',2,'adaptProposalCov=',1,'burnin=',0.20);
[theta,logpost,ar] = arwm(pos,N,'estTime=',true,'adaptScale=',0,'adaptProposalCov=',0,'burnin=',0.1,'firstPrefetch=',Inf,'initScale=',.09);
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
    'figure=',{'position=',get(0,'ScreenSize')}, ...
    'plotInit=',false, ...
    'subplot=',[4,7]);

ftitle(h.figure,'Prior Distributions and Posterior Distributions'); 

legend('Prior Density','Posterior Mode','Posterior Density', ...
    'Lower Bound','Upper Bound');

%% Save Model Object with Estimated Parameters

save estimate_params.mat est mest o pos E theta logpost;

%% Help on IRIS Functions Used in This File
%
% Use either `help` to display help in the command window, or `idoc`
% to display help in an HTML browser window.
%
%    help model/estimate
%    help model/neighbourhood
%    help poster/arwm
%    help poster/stats
%    help grfun/plotpp
%    help logdist
%    help logdist.normal
%    help logdist.lognormal
%    help logdist.beta
%    help logdist.gamma
%    help logdist.invgamma
%    help logdist.uniform
