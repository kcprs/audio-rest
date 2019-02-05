%% Set up variable values
fs = 44100;
ord = 2;
sigLen = 5 * fs;
sigFreq = 440;
gapLen = fs;
fitLen = 200;

%% Prepare the damaged signal
% sig = getSineSig(sigFreq, sigLen);
sig = getChirpSig(sigFreq, sigFreq * 10, sigLen);
[dam, gapLoc] = makeGap(sig, gapLen);

%% Restoration
% Predict the missing signal forward
predFwd = predictOneDir(dam, ord, gapLoc, gapLoc + gapLen - 1, fitLen);

% Predict the missing signal backward
predBwd = predictOneDir(dam, ord, gapLoc, gapLoc + gapLen - 1, fitLen, -1);

% Apply the crossfade
pred = crossfade(predFwd, predBwd);

% Replace gap with predicted signal
dam(gapLoc:gapLoc + gapLen - 1) = pred;

%% Plotting
% Plot the restored signal
subplot(2, 1, 1);
plot(sig, ':');
hold on;
plot(dam);
plot([gapLoc, gapLoc], [-1, 1], 'Color', [0, 0, 0, 0.3]);
plot([gapLoc + gapLen - 1, gapLoc + gapLen - 1], [-1, 1], 'Color', [0, 0, 0, 0.3]);
hold off;
subplot(2, 1, 2);
nfft = 2048;
spectrogram(dam, nfft, nfft / 16, nfft, fs, 'yaxis');
set(gca, 'YScale', 'log');