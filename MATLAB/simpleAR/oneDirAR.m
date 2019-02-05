%% Set up variable values
ord = 2;
sigLen = 1000;
sigFreq = 440;
gapLen = 200;
fitLen = 200;
prDir = -1;

%% Prepare the damaged signal
% sig = getSineSig(sigFreq, sigLen);
sig = getChirpSig(sigFreq, sigFreq * 10, sigLen);
[dam, gapLoc] = makeGap(sig, gapLen);

%% Restoration
% Predict the missing signal
pred = predictOneDir(dam, ord, gapLoc, gapLoc + gapLen - 1, fitLen, prDir);

% Replace gap with predicted signal
dam(gapLoc:gapLoc + gapLen - 1) = pred;

%% Plotting
% Plot the restored signal
plot(sig, ':');
hold on;
plot(dam);
plot([gapLoc, gapLoc], [-1, 1], 'Color', [0, 0, 0, 0.3]);
plot([gapLoc + gapLen - 1, gapLoc + gapLen - 1], [-1, 1], 'Color', [0, 0, 0, 0.3]);
hold off;
