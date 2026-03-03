classdef Master_UI < handle
    % ==========================================
    % 5G NTN SIMULATOR - RESEARCH EDITION (v3.0)
    % Upgraded per Graduate Research Critique:
    % - Stochastic Channel (Rician Fading, Lognormal Shadowing, Rain)
    % - Interference Modeling (Co-Channel Inter-Satellite Leakage)
    % - 3GPP TS 38.214 Link Adaptation (CQI/MCS Table)
    % - Predictive Handover (Derivative/Trend-based)
    % - Array Physics (Restored Chebwin Tapering)
    % ==========================================
    
    properties (Access = private)
        % --- UI Components ---
        UIFigure
        CacheLamp
        StatusLabel
        NumPlanesSpinner
        SatsPerPlaneSpinner
        GridSizeSpinner
        TxPowerSpinner
        WeatherDropdown
        HysteresisSpinner
        PreCompSwitch
        ResearchModeSwitch   % NEW: Toggle Stochastic/Interference Mode
        
        % --- Embedded Axes ---
        AxPower
        AxThroughput
        AxDoppler
        
        % --- Simulation State Data ---
        Scenario
        Satellites
        Phone
        Gateway
        VisWindows
        AllAccess
        SatArray
        D2CLinks
        ActiveSats 
        
        % --- Default Parameters ---
        NumPlanes = 6;       
        SatsPerPlane = 8;    
        GridSize = 10;
        TxPower = 20;
        EnvLoss = 0.5;
        WeatherType = 'Clear Sky';
        HysteresisDB = 3.0;
        DopplerPreComp = true;
    end
    
    methods
        function app = Master_UI()
            % Suppress the missing basemap warning locally
            warning('off', 'shared_orbit:orbitPropagator:UnableToReadBasemap');
            
            app.createComponents();
            app.checkCacheStatus();
        end
    end
    
    methods (Access = private)
        % ==========================================
        % 1. COMPONENT INITIALIZATION (Fully Restored)
        % ==========================================
        function createComponents(app)
            app.UIFigure = uifigure('Name', '5G NTN Research Simulator - Physical Layer Fidelity', 'Position', [50 50 1200 750]);
            
            % --- LEFT COLUMN: CONTROLS ---
            pCache = uipanel(app.UIFigure, 'Position', [20 580 360 150], 'Title', '1. Orbital Data Cache', 'FontWeight', 'bold');
            
            uilabel(pCache, 'Position', [10 95 100 22], 'Text', 'Orbit Planes:');
            app.NumPlanesSpinner = uispinner(pCache, 'Position', [110 95 60 22], 'Value', app.NumPlanes, 'Limits', [1 50]);
            
            uilabel(pCache, 'Position', [190 95 100 22], 'Text', 'Sats/Plane:');
            app.SatsPerPlaneSpinner = uispinner(pCache, 'Position', [280 95 70 22], 'Value', app.SatsPerPlane, 'Limits', [1 100]);
            
            uilabel(pCache, 'Position', [10 60 100 22], 'Text', 'Cache Status:');
            app.CacheLamp = uilamp(pCache, 'Position', [110 62 20 20], 'Color', 'r'); 
            uibutton(pCache, 'Position', [10 15 160 35], 'Text', 'Generate Constellation', ...
                'ButtonPushedFcn', @(btn,event) app.runPhase1(true), 'BackgroundColor', '#EFEFEF');
            uibutton(pCache, 'Position', [185 15 160 35], 'Text', 'Clear Cache File', ...
                'ButtonPushedFcn', @(btn,event) app.deleteCache());
                
            pParams = uipanel(app.UIFigure, 'Position', [20 280 360 290], 'Title', '2. Advanced RF & Research Parameters', 'FontWeight', 'bold');
            
            uilabel(pParams, 'Position', [10 230 150 22], 'Text', 'Array Grid Size (NxN):');
            app.GridSizeSpinner = uispinner(pParams, 'Position', [180 230 100 22], 'Value', app.GridSize, 'Limits', [2 100]);
            
            uilabel(pParams, 'Position', [10 195 150 22], 'Text', 'Satellite TX Power (dBW):');
            app.TxPowerSpinner = uispinner(pParams, 'Position', [180 195 100 22], 'Value', app.TxPower, 'Limits', [-30 50]);
            
            uilabel(pParams, 'Position', [10 160 150 22], 'Text', 'Base Weather Loss:');
            app.WeatherDropdown = uidropdown(pParams, 'Position', [180 160 150 22], ...
                'Items', {'Clear Sky', 'Light Rain', 'Heavy Rain'}, ...
                'ValueChangedFcn', @(dd,event) app.updateWeather());
                
            uilabel(pParams, 'Position', [10 125 150 22], 'Text', 'Handover Hysteresis (dB):');
            app.HysteresisSpinner = uispinner(pParams, 'Position', [180 125 100 22], 'Value', app.HysteresisDB, 'Limits', [0 15], 'Step', 0.5);
            
            uilabel(pParams, 'Position', [10 90 160 22], 'Text', 'Doppler Pre-Compensation:');
            app.PreCompSwitch = uiswitch(pParams, 'Position', [180 90 40 22], 'Value', 'On');
            
            uilabel(pParams, 'Position', [10 30 200 22], 'Text', 'Research Engine (Fading/CCI):', 'FontWeight', 'bold', 'FontColor', [0.6350 0.0780 0.1840]);
            app.ResearchModeSwitch = uiswitch(pParams, 'Slider', 'Position', [220 30 45 22], 'Value', 'On');
                
            pActions = uipanel(app.UIFigure, 'Position', [20 110 360 160], 'Title', '3. Execution Phases', 'FontWeight', 'bold');
            uibutton(pActions, 'Position', [10 90 160 35], 'Text', 'Phase 2: Build Array', ...
                'ButtonPushedFcn', @(btn,event) app.runPhase2());
            uibutton(pActions, 'Position', [185 90 160 35], 'Text', 'Phase 3: Steer Beams', ...
                'ButtonPushedFcn', @(btn,event) app.runPhase3());
            uibutton(pActions, 'Position', [10 20 335 55], 'Text', 'PHASE 4: RUN RESEARCH ANALYSIS', ...
                'ButtonPushedFcn', @(btn,event) app.runPhase4(), 'BackgroundColor', '#A2142F', 'FontColor', 'w', 'FontWeight', 'bold');
                
            app.StatusLabel = uilabel(app.UIFigure, 'Position', [20 20 360 22], ...
                'Text', 'Ready.', 'FontWeight', 'bold', 'FontColor', [0 0.5 0]);
                
            % --- RIGHT COLUMN: EMBEDDED PLOTS ---
            app.AxPower = uiaxes(app.UIFigure, 'Position', [400 500 780 230]);
            app.AxThroughput = uiaxes(app.UIFigure, 'Position', [400 250 780 230]);
            app.AxDoppler = uiaxes(app.UIFigure, 'Position', [400 10 780 230]);
        end
        
        % ==========================================
        % 2. STATE & CACHE MANAGEMENT (Fully Restored)
        % ==========================================
        function checkCacheStatus(app)
            cacheFile = 'Constellation_Ephemeris.mat';
            if exist(cacheFile, 'file')
                cacheVars = whos('-file', cacheFile);
                varNames = {cacheVars.name};
                
                if ismember('gateway', varNames) && ismember('numPlanes', varNames)
                    cachedMeta = load(cacheFile, 'numPlanes', 'satsPerPlane');
                    app.NumPlanesSpinner.Value = cachedMeta.numPlanes;
                    app.SatsPerPlaneSpinner.Value = cachedMeta.satsPerPlane;
                    
                    app.CacheLamp.Color = 'g';
                    app.StatusLabel.Text = 'Valid cache found. Loading...';
                    app.runPhase1(false); 
                    return;
                end
            end
            
            app.CacheLamp.Color = 'r';
            app.StatusLabel.Text = 'Cache invalid or missing. Generate constellation.';
        end
        
        function deleteCache(app)
            if exist('Constellation_Ephemeris.mat', 'file')
                delete('Constellation_Ephemeris.mat');
                app.CacheLamp.Color = 'r';
                app.StatusLabel.Text = 'Cache deleted.';
            end
        end
        
        function updateWeather(app)
            app.WeatherType = app.WeatherDropdown.Value;
            switch app.WeatherType
                case 'Clear Sky'; app.EnvLoss = 0.5;
                case 'Light Rain'; app.EnvLoss = 3.0;
                case 'Heavy Rain'; app.EnvLoss = 12.0;
            end
        end
        
        % ==========================================
        % 3. UI WORKFLOW EXECUTORS
        % ==========================================
        function runPhase1(app, forceOverwrite)
            d = uiprogressdlg(app.UIFigure, 'Title', 'Computing Orbits', 'Indeterminate', 'on');
            app.StatusLabel.Text = 'Processing Orbital Arena...';
            
            app.NumPlanes = app.NumPlanesSpinner.Value;
            app.SatsPerPlane = app.SatsPerPlaneSpinner.Value;
            
            [app.Scenario, app.Satellites, app.Phone, app.Gateway, app.VisWindows, app.AllAccess] = app.initOrbitalArena(forceOverwrite, app.NumPlanes, app.SatsPerPlane);
            
            app.CacheLamp.Color = 'g';
            app.StatusLabel.Text = 'Orbit Processing Complete.'; 
            close(d);
        end
        
        function runPhase2(app)
            d = uiprogressdlg(app.UIFigure, 'Title', 'Array Synthesis', 'Indeterminate', 'on');
            app.GridSize = app.GridSizeSpinner.Value;
            app.SatArray = app.buildPhasedArray(app.GridSize);
            app.StatusLabel.Text = 'Array Synthesized with Chebwin Taper.'; 
            close(d);
        end
        
        function runPhase3(app)
            if isempty(app.Scenario) || isempty(app.SatArray)
                uialert(app.UIFigure, 'Please run Phases 1 and 2 first.', 'Missing Data');
                return;
            end
            d = uiprogressdlg(app.UIFigure, 'Title', 'Beam Steering', 'Indeterminate', 'on');
            app.TxPower = app.TxPowerSpinner.Value;
            
            [app.D2CLinks, app.ActiveSats] = app.steerBeams(app.Scenario, app.Satellites, app.VisWindows, app.Phone, app.SatArray, app.TxPower);
            
            satelliteScenarioViewer(app.Scenario); 
            
            app.StatusLabel.Text = sprintf('Beams Locked (%d links active).', numel(app.D2CLinks)); 
            close(d);
        end
        
        function runPhase4(app)
            if isempty(app.D2CLinks)
                uialert(app.UIFigure, 'Please run Phase 3 first.', 'Missing Data');
                return;
            end
            d = uiprogressdlg(app.UIFigure, 'Title', 'Research RF Physics Engine', 'Value', 0.1);
            app.StatusLabel.Text = 'Analyzing Stochastic Link Budget...';
            
            app.HysteresisDB = app.HysteresisSpinner.Value;
            app.DopplerPreComp = strcmp(app.PreCompSwitch.Value, 'On');
            researchMode = strcmp(app.ResearchModeSwitch.Value, 'On');
            
            app.analyzeLinkBudget(app.D2CLinks, app.ActiveSats, app.Phone, app.Gateway, ...
                app.WeatherType, app.EnvLoss, app.HysteresisDB, app.DopplerPreComp, researchMode, ...
                app.AxPower, app.AxThroughput, app.AxDoppler, d);
            
            app.StatusLabel.Text = 'Analysis Complete.'; 
            close(d);
        end

        % ==========================================
        % 4. INTERNAL PHYSICS ENGINES (Restored & Upgraded)
        % ==========================================
        function [scenario, satellites, phone, gateway, visWindows, allAccess] = initOrbitalArena(~, forceOverwrite, numPlanes, satsPerPlane)
            cacheFile = 'Constellation_Ephemeris.mat';
            isValidCache = false;
            
            if exist(cacheFile, 'file') && ~forceOverwrite
                cacheVars = whos('-file', cacheFile);
                varNames = {cacheVars.name};
                if ismember('gateway', varNames) && ismember('numPlanes', varNames)
                    cachedMeta = load(cacheFile, 'numPlanes', 'satsPerPlane');
                    if cachedMeta.numPlanes == numPlanes && cachedMeta.satsPerPlane == satsPerPlane
                        isValidCache = true;
                    end
                end
            end
            
            if isValidCache
                load(cacheFile, 'satellites', 'allAccess', 'visWindows', 'scenario', 'phone', 'gateway');
            else
                startTime = datetime('now', 'TimeZone', 'UTC');
                stopTime = startTime + hours(4);
                sampleTime = 60; 
                scenario = satelliteScenario(startTime, stopTime, sampleTime);
                
                % Service Link UE
                latKomotini = 41.119; lonKomotini = 25.405;
                phone = groundStation(scenario, latKomotini, lonKomotini, ...
                    'Name', 'Smartphone (Komotini)', 'MinElevationAngle', 10);
                
                % Feeder Link Gateway
                gateway = groundStation(scenario, 37.9838, 23.7275, ...
                    'Name', 'Gateway (Athens)', 'MinElevationAngle', 5);
                    
                earthRadius = 6371000; altitude = 500000; 
                semiMajorAxis = earthRadius + altitude;
                
                numSats = numPlanes * satsPerPlane;
                d_RAAN = 360 / numPlanes; d_MeanAnomaly = 360 / satsPerPlane; 
                
                satellites = cell(1, numSats);
                count = 1;
                for p = 0:numPlanes-1
                    raan = p * d_RAAN;
                    for s = 0:satsPerPlane-1
                        ma = s * d_MeanAnomaly; 
                        satName = sprintf('NTN-Sat-P%d-S%d', p+1, s+1);
                        satellites{count} = satellite(scenario, semiMajorAxis, 0, 53, ...
                            raan, 0, ma, 'Name', satName);
                        count = count + 1;
                    end
                end
                
                allAccess = [];
                for i = 1:numSats
                    ac = access(satellites{i}, phone);
                    allAccess = [allAccess, ac];
                end
                
                visWindows = accessIntervals(allAccess);
                save(cacheFile, 'satellites', 'allAccess', 'visWindows', 'scenario', 'phone', 'gateway', 'numPlanes', 'satsPerPlane');
            end
        end
        
        function satArray = buildPhasedArray(~, arrayGrid)
            % 3GPP TR 38.811 Approximation for S-Band
            fc = 2e9; c = physconst('LightSpeed'); lambda = c / fc; 
            
            patchElement = phased.CosineAntennaElement(...
                'FrequencyRange', [1.5e9 2.5e9], 'CosinePower', [1.5 1.5]);
                
            % RESTORED: Sidelobe control via Chebwin tapering
            taperVector = chebwin(arrayGrid, 30);
            taperMatrix = taperVector * taperVector'; 
                
            satArray = phased.URA('Element', patchElement, ...
                'Size', [arrayGrid arrayGrid], ...
                'ElementSpacing', [lambda/2 lambda/2], ...
                'Taper', taperMatrix); 
        end
        
        function [d2c_link, activeSats] = steerBeams(~, scenario, satellites, visWindows, phone, satArray, txPower)
            fc = 2e9; 
            % RESTORED: Check for existing receivers to prevent duplicating objects
            rxList = phone.Receivers;
            if isempty(rxList)
                rxPhone = receiver(phone, 'Name', 'Smartphone RX', ...
                    'Antenna', phased.IsotropicAntennaElement('FrequencyRange', [1.5e9 2.5e9]), ...
                    'GainToNoiseTemperatureRatio', -30);
            else
                rxPhone = rxList(1); 
            end
            
            allSatNames = string(cellfun(@(s) s.Name, satellites, 'UniformOutput', false));
            sources = unique(string(visWindows.Source));
            targets = unique(string(visWindows.Target));
            activeSatNames = intersect(allSatNames, [sources; targets]);
            
            if numel(activeSatNames) == 0; error('No satellites visible.'); end
            
            d2c_link = []; 
            activeSats = {}; 
            
            for i = 1:numel(activeSatNames)
                satIdx = find(allSatNames == activeSatNames(i)); 
                if ~isempty(satIdx)
                    thisSat = satellites{satIdx}; 
                    activeSats{end+1} = thisSat; 
                    
                    % RESTORED: Safe transmitter creation/reuse
                    if isempty(thisSat.Transmitters)
                        thisSatTx = transmitter(thisSat, 'Name', char("Sat-TX-" + satIdx), ...
                            'Antenna', satArray, 'Frequency', fc, 'Power', txPower); 
                    else
                        thisSatTx = thisSat.Transmitters(1);
                        thisSatTx.Power = txPower;
                        thisSatTx.Antenna = satArray;
                    end
                    pointAt(thisSatTx, phone); 
                    d2c_link = [d2c_link, link(thisSatTx, rxPhone)];
                end
            end
        end
        
        function analyzeLinkBudget(~, d2c_link, activeSats, phone, gateway, weatherType, baseLoss, hysteresisDB, preCompEnabled, researchMode, axPower, axThroughput, axDoppler, progDlg)
            numLinks = numel(d2c_link);
            if nargin > 13, progDlg.Message = 'Extracting spatial vectors & Interference...'; end
            
            [~, ~, time] = sigstrength(d2c_link(1));
            numSteps = length(time); 
            dt = seconds(time(2) - time(1));
            
            rxPowerMatrix = NaN(numLinks, numSteps);
            elMatrix = NaN(numLinks, numSteps);
            rMatrix = NaN(numLinks, numSteps);
            dopplerMatrix = NaN(numLinks, numSteps);
            feederSNRMatrix = NaN(numLinks, numSteps); 
            
            fc = 2e9; c = 3e8; bandwidth = 15e6;
            feederFc = 28e9; % Ka-band feeder link
            
            % ---------------------------------------------------------
            % Phase A: Deterministic Baseline Extraction
            % ---------------------------------------------------------
            for i = 1:numLinks
                [sig, ~, ~] = sigstrength(d2c_link(i));
                rxPowerMatrix(i, :) = sig;
                
                [~, el, r, ~] = aer(phone, activeSats{i});
                elMatrix(i, :) = el; rMatrix(i, :) = r;
                
                radialVel = [0, diff(r)] / dt;
                dopplerMatrix(i, :) = (radialVel / c) * fc;
                
                % Feeder Link (Gateway to Satellite)
                [~, gwEl, gwR, ~] = aer(gateway, activeSats{i});
                gwFspl = fspl(gwR, c/feederFc);
                feederEIRP = 60; % dBW
                feederG_T = 15;  % dB/K satellite rx
                feederC_N0 = feederEIRP - gwFspl + feederG_T + 228.6;
                feederSNRMatrix(i, :) = feederC_N0 - 10*log10(100e6); 
            end
            
            if nargin > 13, progDlg.Message = 'Executing Handover & Stochastic Channel...'; progDlg.Value = 0.4; end
            
            % ---------------------------------------------------------
            % Phase B: 3GPP MCS Table & Pre-calculations
            % ---------------------------------------------------------
            % TS 38.214 Table 5.1.3.1-1 (CQI Index, Modulation, Code Rate, Efficiency)
            mcsTable = [
                -6.5, 0.23; % CQI 1: QPSK
                -4.0, 0.38; % CQI 2: QPSK
                -2.0, 0.60; % CQI 3: QPSK
                 0.0, 0.88; % CQI 4: QPSK
                 2.0, 1.18; % CQI 5: QPSK
                 4.0, 1.48; % CQI 6: QPSK
                 6.0, 1.91; % CQI 7: 16QAM
                 8.0, 2.41; % CQI 8: 16QAM
                10.0, 2.73; % CQI 9: 16QAM
                12.0, 3.32; % CQI 10: 64QAM
                14.0, 3.90; % CQI 11: 64QAM
                16.0, 4.52; % CQI 12: 64QAM
                18.0, 5.12; % CQI 13: 64QAM
                20.0, 5.55; % CQI 14: 64QAM
            ];
            
            connectedSatIdx = 1;
            rxSignal = NaN(1, numSteps); 
            rxSINR = NaN(1, numSteps);
            sysThroughput = zeros(1, numSteps);
            rxDoppler = NaN(1, numSteps);
            
            % Thermal Noise Floor
            noisePowerDBW = 10*log10(1.38e-23 * 290 * bandwidth);
            linearNoise = 10^(noisePowerDBW/10);
            
            % ---------------------------------------------------------
            % Phase C: Time-Series Physics Loop
            % ---------------------------------------------------------
            for t = 1:numSteps
                % 1. Inject Stochastic Fading (If Enabled)
                if researchMode
                    for i = 1:numLinks
                        if isnan(rxPowerMatrix(i,t)); continue; end
                        
                        elev = max(elMatrix(i, t), 5);
                        
                        % Elevation-dependent Rician K-factor
                        K_dB = 2 + 0.15 * elev; 
                        K = 10^(K_dB/10);
                        mu = sqrt(K/(2*(K+1)));
                        sigma = sqrt(1/(2*(K+1)));
                        h = (mu + sigma*randn()) + 1i*(mu + sigma*randn());
                        fadingDB = 20*log10(max(abs(h), 0.01)); % Protect against -inf
                        
                        % Log-normal shadowing (2.5dB std dev)
                        shadowingDB = 2.5 * randn(); 
                        
                        % Dynamic rain loss
                        rainAtten = baseLoss / sind(elev);
                        
                        % Update power dynamically
                        rxPowerMatrix(i,t) = rxPowerMatrix(i,t) - rainAtten + fadingDB + shadowingDB;
                    end
                else
                    % Apply static deterministic loss
                    for i = 1:numLinks
                        if ~isnan(rxPowerMatrix(i,t))
                            elev = max(elMatrix(i, t), 5);
                            rxPowerMatrix(i,t) = rxPowerMatrix(i,t) - (baseLoss / sind(elev));
                        end
                    end
                end
                
                % 2. Predictive Handover Logic
                currentPow = rxPowerMatrix(connectedSatIdx, t);
                [bestPow, bestIdx] = max(rxPowerMatrix(:, t));
                
                % Calculate derivative/trend for predictive break
                if researchMode && t < numSteps - 3
                    futurePow = rxPowerMatrix(connectedSatIdx, t+3);
                    trend = futurePow - currentPow;
                else
                    trend = 0;
                end
                
                % Handover if: Dead signal OR Best is +Hysteresis OR Approaching rapid fade
                if isnan(currentPow) || (bestPow > currentPow + hysteresisDB) || (researchMode && trend < -3.0 && bestPow > currentPow)
                    connectedSatIdx = bestIdx;
                    rxSignal(t) = bestPow;
                else
                    rxSignal(t) = currentPow;
                end
                
                % 3. SINR & Co-Channel Interference Modeling
                if researchMode
                    % Sum power from all active but un-connected satellites
                    interfererIndices = setdiff(1:numLinks, connectedSatIdx);
                    interfererPowers = rxPowerMatrix(interfererIndices, t);
                    linearInterference = sum(10.^(interfererPowers/10), 'omitnan');
                else
                    linearInterference = 0; % Engineering baseline assumes perfect beam isolation
                end
                
                total_IN_DBW = 10*log10(linearNoise + linearInterference);
                currentSINR = rxSignal(t) - total_IN_DBW;
                rxSINR(t) = currentSINR;
                
                % 4. Doppler Pre-Compensation Error
                rawDoppler = dopplerMatrix(connectedSatIdx, t);
                if preCompEnabled
                    % Simulate 3GPP GNSS residual error + phase noise
                    rxDoppler(t) = randn() * 25; 
                else
                    rxDoppler(t) = rawDoppler;
                end
                
                % 5. Adaptive 3GPP Link Adaptation (Throughput)
                isFeederAlive = feederSNRMatrix(connectedSatIdx, t) > 0;
                if ~isnan(currentSINR) && isFeederAlive && rxSignal(t) > -135
                    if currentSINR >= mcsTable(1,1)
                        % Find highest supported CQI
                        idx = find(currentSINR >= mcsTable(:,1), 1, 'last');
                        spectralEfficiency = mcsTable(idx, 2);
                        
                        % Net capacity = BW * SE * 0.8 (protocol overhead approx)
                        sysThroughput(t) = (bandwidth * spectralEfficiency * 0.8) / 1e6;
                    end
                end
            end
            
            % ---------------------------------------------------------
            % Phase D: Rendering
            % ---------------------------------------------------------
            if nargin > 13, progDlg.Message = 'Rendering Data...'; progDlg.Value = 0.9; end
            
            % Clear old plots
            cla(axPower); cla(axThroughput); cla(axDoppler);
            
            % PLOT 1: SINR
            if researchMode
                plot(axPower, time, rxSINR, 'LineWidth', 1.5, 'Color', '#A2142F');
                title(axPower, ['Research SINR (CCI + Fading, ', weatherType, ')']);
            else
                plot(axPower, time, rxSINR, 'LineWidth', 2, 'Color', '#0072BD');
                title(axPower, ['Received SINR (Deterministic, ', weatherType, ')']);
            end
            grid(axPower, 'on'); 
            ylabel(axPower, 'SINR (dB)'); 
            yline(axPower, -6.5, '--r', '3GPP Demodulation Floor (CQI 1)');
            
            % PLOT 2: THROUGHPUT
            plot(axThroughput, time, sysThroughput, 'LineWidth', 1.5, 'Color', '#77AC30');
            grid(axThroughput, 'on'); 
            title(axThroughput, 'System Throughput (3GPP Link Adaptation & Feeder Checked)');
            ylabel(axThroughput, 'Capacity (Mbps)');
            
            % PLOT 3: DOPPLER
            plot(axDoppler, time, rxDoppler / 1000, 'LineWidth', 1.5, 'Color', '#D95319');
            grid(axDoppler, 'on'); 
            if preCompEnabled
                title(axDoppler, 'Residual Doppler Error (Pre-Compensated)');
                ylabel(axDoppler, 'Error (kHz)');
                ylim(axDoppler, [-0.1 0.1]); 
            else
                title(axDoppler, 'Raw Doppler Shift');
                ylabel(axDoppler, 'Doppler Shift (kHz)');
                ylim(axDoppler, 'auto');
            end
        end
    end
end
