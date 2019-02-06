%% Set up variable values
fs = 44100;
f0 = 100;
f1 = 1000;
ord = 2;
sigLen = 3000;
gapLen = 1000;
fitLen = 200;
prDir = 1;

sigType = 'sine';
% sigType = 'sweep';

%% Prepare the damaged signal
if strcmp(sigType, 'sweep')
    sig = getChirpSig(f0, f1, sigLen);
else
    sig = getSineSig(f0, sigLen);
end

[dam, gapLoc] = makeGap(sig, gapLen);

%% Restoration
% Predict the missing signal
pred = predictOneDir(dam, ord, gapLoc, gapLoc + gapLen - 1, fitLen, prDir);

% Replace gap with predicted signal
dam(gapLoc:gapLoc + gapLen - 1) = pred;

%% Plotting
% Plot the original signal
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
                ', fs = ', num2str(fs), ...
                ', dir = ', num2str(prDir)];
p1 = plot(dam, 'DisplayName', description);

% Mark gap area
rectangle('Position', [gapLoc, -1.2, gapLen, 2.4], ...
    'FaceColor', [1, 0, 0, 0.1], ...
    'EdgeColor', 'none');
hold off;

% Add title and legend
title('Reconstruction with One-Sided Burg AR Model (time-domain)');
legend(p1, 'Location', 'southoutside');
