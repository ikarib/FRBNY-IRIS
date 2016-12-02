%% Read and Solve Model
%
% Create a model object by loading the model file `Simple_SPBC.model`,
% assign parameters to the model object, find its steady state, and compute
% the first-order accurate solution. The model object is then saved to a
% mat file, and ready for further experiments.

%% Clear Workspace
%
% Clear workspace, close all graphics figures, clear command window, and
% check the IRIS version.

clear; clc; close all
irisrequired 20151016

%% Read Model File and Create Model Object
%
% The function `model` reads the model file and translates it into a model
% object, called here `m`. Model objects are complex structures that carry
% all the information needed about the model, and can be manipulated by
% calling some of the IRIS functions.

% When reading the model file in, create a model control parameter database,
% include required fields and use the option 'assign=' to pass the database in.
o = struct;
o.kimball = true; % Kimball aggregator
o.bgg = true; % BGG financial frictions
o.nant = 0; % Number of anticipated policy shocks

m = model('frbny.model','assign=',o,'linear=',false);

%% Read and Display Model Parameters
%
% Use the function `get` <?get?> to retrieve a database with currently assigned
% parameter values in the model file.

disp('Get a parameter database from the model object');
get(m,'parameters') %?get?

%% Compute First Order Solution and Steady State
%
% Compute and numerically check the steady-state values for all model
% variables. The option `'blocks=' true` allows to explore the
% steady-state structure of the model, and makes the numerical solution
% more efficient by splitting the system of steady-state equations into
% smaller recusrive blocks clusters.

if islinear(m)
    m = solve(m);
    m = sstate(m);
else
    m = sstate(m);
    m = solve(m);
end
chksstate(m);

disp('Solved model')
m %#ok<NOPTS>

%% Save Model Object
%
% Save the solved model object to a mat-file (binary file) for future use.

save read_nonlin_model.mat m o;

%% Help on IRIS Functions Used in This File
%
% Use either `help` to display help in the command window, or `idoc`
% to display help in an HTML browser window.
%
%    help model/model
%    help model/subsasgn
%    help model/assign
%    help model/sstate
%    help model/chksstate
%    help model/solve
