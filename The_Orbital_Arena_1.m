% ==========================================
% PHASE 1: 5G NTN D2C SIMULATOR
% Setting up the World, Ground Station, and Orbit
% ==========================================

% Clean up the workspace
clear; clc; close all;

%% 1. Initialize the Time and Scenario
% We will simulate a 4-hour window starting from right now.
% The 'sampleTime' of 10 means MATLAB calculates the physics every 10 seconds.
startTime = datetime('now', 'TimeZone', 'UTC');
stopTime = startTime + hours(4);
sampleTime = 10; 

scenario = satelliteScenario(startTime, stopTime, sampleTime);

%% 2. Place the Ground Station (The Smartphone)
% Coordinates for Komotini, Greece
latKomotini = 41.119;
lonKomotini = 25.405;

% We set a 'MinElevationAngle' of 10 degrees. In the real world, 
% buildings and trees block signals at the horizon, so the sat 
% must be at least 10 degrees up in the sky to connect.
phone = groundStation(scenario, latKomotini, lonKomotini, ...
    'Name', 'Smartphone (Komotini)', ...
    'MinElevationAngle', 10);

%% 3. Launch the D2C Satellite
% We use Keplerian Elements to define the orbit.
% Earth's radius is roughly 6371 km. We want a 500 km altitude.
earthRadius = 6371000; 
altitude = 500000; 

semiMajorAxis = earthRadius + altitude; % in meters
eccentricity = 0;                       % 0 = perfectly circular orbit
inclination = 53;                       % 53 degrees (standard for Starlink-style orbits)
rightAscension = 0;
argumentOfPeriapsis = 0;
trueAnomaly = 60;                       % Initial position in the orbit

% Inject the satellite into the scenario
d2c_sat = satellite(scenario, semiMajorAxis, eccentricity, inclination, ...
    rightAscension, argumentOfPeriapsis, trueAnomaly, ...
    'Name', 'NTN-Sat-1');

%% 4. Compute the Access (Line of Sight)
% This tells MATLAB to mathematically find the time windows where 
% the satellite has a clear, unobstructed view of the phone.
satAccess = access(phone, d2c_sat);

% Extract the access intervals to print to the command window
accessIntervals = accessIntervals(satAccess);
disp('Visibility Windows for Komotini:');
disp(accessIntervals);

%% 5. Visualize the World
% Launch the interactive 3D viewer
viewer = satelliteScenarioViewer(scenario, 'ShowDetails', false);