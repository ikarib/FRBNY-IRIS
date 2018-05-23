function check_loglin
% Check loglinearization of nonlinear model

    % Load Solved Model Object
    %
    % You must run `read_linear_model` and `read_nonlin_model` at least once
    % before running this m-file.

    load read_linear_model.mat m; ml=m;
    load read_nonlin_model.mat m;

    % Check policy functions
    disp('Policy function for capital:')
    v='sigw'; printeq(ml,v); printeq(m,v)

    sspace_compare(ml,m)
    disp('Differences in impulse responses (in log10, sorted):')
    t=0:20; shocks=get(ml,'eList');
    for i=1:length(shocks)
        d1=zerodb(ml,t);
        d2=zerodb(m,t);
        d1.(shocks{i})(1)=0.01i;
        d2.(shocks{i})=d1.(shocks{i});
        s1=simulate(ml,d1,t,'deviations=',true);
        s2=simulate(m,d2,t,'deviations=',true);
        v=[get(m,'xList') get(m,'yList')]; e=zeros(size(v));
        islog=get(m,'log');
        for j=1:length(v)
            if islog.(v{j}); s2.(v{j})=log(s2.(v{j})); end
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
%         dbplot((s2+s1)&(s1+s2),get(m,'yList'),t,'maxPerFigure=',52);
%         dbplot((s2+s1)&(s1+s2),get(m,'logList'),t,'maxPerFigure=',52);
%         ftitle(shocks{i},'Interpreter','none'); legend('linear','log-linear')
    end
end

function printeq(m,var)
% prints reduced form equation from solved model m for specified variable var
    [T,R,K] = sspace(m,'triangular=',false);
    [v,sh]=get(m,'xVector','eVector'); [nx,nb]=size(T); nf=nx-nb;
    for n=find(not(cellfun('isempty', strfind(v,var))))'
        fprintf('%s = %.15g',v{n},K(n))
        for i=find(abs(T(n,:))>5000*eps);
            fprintf(' %+.15g*%s{-1}',T(n,i),v{nf+i})
        end
        for i=find(abs(R(n,:))>5000*eps);
            fprintf(' %+.15g*%s',R(n,i),sh{i})
        end
        fprintf('\n')
    end
end

function sspace_compare(m1,m2)
    [T1,R1] = sspace(m1,'triangular=',false);
    [T2,R2] = sspace(m2,'triangular=',false);
    [nx1,nb1]=size(T1); nf1=nx1-nb1;
    [nx2,nb2]=size(T2); nf2=nx2-nb2;
    [x1,e1]=get(m1,'xVector','eVector');
    [x2]=get(m2,'xVector');
    x2=regexprep(x2,'log_(.*)','$1');
    [xr,ix1,ix2]=setxor(x1(nf1+1:end),x2(nf2+1:end));
    T1(nf1+ix1,:)=[]; R1(nf1+ix1,:)=[]; T1(:,ix1)=[]; x1(nf1+ix1)=[];
    T2(nf2+ix2,:)=[]; R2(nf2+ix2,:)=[]; T2(:,ix2)=[]; x2(nf2+ix2)=[];
%     if ~isempty(xr); fprintf('state %s is missing\n',xr{:}); end
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
            str=sprintf('%s %+g*%s{-1}',str,e(i),x1{nf1+i});
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
end