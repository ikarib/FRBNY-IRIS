%% Import CSV Data Files and Prepare Data
%
% Load basic data from CSV data files into databases where each series is
% represented by a tseries (time series) object. Prepare the data to be
% used later with the model: seasonally adjust, convert to quaterly
% periodicity, and create model-consistent variable names.

%% Clear Workspace
%
% Clear workspace, close all graphics figures, clear command window, and
% check the IRIS version.

clear; clc; close all
irisrequired 20151016

%% Set the start and end dates for the historical series
startHist = qq(1959,3);
endHist = qq(2014,4);
disp('Historical range');
dat2str([startHist,endHist])

%% Load the raw series from Haver Analaytics
hpath='\\wahaverdb\DLX\DATA\';
c=haver([hpath 'USECON.dat']);
v={'GDP','C','F','JGDP','LN16N','FBAA','FCM10','TFPJQ','TFPKQ','LXNFC','LRPRIVA','LE'};
d=fetch(c,v);
i=info(c,v);
close(c)
c=haver([hpath 'USNA.dat']);
v={'JCXFE'};
d=[d fetch(c,v)];
i=[i info(c,v)];
close(c)
c=haver([hpath 'DAILY.dat']);
v={'FFED','FYCCZA','FTPZAC'};
d=[d fetch(c,v)];
i=[i info(c,v)];
close(c)
c=haver([hpath 'SURVEYS.dat']);
v={'ASACX10'};
d=[d fetch(c,v)];
i=[i info(c,v)];
close(c)
H=struct;
for j=1:size(d,2)
    % create dates
    switch i(j).Frequency
        case 'D'
            dates=d{j}(:,1);
        case 'M'
            dates=mm(year(d{j}(1)),month(d{j}(1)));
        case 'Q'
            dates=qq(year(d{j}(1)),month(d{j}(1))/3);
        case 'Y'
            dates=yy(year(d{j}(1)));
        otherwise
            error('unknown freq: %s',i(j).Frequency)
    end
    c=evalc('disp(i(j))'); % comment
    H.(i(j).VarName)=tseries(dates,d{j}(:,2),c);
end
clear hpath c v d i j dates
disp('Haver Database');
H %#ok<NOPTS>

%% Retrieve the raw series from FRED, Federal Reserve Bank of St. Louis
c = fred('https://research.stlouisfed.org/fred2/');
d = fetch(c,{'GDP','GDPCTPI','PCEC','FPI','AWHNONAG','CE16OV','CNP16OV','COMPNFB','JCXFE','DFF','BAA','GS10','THREEFYTP10'});
% not used here but used in Julia code:
% PCEPILFE - Personal Consumption Expenditures Excluding Food and Energy (Chain-Type Price Index)
% UNRATE - Civilian Unemployment Rate
% CLF16OV - Civilian Labor Force
% PRS85006013 - Nonfarm Business Sector: Employment
% PRS85006063 - Nonfarm Business Sector: Compensation
% CES0500000030- Average Weekly Earnings of Production and Nonsupervisory Employees: Total Private
close(c)
F=struct;
for j=1:size(d,2)
    % create dates
    switch strtrim(d(j).Frequency)
        case {'Daily','Daily, 7-Day'}
            dates=d(j).Data(:,1);
        case 'Monthly'
            dates=mm(year(d(j).Data(1)),month(d(j).Data(1)));
        case 'Quarterly'
            dates=qq(year(d(j).Data(1)),(month(d(j).Data(1))+2)/3);
        otherwise
            error('unknown freq: %s',d(j).Frequency)
    end
    c=evalc('disp(d(j))'); % comment
    F.(strtrim(d(j).SeriesID))=tseries(dates,d(j).Data(:,2),c);
end
clear c d j dates
disp('FRED Database');
F %#ok<NOPTS>

%% Other data sources
% The Total Factor Productivity series components are made available
% by the Federal Reserve Bank of San Francisco, and can be found at
% http://www.frbsf.org/economic-research/total-factor-productivity-tfp/
% (series alpha and dtfp from the linked spreadsheet).
url = 'http://www.frbsf.org/economic-research/files/';
fname = 'quarterly_tfp.xls';
if ~exist(fname,'file'); fname = websave(fname,[url fname]); end
[data,dates] = xlsread(fname,'quarterly','A3:L281');
dates = str2dat(dates,'dateFormat=','YYYY:%QP','freq=',4);
F.ALPHA = tseries(dates,data(:,10));
F.DTFP = tseries(dates,data(:,11));

