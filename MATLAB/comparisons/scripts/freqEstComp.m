%FREQESTCOMP Compare frequency estimation accuracy between AR modelling and
%two varieties of spectral peak detection

%% Set variable values
fs = 44100;
freq = 1000;
nfft = 2048;

% errMode = 'abs';
errMode = 'rel';

lenMode = 'samples';
% lenMode = 'ms';
% lenMode = 'period';

%% Prepare intermediate variables
lenRange = [100, 5000];
minLen = fs / freq;
sigLengths = round(logspace(max(log10(minLen), log10(lenRange(1))), ...
    log10(lenRange(2)), 1000));
nComps = length(sigLengths);

%% Compute frequency estimate errors
% Prepare vectors for storing error values
arErrors = zeros(nComps, 1);
pdErrors = zeros(nComps, 1);
pdpErrors = zeros(nComps, 1);

% Compute errors for given frequency at multiple signal lengths
for iter = 1:nComps
    len = sigLengths(iter);
    sig = getSineSig(freq, len);

    % AR modelling error
    [~, A] = burgPredict(sig, 2, 0, -100, len);
    [~, poles, ~] = tf2zpk(1, A);
    arFreqEst = fs * abs(angle(poles(1))) / (2 * pi);
    arErrors(iter) = arFreqEst - freq;

    % Peak detection error without padding
    pdFreqEst = findSpecPeak(sig);
    pdErrors(iter) = pdFreqEst - freq;

    % Peak detection error with padding
    pdpFreqEst = findSpecPeak(sig, nfft);
    pdpErrors(iter) = pdpFreqEst - freq;
end

%% Plotting
if strcmp(lenMode, 'ms')
    xVec = sigLengths / fs * 1000;
    xLabelDesc = 'Signal length in ms';
    xLimits = lenRange / fs * 1000;
elseif strcmp(lenMode, 'period')
    xVec = freq * sigLengths / fs;
    xLabelDesc = 'Signal length in frequency periods';
    xLimits = [1, 10000 * lenRange(2) / fs];
else
    xVec = sigLengths;
    xLabelDesc = 'Signal length in samples';
    xLimits = lenRange;
end

if strcmp(errMode, 'rel')
    arVec = arErrors / freq * 100;
    pdVec = pdErrors / freq * 100;
    pdpVec = pdpErrors / freq * 100;
    yLabelDesc = 'Frequency estimate - relative error';
else
    arVec = arErrors;
    pdVec = pdErrors;
    pdpVec = pdpErrors;
    yLabelDesc = 'Frequency estimate error in Hz';
end

semilogx(xVec, arVec, 'DisplayName', 'AR modelling');
hold on;
semilogx(xVec, pdVec, 'DisplayName', ...
    'Peak detection without padding (nfft = length(sig))');
semilogx(xVec, pdpVec, 'DisplayName', ...
    ['Peak detection with padding (nfft = ', num2str(nfft), ')']);
hold off;

title(['Frequency estimate error for sine wave @ ', num2str(freq), ' Hz']);
xlabel(xLabelDesc);
ylabel(yLabelDesc);
grid on;
legend;

if strcmp(errMode, 'rel')
    ytickformat(gca, 'percentage');
end

% Code below is from: https://uk.mathworks.com/matlabcentral/answers/95023-how-do-i-change-the-x-axis-label-on-a-semilogx-plot-from-exponential-to-normal-format-in-matlab
New_XTickLabel = get(gca, 'xtick');
set(gca, 'XTickLabel', New_XTickLabel);
zoomH = zoom(gcf);
set(zoomH, 'ActionPostCallback', {@zoom_postcallback});

function zoom_postcallback(~, ~)
    % This function executes after every zoom operation
    New_XTickLabel = get(gca, 'xtick');
    set(gca, 'XTickLabel', New_XTickLabel);
end

% End of borrowed code
