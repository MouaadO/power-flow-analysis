function st()


    % Load system data
    if ~exist('selectedSystemFile', 'var')
        selectedSystemFile = evalin('base', 'selectedSystemFile');
    end
    run(selectedSystemFile);

    if exist('gendata', 'var')
        disp('L'' analyse de stabilité transitoire peut être effectué');
        
        % Calculate Ybus internally
        Ybus = calculateYbus(linedata, nbus);

        % Create and show parameter window
        showParameterWindow(Ybus, nbus, busdata, gendata, basemva);
    else
        disp('L''analyse de stabilité transitoire n''est pas disponible, manque de données de génerateurs.');
    end
end

function Ybus = calculateYbus(linedata, nbus)
    nbr = size(linedata,1);
    fb = linedata(:,1);
    tb = linedata(:,2);
    r = linedata(:,3);
    x = linedata(:,4);
    b = linedata(:,5);
    z = r + 1i*x;
    y = 1./z;
    % Build off-diagonal entries as sparse
    iIdx = [fb; tb];
    jIdx = [tb; fb];
    vals = [-y; -y];
    Ybus = sparse(iIdx, jIdx, vals, nbus, nbus);
    % Add diagonal series and half-shunt
    for k = 1:nbr
        Ybus(fb(k),fb(k)) = Ybus(fb(k),fb(k)) + y(k) + 1i*b(k)/2;
        Ybus(tb(k),tb(k)) = Ybus(tb(k),tb(k)) + y(k) + 1i*b(k)/2;
    end
end

function showParameterWindow(Ybus, nbus, busdata, gendata, basemva)
    % Create modern GUI
    paramFig = uifigure('Name', 'Paramètres de Stabilité Transitoire', ...
                       'Position', [100 100 500 400]);
    
    % Main grid layout
    mainGrid = uigridlayout(paramFig, [7 2]);
    mainGrid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
    mainGrid.ColumnWidth = {150, '1x'};
    mainGrid.Padding = [10 10 10 10];
    mainGrid.RowSpacing = 15;
    
    % Store data in figure's UserData
    paramFig.UserData.Ybus = Ybus;
    paramFig.UserData.nbus = nbus;
    paramFig.UserData.busdata = busdata;
    paramFig.UserData.gendata = gendata;
    paramFig.UserData.basemva = basemva;
    
    % Input fields with validation
    [~, tmaxField] = createParamField(mainGrid, 1, 'Temps de simulation (s):', 1.5, ...
        'Durée totale de la simulation');
    [~, tcrField] = createParamField(mainGrid, 2, 'Temps critique (s):', 0.2, ...
        'Temps d''élimination du défaut');
    [~, freqField] = createParamField(mainGrid, 3, 'Fréquence (Hz):', 50, ...
        'Fréquence du système');
    [~, dtField] = createParamField(mainGrid, 4, 'Pas de temps:', 0.01, ...
        'Intervalle de temps entre les calculs');
    
    % Store fields in UserData
    paramFig.UserData.tmaxField = tmaxField;
    paramFig.UserData.tcrField = tcrField;
    paramFig.UserData.freqField = freqField;
    paramFig.UserData.dtField = dtField;
    
    % Fault bus selection
    uilabel(mainGrid, 'Text', 'noeud de défaut:', 'FontWeight', 'bold');
    faultBusList = uidropdown(mainGrid, ...
        'Items', cellstr(string(1:nbus)), ...
        'Value', '1', ...
        'ValueChangedFcn', @(dd,event) updateAdjacentBuses(dd, paramFig));
    
    % Adjacent bus selection
    uilabel(mainGrid, 'Text', 'noeud adjacent:', 'FontWeight', 'bold');
    adjBusList = uidropdown(mainGrid, ...
        'Items', {''}, ...
        'Value', '', ...
        'Enable', 'off');
    
    paramFig.UserData.faultBusList = faultBusList;
    paramFig.UserData.adjBusList = adjBusList;
      % Buttons panel
    buttonGrid = uigridlayout(mainGrid, [1 2]);
    buttonGrid.Layout.Row = 7;
    buttonGrid.Layout.Column = [1 2];
    buttonGrid.ColumnWidth = {'1x', '1x'};
    
    uibutton(buttonGrid, 'Text', 'Calculer', ...
        'ButtonPushedFcn', @(btn,event) calculateStability(paramFig));
    uibutton(buttonGrid, 'Text', 'Retour', ...
        'ButtonPushedFcn', @(btn,event) goBack(paramFig));
    
    % Initialize adjacent buses list
    updateAdjacentBuses(faultBusList, paramFig);
end

function goBack(fig)
    % Get the stored calculation window handle
    calcFig = getappdata(0, 'CalcFigHandle');
    
    % Delete the current parameter window
    delete(fig);
    
    % Make sure calc window exists and is valid
    if ~isempty(calcFig) && isvalid(calcFig)
        % Show the window and bring it to front
        calcFig.Visible = 'on';
        figure(calcFig);
    else
        % If window was closed, create a new one
        openCalculationWindow();
    end
