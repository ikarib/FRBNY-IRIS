# FRBNY-IRIS
FRBNY model in IRIS

https://iristoolbox.codeplex.com/

frbny.model is the model file for IRIS toolbox. It initializes all parameters, lists endogenous variables and exogenous shocks in FRBNY model's linear and nonlinear equations.

main.m - main program that reads the model file and runs estimation and MH samples

Auxiliary files for replication checks:
check_loglin.m - checks for log-linearization of nonlinear model by comparing state space matrices
check_gensys.m - solves and simulates the linear model in IRIS using shocks from irf.mat and checks for replication of impulse responses
check_filter.m - checks Kalman filter output
