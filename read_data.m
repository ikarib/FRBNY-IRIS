%% Import and Prepare Data
%
% Load raw data from Haver or Fred databases into databases where each series is
% represented by a tseries (time series) object. In case with no datafeed toolbox,
% load data from CSV files. Prepare the data to be used later with the model:
% convert to quaterly periodicity, and create model-consistent variable names.

%% Clear Workspace
%
% Clear workspace, close all graphics figures, clear command window, and
% check the IRIS version.

clear; clc; close all
irisrequired 20170320

%% Set the start and end dates for the historical series
startHist = qq(1959,3);
endHist = qq(2016,4);
disp('Historical range');
dat2str([startHist,endHist])

%% Load the raw series from Haver Analaytics
fprintf('Connecting to the Haver Analytics database ...\n');
try
    H = feed.haver('\\wahaverdb\DLX\DATA\', ...
        'USECON',{'GDP','C','F','JGDP','JCXFE','LN16N','FCM10','TFPJQ','TFPKQ','LXNFC','LRPRIVA','LE'},...
        'DAILY',{'FFED','FYCCZA','FTPZAC'},...
        'SURVEYS','ASACX10');
    disp('Haver Database');
    dbprintuserdata(H,'Descriptor')
catch E
    warning(E.message)
    for v={'GDP','C','F','JGDP','LN16N','FCM10','TFPJQ','TFPKQ','LXNFC','LRPRIVA','LE','JCXFE','FFED','FYCCZA','FTPZAC','ASACX10'}
        H.(v{1})=tseries;
    end
    warning('Will try FRED next.')
end

%% Retrieve the raw series from FRED, Federal Reserve Bank of St. Louis
fprintf('Connecting to the St. Louis Federal Reserve database (FRED) ...\n');
try
    F = feed.fred('GDP','GDPCTPI','PCEC','FPI','AWHNONAG','CE16OV','CNP16OV','COMPNFB','JCXFE','DFF','BAA','GS10','THREEFYTP10','USRECQ');
    disp('FRED Database');
    dbprintuserdata(F,'Title')
catch E
    % Case with no internet connection
    warning(E.message)
    warning('Will use data from CSV file.\n');
end

%% Other data sources
% The Total Factor Productivity series components are made available
% by the Federal Reserve Bank of San Francisco, and can be found at
% http://www.frbsf.org/economic-research/total-factor-productivity-tfp/
% (series alpha and dtfp from the linked spreadsheet).
url = 'http://www.frbsf.org/economic-research/files/';
fname = 'quarterly_tfp.xls';
fname = websave([tempdir fname],[url fname]);
data = readtable(fname,'Sheet','quarterly','Range','A2:L300');
data(find(cellfun(@isempty,data.date),1):end,:) = [];
dates = str2dat(data.date,'dateFormat=','YYYY:%QP','freq=',4);
F.ALPHA = tseries(dates,data.alpha);
F.DTFP = tseries(dates,data.dtfp);
delete(fname)

% The 10-year Inflation Expectations series from the Survey of Professional
% Forecasters is made available by the Federal Reserve Bank of Philadelphia,
% and can be found at
% https://www.philadelphiafed.org/research-and-data/real-time-center/survey-of-professional-forecasters/historical-data/inflation-forecasts
% (series INFCPI10YR from the linked spreadsheet).
url = 'https://www.philadelphiafed.org/-/media/research-and-data/real-time-center/survey-of-professional-forecasters/historical-data/';
fname = 'inflation.xls';
fname = websave([tempdir fname],[url fname]);
data = readtable(fname,'TreatAsEmpty','#N/A');
dates = qq(data.YEAR,data.QUARTER);
F.INFCPI10YR = tseries(dates,data.INFCPI10YR);
delete(fname)
fname = 'additional-cpie10.xls';
fname = websave([tempdir fname],[url fname]);
warning('off', 'MATLAB:table:ModifiedVarnames');
data = readtable(fname);
warning('on', 'MATLAB:table:ModifiedVarnames');
dates = str2dat(data.SurveyDate,'dateFormat=','YYYY:P','freq=',4);
F.INFCPI10YR = [tseries(dates,data.Combined); F.INFCPI10YR];
delete(fname)

