% this program will check loglinearization of FRBNY model
clear; clc; close all
load irf para
o = struct; o.kimball = false; o.bgg = true; o.nant = 0;
m1 = model('frbny.model','assign=',o,'linear=',true);
m2 = model('frbny.model','assign=',o,'linear=',false);
m1 = assign(m1,get_params(para));
m1 = refresh(m1);
m1 = steady_state(m1,o.bgg);
m1 = solve(m1);
m1 = sstate(m1);
chksstate(m1);
m2.zeta_spsigw=m1.zeta_spsigw; m2.zeta_spmue=m1.zeta_spmue;
m2 = assign(m2,get_params(para));
m2 = sstate(m2);
chksstate(m2);
m2 = solve(m2);
disp('Checking policy functions:')
v='kbar_s'; printeq(m1,v); printeq(m2,v)
sspace_compare(m1,m2)
disp('Checking impulse responses (in log10):')
t=0:20; shocks=get(m1,'eList');
for i=1:length(shocks)
    d1=zerodb(m1,t);
    d2=zerodb(m2,t);
    d1.(shocks{i})(1)=0.01i;
    d2.(shocks{i})=d1.(shocks{i});
    s1=simulate(m1,d1,t,'deviations=',true);
    s2=simulate(m2,d2,t,'deviations=',true);
    v=get(m2,'logList'); e=zeros(size(v));
    for j=1:length(v)
        s2.(v{j})=log(s2.(v{j}));
        if isfield(s1,v{j})
            e(j) = max(abs(s1.(v{j})-s2.(v{j})));
        end
    end
    [e,j]=sort(e,'descend');
    fprintf('%s : ',shocks{i});
    for k=find(e>0)
        fprintf(' %s %g,',v{j(k)},log10(e(k)));
    end
    fprintf('\n')
%     dbplot((s2+s1)&(s1+s2),get(m2,'logList'),t,'maxPerFigure=',52);
%     ftitle(shocks{i},'Interpreter','none'); legend('linear','log-linear')
end