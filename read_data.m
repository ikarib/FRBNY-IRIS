%% Import CSV Data Files and Prepare Data
% by Jaromir Benes
%
% Load basic data from CSV data files into databases where each series is
% represented by a tseries (time series) object. Prepare the data to be
% used later with the model: seasonally adjust, convert to quaterly
% periodicity, and create model-consistent variable names.

%% Clear Workspace
%
% Clear workspace, close all graphics figures, clear command window, and
% check the IRIS version.

clear;
close all;
clc;
irisrequired 20140315;

%% Load CSV Data File
%
% The series in the `Simple_SPBC.csv` file has been downloaded from
% <http://research.stlouisfed.org/fred2>.
%
% Quarterly series:
%
% * `GDPC96` -- Real Gross Domestic Product, 3 Decimal
% * `GDPCTPI` -- Gross Domestic Product: Chain-type Price Index
%
% Monthly series:
%
% * `AHETPI` -- Average Hourly Earnings: Total Private Industries
% * `CPILEGNS` -- Consumer Price Index for All Urban Consumers: All Items
% Less Energy, Seasonally Not Adjusted
% * `CPILEGSL` -- Consumer Price Index for All Urban Consumers: All Items
% Less Energy, Seasonally Adjusted
% * `GS5` -- 5-Year Treasury Constant Maturity Rate
% * `PCE` -- Personal Consumption Expenditures
% * `PCEC96` -- Real Personal Consumption Expenditures
% * `TB3MS` -- 3-Month Treasury Bill: Secondary Market Rate
%
% Daily series:
%
% * `SP500` -- S&P 500 Index

rawQ = dbload('Simple_SPBC_quarterly.csv', ...
    'freq=',4,'dateFormat=','YYYY-MM-01');

rawM = dbload('Simple_SPBC_monthly.csv', ...
    'dateFormat=','YYYY-MM-01');

rawD = dbload('Simple_SPBC_daily.csv', ...
   'freq=',365,'dateFormat=','YYYY-MM-DD');

disp('Quarterly Database');
rawQ %#ok<NOPTS>

disp('Monthly Database');
rawM %#ok<NOPTS>

disp('Daily Database');
rawD %#ok<NOPTS>

%% Display Daily Series
%
% Daily time series are printed in tabular format on the screen, with each
% month occupying one entire row.

rawD.SP500

%% Seasonally Adjust Some Series
%
% The only seasonal series is `CPILEGNS`. Run the standard `X12` on it, and
% compare the results with `CPILEGSL` which is the same CPI series but
% seasonally adjusted by the U.S. Department of Labor. Check the
% correlations between the three consumer deflator series.

rawM.CPILEGNSsa = x12(rawM.CPILEGNS);

figure();
plot(pct([rawM.CPILEGNS,rawM.CPILEGNSsa,rawM.CPILEGSL]));
axis tight;
grid on;
legend('CPILEGNS','CPILEGNS X12 adjusted','CPILEGSL');
title('CPI Inflation, 1Q ROC');

[C,R] = acf(pct([rawM.CPILEGNS,rawM.CPILEGNSsa,rawM.CPILEGSL]));
disp('Cross-Correlations CPILEGNS, CPILEGNSsa, CPILEGSL, 1Q Growth Rates');
R %#ok<NOPTS>

%% Convert Monthly and Daily Series to Quarterly
%
% Convert the daily and monthly series to quarterly, and add them to the
% database `Raw4`; the default conversion method is simple averaging.
% Create also a new series for the consumer deflator.

rawQ.AHETPI = convert(rawM.AHETPI,4);
rawQ.CPILEGNS = convert(rawM.CPILEGNS,4);
rawQ.CPILEGNSsa = convert(rawM.CPILEGNSsa,4);
rawQ.CPILEGSL = convert(rawM.CPILEGSL,4);
rawQ.GS5 = convert(rawM.GS5,4);
rawQ.PCE = convert(rawM.PCE,4);
rawQ.PCEC96 = convert(rawM.PCEC96,4);
rawQ.TB3MS = convert(rawM.TB3MS,4);
rawQ.SP500 = convert(rawD.SP500,4);

rawQ.PCEP = rawQ.PCE/rawQ.PCEC96;

disp('Combined quarterly, monthly and daily data');
disp('(converted all to quarterly)');
rawQ %#ok<NOPTS>

