% WEIGHTEDFWBWAR Fix a gap in a signal using a weighted forward-backward
% predictor

%% Set up variable values
global fsGlobal
fs = fsGlobal;

% Uncomment below to set audio source and corresponding variables
% source = "sine";
% source = "sweep";
% source = "flute.nonvib";
source = "flute.vib";

sigLen = fs; % Total length of damaged signal in samples
gapLen = 5000; % Length of gap in samples
fitLen = 2048; % Length of fitting section in samples

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
    case "flute.nonvib"
        sigStart = 15000;
        arOrd = 200;

        sig = audioread("Flute.nonvib.ff.A4.wav");
        sig = sig(sigStart:sigStart + sigLen - 1);
    case "flute.vib"
        sigStart = 15000;
        arOrd = 200;

        sig = audioread("Flute.vib.ff.A4.wav");
        sig = sig(sigStart:sigStart + sigLen - 1);
end

%% Damage the signal
[sigDmg, gapStart, gapEnd] = makeGap(sig, gapLen);

%% Restoration
% Predict the missing signal forward
predFwd = burgPredict(sigDmg, arOrd, gapStart, gapLen, fitLen);

% Predict the missing signal backward
predBwd = burgPredict(sigDmg, arOrd, gapEnd, -gapLen, fitLen);

% Apply the crossfade
pred = crossfade(predFwd, predBwd);

% Replace gap with predicted signal
sigRest = sigDmg;
sigRest(gapStart:gapEnd) = pred;

%% Plotting
% Pad prediction so that the plot is continuous
predPad = [sigRest(gapStart - 1); pred; sigRest(gapEnd + 1)];

% Convert from samples to ms
t = 1000 * (1:length(sig)) / fs;

% Time domain
tFig = figure(1);
% Plot the original signal
sigNaN = sig;
sigNaN(gapStart:gapEnd) = NaN;
plot(t, sigNaN);
hold on;

% Plot the original signal within the gap
% plot(t(gapStart - 1:gapEnd + 1), sig(gapStart - 1:gapEnd + 1), '--', ...
    %     'Color', [170, 170, 170] / 256);

% Plot the restored signal with legend
description = ['Reconstruction: arOrd = ', num2str(arOrd), ...
                ', gapLen = ', num2str(gapLen), ...
                ', fitLen = ', num2str(fitLen), ...
                ', fs = ', num2str(fs)];
p1 = plot(t(gapStart - 1:gapEnd + 1), predPad, ...
    'DisplayName', join(description, ''), 'Color', [255, 0, 0] / 256);

% Mark fitting areas
plot(t(gapStart - fitLen:gapStart - 1), ...
    sig(gapStart - fitLen:gapStart - 1), ...
    'Color', [31, 140, 12] / 256);
plot(t(gapEnd + 1:gapEnd + fitLen), sig(gapEnd + 1:gapEnd + fitLen), ...
    'Color', [31, 140, 12] / 256);
hold off;

% Add title, legend, etc.
switch source
    case "sine"
        sigDescription = ['sine @ f = ', num2str(f0), ' Hz'];
    case "sweep"
        sigDescription = ['sine sweep: f_{start} = ', num2str(f0), ' Hz', ...
                        ' f_{end} = ', num2str(f1), ' Hz'];
    case "flute.nonvib"
        sigDescription = 'audio: Flute.nonvib.ff.A4.wav';
    case "flute.nonvib"
        sigDescription = 'audio: Flute.vib.ff.A4.wav';
end

title(['Weighted Fwd-Bwd AR Model - ', sigDescription]);
legend(p1, 'Location', 'southoutside');
ylabel("Amplitude");
xlabel("Time (ms)");
grid on;

% Frequency domain
fFig = figure(2);
spgm(sigRest, 1024);
% set(gca, 'YScale', 'log');
title(['Weighted Fwd-Bwd AR Model - ', sigDescription]);

% Original signal in full - time domain
otFig = figure(3);
plot(t, sig);
title("Original signal");
ylabel("Amplitude");
xlabel("Time (ms)");
grid on;

% Frequency domain
ofFig = figure(4);
spgm(sig, 1024);
% set(gca, 'YScale', 'log');
title("Original signal");

% Save figures
switch source
    case "sine"
        filename = ['wfbAR_sine_', num2str(f0), '_arOrd_', ...
                    num2str(arOrd), '_fitLen_', num2str(fitLen)];
    case "sweep"
        filename = ['wfbAR_sweep_', num2str(f0), '-', num2str(f1), ...
                    '_arOrd_', num2str(arOrd), '_fitLen_', num2str(fitLen)];
    case "flute.nonvib"
        filename = ['wfbAR_flute_nonvib_arOrd_', num2str(arOrd), ...
                    '_fitLen_', num2str(fitLen)];
    case "flute.vib"
        filename = ['wfbAR_flute_vib_arOrd_', num2str(arOrd), ...
                    '_fitLen_', num2str(fitLen)];
end

% figPos = get(tFig, 'Position');
% figPos(4) = 0.7 * figPos(4);
% set(tFig, 'Position', figPos);
% tFilename = [filename, '_time'];
% savefig(['figures\\arModelling\\', tFilename]);
% saveas(tFig, ['figures\\arModelling\\', tFilename, '.png']);
% saveas(tFig, ['figures\\arModelling\\', tFilename, '.eps'], 'epsc');
% close(tFig);

% figPos = get(fFig, 'Position');
% figPos(4) = 0.7 * figPos(4);
% set(fFig, 'Position', figPos);
% fFilename = [filename, '_freq'];
% savefig(['figures\\arModelling\\', fFilename]);
% saveas(fFig, ['figures\\arModelling\\', fFilename, '.png']);
% saveas(fFig, ['figures\\arModelling\\', fFilename, '.eps'], 'epsc');
% close(fFig);

% figPos = get(otFig, 'Position');
% figPos(4) = 0.7 * figPos(4);
% set(otFig, 'Position', figPos);
% otFilename = [filename, '_origTime'];
% savefig(['figures\\arModelling\\', otFilename]);
% saveas(otFig, ['figures\\arModelling\\', otFilename, '.png']);
% saveas(otFig, ['figures\\arModelling\\', otFilename, '.eps'], 'epsc');
% close(otFig);

% figPos = get(ofFig, 'Position');
% figPos(4) = 0.7 * figPos(4);
% set(ofFig, 'Position', figPos);
% ofFilename = [filename, '_origFreq'];
% savefig(['figures\\arModelling\\', ofFilename]);
% saveas(ofFig, ['figures\\arModelling\\', ofFilename, '.png']);
% saveas(ofFig, ['figures\\arModelling\\', ofFilename, '.eps'], 'epsc');
% close(ofFig);
