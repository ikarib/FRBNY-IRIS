% information is the negative of hessian of posterior
function info=information(Pos)
tic
plist = Pos.ParamList;
param = Pos.InitParam;
n=numel(param);
e=exp(-10)*max(abs(param),1);
P=struct;
for i=1:n
    P.(plist{i})=param(i);
end
f=eval(Pos,P);
fx = nan(1,n); fy = fx;
parfor i=1:n
    p=P;
    p.(plist{i})=param(i)+e(i);
    fx(i)=eval(Pos,p);
    p.(plist{i})=param(i)-e(i);
    fy(i)=eval(Pos,p);
end
fxy=zeros(n);
parfor i=1:n-1
    p=P;
    p.(plist{i})=param(i)+e(i);
    tmp=zeros(1,n);
    for j=i+1:n
        p.(plist{j})=param(j)-e(j);
        tmp(j)=eval(Pos,p);
        p.(plist{j})=param(j);
    end
    fxy(i,:)=tmp;
end
fxy=f*eye(n)+fxy+triu(fxy,1)';
fxfy=bsxfun(@plus,fx',fy);
fxfy=triu(fxfy)+triu(fxfy,1)';
info=(fxy-fxfy+f)./bsxfun(@times,e,e');
toc