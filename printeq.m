function printeq(m,var)
% prints reduced form equation from solved model m for specified variable var
[T,R,K] = sspace(m,'triangular=',false);
[v,sh]=get(m,'xVector','eVector'); [nx,nb]=size(T); nf=nx-nb;
for n=find(not(cellfun('isempty', strfind(v,var))))'
    fprintf('%s = %g',v{n},K(n))
    for i=find(abs(T(n,:))>5000*eps);
        fprintf(' %+g*%s{-1}',T(n,i),v{nf+i})
    end
    for i=find(abs(R(n,:))>5000*eps);
        fprintf(' %+g*%s',R(n,i),sh{i})
    end
    fprintf('\n')
end