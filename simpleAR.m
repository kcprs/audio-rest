%% Set up variable values
arOrder = 2;
sigLen = 1000;
sigFreq = 440;
gapLen = 200;
preLen = 200;

%% Prepare the damaged signal
sig = getSineSig(sigFreq, sigLen);
[dam, gapLoc] = makeGap(sig, gapLen);

%% Restoration
% Select signal section for model fitting
fitSect = dam(gapLoc - preLen:gapLoc - 1);

% Fit the model
[a, e] = arburg(fitSect, arOrder);

% Find initial conditions
zinit = filtic(e, a, fliplr(fitSect));

% Prepare impulse signal
imp = zeros(gapLen, 1);
imp(1) = 1;

% Get restored signal
rest = filter(e, a, imp, zinit);

% Replace gap with restored signal
dam(gapLoc:gapLoc + gapLen - 1) = rest;

%% Plotting
% Plot AR model in z-domain
subplot(2, 1, 1);
zplane(1, a);

% Plot the restored signal
subplot(2, 1, 2);
plot(sig, ':');
hold on;
plot(dam);
plot([gapLoc, gapLoc], [-1, 1], 'Color', [0, 0, 0, 0.3]);
plot([gapLoc + gapLen - 1, gapLoc + gapLen - 1], [-1, 1], 'Color', [0, 0, 0, 0.3]);
hold off;
