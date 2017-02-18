function E = priors(P,o)
%% Set Up Estimation Input Structure
%
% The estimation input struct describes which parameters to estimate and
% how to estimate them. A struct needs to be created with one field for
% each parameter that is to be estimated. Each parameter can be then
% assigned a cell array with up to four pieces of information:
%
%    E.parameter_name = {starting}
%    E.parameter_name = {starting,lower}
%    E.parameter_name = {starting,lower,upper}
%    E.parameter_name = {starting,lower,upper,logdist}
%
% where `starting` is a starting value for the iteration, `lower` and
% `upper` are the lower and upper bounds, respectively, and `logdist` is a
% function handle taking one input and returning the log prior density.
%
% If the starting value is `NaN`, then the currently assigned parameter
% value (from the model object) is used. The constants `-Inf` and `Inf` can
% be used for the lower and upper bounds, respectively. Use the `logdist`
% package to set up the log-prior function handles.

E = struct();
E.alp = {P.alp, 1E-5, .999, logdist.normal(.3,.05)};
E.zeta_p = {P.zeta_p, 1E-5, .999, logdist.beta(.5,.1)};
E.iota_p = {P.iota_p, 1E-5, .999, logdist.beta(.5,.15)};
% E.ups = {P.ups, 1E-5, Inf, logdist.gamma(1,.5)};
E.Bigphi = {P.Bigphi, 1, Inf, logdist.normal(1.25,.12)};
E.s2 = {P.s2, -Inf, Inf, logdist.normal(4,1.5)};
E.h = {P.h, 1E-5, .999, logdist.beta(.7,.1)};
E.ppsi = {P.ppsi, 1E-5, .999, logdist.beta(.5,.15)};
E.nu_l = {P.nu_l, 1E-5, Inf, logdist.normal(2,.75)};
E.zeta_w = {P.zeta_w, 1E-5, .999, logdist.beta(.5,.1)};
E.iota_w = {P.iota_w, 1E-5, .999, logdist.beta(.5,.15)};
E.bet_ = {P.bet_, 1E-5, Inf, logdist.gamma(.25,.1)};
E.psi1 = {P.psi1, 1E-5, Inf, logdist.normal(1.5,.25)};
E.psi2 = {P.psi2, -Inf, Inf, logdist.normal(.12,.05)};
E.psi3 = {P.psi3, -Inf, Inf, logdist.normal(.12,.05)};
% E.pistar_ = {P.pistar_, 1E-5, Inf, logdist.gamma(.75,.4)};
E.sigmac = {P.sigmac, 1E-5, Inf, logdist.normal(1.5,.37)};
E.rho = {P.rho, 1E-5, .999, logdist.beta(.75,.1)};
% Priors on Financial Frictions Parameters
% E.Fom_ = {P.Fom_, 1E-5, .99, logdist.beta(.03,.01)};
E.sprd_ = {P.sprd_, 1E-5, Inf, logdist.gamma(2,.1)};
E.zeta_spb = {P.zeta_spb, 1E-5, .99, logdist.beta(.05,.005)};
% E.gammstar = {P.gammstar, 1E-5, .99, logdist.beta(.99,.002)};
% Priors on exogenous processes - level
E.gam_ = {P.gam_, -Inf, Inf, logdist.normal(.4,.1)};
E.Lmean = {P.Lmean, -Inf, Inf, logdist.normal(-45,5)};
% Priors on exogenous processes - autocorrelation -CHANGE TO STANDARD!
E.rho_g = {P.rho_g, 1E-5, .999, logdist.beta(.5,.2)};
E.rho_b = {P.rho_b, 1E-5, .999, logdist.beta(.5,.2)};
E.rho_mu = {P.rho_mu, 1E-5, .999, logdist.beta(.5,.2)};
E.rho_z = {P.rho_z, 1E-5, .999, logdist.beta(.5,.2)};
E.rho_laf = {P.rho_laf, 1E-5, .999, logdist.beta(.5,.2)};
E.rho_law = {P.rho_law, 1E-5, .999, logdist.beta(.5,.2)};
E.rho_rm = {P.rho_rm, 1E-5, .999, logdist.beta(.5,.2)};

