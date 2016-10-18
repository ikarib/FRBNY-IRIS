# FRBNY-IRIS
FRBNY model in IRIS

https://iristoolbox.codeplex.com/

main.m - main program that reads the model file (linear or nonlinear version), runs estimation and MH samples
frbny.model - this is the model file for IRIS toolbox. It initializes all parameters, lists endogenous variables and exogenous shocks in FRBNY model's linear and nonlinear equations.
steady_state.m - this file is needed only for linear version of the model since the model file contains only steady state equations only for nonlinear version
est.mat - contains the parameter struct with the max posterior mode
priors.m - contains the priors and bounds


Auxiliary files for replication checks:
check_loglin.m - checks for log-linearization of nonlinear model by comparing state space matrices
check_gensys.m - solves and simulates the linear model in IRIS using shocks from irf.mat and checks for replication of impulse responses
check_filter.m - checks Kalman filter output
