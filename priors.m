function E = priors(o)
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

load para; P=para1; % use modes from csminwel solver (transformed from max to model)
% load est P; P = put_params(P,m); % use posterior modes from last IRIS estimation
% P = nan(82,1); % use initial values assigned in model file

E = struct();
E.alp = {P(1), 1E-5, .999, logdist.normal(.3,.05)};
E.zeta_p = {P(2), 1E-5, .999, logdist.beta(.5,.1)};
E.iota_p = {P(3), 1E-5, .999, logdist.beta(.5,.15)};
% E.ups = {P(4), 1E-5, Inf, logdist.gamma(1,.5)};
E.Bigphi = {P(5), 1, Inf, logdist.normal(1.25,.12)};
E.s2 = {P(6), -Inf, Inf, logdist.normal(4,1.5)};
E.h = {P(7), 1E-5, .999, logdist.beta(.7,.1)};
E.ppsi = {P(8), 1E-5, .999, logdist.beta(.5,.15)};
E.nu_l = {P(9), 1E-5, Inf, logdist.normal(2,.75)};
E.zeta_w = {P(10), 1E-5, .999, logdist.beta(.5,.1)};
E.iota_w = {P(11), 1E-5, .999, logdist.beta(.5,.15)};
E.bet_ = {P(12), 1E-5, Inf, logdist.gamma(.25,.1)};
E.psi1 = {P(13), 1E-5, Inf, logdist.normal(1.5,.25)};
E.psi2 = {P(14), -Inf, Inf, logdist.normal(.12,.05)};
E.psi3 = {P(15), -Inf, Inf, logdist.normal(.12,.05)};
% E.pistar_ = {P(16), 1E-5, Inf, logdist.gamma(.75,.4)};
E.sigmac = {P(17), 1E-5, Inf, logdist.normal(1.5,.37)};
E.rho = {P(18), 1E-5, .999, logdist.beta(.75,.1)};
% Priors on Financial Frictions Parameters
% E.Fom_ = {P(19), 1E-5, .99, logdist.beta(.03,.01)};
E.sprd_ = {P(20), 1E-5, Inf, logdist.gamma(2,.1)};
E.zeta_spb = {P(21), 1E-5, .99, logdist.beta(.05,.005)};
% E.gammstar = {P(22), 1E-5, .99, logdist.beta(.99,.002)};
% Priors on exogenous processes - level
E.gam_ = {P(23), -Inf, Inf, logdist.normal(.4,.1)};
E.Lmean = {P(24), -Inf, Inf, logdist.normal(-45,5)};
% Priors on exogenous processes - autocorrelation -CHANGE TO STANDARD!
E.rho_g = {P(25), 1E-5, .999, logdist.beta(.5,.2)};
E.rho_b = {P(26), 1E-5, .999, logdist.beta(.5,.2)};
E.rho_mu = {P(27), 1E-5, .999, logdist.beta(.5,.2)};
E.rho_z = {P(28), 1E-5, .999, logdist.beta(.5,.2)};
E.rho_laf = {P(29), 1E-5, .999, logdist.beta(.5,.2)};
E.rho_law = {P(30), 1E-5, .999, logdist.beta(.5,.2)};
E.rho_rm = {P(31), 1E-5, .999, logdist.beta(.5,.2)};

E.rho_sigw = {P(32), 1E-5, .999, logdist.beta(.75,.15)};
% E.rho_mue = {P(33), 1E-5, .99, logdist.beta(.75,.15)};
% E.rho_gamm = {P(34), 1E-5, .99, logdist.beta(.75,.15)};
% E.rho_pist = {P(35), 1E-5, .999, logdist.beta(.5,.2)};
E.rho_lr = {P(36), 1E-5, .999, logdist.beta(.5,.2)};
E.rho_zp = {P(37), 1E-5, .999, logdist.beta(.5,.2)};
E.rho_tfp = {P(38), 1E-5, .999, logdist.beta(.5,.2)};
E.rho_gdpdef = {P(39), 1E-5, .999, logdist.beta(.5,.2)};
E.rho_pce = {P(40), 1E-5, .999, logdist.beta(.5,.2)};
% Priors on exogenous processes - standard deviation
E.std_g_sh = {P(41), 1E-8, Inf, logdist.scaleinvchisq(.1,2)};
E.std_b_sh = {P(42), 1E-8, Inf, logdist.scaleinvchisq(.1,2)};
E.std_mu_sh = {P(43), 1E-8, Inf, logdist.scaleinvchisq(.1,2)};
E.std_z_sh = {P(44), 1E-8, Inf, logdist.scaleinvchisq(.1,2)};
E.std_laf_sh = {P(45), 1E-8, Inf, logdist.scaleinvchisq(.1,2)};
E.std_law_sh = {P(46), 1E-8, Inf, logdist.scaleinvchisq(.1,2)};
E.std_rm_sh = {P(47), 1E-8, Inf, logdist.scaleinvchisq(.1,2)};

if o.bgg
    E.std_sigw_sh = {P(48), 1E-5, Inf, logdist.scaleinvchisq(.05,4)};
%     E.std_mue_sh = {P(49), 1E-5, Inf, logdist.scaleinvchisq(.05,4)};
%     E.std_gamm_sh = {P(50), 1E-5, Inf, logdist.scaleinvchisq(.01,4)};
end

E.std_pist_sh = {P(51), 1E-8, Inf, logdist.scaleinvchisq(.03,6)};
E.std_lr_sh = {P(52), 1E-8, Inf, logdist.scaleinvchisq(.75,2)};
E.std_zp_sh = {P(53), 1E-8, Inf, logdist.scaleinvchisq(.1,2)};
E.std_tfp_sh = {P(54), 1E-8, Inf, logdist.scaleinvchisq(.1,2)};
E.std_gdpdef_sh = {P(55), 1E-8, Inf, logdist.scaleinvchisq(.1,2)};
E.std_pce_sh = {P(56), 1E-8, Inf, logdist.scaleinvchisq(.1,2)};

% Priors on standard deviations of the anticipated policy shocks
for i = 1:min(o.nant,12)
    eval(strcat('E.std_rm_sh',num2str(i),' = {P(56+i), 1E-5, Inf, logdist.scaleinvchisq(.2,4)};'));
end

E.eta_gz = {P(77), 1E-5, .999, logdist.beta(.5,.2)};
E.eta_laf = {P(78), 1E-5, .999, logdist.beta(.5,.2)};
E.eta_law = {P(79), 1E-5, .999, logdist.beta(.5,.2)};

% E.modelalp_ind = {P(80), -Inf, Inf, logdist.beta(.5,.2)};
E.gamm_gdpdef = {P(81), -Inf, Inf, logdist.normal(1,2)};
E.del_gdpdef = {P(82), -Inf, Inf, logdist.normal(0,2)};
