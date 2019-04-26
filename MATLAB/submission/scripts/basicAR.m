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

sigLen = 4000; % Total length of damaged signal in samples
gapLen = 1000; % Length of gap in samples
fitLen = 512; % Length of fitting section in samples

%% Prepare the damaged signal
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

% Replace gap with predicted signal
sigDmg(gapStart:gapStart + gapLen - 1) = pred;

%% Plotting
% Convert from samples to ms
t = 1000 * (1:length(sig)) / fs;

% Plot the original signal within the gap
plot(t(gapStart:gapEnd), sig(gapStart:gapEnd), '--', 'Color', ...
    [180, 180, 180] / 256);

% Plot the restored signal with legend
hold on;
set(gca, 'ColorOrderIndex', 1);

description = ['arOrd = ', num2str(arOrd), ...
                ', gapLen = ', num2str(gapLen), ...
                ', fitLen = ', num2str(fitLen), ...
                ', fs = ', num2str(fs), ...
                ', dir = ', prDir];
p1 = plot(t, sigDmg, 'DisplayName', join(description, ''));

% Mark gap area
recHeight = 1.1 * max([abs(sig); abs(pred)]);
rectangle('Position', [t(gapStart), -recHeight, t(gapLen), 2 * recHeight], ...
    'FaceColor', 'none', 'EdgeColor', [219, 61, 21] / 256, ...
    'LineStyle', '--');

% Mark fitting area
if strcmp(prDir, 'bwd')
    fitStart = predStart + 1;
else
    fitStart = predStart - fitLen;
end

rectangle('Position', [t(fitStart), -recHeight, t(fitLen), 2 * recHeight], ...
    'FaceColor', 'none', 'EdgeColor', [96, 186, 27] / 256, ...
    'LineStyle', '--');
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

% Save figure
switch source
    case "sine"
        filename = ['basicAR_sine_', num2str(f0), '_fitLen_', ...
                    num2str(fitLen)];
    case "sweep"
        filename = ['basicAR_sweep_', num2str(f0), '-', num2str(f1), ...
                    '_fitLen_', num2str(fitLen)];
    case "flute"
        filename = ['basicAR_flute_arOrd_', num2str(arOrd), '_fitLen_', ...
                    num2str(fitLen)];
end

% savefig(['figures\\arModelling\\', filename]);
% saveas(gcf, ['figures\\arModelling\\', filename, '.png']);
% saveas(gcf, ['figures\\arModelling\\', filename, '.eps'], 'epsc');
