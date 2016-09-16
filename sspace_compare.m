function sspace_compare(m1,m2)
[T1,R1] = sspace(m1,'triangular=',false);
[T2,R2] = sspace(m2,'triangular=',false);
[nx1,nb1]=size(T1); nf1=nx1-nb1;
[nx2,nb2]=size(T2); nf2=nx2-nb2;
[x1,e1]=get(m1,'xVector','eVector');
[x2]=get(m2,'xVector');
x2=regexprep(x2,'log\((.*)\)','$1');
[x,ix1,ix2]=intersect(x1,x2);
dif = false;
for n=1:size(x,1)
    str='';
%     e=T1(ix1(n),ix1(ix1>nf1)-nf1)-T2(ix2(n),ix2(ix2>nf2)-nf2);
%     for i=find(abs(e)>5000*eps);
%         fprintf(' %+g*%s',e(i),x1{ix1(ix1>nf1)})
%     end
    e=T1(ix1(n),:)-T2(ix2(n),:);
%     str=sprintf('%s %+g',str,max(abs(e)));
    for i=find(abs(e)>2e-7)
        str=sprintf('%s %+g*%s',str,e(i),x1{i});
    end
    e=R1(ix1(n),:)-R2(ix2(n),:);
%     str=sprintf('%s %+g',str,max(abs(e)));
    for i=find(abs(e)>1e-7)
        str=sprintf('%s %+g*%s',str,e(i),e1{i});
    end
    if ~isempty(str)
        fprintf('%s : %s\n',x{n},str)
        dif = true;
    end
end
if ~dif
    disp('there are no differences in policy functions. good!')
else
    disp('policy functions are different')
end