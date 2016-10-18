% run this file at the end of dsgelh.m
eval(strcat('states',num2str(mspec)));
% t=qq(1959,3):qq(1959,4);
t=qq(1960,1):qq(2014,4);
z=struct;
% v_all={'y_s','c_s','i_s','kbar_s','w_s','qk_s','L_s','u_s','spread_s','R_s','pi_s','y_f','c_f','i_f','kbar_f','qk_f','z','ztil','zp','g','b','mu','laf','laf1','law','law1','pist','rm','n','sigw','mue','gamm','lr','tfp','gdpdef','pce','E_pi','E_R','y_s{-1}','c_s{-1}','i_s{-1}','w_s{-1}','u_s{-1}'};
% nb=length(v_all); Pend=nan(nb);
v={'y_s','c_s','i_s','k_s','kbar_s','w_s','Rktil_s','rk_s','qk_s','L_s','u_s','muw_s','mc_s','y_f','c_f','i_f','k_f','kbar_f','w_f','rk_f','qk_f','L_f','u_f','z','ztil','zp','g','b','mu','laf','law','R_s','pi_s','pist','rm','n','sigw','mue','gamm'};
for j=1:length(v)
    i=eval([regexprep(v{j},'(.*)_s$','$1') '_t']);
    z.(v{j})=tseries(t,filt(i,:));
%     z.(v{j})=tseries(qq(1959,4),mt(1).z(i));
%     Pend()=tseries(qq(1959,4),mt(1).Pend(i,i));
end
logl = mt(p).pyt;
save z z logl % Pend