function Master_UI()
    % ==========================================
    % 5G NTN SIMULATOR - MASTER CONTROL PANEL
    % ==========================================

    % Create the main window
    fig = uifigure('Name', '5G NTN Simulator Control Panel', 'Position', [100 100 400 380]);

    % --- USER INPUTS ---
    % Array Size Input
    uilabel(fig, 'Position', [40 310 150 22], 'Text', 'Array Grid Size (N x N):', 'FontWeight', 'bold');
    arrayInput = uieditfield(fig, 'numeric', 'Position', [220 310 100 22], 'Value', 10);

    % Transmit Power Input
    uilabel(fig, 'Position', [40 270 150 22], 'Text', 'Transmit Power (Watts):', 'FontWeight', 'bold');
    powerInput = uieditfield(fig, 'numeric', 'Position', [220 270 100 22], 'Value', 20);

    % --- BUTTONS ---
    uibutton(fig, 'Position', [50 200 300 40], 'Text', '1. Initialize Orbital Arena', ...
        'ButtonPushedFcn', @(btn,event) runScript('The_Orbital_Arena_1'), ...
        'BackgroundColor', '#0072BD', 'FontColor', 'white', 'FontWeight', 'bold');

    uibutton(fig, 'Position', [50 150 300 40], 'Text', '2. Build Phased Array', ...
        'ButtonPushedFcn', @(btn,event) runPhase2(arrayInput.Value));

    uibutton(fig, 'Position', [50 100 300 40], 'Text', '3. Dynamic Beam Steering', ...
        'ButtonPushedFcn', @(btn,event) runPhase3(powerInput.Value));

    uibutton(fig, 'Position', [50 50 300 40], 'Text', '4. Link Analysis & Doppler', ...
        'ButtonPushedFcn', @(btn,event) runScript('The_Physics_and_Visualization_4_5'), ...
        'BackgroundColor', '#D95319', 'FontColor', 'white', 'FontWeight', 'bold');

    % ==========================================
    % CALLBACK FUNCTIONS (The Engine)
    % ==========================================
    
    % This forces the scripts to run in the main MATLAB workspace so they 
    % can share variables (like the satellite and phone objects) with each other.
    function runScript(scriptName)
        evalin('base', scriptName);
    end

    function runPhase2(gridSize)
        % Send the UI array size to the base workspace, then run script 2
        assignin('base', 'arrayGrid', gridSize);
        evalin('base', 'The_10x10_Phased_Array_2');
    end

    function runPhase3(txPow)
        % Send the UI watts to the base workspace, then run script 3
        assignin('base', 'txPower', txPow);
        evalin('base', 'Dynamic_Beam_Steering_3');
    end
end