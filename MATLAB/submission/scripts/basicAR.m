%BASICAR Fix a gap in a signal using a simple, one-directional AR predictor

% NOTE: Before running this script, call setup() to add required folders to
% MATLAB path and set global variable values.

%% Set up variable values
global fsGlobal
fs = fsGlobal;

% Uncomment below to set audio source and corresponding variables
% source = "flute";
source = "sine";
% source = "sweep";

% Uncomment below to set prediction direction
prDir = "fwd";
% prDir = "bwd";

sigLen = 2000;  % Total length of damaged signal in samples
gapLen = 1000;  % Length of gap in samples
fitLen = 256;   % Length of fitting section in samples

%% Prepare the damaged signal
switch source
    case "sine"
        f0 = 440;
        ord = 2;
        
        sig = getSinSig(sigLen, f0);
    case "sweep"
        f0 = 440;
        f1 = 880;
        ord = 2;

        sig = getSweepSig(sigLen, f0, f1);
    case "flute"
        sigStart = 20000;
        ord = 200;

        sig = audioread("Flute.nonvib.ff.A4.wav");
        sig = sig(sigStart:sigStart + sigLen - 1);
end

[sigDmg, gapStart, gapEnd] = makeGap(sig, gapLen);

%% Restoration
% Predict the missing signal
switch prDir
    case "fwd"
        predStart = gapStart;
        predLen = gapLen;
    case "bwd"
        predStart = gapEnd;
        predLen = -gapLen;
end

pred = burgPredict(sigDmg, ord, predStart, predLen, fitLen);

% Replace gap with predicted signal
sigDmg(gapStart:gapStart + gapLen - 1) = pred;

%% Plotting
% Convert from samples to ms
t = 1000 * (1:length(sig)) / fs;

% Plot the original signal
plot(t, sig, ':');

% Plot the restored signal with legend
hold on;

description = ['arOrd = ', num2str(ord), ...
                ', gapLen = ', num2str(gapLen), ...
                ', fitLen = ', num2str(fitLen), ...
                ', fs = ', num2str(fs), ...
                ', dir = ', prDir];
p1 = plot(t, sigDmg, 'DisplayName', join(description, ''));

% Mark gap area
maxAmp = max([abs(sig); abs(pred)]);
rectangle('Position', [t(gapStart), -maxAmp, t(gapLen), 2 * maxAmp], ...
    'FaceColor', [1, 0, 0, 0.1], ...
    'EdgeColor', 'none');

% Mark fitting area
if strcmp(prDir, 'bwd')
    fitStart = predStart + 1;
else
    fitStart = predStart - fitLen;
end

rectangle('Position', [t(fitStart), -maxAmp, t(fitLen), 2 * maxAmp], ...
    'FaceColor', [0, 1, 0, 0.1], ...
    'EdgeColor', 'none');
hold off;

% Add title, legend, etc.
switch source
case "sine"
    sigDescription = ['sine @ f = ', num2str(f0), ' Hz'];
case "sweep"
    sigDescription = ['sine sweep: f_{start} = ', num2str(f0), ' Hz', ...
                    ' f_{end} = ', num2str(f1), ' Hz'];
case "flute"
    sigDescription = 'audio: Flute.nonvib.ff.A4.wav';
end

title(['Reconstruction with One-Sided Burg AR Model - ', sigDescription]);
legend(p1, 'Location', 'southoutside');
ylabel("Amplitude");
xlabel("Time (ms)");
grid on;