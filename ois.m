%% Derive expected FFR from OIS quotes

% Tullett Prebon series start at 2012Q3
v={'M111F3M','M111F6M','M111F9M','M111FWM','M111FFM','M111FGM','M111FOM','M111FBM','M111FEH','M111FIH','M111FRH','M111F3Y','M111F9S'};
ois = feed.haver('\\wahaverdb\DLX\DATA\','INTDAILY',v);
ois = dbfun(@(x) convert(x,4,'method=','last'),ois);
ois_tp = struct;
ois_tp.obs_ois1 = ois.(v{1});
for t=2:numel(v)
    ois_tp.(sprintf('obs_ois%d',t)) = ois.(v{t})*t-ois.(v{t-1})*(t-1);
end
ois_tp = dbfun(@(x) x/4,ois_tp);

% Reuters series start at 2003Q3, but Haver is missing 15-month, 18-month and 21-month OIS rates
ois = feed.haver('\\wahaverdb\DLX\DATA\','INTDAILY',{'T111W3M','T111W6M','T111W9M','T111W1','T111W2','T111W3'});
ois = dbfun(@(x) convert(x,4,'method=','last'),ois);
ois_r = struct;
ois_r.obs_ois1 = convert(ois.T111W3M,4,'method=','last');
ois_r.obs_ois2 = convert(ois.T111W6M,4,'method=','last')*2-ois_r.obs_ois1;
ois_r.obs_ois3 = convert(ois.T111W9M,4,'method=','last')*3-ois_r.obs_ois1-ois_r.obs_ois2;
ois_r.obs_ois4 = convert(ois.T111W1,4,'method=','last')*4-ois_r.obs_ois1-ois_r.obs_ois2-ois_r.obs_ois3;
ois_r.obs_ois8 = (convert(ois.T111W2,4,'method=','last')*8-ois_r.obs_ois1-ois_r.obs_ois2-ois_r.obs_ois3-ois_r.obs_ois4)/4;
ois_r.obs_ois12 = (convert(ois.T111W3,4,'method=','last')*12-ois_r.obs_ois1-ois_r.obs_ois2-ois_r.obs_ois3-ois_r.obs_ois4)/4-ois_r.obs_ois8;
ois_r = dbfun(@(x) x/4,ois_r);

%% Bloomberg OIS rates
ois = feed.bloomberg({'USSOC Curncy','USSOF Curncy','USSOI Curncy','USSO1 Curncy','USSO1C Curncy','USSO1F Curncy','USSO1I Curncy','USSO2 Curncy'},'PX_LAST','quarterly');
sec = fieldnames(ois);
ois_blp = struct;
ois_blp.obs_ois1 = ois.(sec{1});
for t=2:numel(sec)
    ois_blp.(sprintf('obs_ois%d',t)) = ois.(sec{t})*t-ois.(sec{t-1})*(t-1);
end
clear ois sec t
ois_blp = dbfun(@(x) x/4,ois_blp);
save ois_blp ois_blp

%
% warning('off', 'MATLAB:table:ModifiedVarnames');
% data = readtable('OIS_Bloomberg.xlsx');
% warning('on', 'MATLAB:table:ModifiedVarnames');
% data(cellfun(@isempty,data.Var1),:) = [];
% dates = str2dat(data.Var1,'dateFormat=','%C%QP YYYY','freq=',4);
% data(:,1) = [];
% ois_blp = struct;
% ois_blp.obs_ois1 = tseries(dates,data{:,1});
% for t=2:8
%     ois_blp.(sprintf('obs_ois%d',t)) = tseries(dates,data{:,t}*t-data{:,t-1}*(t-1));
% end
% ois_blp = dbfun(@(x) x/4,ois_blp);
% clear data dates

% original CSV file
% ois_csv = dbload('ois_150102.csv','freq=',4,'dateFormat=','YYYY-MM-DD','nameRow=','date');
% ois_csv = dbfun(@(x) x/4,ois_csv);

dbplot(ois_tp&ois_r&ois_blp,qq(2008,4):endHist);
legend('Tullett Prebon','Reuters','Bloomberg')

