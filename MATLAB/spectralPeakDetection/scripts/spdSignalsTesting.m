%SPDSIGNALSTESTING Evaluate spectral peak detection performance for
%different input signals.

%% Set variable values
fs = 44100;
nfft = 2048;
sigType = 'sin + noise';
% sigType = 'realrec';
sigLen = 1000;
sinFreqs = [50; 890; 1000; 2000];
sinAmps = [0.1; 0.1; 0.15; 0.1];
% sinPhs = rand(length(sinFreqs), 1) * 2 * pi;
sinPhs = zeros(length(sinFreqs), 1);
noiseAmp = 0.6;
detThresh = 25;

%% Prepare signal
if strcmp(sigType, 'realrec')
    error('Not yet implemented');
else
    sig = zeros(sigLen, 1);

    for iter = 1:length(sinFreqs)
        sig = sig + getSineSig(sigLen, sinFreqs(iter), sinAmps(iter), ...
            sinPhs(iter));
    end

    sig = sig + noiseAmp * (2 * rand(sigLen, 1) - 1);
end

%% Find spectral peaks
specPeaks = findSpecPeaks(sig, detThresh, nfft);
f = specPeaks(:, 1);
m = specPeaks(:, 2);
a = specPeaks(:, 3);

%% Plotting
% Prepare strings for plot legend
sigString = '';

for iter = 1:length(sinFreqs)
    fSigFig = floor(log10(sinFreqs(iter))) + 1;
    fString = num2str(sinFreqs(iter), fSigFig);
    aString = num2str(sinAmps(iter), 3);
    pString = num2str(sinPhs(iter), 2);

    sigString = strcat(sigString, {' ('}, fString, {', '}, aString, ...
        {', '}, pString, ')');
end

% Plot analysed signal
subplot(2, 1, 1);
plot(sig, 'DisplayName', ['Signal: ', num2str(length(sinFreqs)), ...
                        ' sinusoids (f, a, p):', char(sigString), ...
                        ' + white noise of amp ', num2str(noiseAmp)]);
title('Spectral peak detection test');
xlabel('Time in samples');
ylabel('Analysed signal');
legend;

% Plot spectrum and peak estimates
subplot(2, 1, 2);
yVec = 20 * log10(abs(fft(sig .* gausswin(sigLen) .* kaiser(sigLen), ...
    nfft)));
xVec = linspace(0, fs / 2, nfft / 2);
semilogx(xVec, yVec(1:nfft / 2), 'DisplayName', 'Signal spectrum');
xlim([20, 20000]);
hold on;
plot(f, m, 'x', 'DisplayName', 'Frequency and magnitude estimates');
hold off;
xlabel('Frequency in Hz');
ylabel('Magnitude spectrum in dB');
legend;
grid on;

% Prepare strings for plot annotations
fString = cell(1, length(f));
mString = cell(1, length(m));
aString = cell(1, length(a));

for iter = 1:length(f)
    fSigFig = floor(log10(round(f(iter)))) + 1;
    fString(iter) = {num2str(f(iter), fSigFig)};

    mString(iter) = {num2str(m(iter), 3)};
    aString(iter) = {num2str(a(iter), 2)};
end

% Add plot annotations for peak estimates
for iter = 1:length(f)
    text(f(iter), m(iter), ['  f=', char(fString(iter)), ', m=', ...
                                char(mString(iter)), ', a=', ...
                                char(aString(iter))]);
end

% Change xlabel format from 10^(n) to simple integers
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