end

function [label, field] = createParamField(parent, row, labelText, defaultVal, tooltip)
    label = uilabel(parent, 'Text', labelText, 'FontWeight', 'bold');
    label.Layout.Row = row;
    label.Layout.Column = 1;
    
    field = uieditfield(parent, 'numeric', ...
        'Value', defaultVal, ...
        'ValueChangedFcn', @(field,event) validateInput(field), ...
        'Tooltip', tooltip);
    field.Layout.Row = row;
    field.Layout.Column = 2;
end

function validateInput(field)
    val = field.Value;
    if isempty(val) || val <= 0
        field.BackgroundColor = [1 0.8 0.8];
    else
        field.BackgroundColor = [1 1 1];
    end
end

function updateAdjacentBuses(sourceDropdown, fig)
    n2 = str2double(sourceDropdown.Value);
    Ybus = fig.UserData.Ybus;
    adjBusList = fig.UserData.adjBusList;
    
    Ouvre = Ybus(n2,:);
    Ouvre(n2) = 0;
    Adjassant = find(Ouvre~=0);
    
    if isempty(Adjassant)
        adjBusList.Items = {'Aucun noeud adjacent'};
        adjBusList.Value = 'Aucun noeud adjacent';
        adjBusList.Enable = 'off';
    else
        % Create items with impedance information
        items = cell(size(Adjassant));
        for i = 1:length(Adjassant)
            adj = Adjassant(i);
            Y = Ybus(n2,adj);
            Z = 1/Y;  % Convert admittance to impedance
            R = real(Z);
            X = imag(Z);
            items{i} = sprintf('Bus %d (R=%.4f, X=%.4f)', adj, R, X);
        end
        
        adjBusList.Items = items;
        adjBusList.Value = items{1};
        adjBusList.Enable = 'on';
    end
end

