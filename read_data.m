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
irisrequired 20151016

%% Set the start and end dates for the historical series
startHist = qq(1959,3);
endHist = qq(2014,4);
disp('Historical range');
dat2str([startHist,endHist])

%% Load the raw series from Haver Analaytics
if license('test','datafeed_toolbox')
    hpath='\\wahaverdb\DLX\DATA\'; % set your local path here
    fprintf('Connecting to the Haver Analytics database at the path %s ...\n',hpath);
    try
        c=haver([hpath 'USECON.dat']);
        v={'GDP','C','F','JGDP','JCXFE','LN16N','FBAA','FCM10','TFPJQ','TFPKQ','LXNFC','LRPRIVA','LE'};
        d=fetch(c,v);
        i=info(c,v);
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
    catch E
		warning(E.message)
        for v={'GDP','C','F','JGDP','LN16N','FBAA','FCM10','TFPJQ','TFPKQ','LXNFC','LRPRIVA','LE','JCXFE','FFED','FYCCZA','FTPZAC','ASACX10'}; H.(v{1})=tseries; end
		fprintf('Will try FRED next.\n');
    end
end

%% Retrieve the raw series from FRED, Federal Reserve Bank of St. Louis
if license('test','datafeed_toolbox')
	% Load data from FRED and convert to quarterly periodicity
	% Note that Dates are start-of-period Dates in the FRED database
    fprintf('Connecting to the St. Louis Federal Reserve database (FRED) ...\n');
	% FRED time series to be used for our analysis
    Series = {'GDP','GDPCTPI','PCEC','FPI','AWHNONAG','CE16OV','CNP16OV','COMPNFB','JCXFE','DFF','BAA','GS10','THREEFYTP10'};
    try
        c = fred('https://research.stlouisfed.org/fred2/');
        d = fetch(c,Series);
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
    catch E
		% Case with no internet connection
        warning(E.message)
		fprintf('Will use data from CSV file.\n');
    end
end

%% Other data sources
% The Total Factor Productivity series components are made available
% by the Federal Reserve Bank of San Francisco, and can be found at
% http://www.frbsf.org/economic-research/total-factor-productivity-tfp/
% (series alpha and dtfp from the linked spreadsheet).
url = 'http://www.frbsf.org/economic-research/files/';
fname = 'quarterly_tfp.xls';
fname = websave([tempdir fname],[url fname]);
[data,dates] = xlsread(fname,'quarterly','A3:L300');
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
fname = websave([tempdir fname],[url fname]);
data = xlsread(fname,'A2:E200');
dates = qq(data(:,1),data(:,2));
F.INFCPI10YR = tseries(dates,data(:,5));
fname = 'additional-cpie10.xls';
fname = websave([tempdir fname],[url fname]);
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
fname = websave([tempdir fname],[url fname]);
[data,dates] = xlsread(fname,'A11:K15000');
dates = str2dat(dates,'dateFormat=','YYYY-MM-DD','freq=',365)';
F.SVENY10 = tseries(dates,data(:,10));

%% Population forecasted by Macro Advisers
% url = 'https://macroadvisers.bluematrix.com/sellside/EmailDocViewer';
% fname = '9096_fa097bed-4065-4531-a82b-777609989921.xlsx';
% fname = websave([tempdir fname],url,'encrypt','7fc2fad0-58b0-4183-9846-9bb56bb74182','mime','xlsx','attachmentName',fname);
% data = xlsread(fname,'B1827:Q1841');
% dates = qq(floor(data(1,:)),round(rem(data(1,:),1)*10));
% MA_pop = tseries(dates,round(data(15,:)'*1000,4));
% clear url fname data dates 
MA_pop = tseries(qq(2014,4),[248842.6666 249799.5291 250273.88 250785.5347 251296.4105 251808.0652 252319.7198 252831.3745 253343.8079 253855.4625 254367.8959 254879.5506 255391.984]');
% MA_pop = tseries(qq(2016,1),[252580.6732 253179.9927 253854.9957 254537.0789 255173.8892 255804.9622 256407.6233 257010.2539 257612.9456 258215.6067 258818.2068 259420.7764 260023.3765 260625.9460 261231.4148 261836.8835]');
% Convert monthly population series to quarterly
% the default conversion method is simple averaging.
H.POP = hpf([MA_pop;convert(H.LN16N,4)],[qq(1959,1),Inf]);
F.POP = hpf([MA_pop;convert(F.CNP16OV,4)],[qq(1959,1),Inf]);
clear MA_pop

%% Create Model Consistent Variable Names
%
% Create a new database with model-consistent measurement variable names.

% Output growth (log approximation quarterly)
h.obs_gdp = 100*diff(log(H.GDP/H.JGDP/H.POP));
f.obs_gdp = 100*diff(log(F.GDP/F.GDPCTPI/F.POP));
% Employment/Hours per capita (log hours per capita)
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
h.obs_nominalrate = convert(H.FFED,4)/4;
f.obs_nominalrate = convert(F.DFF,4)/4;
% Consumption growth (log approximation quarterly annualized)
h.obs_consumption = 100*diff(log(H.C/H.JGDP/H.POP));
f.obs_consumption = 100*diff(log(F.PCEC/F.GDPCTPI/F.POP));
% Investment growth (log approximation quarterly annualized)
h.obs_investment = 100*diff(log(H.F/H.JGDP/H.POP));
f.obs_investment = 100*diff(log(F.FPI/F.GDPCTPI/F.POP));
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

dbsave(f,['data_' datestr(now,'yymmdd') '.csv'],startHist:endHist,'comment=',false,'class=',false,'format=','%.16g');

%% Load dataset from CSV file
%
fprintf('Loading data from data_150102.csv ...\n');
d = dbload('data_150102.csv','freq=',4,'dateFormat=','YYYY-MM-DD','nameRow=','date');
% d = dbload('debug/data_151127.csv','freq=',4,'dateFormat=','YYYY-MM-DD','nameRow=','date');

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

ftitle('U.S. Data for FRBNY Tutorial');

%% Loads in expected FFR derived from OIS quotes
% ois = history(blp,strcat({'USSOC','USSOF','USSOI','USSO1','USSO1C','USSO1F','USSO1I','USSO2'},' Curncy'),'PX_LAST','12/31/2008',today,'quaterly');
ois = dbload('ois_150102.csv','freq=',4,'dateFormat=','YYYY-MM-DD','nameRow=','date');
d = dbmerge(d,dbfun(@(x) x/4,ois));
% ois = dbload('ois_161205.csv','freq=',4,'dateFormat=','DD/MM/YYYY');
% v = fieldnames(ois);
% for i=1:numel(v)
%     d.(['obs_ois' num2str(i)]) = ois.(v{i})/4;
% end
% clear ois v i

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