% The 10-year Inflation Expectations series from the Survey of Professional
% Forecasters is made available by the Federal Reserve Bank of Philadelphia,
% and can be found at
% https://www.philadelphiafed.org/research-and-data/real-time-center/survey-of-professional-forecasters/historical-data/inflation-forecasts
% (series INFCPI10YR from the linked spreadsheet).
url = 'https://www.philadelphiafed.org/-/media/research-and-data/real-time-center/survey-of-professional-forecasters/historical-data/';
fname = 'inflation.xls';
if ~exist(fname,'file'); fname = websave(fname,[url fname]); end
data = xlsread(fname,'A2:E189');
dates = qq(data(:,1),data(:,2));
F.INFCPI10YR = tseries(dates,data(:,5));
fname = 'additional-cpie10.xls';
if ~exist(fname,'file'); fname = websave(fname,[url fname]); end
[data,dates] = xlsread(fname,'A15:D61');
dates = str2dat(dates(:,1),'dateFormat=','YYYY:P','freq=',4);
F.INFCPI10YR(dates) = data(:,3);

% The 10-year Treasury Yield (zero-coupon, continuously compounded) series
% is made available by the Board of Governors of the Federal Reserve System,
% and can be found at
% http://www.federalreserve.gov/pubs/feds/2006/200628/200628abs.html
% (series SVENY10 from the linked spreadsheet)
url = 'https://www.federalreserve.gov/econresdata/researchdata/';
fname = 'feds200628.xls';
if ~exist(fname,'file'); fname = websave(fname,[url fname]); end
[data,dates] = xlsread(fname,'A11:K13839');
dates = str2dat(dates,'dateFormat=','YYYY-MM-DD','freq=',365)';
F.SVENY10 = tseries(dates,data(:,10));
clear fname data dates

%% Convert Monthly Population Series to Quarterly
%
% Convert the monthly series to quarterly
% the default conversion method is simple averaging.
popreal = convert(H.LN16N,4);
% population forecasted by Macro Advisers
MA_pop = tseries(endHist,[248842.6666 249799.5291 250273.88 250785.5347 251296.4105 251808.0652 252319.7198 252831.3745 253343.8079 253855.4625 254367.8959 254879.5506 255391.984]');
smpl = qq(1959,1):endHist;
% Run HP Filter
popfor = hpf([MA_pop;popreal{smpl}],@all);
population = popfor{smpl};
% MA_pop = popfor{specrange(MA_pop,@all)};
% dlpopreal = diff(log(popreal));
% dlpopall = diff(log(population));
% dlMA_pop = diff(log(MA_pop));
clear popreal MA_pop smpl MA_pop smpl popfor

%% Create Model Consistent Variable Names
%
% Create a new database with model-consistent measurement variable names.

% Output growth (log approximation quarterly)
h.obs_gdp = 100*diff(log(H.GDP/H.JGDP/population));
f.obs_gdp = 100*diff(log(F.GDP/F.GDPCTPI/population));
% Employment/Hours per capita (log hours per capita)
h.obs_hours = 100*log(3*convert(H.LRPRIVA*H.LE,4)/100/population);
f.obs_hours = 100*log(3*convert(F.AWHNONAG*F.CE16OV,4)/100/population);
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
h.obs_nominalrate = convert(H.FFED,4)/4;
f.obs_nominalrate = convert(F.DFF,4)/4;
% Consumption growth (log approximation quarterly annualized)
h.obs_consumption = 100*diff(log(H.C/H.JGDP/population));
f.obs_consumption = 100*diff(log(F.PCEC/F.GDPCTPI/population));
% Investment growth (log approximation quarterly annualized)
h.obs_investment = 100*diff(log(H.F/H.JGDP/population));
f.obs_investment = 100*diff(log(F.FPI/F.GDPCTPI/population));
% spread: BAA-10yr TBill for model with Financial Frictions
h.obs_spread = convert(H.FBAA-H.FCM10,4)/4;
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

%% Compare databases
disp('Database differences (Haver vs Fred)');
maxabs(h,f)

%% Load sample dataset provided for the 2015 Nov 27 vintage in Julia package
%
d = dbload('data_150102.csv','freq=',4,'dateFormat=','YYYY-MM-DD','nameRow=','date');

%% Plot Data
%
% The function `dbplot` creates graphs based on the list supplied as the
% third input argument.

dbplot(d&h&f,Inf, ...
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
    'tight=',true);

grfun.ftitle('U.S. Data for FRBNY Tutorial');

%% Save Data for Future Use
%
% Save the final database and the dates in a mat-file (binary file) for
% future use.

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