E.rho_sigw = {P.rho_sigw, 1E-5, .999, logdist.beta(.75,.15)};
% E.rho_mue = {P.rho_mue, 1E-5, .99, logdist.beta(.75,.15)};
% E.rho_gamm = {P.rho_gamm, 1E-5, .99, logdist.beta(.75,.15)};
% E.rho_pist = {P.rho_pist, 1E-5, .999, logdist.beta(.5,.2)};
E.rho_lr = {P.rho_lr, 1E-5, .999, logdist.beta(.5,.2)};
E.rho_zp = {P.rho_zp, 1E-5, .999, logdist.beta(.5,.2)};
E.rho_tfp = {P.rho_tfp, 1E-5, .999, logdist.beta(.5,.2)};
E.rho_gdpdef = {P.rho_gdpdef, 1E-5, .999, logdist.beta(.5,.2)};
E.rho_pce = {P.rho_pce, 1E-5, .999, logdist.beta(.5,.2)};
% Priors on exogenous processes - standard deviation
E.std_g_sh = {P.std_g_sh, 1E-8, Inf, logdist.invgamma(NaN,NaN,1,.01)};
E.std_b_sh = {P.std_b_sh, 1E-8, Inf, logdist.invgamma(NaN,NaN,1,.01)};
E.std_mu_sh = {P.std_mu_sh, 1E-8, Inf, logdist.invgamma(NaN,NaN,1,.01)};
E.std_z_sh = {P.std_z_sh, 1E-8, Inf, logdist.invgamma(NaN,NaN,1,.01)};
E.std_laf_sh = {P.std_laf_sh, 1E-8, Inf, logdist.invgamma(NaN,NaN,1,.01)};
E.std_law_sh = {P.std_law_sh, 1E-8, Inf, logdist.invgamma(NaN,NaN,1,.01)};
E.std_rm_sh = {P.std_rm_sh, 1E-8, Inf, logdist.invgamma(NaN,NaN,1,.01)};

if o.bgg
    E.std_sigw_sh = {P.std_sigw_sh, 1E-5, Inf, logdist.invgamma(NaN,NaN,2,.005)};
%     E.std_mue_sh = {P.std_mue_sh, 1E-5, Inf, logdist.invgamma(NaN,NaN,2,.005)};
%     E.std_gamm_sh = {P.std_gamm_sh, 1E-5, Inf, logdist.invgamma(NaN,NaN,2,.0002)};
end

E.std_pist_sh = {P.std_pist_sh, 1E-8, Inf, logdist.invgamma(NaN,NaN,3,.0027)};
E.std_lr_sh = {P.std_lr_sh, 1E-8, Inf, logdist.invgamma(NaN,NaN,1,.5625)};
E.std_zp_sh = {P.std_zp_sh, 1E-8, Inf, logdist.invgamma(NaN,NaN,1,.01)};
E.std_tfp_sh = {P.std_tfp_sh, 1E-8, Inf, logdist.invgamma(NaN,NaN,1,.01)};
E.std_gdpdef_sh = {P.std_gdpdef_sh, 1E-8, Inf, logdist.invgamma(NaN,NaN,1,.01)};
E.std_pce_sh = {P.std_pce_sh, 1E-8, Inf, logdist.invgamma(NaN,NaN,1,.01)};

% Priors on standard deviations of the anticipated policy shocks
for v = sprintfc('std_rm_sh%d',1:o.nant)
    E.(v{1}) = {P.(v{1}), 1E-5, Inf, logdist.invgamma(NaN,NaN,2,.08)};
end

E.eta_gz = {P.eta_gz, 1E-5, .999, logdist.beta(.5,.2)};
E.eta_laf = {P.eta_laf, 1E-5, .999, logdist.beta(.5,.2)};
E.eta_law = {P.eta_law, 1E-5, .999, logdist.beta(.5,.2)};

% E.modelalp_ind = {P.modelalp_ind, -Inf, Inf, logdist.beta(.5,.2)};
E.gamm_gdpdef = {P.gamm_gdpdef, -Inf, Inf, logdist.normal(1,2)};
E.del_gdpdef = {P.del_gdpdef, -Inf, Inf, logdist.normal(0,2)};
