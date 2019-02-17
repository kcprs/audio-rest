%SPDSIGNALSTESTING Evaluate spectral peak detection performance for
%different input signals.

%% Set variable values
fs = 44100;
nfft = 2048;
sigType = 'sin + noise';
% sigType = 'realrec';
sigLen = 1000;
sinFreqs = [1000; 890; 2000];
sinAmps = [0.4; 0.7; 0.4];
sinPhs = rand(length(sinFreqs), 1);
randPhase = true;
noiseAmp = 0.4;

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
[f, m, a] = findSpecPeak(sig, nfft);

%% Plotting
subplot(2, 1, 1);
sinusoids = [sinFreqs, sinAmps, sinPhs];
plot(sig, 'DisplayName', ['Signal: ', num2str(length(sinFreqs)), ...
                        ' sinusoids (freq, amp, ph): ', ...
                        mat2str(sinusoids, 4), ' + white noise of amp ', ...
                        num2str(noiseAmp)]);
title('Spectral peak detection test');
xlabel('Time in samples');
ylabel('Analysed signal');
legend;
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

for iter = 1:length(f)
    text(f(iter), m(iter), ['  f = ', num2str(f(iter), 5), ', m = ', ...
                                num2str(m(iter), 3), ', a = ', ...
                                num2str(a(iter), 2)]);
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
