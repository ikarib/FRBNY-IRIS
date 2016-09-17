for shock={'g_sh','b_sh','mu_sh','z_sh','zp_sh','laf_sh','law_sh','rm_sh','pist_sh','sigw_sh','mue_sh','gamm_sh'}
z=zeros(nex,1);
z(eval(shock{1}))=0.01;
y=zeros(nstates,1);
y(:,2)=T0*z; T=20;
for t=2:T; y(:,t+1)=T1*y(:,t); end
s=struct;
for v={'y_s','c_s','i_s','k_s','kbar_s','w_s','rk_s','qk_s','L_s','u_s','muw_s','mc_s','y_f','c_f','i_f','k_f','kbar_f','w_f','r_f','rk_f','qk_f','L_f','u_f','z','ztil','zp','g','b','mu','laf','law','R','pi','pist','rm','n','sigw','mue','gamm'};
    s.(v{1})=tseries(0:T,y(eval([regexprep(v{1},'(.*)_s$','$1') '_t']),:));
end
s.b = s.b*(-sigmac*(1+h*exp(-zstar))/(1-h*exp(-zstar)));
betbar=bet*exp((1-sigmac)*zstar);
s.laf = s.laf/((1-zeta_p*betbar)*(1/zeta_p-1)/(1+iota_p*betbar)/(1+(Bigphi-1)*epsp)*(1-1/Bigphi));
s.law = s.law/((1-zeta_w*betbar)*(1/zeta_w-1)/(1+betbar)/(1+(law-1)*epsw)*(1-1/law));
s.sigw = s.sigw/zeta_spsigw;
s.mue = s.mue/zeta_spmue;
s.gamm = s.gamm/gammstar*nstar/vstar;
s.rktil_s = (rkstar*s.rk_s+(1-del)*s.qk_s)/(rkstar+1-del) - s.qk_s{-1};
s.r_s = s.R-s.pi{1};
s.xi_f = -sigmac/(1-h*exp(-zstar))*(s.c_f-h*exp(-zstar)*(s.c_f{-1}-s.z))+(sigmac-1)*Lstar^(1+nu_l)*s.L_f;
s.xi_s = -sigmac/(1-h*exp(-zstar))*(s.c_s-h*exp(-zstar)*(s.c_s{-1}-s.z))+(sigmac-1)*Lstar^(1+nu_l)*s.L_s;
s.spread_s = zeta_spb*(s.qk_s+s.kbar_s-s.n)+zeta_spsigw*s.sigw+zeta_spmue*s.mue;
s.rktil_f = (rkstar*s.rk_f+(1-del)*s.qk_f)/(rkstar+1-del) - s.qk_f{-1};
s.muw_f = tseries(0:T,0);
s.mc_f = tseries(0:T,0);
s.spread_f = tseries(0:T,0);
s.laf1 = tseries(0:T,y(laf_t1,:));
s.law1 = tseries(0:T,y(law_t1,:));
for v={'g_sh','b_sh','mu_sh','z_sh','zp_sh','laf_sh','law_sh','rm_sh','pist_sh','sigw_sh','mue_sh','gamm_sh'};
    s.(v{1})=tseries(0:T,0);
    s.(v{1})(1)=z(eval(v{1}));
end
s.laf1 = s.laf_sh/((1-zeta_p*betbar)*(1/zeta_p-1)/(1+iota_p*betbar)/(1+(Bigphi-1)*epsp)*(1-1/Bigphi));
s.law1 = s.law_sh/((1-zeta_w*betbar)*(1/zeta_w-1)/(1+betbar)/(1+(law-1)*epsw)*(1-1/law));
save(['irf_' shock{1}],'s');
end