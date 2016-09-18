# FRBNY-IRIS
FRBNY model in IRIS

https://iristoolbox.codeplex.com/

frbny.model is the model file for IRIS toolbox. It initializes all parameters, lists endogenous variables and exogenous shocks in FRBNY model's linear and nonlinear equations.

main.m - checks for log-linearization of nonlinear model by comparing state space matrices

save_simulation.m - run this file after gensys is done in dsgesolv.m (line 105) to save impulse responses in irf.mat

check_gensys.m - solves and simulates the linear model in IRIS using shocks from irf.mat and checks for replication of impulse responses
