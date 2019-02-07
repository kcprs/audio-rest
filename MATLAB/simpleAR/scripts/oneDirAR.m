%% Set up variable values
fs = 44100;
f0 = 100;
f1 = 1000;
ord = 2;
sigLen = 3000;
gapLen = 1000;
% fitLen = 500;
fitLen = round(fs / f0);

prDir = 'fwd';
% prDir = 'bwd';

sigType = 'sine';
% sigType = 'sweep';

%% Prepare the damaged signal
if strcmp(sigType, 'sweep')
    sig = getChirpSig(f0, f1, sigLen);
else
    sig = getSineSig(f0, sigLen);
end

[dam, gapStart, gapEnd] = makeGap(sig, gapLen);

%% Restoration
% Predict the missing signal
if strcmp(prDir, 'bwd')
    predStart = gapEnd;
    predLen = -gapLen;
else
    predStart = gapStart;
    predLen = gapLen;
end

pred = burgPredict(dam, ord, predStart, predLen, fitLen);

% Replace gap with predicted signal
dam(gapStart:gapStart + gapLen - 1) = pred;

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
                ', dir = ', prDir];
p1 = plot(dam, 'DisplayName', description);

% Mark gap area
rectangle('Position', [gapStart, -1.2, gapLen, 2.4], ...
    'FaceColor', [1, 0, 0, 0.1], ...
    'EdgeColor', 'none');
hold off;

% Add title and legend
title('Reconstruction with One-Sided Burg AR Model (time-domain)');
legend(p1, 'Location', 'southoutside');
