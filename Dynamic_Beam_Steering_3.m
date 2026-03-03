% ==========================================
% PHASE 3: Dynamic Beam Steering & Tracking
% ==========================================

%% 1. Mount the Phased Array to the Satellite
% We create a transmitter on the satellite and attach our 10x10 array.
% We set the transmit power to 20 Watts (typical for a small NTN satellite).
satTx = transmitter(d2c_sat, ...
    'Name', 'Satellite Phased Array TX', ...
    'Antenna', satArray, ...
    'Frequency', fc, ...
    'Power', txPower); 

%% 2. Set Up the Smartphone Receiver
% The phone gets a basic omnidirectional antenna (Isotropic).
% FIX: The correct MATLAB parameter name is 'GainToNoiseTemperatureRatio'
phoneRx = receiver(phone, ...
    'Name', 'Smartphone RX', ...
    'Antenna', phased.IsotropicAntennaElement('FrequencyRange', [1.5e9 2.5e9]), ...
    'GainToNoiseTemperatureRatio', -30); 

%% 3. Steer the Beam (The Magic Command)
% This command tells the satellite to continuously calculate the 3D vector 
% to the smartphone and electronically steer its main lobe directly at it 
% for the entire duration of the flyover.
pointAt(satTx, phone);

%% 4. Establish the Communication Link
% Now we tie the transmitter and receiver together. MATLAB will now calculate 
% the RF physics (path loss, Doppler, received power) across this invisible wire.
d2c_link = link(satTx, phoneRx);

%% 5. Visualize the Dynamic Beam in 3D
% Let's actually watch the beam track your city in the 3D viewer!
viewer = satelliteScenarioViewer(scenario, 'ShowDetails', false);

% This draws the massive 3D radiation pattern directly onto the globe.
% pattern(satTx, 'SizeRatio', 0.5); %