function calculateStability(fig)
    % Get fields from UserData
    tmaxField = fig.UserData.tmaxField;
    tcrField = fig.UserData.tcrField;
    freqField = fig.UserData.freqField;
    dtField = fig.UserData.dtField;
    faultBusList = fig.UserData.faultBusList;
    adjBusList = fig.UserData.adjBusList;
    
    % Validate all inputs
    if ~validateAllInputs(tmaxField, tcrField, freqField, dtField, adjBusList)
        uialert(fig, 'Veuillez vérifier les valeurs saisies.', 'Erreur de saisie');
        return;
    end
      % Get values
    Tmax = tmaxField.Value;
    tcr = tcrField.Value;
    f = freqField.Value;
    delta_t = dtField.Value;
    n2 = str2double(faultBusList.Value);
    
    % Extract bus number from the string "Bus X (R=0.xxxx, X=0.xxxx)"
    adjBusStr = adjBusList.Value;
    n1 = str2double(regexp(adjBusStr, 'Bus (\d+)', 'tokens', 'once'));
    
    % Get data from UserData
    Ybus = fig.UserData.Ybus;
    busdata = fig.UserData.busdata;
    gendata = fig.UserData.gendata;
    basemva = fig.UserData.basemva;
    nbus = fig.UserData.nbus;
    
    % Close parameter window
    delete(fig);
    
    % Power flow initialization
    maxiter = 100; % Maximum number of iterations
    tolerance = 1e-5; % Convergence tolerance
    
    % Initial voltage calculation
    V = busdata(:,3).*exp(1i*pi/180*busdata(:,4));
    V1 = V;
    P = (busdata(:,7)-busdata(:,5))/basemva;
    Q = (busdata(:,8)-busdata(:,6)+busdata(:,11))/basemva;
    erreur = 10;
    N = 0;

    % Power flow calculation with SUI.m
    while(erreur >= tolerance && N < maxiter)
        for i=1:nbus
            if(i~=1)
                R = sum(Ybus(1:i-1,i).*V1(1:i-1));
            else
                R = 0;
            end
            if(i~=nbus)
                Z = sum(Ybus(i+1:nbus,i).*V(i+1:nbus));
            else
                Z = 0;
            end
            % Run SUI for bus i
            run('SUI.m');
        end
        N = N+1;
        erreur1 = max(abs(real(V1)-real(V)));
        erreur2 = max(abs(imag(V1)-imag(V)));
        erreur = max(erreur1,erreur2);
        V = V1;
    end
    
    % Check convergence
    if N >= maxiter
        warndlg('Le calcul de répartition de puissance n''a pas convergé.', 'Avertissement');
    end
    
    V = abs(V);
    
    % données des générateurs
    n_gen = gendata(:,1);
    Ra = gendata(:,2);
    Xd = gendata(:,3);
    H = gendata(:,4);
    nb_gen = length(n_gen);  % le nombre de générateurs

    Ouvre = Ybus(n2,:);
    Ouvre(n2) = 0;
    Adjassant = find(Ouvre~=0);
    Adjassant = num2cell(Adjassant);
    tic

    % Modification de la matrice admittance
    Ynouveau = zeros(nb_gen+nbus);
    Ynouveau(1:nbus,1:nbus) = Ybus;
    for i=1:nb_gen
        Ynouveau(n_gen(i),nbus+i) = -1/(Ra(i)+1i*Xd(i));
        Ynouveau(nbus+i,n_gen(i)) = Ynouveau(n_gen(i),nbus+i);
        Ynouveau(n_gen(i),n_gen(i)) = Ynouveau(n_gen(i),n_gen(i))+1/(Ra(i)+1i*Xd(i));
        Ynouveau(nbus+i,nbus+i) = Ynouveau(nbus+i,nbus+i)+1/(Ra(i)+1i*Xd(i));
    end

    % Les noeuds de charge
    for i=1:nbus
        Ynouveau(i,i) = Ynouveau(i,i)+(busdata(i,5)-1i*(busdata(i,6)))/(basemva*V(i)^2);
    end

    % Matrice admittance pendant le défaut
    Y1 = Ynouveau;
    Y1(n2,:) = 0;

    % Matrice admittance après défaut
    Y2 = Ynouveau;
    Y2(n1,n1) = Y2(n1,n1)+Y2(n1,n2);
    Y2(n2,n2) = Y2(n2,n2)+Y2(n1,n2);
    Y2(n1,n2) = 0;Y2(n2,n1) = 0;

    % Ajout des noeuds de l'autre coté des générateurs
    Pg = P(n_gen)+busdata(n_gen,5)/basemva;
    Qg = Q(n_gen)+busdata(n_gen,6)/basemva;
    Ig = (Pg-1i*Qg)./(conj(V(n_gen)));
    V(end+1:end+nb_gen) = V(n_gen)+(Ra+1i*Xd).*Ig;
    Pm = Pg; % puissance mécanique supposée fixe

    % Angles internes des tensions initiaux
    D1 = angle(V(end-nb_gen+1:end));
    Df = zeros(nb_gen,floor(Tmax/delta_t)+1);
    wf = zeros(nb_gen,floor(Tmax/delta_t)+1);
    kn = 0;
    w = 2*pi*f*ones(nb_gen,1);
    Y1(n2,n2) = 1;
    
    for t1=0:delta_t:Tmax
        kn = kn+1;
        if t1 < tcr
            Y = Y1;
        else
            Y = Y2;
        end

        erreur = 10;
        while(erreur>10^(-5))
            V1 = V;
            for i=1:nbus
               V(i) = 1/Y(i,i)*(-(Y(i,:)*V-Y(i,i)*V(i)));
            end
            e1 = max(abs(real(V1-V)));
            e2 = max(abs(imag(V1-V)));
            erreur = max(e1,e2);
        end

        Ig = (V(end-nb_gen+1:end)-V(n_gen))./(Ra+1i*Xd);
        Pe = real(Ig.*conj(V(end-nb_gen+1:end)));
        dw = pi*f*(Pm-Pe)./H;
        w = w+dw*delta_t;
        wf(:,kn) = w;
        D1 = D1+(w-2*pi*f)*delta_t;
        V(end-nb_gen+1:end) = abs(V(end-nb_gen+1:end)).*exp(1i*D1);
        Df(:,kn) = 180*D1/pi;
    end
    
    D = toc;
    temp = 0:delta_t:Tmax;    figure(1)
    % Plot all speeds together
    subplot(2,1,1)
    for i=1:nb_gen
        leg = char([86 105 116 101 115 115 101 48+i]);
        plot(temp,wf(i,:)/(2*pi*f),'DisplayName',leg)
        hold on
    end
    legend
    grid on
    grid minor
    xlabel(' t(s)')
    ylabel('V(t)/Vn')
    title('Vitesses des générateurs')
    hold off
    
    % Plot all angles together
    subplot(2,1,2)
    for i=1:nb_gen
        leg = char([68 101 108 116 97 48+i]);
        plot(temp,Df(i,:),'DisplayName',leg)
        hold on
    end
    legend
    grid on
    grid minor
    xlabel(' t(s)')
    ylabel('L''angle de tension interne (deg)')
    title('Angles internes des générateurs')
    hold off
    
    figure(2)
    % Plot phase differences
    for i=2:nb_gen
        leg = char([68 101 108 116 97 48+i 49]);
        plot(temp,Df(i,:)-Df(1,:),'DisplayName',leg)
        hold on
    end
    legend
    grid on
    grid minor
    xlabel(' t(s)')
    ylabel('La phase (deg)')
    title('Phases relatives des générateurs')
    hold off
    disp('Le temps de calcul (en seconde):')
    disp(D)
end

function valid = validateAllInputs(tmaxField, tcrField, freqField, dtField, adjBusList)
    valid = tmaxField.Value > 0 && ...
            tcrField.Value >= 0 && ...
            freqField.Value > 0 && ...
            dtField.Value > 0 && ...
            ~strcmp(adjBusList.Enable, 'off');
end
