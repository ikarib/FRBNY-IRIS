%% Assign and Change Parameters and Steady States
%
% Assign or change the values of parameters and/or steady states of
% variables in a model object using a number of different ways. Under
% different circumstances, different methods of assigning parameters may be
% more convenient (but they, of course, all do the same job).

%% Clear Workspace
%
% Clear workspace, close all graphics figures, clear command window, and
% check the IRIS version.

clear; clc; close all
irisrequired 20151016
%#ok<*NOPTS>
%#ok<*NASGU>

%% Load Solved Model Object and Historical Database
%
% Load the solved model object built `read_linear_model`. You must run
% `read_linear_model` at least once before running this m-file.

load read_linear_model.mat;

%% Read Model File and Assign Parameters to Model Object
%
% The easiest way to assign or change parameters is simply by using the
% dot-reference, i.e. the name of the model object dot the name of the
% parameter <?dotRef?>.

m.alp = 0.16; %?dotRef?
m.del = 0.03;
m.gam_ = 0.4;
m.rho = 0.8;
m.std_g_sh = 3;
m.std_rm_sh = 0.3;

%% Assign Parameter Database When Reading Model File
%
% Create first a database with the desired parameter values <?paramDbase?>
% (or use an existing one, for example), and assign the database when
% reading the model file, i.e. when calling the function `model`
% <?assignOpt?>, by using the option `assign=`.

P = struct();
P.kimball = true; P.bgg = true; P.nant = 6; % required control parameters
P.alp = 0.16; %?paramDbase?
P.del = 0.03;
P.gam_ = 0.4;
P.rho = 0.8;
P.std_g_sh = 3;
P.std_rm_sh = 0.3;

m = model('frbny.model','assign=',P,'linear=',true); %?assignOpt?

%% Åssign Parameter Database After Reading Model File
%
% Here, use again a parameter database, but assign the database after
% reading the model file, in a separate call to the function `assign`
% <?assignDbaseAfter?>.

m = model('frbny.model','assign=',o,'linear=',true);

m = assign(m,P); %?assignDbaseAfter?>

%% Change Parameters in Model Object
%
% There are several ways how to change some of the parameters. All the
% following three blocks of code do exactly the same.
%
% Refer directly to the model object using a model-dot-name notation.

m.alp = 0.16;
m.del = 0.03;

% ...
%
% Use the function `assign` and specify name-value pairs; you can
% optionally use the equal signs <?equalSigns?>.

m = assign(m,'alp',0.16,'del',0.03);
% m = assign(m,'chi=',0.9,'xip=',100); %?equalSigns?

% ...
%
% Create a database with the new values, and call the function `assign`.

P = struct();
P.alp = 0.16;
P.del = 0.03;
m = assign(m,P);

% ...
%
% Reset the parameters to their original values.

m.alp = 0.1793;
m.del = 0.025;

%% Speedy Way to Repeatedly Change Parameters
%
% If you need to iterate over a number of different parameterisations, use
% the fast version of the function `assign`. First, initialise the fast
% `assign` by specifying the list of parameters (and nothing else)
% <?fastInit?>. Then, use `assign` repeatedly to pass different sets of
% values (in the same order) to the model object <?fastAssign?>. Compare
% the time needed to assign 1,000 different pairs of values for two
% parameters.

load read_linear_model m;

alps = linspace(0.1,0.3,1000);
dels = linspace(0.01,0.04,1000);

assign(m,{'alp','del'}); %?fastInit?

tic
for i = 1 : 1000
   m = assign(m,[alps(i),dels(i)]); %?fastAssign?
end
toc

tic
for i = 1 : 1000
   m.alp = alps(i);
   m.del = dels(i);
end
toc

%% Assign or Change Steady State Manually
%
% If you wish to manually change some of the steady-state values (or, for
% instance, assign all of them because they have been computed outside the
% model), treat the steady-state values the same way as parameters.


m = sstate(m);
chksstate(m)
disp('Steady-state database')
sstate_database = get(m,'sstate')

% ...
%
% Change the levels of `y` and `c` using the
% model-dot-name notation.

m.y = 2;
m.c = 1;

% ...
%
% Change the steady states for `y` and `c` using the function `assign` with
% name-pair values.

m = assign(m,'y',2,'c',1);

% ...
%
% Change the steady states by creating a database with the new values, and
% passing the database in `assign`.

P = struct();
P.y = 2;
P.c = 1;
m = assign(m,P);

% ...
%
% Note that the newly assigned steady states are, of course, not consistent
% with the model.

disp('Check steady state -- it does not hold');
[flag,list] = chksstate(m,'error=',false);
flag
list.'

% ...
%
% Reset the steady state to the original values.

m = assign(m,sstate_database);
disp('Check steady state -- it holds');
chksstate(m)

%% Help on IRIS Functions Used in This File
%
% Use either `help` to display help in the command window, or `idoc`
% to display HTML help in a browser window.
%
%    help model/model
%    help model/subsasgn
%    help model/assign
%    help model/chksstate
