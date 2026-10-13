function power_flow_app
    % Create main figure
    clc;clear all;
    fig = uifigure('Name', 'Analyse des Réseaux Électriques', 'Position', [100 100 600 400]);

    % Main grid layout (vertical structure)
    gl = uigridlayout(fig, [9, 1]);
    gl.RowHeight = {30, 30, 30, 30, 30, '1x', 'fit', '1x', 10};
    gl.ColumnWidth = {'1x'};

    % Header labels
    uilabel(gl, ...
        'Text', 'Département d''électrotechnique', ...
        'FontSize', 16, ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center');

    uilabel(gl, ...
        'Text', 'Analyse des réseaux électriques', ...
        'FontSize', 16, ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center');

    uilabel(gl, ...
        'Text', 'Année universitaire 2024/2025', ...
        'FontSize', 14, ...
        'HorizontalAlignment', 'center');

    uilabel(gl, ...
        'Text', 'Academic team project', ...
        'FontSize', 14, ...
        'HorizontalAlignment', 'center');

    uilabel(gl, ...
% Academic coursework.
        'FontSize', 14, ...
        'HorizontalAlignment', 'center');

    % Panel to center the buttons
    btnPanel = uipanel(gl);
    btnPanel.Layout.Row = 7;
    btnPanel.Layout.Column = 1;
 
    % Grid layout inside the panel to center buttons
    btnLayout = uigridlayout(btnPanel, [2, 3]);
    btnLayout.RowHeight = {35, 35};
    btnLayout.ColumnWidth = {'1x', 'fit', '1x'};

    % Create System Choice button
    btn1 = uibutton(btnLayout, ...
        'Text', 'System Choice', ...
        'FontSize', 12, ...
        'ButtonPushedFcn', @(btn, event) chooseSystem(fig));
    btn1.Layout.Row = 1;
    btn1.Layout.Column = 2;

    % Create Exit button
    btn2 = uibutton(btnLayout, ...
        'Text', 'Exit', ...
        'FontSize', 12, ...
        'ButtonPushedFcn', @(btn, event) close(fig));
    btn2.Layout.Row = 2;
    btn2.Layout.Column = 2;
end

function chooseSystem(mainFig)
    [file, path] = uigetfile('system*.m', 'Select a Power System File');
    if isequal(file, 0)
        uialert(mainFig, 'No file selected.', 'Cancelled');
    else
        selectedFile = fullfile(path, file);
        assignin('base', 'selectedSystemFile', selectedFile);
        close(mainFig);
        openCalculationWindow(); % Cette fonction vérifiera maintenant automatiquement la présence de gendata
    end
end

function openCalculationWindow()
    % Create calculation window
    calcFig = uifigure('Name', 'Power System Analysis', 'Position', [100 100 800 500]);
    
    % Store figure handle in app data
    setappdata(0, 'CalcFigHandle', calcFig);
    
    % Main grid layout
    gl = uigridlayout(calcFig, [3, 1]);
    gl.RowHeight = {'fit', '1x', 50};
    gl.ColumnWidth = {'1x'};

    % Horizontal button panel
    btnPanel = uipanel(gl);
    btnPanel.Layout.Row = 1;
    btnPanel.Layout.Column = 1;

    % Check if selected file contains 'gendata'
    selectedFile = evalin('base', 'selectedSystemFile');
    fileContent = fileread(selectedFile);
    hasGendata = contains(fileContent, 'gendata');
    
    % Determine which buttons to show
    buttonNames = {'Ybus', 'Zbus', 'Verif de Zbus', 'Gauss-Seidel', 'Newton-Raphson', 'FD Power Flow'};
    if hasGendata
        buttonNames = [buttonNames, {'Stabilité Transitoire'}];
    end
    buttonNames = [buttonNames, {'Clear'}];
    
    % Create button grid with appropriate number of columns
    numButtons = length(buttonNames);
    btnGrid = uigridlayout(btnPanel, [1, numButtons]);
    btnGrid.ColumnWidth = repmat({'1x'}, 1, numButtons);
    btnGrid.RowHeight = {'fit'};
    
    % Create buttons
    for i = 1:length(buttonNames)
        switch buttonNames{i}
            case 'Ybus'
                uibutton(btnGrid, 'Text', buttonNames{i}, 'ButtonPushedFcn', @(btn,event) ybusCalculation());
            case 'Zbus'
                uibutton(btnGrid, 'Text', buttonNames{i}, 'ButtonPushedFcn', @(btn,event) zbusCalculation());
            case 'Verif de Zbus'
                uibutton(btnGrid, 'Text', buttonNames{i}, 'ButtonPushedFcn', @(btn,event) verifZbusCalculation());
            case 'Gauss-Seidel'
                uibutton(btnGrid, 'Text', buttonNames{i}, 'ButtonPushedFcn', @(btn,event) gaussSeidelPowerFlow());
            case 'Newton-Raphson'
                uibutton(btnGrid, 'Text', buttonNames{i}, 'ButtonPushedFcn', @(btn,event) newtonRaphsonPowerFlow());
            case 'FD Power Flow'
                uibutton(btnGrid, 'Text', buttonNames{i}, 'ButtonPushedFcn', @(btn,event) fdPowerFlow());
            case 'Stabilité Transitoire'
                uibutton(btnGrid, 'Text', buttonNames{i}, 'ButtonPushedFcn', @(btn,event) transientStability());
            case 'Clear'
                uibutton(btnGrid, 'Text', buttonNames{i}, 'ButtonPushedFcn', @(btn,event) clearResults());
        end
    end

    % Results display area
    resultText = uitextarea(gl, ...
        'Editable', 'off', ...
        'FontSize', 12, ...
        'Tag', 'resultText', ...
        'WordWrap', 'off', ...
        'HorizontalAlignment', 'left');
    resultText.Layout.Row = 2;
    resultText.Layout.Column = 1;
    
    % Store text area handle in app data
    setappdata(calcFig, 'ResultTextHandle', resultText);

    % Go Home button
    goHomeBtn = uibutton(gl, ...
        'Text', 'Return', ...
        'ButtonPushedFcn', @(btn,event) goBackToMainPage(calcFig));
    goHomeBtn.Layout.Row = 3;
    goHomeBtn.Layout.Column = 1;
end

function zbusCalculation()
    % Clear previous results completely
    clearResults();
    
    % Get the stored text area handle
    calcFig = getappdata(0, 'CalcFigHandle');
    resultText = getappdata(calcFig, 'ResultTextHandle');
    
    try
        % Get selected file
        selectedFile = evalin('base', 'selectedSystemFile');
        if ~exist(selectedFile, 'file')
            error('System file not found: %s', selectedFile);
        end
        
        % Load system data
        run(selectedFile);
        
        % Check if Z_bus.m exists
        if ~exist('Z_bus.m', 'file')
            error('Z_bus.m not found in current directory.');
        end
        
        % Capture ALL command window output from Z_bus
        cmdOutput = evalc('Z_bus()');
        
        % Display in GUI (REPLACE mode, not append)
        resultText.Value = cmdOutput;
        
    catch ME
        errMsg = getReport(ME, 'basic', 'hyperlinks', 'off');
        resultText.Value = ['ERROR: ' errMsg];
    end
end

function ybusCalculation()
    % Clear previous results completely
    clearResults();
    
    % Get the stored text area handle
    calcFig = getappdata(0, 'CalcFigHandle');
    resultText = getappdata(calcFig, 'ResultTextHandle');
    
    try
        % Get selected file
        selectedFile = evalin('base', 'selectedSystemFile');
        if ~exist(selectedFile, 'file')
            error('System file not found: %s', selectedFile);
        end
        
        % Load system data
        run(selectedFile);
        
        % Capture ALL command window output from Y_bus
        cmdOutput = evalc('Y_bus()');
        
        % Display in GUI (REPLACE mode, not append)
        resultText.Value = cmdOutput;
        
    catch ME
        errMsg = getReport(ME, 'basic', 'hyperlinks', 'off');
        resultText.Value = ['ERROR: ' errMsg];
    end
end

function gaussSeidelPowerFlow()
    % Clear previous results
    clearResults(true); % silent clear (keeps command window)
    
    % Get the stored text area handle
    calcFig = getappdata(0, 'CalcFigHandle');
    resultText = getappdata(calcFig, 'ResultTextHandle');
    
    try
        % Verify we have a selected file
        if ~evalin('base', 'exist(''selectedSystemFile'', ''var'')')
            error('No system file selected');
        end
        
        selectedFile = evalin('base', 'selectedSystemFile');
        if ~exist(selectedFile, 'file')
            error('System file not found: %s', selectedFile);
        end
        
        % Check if Gauss_Seidel.m exists
        if ~exist('Gauss_Seidel.m', 'file')
            error('Gauss_Seidel.m not found in current directory.');
        end
        
        % Load system data
        run(selectedFile);
        
        % Capture ALL command window output from Gauss_Seidel
        cmdOutput = evalc('Gauss_Seidel()');
        
        % Display in GUI (replaces any previous content)
        resultText.Value = cmdOutput;
        
    catch ME
        errMsg = getReport(ME, 'basic', 'hyperlinks', 'off');
        resultText.Value = ['ERROR: ' errMsg];
    end
end

function newtonRaphsonPowerFlow()
    % Clear previous results (silent mode)
    clearResults(true);
    
    % Get UI handles
    calcFig = getappdata(0, 'CalcFigHandle');
    resultText = getappdata(calcFig, 'ResultTextHandle');
    
    try
        % Verify system file is selected
        if ~evalin('base', 'exist(''selectedSystemFile'',''var'')')
            error('No system file selected');
        end
        
        selectedFile = evalin('base', 'selectedSystemFile');
        if ~exist(selectedFile, 'file')
            error('System file not found: %s', selectedFile);
        end
        
        % Verify Newton_Raphson.m exists
        if ~exist('Newton_Raphson.m', 'file')
            error('Newton_Raphson.m not found');
        end
        
        % Load system data
        run(selectedFile);
        
        % Run and capture output
        cmdOutput = evalc('Newton_Raphson()');
        
        % Display results
        resultText.Value = cmdOutput;
        
    catch ME
        errMsg = getReport(ME, 'basic', 'hyperlinks', 'off');
        resultText.Value = ['ERROR: ' errMsg];
    end
end

function updateButtonStates()
    calcFig = getappdata(0, 'CalcFigHandle');
    if isempty(calcFig) || ~isvalid(calcFig)
        return;
    end
    
    try
        selectedFile = evalin('base', 'selectedSystemFile');
        fileContent = fileread(selectedFile);
        
        % Trouver le bouton Stabilité Transitoire
        btnGrid = findobj(calcFig, 'Type', 'uigridlayout');
        transStabBtn = findobj(btnGrid, 'Text', 'Stabilité Transitoire');
        
        if contains(fileContent, 'gendata')
            transStabBtn.Enable = 'on';
        else
            transStabBtn.Enable = 'off';
            transStabBtn.Tooltip = 'Fonction non disponible - le fichier système ne contient pas gendata';
        end
    catch
        % Ne rien faire si erreur
    end
end

function fdPowerFlow()
    % Clear previous results completely
    clearResults();
    
    % Get the stored text area handle
    calcFig = getappdata(0, 'CalcFigHandle');
    resultText = getappdata(calcFig, 'ResultTextHandle');
    
    try
        % Get selected file
        selectedFile = evalin('base', 'selectedSystemFile');
        if ~exist(selectedFile, 'file')
            error('System file not found: %s', selectedFile);
        end
        
        % Load system data
        run(selectedFile);
        
        % Check if FDLF.m exists
        if ~exist('FDLF.m', 'file')
            error('FDLF.m not found in current directory.');
        end
        
        % Capture ALL command window output from FDLF
        cmdOutput = evalc('FDLF()');
        
        % Display in GUI (REPLACE mode, not append)
        resultText.Value = cmdOutput;
        
    catch ME
        errMsg = getReport(ME, 'basic', 'hyperlinks', 'off');
        resultText.Value = ['ERROR: ' errMsg];
    end
end

function transientStability()
    try
        % Verify and load system data
        if ~evalin('base', 'exist(''selectedSystemFile'',''var'')')
            error('Veuillez sélectionner un fichier système d''abord.');
        end
        
        % Get the results text area
        calcFig = getappdata(0, 'CalcFigHandle');
        if ~isempty(calcFig) && isvalid(calcFig)
            resultText = getappdata(calcFig, 'ResultTextHandle');
            if ~isempty(resultText)
                resultText.Value = 'Lancement de l''analyse de stabilité transitoire...';
                drawnow;
            end
        end
        
        % Run st.m directly
        st
        
    catch ME
        calcFig = getappdata(0, 'CalcFigHandle');
        if ~isempty(calcFig) && isvalid(calcFig)
            resultText = getappdata(calcFig, 'ResultTextHandle');
            if ~isempty(resultText)
                resultText.Value = ['ERROR: ' ME.message];
            end
        end
    end
end

function clearResults(silent)
    % Get the stored text area handle
    calcFig = getappdata(0, 'CalcFigHandle');
    resultText = getappdata(calcFig, 'ResultTextHandle');
    
    % Clear the GUI results display
    resultText.Value = '';
    
    % Clear the MATLAB command window if not in silent mode
    if nargin < 1 || ~silent
        clc;
    end
end

function goBackToMainPage(calcFig)
    rmappdata(0, 'CalcFigHandle');
    close(calcFig);
    power_flow_app();
end

% Add function to verify Zbus
function verifZbusCalculation()
    % Clear previous results
    clearResults();
    calcFig = getappdata(0, 'CalcFigHandle');
    resultText = getappdata(calcFig, 'ResultTextHandle');
    try
        % Load system file
        selectedFile = evalin('base', 'selectedSystemFile');
        run(selectedFile);
        % Calculate Ybus via external script
        run('Y_bus.m');  % populates Ybus
        % Compute impedance matrix (inverse of Ybus)
        Zbus = inv(Ybus);
        % Check identity
        Iden = Ybus * Zbus;
        % Prepare display: three parts
        cmdOutput = evalc("disp('--- Ybus matrix ---'); disp(Ybus);" + ...
                         "disp('--- Zbus matrix  ---'); disp(Zbus);" + ...
                         "disp('--- Ybus*Zbus  ---'); disp(Ybus*Zbus);");
        resultText.Value = splitlines(cmdOutput);
    catch ME
        errMsg = getReport(ME, 'basic', 'hyperlinks', 'off');
        resultText.Value = ['ERROR: ' errMsg];
    end
end
