clear; clc; close all
o=struct; o.kimball=false; o.bgg=true;
m = model('frbny.model','assign=',o,'linear=',true);
m=steady_state(m,o.bgg);
m=solve(m);
m=sstate(m);
chksstate(m);
%% check impulse responses
t=0:20;
for shock={'pist_sh'};%{'g_sh','b_sh','mu_sh','z_sh','zp_sh','laf_sh','law_sh','rm_sh','pist_sh','sigw_sh','mue_sh','gamm_sh'}
d=zerodb(m,t);
d.(shock{1})(1)=0.01;
s_=simulate(m,d,t,'deviations=',true,'anticipate=',false);
load(['..\DSGE-2015-Apr\irf_' shock{1}],'s');
v=get(m,'xList'); e=zeros(size(v));
for j=1:length(v)
    e(j) = max(abs(s.(v{j})-s_.(v{j})));
end
[e,j]=sort(e,'descend');
fprintf('%s : ',shock{1});
for k=find(e>0)
    fprintf(' %s %g,',v{j(k)},log10(e(k)));
end
fprintf('\n')
dbplot(s&s_,get(m,'xList'),t,'maxPerFigure=',50); ftitle(shock{1},'Interpreter','none'); legend('gensys','IRIS')
[A,B,C,D,F,G,H,J,List,Nf] = system(m);
x=eval(['[' sprintf('s.%s ',List{2}{:}) ']']);
e=eval(['[' sprintf('s.%s ',List{3}{:}) ']']);
z=x*A'+x{-1}*B'+C'+e*D';
eq=get(m,'xEqtn');
er=max(abs(z.data));
for i=find(er>105*eps)
    fprintf('%s : %g : %s\n',shock{1},er(i),eq{i})
end
end
addpath('..\DSGE-2015-Apr\dsgesolv')
solve_gensys(m)