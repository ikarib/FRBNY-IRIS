# FRBNY-IRIS
FRBNY model in IRIS

https://iristoolbox.codeplex.com/

frbny.model is the model file for IRIS toolbox. It initializes all parameters, lists endogenous variables and exogenous shocks in FRBNY model's linear and nonlinear equations.

estimate_params.m - main program that reads the model file (linear or nonlinear version), runs estimation and does MH sampling. Optimization in IRIS is done using fmincon which is about 30 times faster than using csminwel with gensys. Hessian is computed during optimization so no need to recompute it separately. Zero lower bound in not implemented yet.

filter_hist_data.m - shock decomposition and historical simulations

estimate_params.mat - contains the parameter struct est with the max posterior mode

priors.m - contains the priors and lower and upper bounds on parameters

These programs require my IRIS fork which is available at https://iristoolbox.codeplex.com/SourceControl/network/forks/ikarib/IRISdev

Unconstrained minimization algorithm such as csminwel requires rescaling of constrained parameters. The problem is that we don't know if any of the constraints will become binding at the mode. For example, parameter rho_sigw becomes binding at the upper boundary 0.99 that was imposed in original v990 code. That caused the algorithm to slow down to a crawl since the unscaled parameter tried to go to infinity. I therefore had to increase this upper limit to 0.999. As a result the Julia csminwel code which was running several days, now runs in 4 hours after binding constraint on rho_sigw was removed. We can avoid this problem in IRIS by using constrained minimization method such as fmincon (with active-set algorithm), which can estimate the model in 5 minutes.