% The 10-year Treasury Yield (zero-coupon, continuously compounded) series
% is made available by the Board of Governors of the Federal Reserve System,
% and can be found at
% http://www.federalreserve.gov/pubs/feds/2006/200628/200628abs.html
% (series SVENY10 from the linked spreadsheet)
url = 'https://www.federalreserve.gov/econresdata/researchdata/';
fname = 'feds200628.xls';
fname = websave([tempdir fname],[url fname]);
data = readtable(fname,'Range','A10:K15000');
dates = str2dat(data.Var1,'dateFormat=','YYYY-MM-DD','freq=',365)';
F.SVENY10 = tseries(dates,data.SVENY10);
delete(fname)
clear url fname data dates

%% Population forecasted by Macro Advisers
url = 'https://macroadvisers.bluematrix.com/sellside/EmailDocViewer';
fname = '9512_86cae8f6-90a8-498a-8ade-43fa398806e7.xlsx'; % update this
fname = websave([tempdir fname],url,'encrypt','7fc2fad0-58b0-4183-9846-9bb56bb74182','mime','xlsx','attachmentName',fname);
data = readtable(fname,'Range','1827:1841','ReadRowNames',true,'ReadVariableNames',false);
data(:,find(diff(data{{'Row1'},:})<0,1)+1:end) = [];
dates = qq(floor(data{{'Row1'},:}),round(rem(data{{'Row1'},:},1)*10));
MA_pop = tseries(dates,round(data{'Working age population',:}'*1000,4));
if maxabs(MA_pop,convert(F.CNP16OV,4))>1e-2; error('please update MA_pop'); end
% MA_pop = tseries(qq(2014,4),[248842.6666 249799.5291 250273.88 250785.5347 251296.4105 251808.0652 252319.7198 252831.3745 253343.8079 253855.4625 254367.8959 254879.5506 255391.984]');
% Convert monthly population series to quarterly
% the default conversion method is simple averaging.
H.POP = hpf([MA_pop;convert(H.LN16N,4)],[qq(1959,1),Inf]);
F.POP = hpf([MA_pop;convert(F.CNP16OV,4)],[qq(1959,1),Inf]);
delete(fname)
clear url fname data dates MA_pop

%% Create Model Consistent Variable Names
%
% Create a new database with model-consistent measurement variable names
h = struct;
f = struct;
% Output growth (log approximation quarterly)
h.obs_gdp = 100*diff(log(H.GDP/H.JGDP/H.POP));
f.obs_gdp = 100*diff(log(F.GDP/F.GDPCTPI/F.POP));
% Employment/Hours per capita (log hours per capita), quarterly
h.obs_hours = 100*log(3*convert(H.LRPRIVA*H.LE,4)/100/H.POP);
f.obs_hours = 100*log(3*convert(F.AWHNONAG*F.CE16OV,4)/100/F.POP);
% Real Wage Growth
h.obs_wages = 100*diff(log(H.LXNFC/H.JGDP));
f.obs_wages = 100*diff(log(F.COMPNFB/F.GDPCTPI));
% Price Index (not Implicit Price Deflator for GDP)
h.obs_gdpdeflator = 100*diff(log(H.JGDP));
f.obs_gdpdeflator = 100*diff(log(F.GDPCTPI));
% Core PCE for models with factor structure on inflation
h.obs_corepce = 100*diff(log(H.JCXFE));
f.obs_corepce = 100*diff(log(F.JCXFE));
% nominal short-term interest rate (3 months) - % annualized
h.obs_nominalrate = convert(H.FFED,4,'missing=','last')/4;
f.obs_nominalrate = convert(F.DFF,4)/4;
% Consumption growth (log approximation quarterly annualized)
h.obs_consumption = 100*diff(log(H.C/H.JGDP/H.POP));
f.obs_consumption = 100*diff(log(F.PCEC/F.GDPCTPI/F.POP));
% Investment growth (log approximation quarterly annualized)
h.obs_investment = 100*diff(log(H.F/H.JGDP/H.POP));
f.obs_investment = 100*diff(log(F.FPI/F.GDPCTPI/F.POP));
% spread: BAA-10yr TBill for model with Financial Frictions
h.obs_spread = convert(F.BAA-H.FCM10,4)/4; % H.FBAA discontinued
f.obs_spread = convert(F.BAA-F.GS10,4)/4;
% Long Term Inflation Expectations
h.obs_longinflation = (H.ASACX10-0.5)/4;
f.obs_longinflation = (F.INFCPI10YR-0.5)/4;
% Long rate (10-year, zero-coupon)
h.obs_longrate = convert(H.FYCCZA-H.FTPZAC,4)/4;
f.obs_longrate = convert(F.SVENY10-F.THREEFYTP10,4)/4;
% Fernald TFP series
h.obs_tfp = (H.TFPKQ-nanmean(H.TFPKQ))/(4*(1-H.TFPJQ));
f.obs_tfp = (F.DTFP-nanmean(F.DTFP))/(4*(1-F.ALPHA));

%% Clip databases
h = dbclip(h,startHist:endHist);
f = dbclip(f,startHist:endHist);

%% Compare databases
disp('Database differences (Haver vs Fred)');
maxabs(h,f)

%% Save new vintage and load previous vintage from CSV file
dbsave(f,['data_' datestr(now,'yymmdd') '.csv'],startHist:endHist,'comment=',false,'class=',false,'format=','%.16g');
d = dbload('data_150102.csv','freq=',4,'dateFormat=','YYYY-MM-DD','nameRow=','date');

%% Plot Data
%
% The function `dbplot` creates graphs based on the list supplied as the
% third input argument.

% Get NBER based US recession date ranges that will be highlighted.
USRECQ = find(F.USRECQ);
USRECQ = mat2cell(USRECQ,diff([0;find([diff(USRECQ)>1;1])]));

dbplot(f,Inf, ...
    { ...
    ' "Output Growth" obs_gdp ', ...
    ' "Hours Worked" obs_hours ', ...
    ' "Real Wage Growth" obs_wages ', ...
    ' "Inflation (GDP Deflator)" obs_gdpdeflator ', ...
    ' "Inflation (Core PCE)" obs_corepce ', ...
    ' "Federal Funds Rate" obs_nominalrate ', ...
    ' "Consumption Growth" obs_consumption ', ...
    ' "Investment Growth" obs_investment ', ...
    ' "Spread (Baa)" obs_spread ', ...
    ' "10-year Inflation Expectations" obs_longinflation ', ...
    ' "10-year Interest Rate" obs_longrate ', ...
    ' "Total Factor Productivity" obs_tfp ', ...
    }, ...
    'tight=',true, 'highlight=',USRECQ, ...
    'DateFormat=','YY', 'DateTick=',qq(1960:5:2015,1));

ftitle('U.S. Data for FRBNY Model');

%% Derive expected FFR from OIS quotes

% Tullett Prebon series start at 2014Q3
v={'M111F3M','M111F6M','M111F9M','M111FWM','M111FFM','M111FGM','M111FOM','M111FBM','M111FEH','M111FIH','M111FRH','M111F3Y','M111F9S'};
H = feed.haver('\\wahaverdb\DLX\DATA\','INTDAILY',v);
H = dbfun(@(x) convert(x,4,'method=','last'),H);
ois_tp = struct;
ois_tp.obs_ois1 = H.(v{1});
for t=2:numel(v)
    ois_tp.(sprintf('obs_ois%d',t)) = H.(v{t})*t-H.(v{t-1})*(t-1);
end
ois_tp = dbfun(@(x) x/4,ois_tp);

% Reuters series start at 2003Q3, but Haver is missing 15-month, 18-month and 21-month OIS rates
H = feed.haver('\\wahaverdb\DLX\DATA\','INTDAILY',{'T111W3M','T111W6M','T111W9M','T111W1','T111W2','T111W3'});
H = dbfun(@(x) convert(x,4,'method=','last'),H);
ois_r = struct;
ois_r.obs_ois1 = convert(H.T111W3M,4,'method=','last');
ois_r.obs_ois2 = convert(H.T111W6M,4,'method=','last')*2-ois_r.obs_ois1;
ois_r.obs_ois3 = convert(H.T111W9M,4,'method=','last')*3-ois_r.obs_ois1-ois_r.obs_ois2;
ois_r.obs_ois4 = convert(H.T111W1,4,'method=','last')*4-ois_r.obs_ois1-ois_r.obs_ois2-ois_r.obs_ois3;
ois_r.obs_ois8 = (convert(H.T111W2,4,'method=','last')*8-ois_r.obs_ois1-ois_r.obs_ois2-ois_r.obs_ois3-ois_r.obs_ois4)/4;
ois_r.obs_ois12 = (convert(H.T111W3,4,'method=','last')*12-ois_r.obs_ois1-ois_r.obs_ois2-ois_r.obs_ois3-ois_r.obs_ois4)/4-ois_r.obs_ois8;
ois_r = dbfun(@(x) x/4,ois_r);

% Bloomberg OIS rates
ois_data = feed.bloomberg({'USSOC Curncy','USSOF Curncy','USSOI Curncy','USSO1 Curncy','USSO1C Curncy','USSO1F Curncy','USSO1I Curncy','USSO2 Curncy'},'PX_LAST','quarterly');
sec = fieldnames(ois_data);
ois_blp = struct;
ois_blp.obs_ois1 = ois_data.(sec{1});
for t=2:numel(sec)
    ois_blp.(sprintf('obs_ois%d',t)) = ois_data.(sec{t})*t-ois_data.(sec{t-1})*(t-1);
end
clear ois_data sec t
ois_blp = dbfun(@(x) x/4,ois_blp);

warning('off', 'MATLAB:table:ModifiedVarnames');
data = readtable('OIS_Bloomberg.xlsx');
warning('on', 'MATLAB:table:ModifiedVarnames');
data(cellfun(@isempty,data.Var1),:) = [];
dates = str2dat(data.Var1,'dateFormat=','%C%QP YYYY','freq=',4);
data(:,1) = [];
ois_blp = struct;
ois_blp.obs_ois1 = tseries(dates,data{:,1});
for t=2:8
    ois_blp.(sprintf('obs_ois%d',t)) = tseries(dates,data{:,t}*t-data{:,t-1}*(t-1));
end
ois_blp = dbfun(@(x) x/4,ois_blp);
clear data dates

% original CSV file
ois = dbload('ois_150102.csv','freq=',4,'dateFormat=','YYYY-MM-DD','nameRow=','date');
ois = dbfun(@(x) x/4,ois);

dbplot(ois_tp&ois_r&ois_blp&ois,qq(2008,4):endHist);
legend('Tullett Prebon','Reuters','Bloomberg','CSV')

%% Save Data for Future Use
%
% Save the final database and the dates in a mat-file (binary file) for
% future use.

ois_blp = dbclip(ois_blp,qq(2008,4):endHist);
d = dbmerge(f,ois_blp);

save read_data.mat d startHist endHist;

%% Help on IRIS Functions Used in This File
%
% Use either `help` to display help in the command window, or `idoc`
% to display help in an HTML browser window.
%
%   help dbload
%   help dbbatch
%   help tseris/acf
%   help tseries/apct
%   help tseries/convert
%   help tseries/x12
%   help qreport/qplot
%   help qreportlang
