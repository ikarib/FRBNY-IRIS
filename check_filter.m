% Likelihood Function Evaluation using Kalman Filter

clear; clc; close all
addpath('kalcvf')
load irf para
o = struct; o.kimball = true; o.bgg = true; o.nant = 0;
m = model('frbny.model','assign=',o,'linear=',true);
m = assign(m,get_params(para));
m = refresh(m);
m = steady_state(m,o.bgg);
m = solve(m);
m = sstate(m);
chksstate(m);

% Data = dbload('data_151127.csv','freq=',4,'dateFormat=','YYYY-MM-DD','nameRow=','date');
load Data
Range = qq(1959,3):qq(2014,4);
load z; logl
[~,Outp] = filter(m,Data,Range,'relative=',false,'output=','filter','objRange=',qq(1960,1):qq(2014,4));
maxabs(z,Outp.mean)


return





y = get(m,'yVector');
[data,~,Range] = db2array(Data,y,qq(1959,3):qq(1959,4));

[T,R,K,Z,H,D,~,Omg] = sspace(m,'triangular=',false);
nb=size(T,2); nf=size(T,1)-nb; b=nf+(1:nb);
T=T(b,:); K=K(b,:); R=R(b,:);
var = [R;H]*Omg*[R;H]';
z0 = (eye(nb)-T)\K;
% vz0 = dlyap(T,R*Omg*R'); % full rank Omg
V=R*Omg*R'; vz0 = reshape((eye(nb^2)-kron(T,T))\V(:),nb,nb);
% [logl, zend, Pend, pred, vpred, yprederror, ystdprederror, rmse_ypred, rmse_ystdpred, filt, vfilt] = kalcvf2NaN(data', 0, K, T, D, Z, var, z0, vz0);
% [logl, zend, Pend, pred, vpred, yprederror, ystdprederror, rmse_ypred, rmse_ystdpred, filt, vfilt] = kalcvf2NaN((mt(1).YY)', 1, zeros(size(mt(2).TTT,2),1), mt(2).TTT, mt(1).DD, mt(1).ZZ, mt(1).VVall, A0, P0);
% [logl_, pred_, vpred_, filt_, vfilt_] = kalcvf((mt(1).YY)', 1, zeros(size(mt(2).TTT,2),1), mt(2).TTT, mt(1).DD, mt(1).ZZ, mt(1).VVall, A0, P0);
[logl_, pred_, vpred_, filt_, vfilt_] = kalcvf(data', 1, K, T, D, Z, var, z0, vz0);
load test
logl-logl_
xb=get(m,'xbVector'); xb=regexprep(xb,'{-1}','1');
load s
t=qq(1959,3):qq(1959,4);
pred=array2db(pred_(:,1:2)',t,xb);
maxabs(s,pred)
[pred.y_s s.y_s Outp.pred.mean.y_s]
% max(max(abs(vpred-vpred_(:,:,1:2))))
% max(max(abs(filt-filt_(:,1:2))))
% max(max(abs(vfilt-vfilt_(:,:,1:2))))
return
[smoo, vsmoo] = kalcvs(data', K, T, D, Z, var, pred, vpred);

fprintf('    Actual Predicted  Filtered  Smoothed\n')
format,disp([data(1:16,1); pred(1,1:16); filt(1,1:16); smoo(1,1:16)]')

% initial conditions
[xb,ic]=get(m,'xbVector','initCond'); ic=regexprep(ic,'{-1}',''); initCond=struct;
for i=1:size(ic,2)
    j=find(strcmp(xb,ic{i}));
    initCond.mean.(xb{j})=tseries(Range(1)-1,z0(j));
end
initCond.mse=tseries(Range(1)-1,permute(vz0,[3 2 1]));


[M,Outp,V,Delta,PE,SCov] = filter(m,Data,Range,'relative=',false,'dtrends=',false,'output=','predict,filter,smooth','initCond=',initCond);

PRED=Outp.pred.mean.y_s(Range)';
VPRED=shiftdim(Outp.pred.mse(Range),1);
fprintf('   Actual    kalcvf predicts     IRIS predicts\n')
format,d=[data(:,1); pred(1,:); PRED(1,:)]';disp(d(1:16,:))
% format compact,d=[vpred VPRED];disp(d(:,:,1:16))

%% compare output
i=cellfun(@isempty,strfind(xb,'{-1}'));
disp('max abs diff in log10:')
for f=fields(Outp)'
    z=db2array(Outp.(f{1}).mean,xb(i),Range);
    P=shiftdim(Outp.(f{1}).mse(Range,i,i),1);
    err=max(max(abs(z'-eval([f{1}(1:4) '(i,:)']))));
    verr=max(max(max(abs(P-eval(['v' f{1}(1:4) '(i,i,:)'])))));
    fprintf('%s : %f\n',f{1},log10(err));
    fprintf('v%s : %f\n',f{1},log10(verr));
%     if err<5e-10 && verr<7e-7
%         disp([f{1} ' data are the same'])
%     else
%         error([f{1} ' data are not the same'])
%     end
end