% ...
%
% The six conversion lines above can be replaced with the following single
% batch command:
%
%    Raw4 = dbbatch(Raw,'$0','convert(Raw12.$0,"quarterly")');


%% Create Model Consistent Variable Names
%
% Create a new database with model-consistent measurement variable names.
% Also find the start and end dates for the historical series (based on the
% `Growth` series, which has the longest release lag). The function `apct`
% calculates annualised percent rates of change.

d = struct();

d.Infl = apct(rawQ.GDPCTPI); % apct(Raw4.PCEP);
d.Short = rawQ.TB3MS;
d.Growth = apct(rawQ.GDPC96); %apct(Raw4.PCEC96);
d.Wage = apct(rawQ.AHETPI);
d.Asset = apct(rawQ.SP500);
d.Long = rawQ.GS5;

startHist = get(d.Growth,'start');
endHist = get(d.Growth,'end');

disp('Historical range');
dat2str(startHist:endHist)

%% Run HP Filter with Tunes
%
% Illustrate the use of the HP filter with tunes, and plot the trends
% against the data. The trends are calculated for this example only, and
% are not needed otherwise.

% ...
%
% * Inflation

d.Infl_tnd = hpf(d.Infl); %?plainHP?

x = tseries();
x(endHist) = 2.5;
d.Infl_tnd2 = hpf(d.Infl,Inf,'lambda=',5000,'level=',x); %?HPwithtunes?

% ...
%
% * Wage inflation

d.Wage_tnd = hpf(d.Wage); %?plainHP?

x = tseries();
x(endHist) = 0;
d.Wage_tnd2 = hpf(d.Wage,Inf,'lambda=',5000,'change=',x); %?HPwithtunes?

% ...
%
% * Short interest rates

d.Short_tnd = hpf(d.Short); %?plainHP?

x = tseries();
x(endHist) = 0;
d.Short_tnd2 = hpf(d.Short,Inf,'lambda=',5000,'change=',x); %?HPwithtunes?

% ...
%
% * Long interest rates

d.Long_tnd = hpf(d.Long); %?plainHP?

x = tseries();
x(endHist) = 0;
d.Long_tnd2 = hpf(d.Long,Inf,'lambda=',5000,'change=',x); %?HPwithtunes?

% ...
%
% * Growth

d.Growth_tnd = hpf(d.Growth); %?plainHP?

x = tseries();
x(endHist) = 2;
d.Growth_tnd2 = hpf(d.Growth,Inf,'lambda=',5000,'level=',x); %?HPwithtunes?

% ...
%
% * Asset price change

d.Asset_tnd = hpf(d.Asset); %?plainHP?

x = tseries();
x(endHist) = 0;
d.Asset_tnd2 = hpf(d.Asset,Inf,'lambda=',5000,'change=',x); %?HPwithtunes?

d %#ok<NOPTS>

% ...
%
% * <?plainHP?> Plain HP with the default $\lambda$ for quarterly series
% $\lambda = 1,600$.
% * <?HPwithtunes?> HP with a stiffer trend, $\lambda = 5,000$, and tunes
% on the trend paths. Note that the tunes are imposed either on the level
% of the trend, or on the change in the trend, depending on the variable.

%% Plot Data
%
% The function `dbplot` creates graphs based on the list supplied as the
% third input argument.

dbplot(d,Inf, ...
	{ ...
    ' "Consumer Deflator Inflation, 1Q ROC PA" [Infl,Infl_tnd,Infl_tnd2]', ...
    ' "Wage Inflation, 1Q ROC PA" [Wage,Wage_tnd,Wage_tnd2]', ...
    ' "3-Month Treasury Bill Rate, PA" [Short,Short_tnd,Short_tnd2]', ...
    ' "5-Year Treasury Const Maturity Rate, PA" [Long,Long_tnd,Long_tnd2]', ...
    ' "Consumption Growth, 1Q ROC PA" [Growth,Growth_tnd,Growth_tnd2]', ...
    ' "Asset Price Change, 1Q ROC PA" [Asset,Asset_tnd,Asset_tnd2]', ...
    }, ...
    'tight=',true);

grfun.bottomlegend('Data','HP Plain','HP Tuned');
grfun.ftitle('U.S. Data for SPBC Tutorial');

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
