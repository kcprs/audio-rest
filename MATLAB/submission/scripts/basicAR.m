%BASICAR Fix a gap in a signal using a simple, one-directional AR predictor

% NOTE: Before running this script, call setup() to add required folders
% to MATLAB path and set global variable values.

%% Set up variable values
global fsGlobal
fs = fsGlobal;

% Uncomment below to set audio source and corresponding variables
source = "sine";
% source = "sweep";
% source = "flute";

% Uncomment below to set prediction direction
prDir = "fwd";
% prDir = "bwd";

sigLen = 4000; % Total length of damaged signal in samples
gapLen = 1000; % Length of gap in samples
fitLen = 512; % Length of fitting section in samples

% Set source-specific variable values
switch source
case "sine"
    f0 = 100;
    arOrd = 2;
    
    sig = getSinSig(sigLen, f0);
case "sweep"
    f0 = 200;
    f1 = 400;
    arOrd = 2;
    
    sig = getSweepSig(sigLen, f0, f1);
case "flute"
    sigStart = 20000;
    arOrd = 200;
    
    sig = audioread("Flute.nonvib.ff.A4.wav");
    sig = sig(sigStart:sigStart + sigLen - 1);
end

%% Damage the signal
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

pred = burgPredict(sigDmg, arOrd, predStart, predLen, fitLen);

%% Plotting
% Pad prediction so that the plot is continuous
predPad = [sigDmg(gapStart - 1); pred; sigDmg(gapEnd + 1)];

% Convert from samples to ms
t = 1000 * (1:length(sig)) / fs;

% Plot original signal with gap in the middle
sigNaN = sig;
sigNaN(gapStart:gapEnd) = NaN;
plot(t, sigNaN);
hold on;

% Plot the original signal within the gap
plot(t(gapStart - 1:gapEnd + 1), sig(gapStart - 1:gapEnd + 1), '--', ...
    'Color', [170, 170, 170] / 256);

% Plot the restored signal with legend
description = ['Reconstruction: arOrd = ', num2str(arOrd), ...
                ', gapLen = ', num2str(gapLen), ...
                ', fitLen = ', num2str(fitLen), ...
                ', fs = ', num2str(fs), ...
                ', dir = ', prDir];
p1 = plot(t(gapStart - 1:gapEnd + 1), predPad, ...
    'DisplayName', join(description, ''), 'Color', [219, 61, 21] / 256);

% Mark fitting area
if strcmp(prDir, 'bwd')
    fitStart = predStart + 1;
else
    fitStart = predStart - fitLen;
end

plot(t(fitStart:fitStart + fitLen), sig(fitStart:fitStart + fitLen), ...
    'Color', [31, 140, 12] / 256);
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

% title(['Reconstruction with One-Sided Burg AR Model - ', sigDescription]);
% legend(p1, 'Location', 'southoutside');
ylabel("Amplitude");
% ylim([-1.5; 1.5]);
xlabel("Time (ms)");
grid on;

% Save figure
switch source
    case "sine"
        filename = ['basicAR_sine_', num2str(f0), '_arOrd_', ...
                    num2str(arOrd), '_fitLen_', num2str(fitLen)];
    case "sweep"
        filename = ['basicAR_sweep_', num2str(f0), '-', num2str(f1), ...
                    '_arOrd_', num2str(arOrd), '_fitLen_', num2str(fitLen)];
    case "flute"
        filename = ['basicAR_flute_arOrd_', num2str(arOrd), '_fitLen_', ...
                    num2str(fitLen)];
end

% figPos = get(gcf, 'Position');
% figPos(4) = 0.7 * figPos(4);
% set(gcf, 'Position', figPos);
% savefig(gcf, ['figures\\arModelling\\', filename, '.fig']);
% saveas(gcf, ['figures\\arModelling\\', filename, '.png']);
% saveas(gcf, ['figures\\arModelling\\', filename, '.eps'], 'epsc');
% close(gcf);
