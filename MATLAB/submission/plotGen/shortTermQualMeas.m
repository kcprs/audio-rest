% NOTE: Before running this script, call setup() to add required folders
% to MATLAB path and set global variable values.

%% Set up variable values
global fsGlobal
fs = fsGlobal;

gapLen = 1000;
f = 800;

restType = "sin";
% restType = "noise";

% Fit one more period in restored version
fRest = f + fs / gapLen;
fError = 100 * (fRest - f) / f;
% disp(['f error: ', num2str(fError), ' %']);

sigLen = gapLen + 500;
sig = getCosSig(sigLen, f);
[sigDmg, gapStart, gapEnd] = makeGap(sig, gapLen);

phs = acos(sig(gapStart));

if sig(gapStart) > sig(gapStart - 1)
    phs = 2 * pi - phs;
end

switch restType
    case "sin"
        pred = getCosSig(gapLen, fRest, 0, phs);
    case "noise"
        pred = randn([gapLen, 1]) / 3;
end

sigRestFull = sig;
sigRestFull(gapStart:gapEnd) = pred;
sigDiff = sigRestFull - sig;

snrVal = snr(sig(gapStart:gapEnd), sigDiff(gapStart:gapEnd));
mseVal = getMSE(sig(gapStart:gapEnd), pred);

%% Plotting
% Pad prediction for continuous plot
predPad = [sigDmg(gapStart - 1); pred; sigDmg(gapEnd + 1)];
% Convert from samples to ms
t = 1000 * (1:length(sig)) / fs;

% Overlapped
oFig = figure(1);
% Plot original signal with gap in the middle
sigNaN = sig;
sigNaN(gapStart:gapEnd) = NaN;
plot(t, sigNaN);
hold on;

if strcmp(restType, "sin")
    % Plot the original signal within the gap
    plot(t(gapStart - 1:gapEnd + 1), sig(gapStart - 1:gapEnd + 1), '--', ...
        'Color', [170, 170, 170] / 256);
end

% plot the restoration
plot(t(gapStart - 1:gapEnd + 1), predPad, 'Color', [219, 61, 21] / 256);

switch restType
    case "sin"
        title(['Inaccurately restored sinusoid @ ', num2str(f), ' Hz']);
    case "noise"
        title(['Failed reconstruction of sinusoid @ ', num2str(f), ' Hz']);
end

ylabel("Amplitude");
ylim([-1.1; 1.1]);
xlabel("Time (ms)");
grid on;
hold off;

% Difference
dFig = figure(2);
plot(t, sigDiff);
title(['Difference between restoration and original (SNR: ', ...
        num2str(snrVal, 2), ' dB, MSE: ', num2str(mseVal, 2), ')']);
ylabel("Amplitude");
xlabel("Time (ms)");
grid on;

% Save figure
switch restType
    case "sin"
        restDesc = ['_fRest_', num2str(fRest)];
    case "noise"
        restDesc = '_noise';
end

filename = ['shortTermQualMeas_overlapped_gap_', num2str(gapLen), '_f_', ...
                num2str(f), restDesc];
figPos = get(oFig, 'Position');
figPos(3) = 1.5 * figPos(3);
figPos(4) = 0.5 * figPos(4);
set(oFig, 'Position', figPos);
savefig(oFig, ['figures\\qualityAssessment\\', filename, '.fig']);
saveas(oFig, ['figures\\qualityAssessment\\', filename, '.png']);
saveas(oFig, ['figures\\qualityAssessment\\', filename, '.eps'], 'epsc');
close(oFig);

filename = ['shortTermQualMeas_difference_gap_', num2str(gapLen), '_f_', ...
                num2str(f), restDesc];
figPos = get(dFig, 'Position');
figPos(3) = 1.5 * figPos(3);
figPos(4) = 0.5 * figPos(4);
set(dFig, 'Position', figPos);
savefig(dFig, ['figures\\qualityAssessment\\', filename, '.fig']);
saveas(dFig, ['figures\\qualityAssessment\\', filename, '.png']);
saveas(dFig, ['figures\\qualityAssessment\\', filename, '.eps'], 'epsc');
close(dFig);
