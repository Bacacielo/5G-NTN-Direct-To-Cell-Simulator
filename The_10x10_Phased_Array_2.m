% ==========================================
% PHASE 2: Designing the Phased Array Antenna 
% ==========================================

%% 1. Define the RF Physics
% We will use 2 GHz (S-Band), which is standard for 5G mobile satellite services.
fc = 2e9; 
c = physconst('LightSpeed'); 
lambda = c / fc; % Calculate the wavelength

%% 2. Create the Individual Antenna Element
% A smartphone has an omnidirectional antenna. The satellite, however, 
% uses directional "patch" antennas. We model this using a Cosine element.
patchElement = phased.CosineAntennaElement(...
    'FrequencyRange', [1.5e9 2.5e9], ...
    'CosinePower', [1.5 1.5]);

%% 3. Build the Uniform Rectangular Array (URA)
% We arrange the patches into a 10x10 grid.
% Crucially, the spacing between elements must be exactly half a wavelength 
% to prevent signal interference (grating lobes).
satArray = phased.URA('Element', patchElement, ...
    'Size', [arrayGrid arrayGrid], ...
    'ElementSpacing', [lambda/2 lambda/2]);

%% 4. Calculate the Maximum Gain
% Let's see how much power this array gives us compared to a standard antenna.
% FIX: The angle is now properly formatted as a 2x1 vector [Azimuth; Elevation] -> [0; 0]
maxDirectivity = directivity(satArray, fc, [0; 0], 'PropagationSpeed', c);
disp(['Maximum Satellite Antenna Gain: ', num2str(maxDirectivity), ' dBi']);

%% 5. Visualize the 3D Radiation Pattern
% This generates the 3D shape of the RF energy emitted by the satellite.
figure('Name', 'Satellite Phased Array Beam');
pattern(satArray, fc, ...
    'PropagationSpeed', c, ...
    'Type', 'directivity', ...
    'CoordinateSystem', 'rectangular');
title(['3D Radiation Pattern of ', num2str(arrayGrid), 'x', num2str(arrayGrid), ' Satellite Array']);