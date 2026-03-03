% ==========================================
% PHASE 4 & 5: Link Budget & Doppler Tracking
% ==========================================

%% 1. Extract the Data over Time
% Get the Azimuth, Elevation, and Range (Distance in meters)
[az, el, r, time] = aer(phone, d2c_sat);

% Get the Power at Receiver Input (PRI) in dBW
% FIX: The correct MATLAB function is 'sigstrength', not 'receivedPower'
[~, rxPower] = sigstrength(d2c_link);

%% 2. Process Data (Isolate the First Flyover)
% When the satellite is below our 10-degree minimum elevation, 
% MATLAB sets the power to NaN. We filter those out.
validIdx = ~isnan(rxPower);
visibleTime = time(validIdx);
visiblePower = rxPower(validIdx);
visibleRange = r(validIdx);

% Because a 4-hour scenario might have multiple flyovers separated by hours,
% we will isolate just the VERY FIRST pass so our graphs look clean.
gapIdx = find(seconds(diff(visibleTime)) > 60, 1); 
if ~isempty(gapIdx)
    visibleTime = visibleTime(1:gapIdx);
    visiblePower = visiblePower(1:gapIdx);
    visibleRange = visibleRange(1:gapIdx);
end

%% 3. Calculate Doppler Shift (The Hardcore Physics)
% The satellite moves at ~7.8 km/s. We calculate the radial velocity 
% by taking the numerical derivative of the range over time.
dt = seconds(diff(visibleTime)); % Time step in seconds
dr = diff(visibleRange);         % Change in distance in meters
radialVelocity = dr ./ dt;       % Velocity relative to the phone (m/s)

% Doppler Equation: delta_f = (v_rel / c) * fc
dopplerShift = (radialVelocity / c) * fc;

% Align the time array for Doppler (diff reduces array length by 1)
dopplerTime = visibleTime(1:end-1);

%% 4. Plotting the Portfolio Results
figure('Name', '5G NTN D2C Link Analysis', 'Position', [100, 100, 900, 600]);

% --- Plot 1: Received Power (The Link Budget) ---
subplot(2,1,1);
plot(visibleTime, visiblePower, 'LineWidth', 2, 'Color', '#0072BD');
grid on;
title('Smartphone Received Power During Satellite Flyover');
ylabel('Received Power (dBW)');
xlabel('Time (UTC)');
% A standard phone needs roughly -130 dBW (-100 dBm) to hold a connection.
yline(-130, '--r', '5G Minimum Threshold (-130 dBW)', 'LabelHorizontalAlignment', 'left', 'LineWidth', 1.5);

% --- Plot 2: Doppler Shift ---
subplot(2,1,2);
plot(dopplerTime, dopplerShift / 1000, 'LineWidth', 2, 'Color', '#D95319'); % Convert to kHz
grid on;
title('Doppler Shift Sensed by Smartphone in Komotini');
ylabel('Frequency Shift (kHz)');
xlabel('Time (UTC)');