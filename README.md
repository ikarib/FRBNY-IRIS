# FRBNY-IRIS
FRBNY model in IRIS

https://iristoolbox.codeplex.com/

frbny.model is the model file for IRIS toolbox. It initializes all parameters, lists endogenous variables and exogenous shocks in FRBNY model's linear and nonlinear equations.

estimate_params.m - main program that reads the model file (linear or nonlinear version), runs estimation and does MH sampling. Optimization in IRIS is done using fmincon which is about 30 times faster than using csminwel with gensys. Hessian is computed during optimization so no need to recompute it separately. Zero lower bound in not implemented yet.

filter_hist_data.m - shock decomposition and historical simulations

estimate_params.mat - contains the parameter struct est with the max posterior mode

priors.m - contains the priors and lower and upper bounds on parameters

These programs require my IRIS fork which is available at https://iristoolbox.codeplex.com/SourceControl/network/forks/ikarib/IRISdev

The problem with csminwel is by being unconstrained minimization algorithm, we don't know if any of the constraints will become binding at the mode. For example, parameter \rho_sigw becomes binding at upper level 0.99. Then the algorithm slows down to a crawl since the unscaled parameter tries to go to infinity. We therefore have to change the limit to 0.999, but we don't know this beforehand.
