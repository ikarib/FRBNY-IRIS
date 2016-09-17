function solve_gensys(m)
[A,B,C,D,~,~,~,~,List,Nf] = system(m);
N=size(A,2);
G0=[-B(:,1:Nf) -A; eye(Nf,N+Nf)];
G1=[zeros(N,2*Nf) B(:,Nf+1:N); zeros(Nf) eye(Nf,N)];
CC=[C; zeros(Nf,1)];
PSI=[D; zeros(Nf,size(D,2))];
PIE=[zeros(N,Nf); eye(Nf)];
[T1,TC,T0,~,~,~,~,RC] = gensys(G0,G1,CC,PSI,PIE,1+10^(-6)); % y=[xf{-1};xf;xb]
assert(all(RC))
x=[regexprep(List{2}(1:Nf),'(.*)\{1\}(.*)','$1$2') List{2}];%fprintf('%s ',x{:});fprintf('\n');
x1=[regexprep(List{2}(1:Nf),'(.*)\{1\}(.*)','$1{-1}$2') ...
   regexprep(List{2}(1:Nf),'(.*)\{1\}(.*)','$1$2') ...
   regexprep(List{2}(Nf+1:N),'(.*)','$1{-1}')];
for i=[1:Nf 2*Nf+1:Nf+N]
    fprintf('%s = %g',x{i},TC(i))
    for j=find(abs(T1(i,:))>1000*eps);
        fprintf(' %+g*%s',T1(i,j),x1{j})
    end
    for j=find(abs(T0(i,:))>1000*eps);
        fprintf(' %+g*%s',T0(i,j),List{3}{j})
    end
    fprintf('\n')
end