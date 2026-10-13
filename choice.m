clear; clc;

files = dir('system*.m');
dataOptions = {files.name};              
dataOptions = erase(dataOptions, '.m');  


dataChoice = menu('Choose a Power System Data File:', dataOptions);

if dataChoice == 0
    error('No data file selected.');
end

dataFile = dataOptions{dataChoice};
fprintf('\n--> Loading data from: %s.m\n', dataFile);
run([dataFile '.m']);  

% === 2. Choose Load Flow Method ===
methodOptions = {'FDLF', 'Gauss_Seidel', 'Newton_Raphson'};
methodChoice = menu('Choose a Load Flow Method:', methodOptions);

if methodChoice == 0
    error('No method selected.');
end

methodFile = methodOptions{methodChoice};
fprintf('--> Running method: %s.m\n\n', methodFile);
run([methodFile '.m']);  % Run the selected method file
