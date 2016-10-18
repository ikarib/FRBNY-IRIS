function P=get_params(para)
params = {'alp','zeta_p','iota_p','ups','Bigphi','s2','h','ppsi','nu_l','zeta_w','iota_w','bet_','psi1','psi2','psi3','pistar_','sigmac','rho','Fom_','sprd_','zeta_spb','gammstar','gam_','Lmean','rho_g','rho_b','rho_mu','rho_z','rho_laf','rho_law','rho_rm','rho_sigw','rho_mue','rho_gamm','rho_pist','rho_lr','rho_zp','rho_tfp','rho_gdpdef','rho_pce','std_g_sh','std_b_sh','std_mu_sh','std_z_sh','std_laf_sh','std_law_sh','std_rm_sh','std_sigw_sh','std_mue_sh','std_gamm_sh','std_pist_sh','std_lr_sh','std_zp_sh','std_tfp_sh','std_gdpdef_sh','std_pce_sh','std_rm_sh1','std_rm_sh2','std_rm_sh3','std_rm_sh4','std_rm_sh5','std_rm_sh6','std_rm_sh7','std_rm_sh8','std_rm_sh9','std_rm_sh10','std_rm_sh11','std_rm_sh12','std_rm_sh13','std_rm_sh14','std_rm_sh15','std_rm_sh16','std_rm_sh17','std_rm_sh18','std_rm_sh19','std_rm_sh20','eta_gz','eta_laf','eta_law','modelalp_ind','gamm_gdpdef','del_gdpdef'};
n = numel(params);
if numel(para)~=n; error('incorrect number of parameters'); end
P=struct;
for i=setdiff(1:n,[4 16 19 22 33 34 35 49 50 57:76 80])
    P.(params{i}) = para(i);
end