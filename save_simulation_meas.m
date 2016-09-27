% run this file at the end of measur990.m
T=20;
e=randn(nex,T);
S=zeros(size(TTT,1),T);
X=zeros(nvar,T);
S(:,1)=RRR*e(:,1);
X(:,1)=ZZ*S(:,1)+DD;
for t=2:T;
    S(:,t)=TTT*S(:,t-1)+RRR*e(:,t);
    X(:,t)=ZZ*S(:,t)+DD;
end
s=struct;
for v={'y_s','c_s','i_s','k_s','kbar_s','w_s','Rktil_s','rk_s','qk_s','L_s','u_s','muw_s','mc_s','y_f','c_f','i_f','k_f','kbar_f','w_f','rk_f','qk_f','L_f','u_f','z','ztil','zp','g','b','mu','laf','law','R_s','pi_s','pist','rm','n','sigw','mue','gamm','lr','tfp'};
    s.(v{1})=tseries(0:T,[0 S(eval([regexprep(v{1},'(.*)_s$','$1') '_t']),:)]);
end
v={'obs_gdp','obs_hours','obs_wages','obs_gdpdeflator','obs_corepce','obs_nominalrate','obs_consumption','obs_investment','obs_spread','obs_longinflation','obs_longrate','obs_tfp'};
for i=1:size(v,2)
    s.(v{i}) = tseries(0:T,[DD(i) X(i,:)]);
end
s.E_pi = tseries(0:T,[0 X(10,:)-100*(pistar-1)]);
s.E_R = tseries(0:T,[0 X(11,:)-S(lr_t,:)-Rstarn]);
s.gdpdef = tseries(0:T,[0 S(e_gdpdef,:)]);
s.pce = tseries(0:T,[0 S(e_pce,:)]);
s.laf1 = tseries(0:T,[0 S(laf_t1,:)]);
s.law1 = tseries(0:T,[0 S(law_t1,:)]);
betbar=bet*exp((1-sigmac)*zstar);
s.b = s.b*(-sigmac*(1+h*exp(-zstar))/(1-h*exp(-zstar)));
s.laf = s.laf/((1-zeta_p*betbar)*(1/zeta_p-1)/(1+iota_p*betbar)/(1+(Bigphi-1)*epsp)*(1-1/Bigphi));
s.laf1 = s.laf1/((1-zeta_p*betbar)*(1/zeta_p-1)/(1+iota_p*betbar)/(1+(Bigphi-1)*epsp)*(1-1/Bigphi));
s.law = s.law/((1-zeta_w*betbar)*(1/zeta_w-1)/(1+betbar)/(1+(law-1)*epsw)*(1-1/law));
s.law1 = s.law1/((1-zeta_w*betbar)*(1/zeta_w-1)/(1+betbar)/(1+(law-1)*epsw)*(1-1/law));
s.sigw = s.sigw/zeta_spsigw;
s.mue = s.mue/zeta_spmue;
s.gamm = s.gamm/gammstar*nstar/vstar;
s.xi_f = -sigmac/(1-h*exp(-zstar))*(s.c_f-h*exp(-zstar)*(s.c_f{-1}-s.z))+(sigmac-1)*Lstar^(1+nu_l)*s.L_f;
s.xi_s = -sigmac/(1-h*exp(-zstar))*(s.c_s-h*exp(-zstar)*(s.c_s{-1}-s.z))+(sigmac-1)*Lstar^(1+nu_l)*s.L_s;
s.spread_s = zeta_spb*(s.qk_s+s.kbar_s-s.n)+zeta_spsigw*s.sigw+zeta_spmue*s.mue;
s.muw_f = tseries(0:T,0);
s.mc_f = tseries(0:T,0);
s.spread_f = tseries(0:T,0);
s.pi_f=tseries(0:T,0);
s.R_f=tseries(0:T,[0 S(r_f_t,:)]);
s.Rktil_f = (rkstar*s.rk_f+(1-del)*s.qk_f)/(rkstar+1-del) - s.qk_f{-1} + s.pi_f;
for v={'g_sh','b_sh','mu_sh','z_sh','zp_sh','laf_sh','law_sh','rm_sh','pist_sh','sigw_sh','mue_sh','gamm_sh','lr_sh','tfp_sh','gdpdef_sh','pce_sh'}
    s.(v{1})=tseries(0:T,[0 e(eval(v{1}),:)]);
end
save irf s
