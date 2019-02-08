% WEIGHTEDFWBWAR Fix a gap in a signal using a weighted forward-backward
% predictor

%% Set up variable values
fs = 44100;
f0 = 100;
f1 = 1000;
ord = 2;
sigLen = 4000;
gapLen = 2000;
fitLen = 200;

% sigType = 'sine';
sigType = 'sweep';

%% Prepare the damaged signal
if strcmp(sigType, 'sweep')
    sig = getChirpSig(f0, f0 * 10, sigLen);
else
    sig = getSineSig(f0, sigLen);
end

[dam, gapStart, gapEnd] = makeGap(sig, gapLen);

%% Restoration
% Predict the missing signal forward
predFwd = burgPredict(dam, ord, gapStart, gapLen, fitLen);

% Predict the missing signal backward
predBwd = burgPredict(dam, ord, gapEnd, -gapLen, fitLen);

% Apply the crossfade
pred = crossfade(predFwd, predBwd);

% Replace gap with predicted signal
dam(gapStart:gapEnd) = pred;

%% Plotting
% Time domain
% Plot the original signal
subplot(2, 1, 1);
plot(sig, ':');

% Plot the restored signal with legend
hold on;

if strcmp(sigType, 'sweep')
    sigDescription = ['f0 = ', num2str(f0), ' f1 = ', num2str(f1)];
else
    sigDescription = ['f0 = ', num2str(f0)];
end

description = ['ord = ', num2str(2), ...
                ', gapLen = ', num2str(gapLen), ...
                ', fitLen = ', num2str(fitLen), ...
                ', ', sigDescription, ...
                ', fs = ', num2str(fs)];
p1 = plot(dam, 'DisplayName', description);

% Mark gap area
rectangle('Position', [gapStart, -1.2, gapLen, 2.4], ...
    'FaceColor', [1, 0, 0, 0.1], ...
    'EdgeColor', 'none');
hold off;

% Mark fitting areas
rectangle('Position', [gapStart - fitLen, -1.2, fitLen, 2.4], ...
    'FaceColor', [0, 1, 0, 0.1], ...
    'EdgeColor', 'none');

rectangle('Position', [gapEnd + 1, -1.2, fitLen, 2.4], ...
    'FaceColor', [0, 1, 0, 0.1], ...
    'EdgeColor', 'none');
hold off;

% Add title and legend
title('Reconstruction with Weighted Fwd-Bwd Burg AR Model (time-domain)');
legend(p1, 'Location', 'southoutside');

% Frequency domain
subplot(2, 1, 2);
nfft = 1024;
hopSize = 64;
spectrogram(dam, nfft, nfft - hopSize, nfft, fs, 'yaxis');
set(gca, 'YScale', 'log');

% Add title
title('Reconstruction with Weighted Fwd-Bwd Burg AR Model (frequency-domain)');
