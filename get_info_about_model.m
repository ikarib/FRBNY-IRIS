%% Get Information About Model Object
%
% Use the function `get` (and a few others) to access various pieces of
% information about the model and its properties, such as variable names,
% parameter values, equations, lag structure, or the model eigenvalues. Two
% related topics are furthermore covered in separate files:
% assigning/changing parameters and steady-state values, and accessing
% model solution matrices.

%% Clear Workspace
%
% Clear workspace, close all graphics figures, clear command window, and
% check the IRIS version.

clear; clc; close all
irisrequired 20151016
%#ok<*NOPTS>

%% Load Solved Model Object and Historical Database
%
% Load the solved model object built `read_linear_model`. You must run
% `read_linear_model` at least once before running this m-file.

load read_linear_model.mat m;

%% Names of Variables, Shocks and Parameters

disp('List of transition variables');
get(m,'xList')'

disp('List of measurement variables');
get(m,'yList')'

disp('List of shocks');
get(m,'eList')'

disp('List of parameters');
get(m,'pList')'

%% Description of Variables, Shocks and Parameters

disp('Database with descriptions of all variables, shocks and parameters');
get(m,'descript')

disp('List of descriptions of transition variables');
get(m,'xDescript')'

%% Equations and Equation Labels

disp('Transition equations')
get(m,'xEqtns')

disp('Measurement equations')
get(m,'yEqtn')

disp('Transition equation labels')
get(m,'xLabels')

disp('Equation with whose label is Production function');
findeqtn(m,'Aggregate Production Function')

disp('Equations whose labels start with P');
findeqtn(m,rexp('^P.*'))

%% Comments and User Data
%
% Assign a text comment or any kind of user data to a model object using
% the functions `comment` and `userdata`, respectively. The same functions
% are also used to get the current comment or the user data. It's only your
% business whether and how you use these.

c = comment(m)

m = comment(m,'New comment');
comment(m)

m = comment(m,c);

x = struct();
x.ToDo = 'Fix this and that';
x.SomeRandNumbers = rand(1,10);

m = userdata(m,x)

userdata(m)

%% Different Ways to Get and Assign/Change Parameters
%
% There are multiple equivalent ways how to view and assign parameters.
% Display the parameter 'gamma', and change the values for two std
% deviations, 'std_ep' and 'std_ew'.

P = get(m,'parameters');
P.gam

m.gam

s = struct();
s.std_b_sh = 0.02;
s.std_pist_sh = 0.02;
m = assign(m,s);

m = assign(m,'std_b_sh',0.02,'std_pist_sh',0.02);

m.std_b_sh = 0.02;
m.std_pist_sh = 0.02;

%% Check Stationarity
%
% The logical value `true` is displayed as `1`, the logical value `false`
% is displayed as `0`.

disp('Is the model stationary?');
isstationary(m)

disp('Is the variable stationary?');
get(m,'stationary')

disp('List of stationary variables');
get(m,'stationaryList')'

disp('List of non-stationary variables');
get(m,'nonstationaryList')'

%% Get Currently Assigned Steady State
%
% Steady state is described by complex numbers:
%
% * real part = steady-state levels
% * imaginary part = steady-state growth
%
% The interpretation of the steady-state growth rates
% differs for linearised versus log-linearised variables:
% * linearised variables: x(t) - x(t-1)
% * log-linearised variables: x(t) / x(t-1)

disp('Steady-state levels and growth rates');
get(m,'sstate')

disp('Steady-state levels');
get(m,'sstateLevel')

disp('Steady-state growth rates')
get(m,'sstateGrowth')

disp('Is the variable a log-variable?');
get(m,'log')

disp('List of log-variables');
get(m,'logList')  

%% Lags and Initial Conditions

disp('Maximum lag in the model');
get(m,'maxLag')

disp('List of initial conditions needed for simulations and forecasts');
get(m,'required')'

%% Eigenvalues
%
% Get stable, unit, or unstable eigenvalues (roots). Plot the stable roots
% in a unit circle. Display the dominant (largest) stable root, and the
% dominant (smallest) unstable root.

format('short','e');

disp('Model eigenvalues');
all_roots = get(m,'roots');
all_roots.'

stable_roots = get(m,'stableRoots');
unit_roots = get(m,'unitRoots');
unstable_roots = get(m,'unstableRoots');

disp('Stable roots');
stable_roots.'

disp('Unit roots');
unit_roots.'

disp('Unstable roots');
unstable_roots.'

format();

figure();
ploteig(stable_roots);
title('Stable roots of the model');

[~,index] = sort(abs(stable_roots),'descend');
stable_roots = stable_roots(index);
[~,index] = sort(abs(unstable_roots),'ascend');
unstable_roots = unstable_roots(index);

disp('Largest stable root');
stable_roots(1)
disp('Smallest unstable root and its inverse');
[unstable_roots(1),1./unstable_roots(1)]

%% Help on IRIS Functions Used in This File
%
%    help model/comment
%    help model/findeqtn
%    help model/get
%    help model/subsref
%    help model/subsasgn
%    help model/userdata
