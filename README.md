# FRBNY-IRIS
FRBNY model in IRIS

frbny.model is the model file for IRIS toolbox. It initializes all parameters, lists endogenous variables and exogenous shocks in FRBNY model's linear and nonlinear equations.

main.m is the main program that checks that linear and nonlinear models replicate policy functions and impulse responses.

save_simulation.m - run this file after gensys in dsgesolv.m (line 105) to save impulse responses in irf.mat

check_gensys.m - replicates impulse responses in IRIS and compares them with irf.mat
