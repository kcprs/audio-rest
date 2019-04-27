%ARFREQESTERROR Investigate frequency estimate error in Burg AR method
% Plot estimation error against fitting section length

% NOTE: Before running this script, call setup() to add required folders
% to MATLAB path and set global variable values.

%% Set variable values
global fsGlobal
fs = fsGlobal;

% Frequency of the sinusoid used for fitting the AR model
freq = 100;

% Uncomment one below to choose relative or absolute error shown in the plot
% errMode = "abs";
errMode = "rel";

% Uncomment one below to choose units of fit length in the plot
% lenMode = "samples";
lenMode = "ms";
% lenMode = "period";

% Range of fitting lengths tried
lenRange = [128, 4096];  

% Numer of checks within the range above
nChecks = 1000;

%% Prepare intermediate variables
fitLengths = linspace(lenRange(1), lenRange(2), nChecks);

%% Compute frequency estimate errors
% Prepare vectors for storing frequency estimate errors and pole moduli 
freqEstErrors = zeros(nChecks, 1);
arPoleMods = zeros(nChecks, 1);

% Compute errors at multiple fitting lengths
for iter = 1:nChecks
    len = round(fitLengths(iter));
    sig = getCosSig(len, freq);

    % AR modelling error
    [~, A] = burgPredict(sig, 2, 0, -100, len);
    [~, arPoles, ~] = tf2zpk(1, A);

    % Compute frequency estimate from filter pole positions
    % Any of the two poles can be used as they are complex conjugates.
    % Taking the absolute value of the pole argument will give the same
    % result for either of the poles.
    arFreqEst = fs * abs(angle(arPoles(1))) / (2 * pi);
    freqEstErrors(iter) = arFreqEst - freq;

    % Compute pole modulus
    % Again, since the two poles are complex conjugates, they have the
    % same modulus 
    arPoleMods(iter) = abs(arPoles(1));
end

%% Plotting
% Frequency estimate errors
switch lenMode
    case "samples"
        xLabelDesc = 'Signal length in samples';
        xVec = fitLengths;
        xLimits = lenRange;
    case "ms"
        xLabelDesc = 'Fitting section length in ms';
        xVec = fitLengths / fs * 1000;
        xLimits = lenRange / fs * 1000;
    case "period"
        xLabelDesc = 'Fitting section length in wave periods';
        xVec = freq * fitLengths / fs;
        xLimits = [1, 10000 * lenRange(2) / fs];

end

switch errMode
    case "rel"
        yVec = freqEstErrors / freq * 100;
        yLabelDesc = 'Frequency estimate - relative error';
    case "abs"
        yVec = freqEstErrors;
        yLabelDesc = 'Frequency estimate error in Hz';
end

freqEstFig = figure(1);
plot(xVec, yVec);
title(['AR modelling - frequency estimate error for sine wave @ ', ...
        num2str(freq), ' Hz']);
xlabel(xLabelDesc);
ylabel(yLabelDesc);
grid on;
set(gca, 'YMinorTick','on', 'YMinorGrid', 'on');

if strcmp(errMode, 'rel')
    ytickformat(gca, 'percentage');
end

% Pole moduli
modFig = figure(2);
plot(xVec, arPoleMods);
title(['AR modelling - filter pole modulus - sine wave @ ', ...
num2str(freq), ' Hz']);
xlabel(xLabelDesc);
ylabel('Pole modulus');
grid on;
set(gca, 'YMinorTick','on', 'YMinorGrid', 'on');

% Save figures
% filenameFreq = ['arFreqEstError_cos_', num2str(freq), '_Hz'];
% savefig(['figures\\arModelling\\', filenameFreq]);
% saveas(freqEstFig, ['figures\\arModelling\\', filenameFreq, '.png']);
% saveas(freqEstFig, ['figures\\arModelling\\', filenameFreq, '.eps'], 'epsc');

% filenameRad = ['arPoleModulus_cos_', num2str(freq), '_Hz'];
% savefig(['figures\\arModelling\\', filenameRad]);
% saveas(modFig, ['figures\\arModelling\\', filenameRad, '.png']);
% saveas(modFig, ['figures\\arModelling\\', filenameRad, '.eps'], 'epsc');
