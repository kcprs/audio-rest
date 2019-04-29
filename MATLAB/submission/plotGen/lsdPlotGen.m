% NOTE: Before running this script, call setup() to add required folders
% to MATLAB path and set global variable values.

%% Set up variable values
global fsGlobal
fs = fsGlobal;

sigLen = fs;

source = "cello";
% source = "noise";
% source = "sines";

switch source
    case "cello"
        fs = 44100;
        gapStart = 50000;
        gapLen = 20480;

        sig = audioread("Cello.arco.mf.sulC.A2.wav");
        sigRest = audioread("Cello.arco.mf.sulC.A2.rest.wav");
    case "noise"
        gapLen = 5000;
        gapStart = (sigLen - gapLen) / 2;

        sig = randn([sigLen, 1]);
        sigRest = sig;
        sigRest(gapStart:gapStart + gapLen - 1) = randn([gapLen, 1]);
    case "sines"
        gapLen = sigLen;
        gapStart = 1;

        sig = getCosSig(sigLen, 440);
        sigRest = getCosSig(sigLen, 880);
end

fig1 = figure(1);
[t, f, psdSig] = spgm(sig);

switch source
    case "cello"
        ylim([20, 10000] / 1000);
        title("Spectrogram of the original signal");
    case "noise"
        title("Spectrogram of pure gaussian white noise");
    case "sines"
        title("Spectrogram of sinusoid @ 440 Hz");
end

fig2 = figure(2);
[~, ~, psdRest] = spgm(sigRest);

switch source
    case "cello"
        ylim([20, 10000] / 1000);
        title("Spectrogram of the restored signal");
    case "noise"
        title("Spectrogram of restoration, gap from 450 to 550 ms");
    case "sines"
        title("Spectrogram of sinusoid @ 880 Hz");
end

figDiff = figure(3);
spgmDiff(t, f, psdSig, psdRest);

switch source
    case "cello"
        ylim([20, 10000] / 1000);
        title("Spectrogram difference: restoration - original");
    case "noise"
        title("Spectrogram difference: restoration - original");
    case "sines"
        title("Spectrogram difference");
end

figLSD = figure(4);
lsd = getLogSpecDist(psdRest, psdSig);

gapStartSec = gapStart / fs;
gapLenSec = gapLen / fs;

gapStartIdx = find(t >= gapStartSec, 1, 'first');
gapEndIdx = find(t <= gapStartSec + gapLenSec, 1, 'last');

gapLSD = mean(lsd(gapStartIdx:gapEndIdx));
plot(t, lsd);
title(['LSD between original and restored signal. Avg over gap: ', ...
        num2str(gapLSD, 3), ' dB']);

if strcmp(source, "cello")
    xlabel("Time (s)");
else
    xlabel("Time (ms)");
end

ylabel("LSD (dB)");
grid on;

% Save figures
switch source
    case "cello"
        sigDesc = 'cello';
    case "noise"
        sigDesc = 'noise';
    case "sines"
        sigDesc = 'sines';
end

filename = ['spgmSig_', sigDesc];
figPos = get(fig1, 'Position');
figPos(4) = 0.7 * figPos(4);
set(fig1, 'Position', figPos);
savefig(fig1, ['figures\\qualityAssessment\\', filename, '.fig']);
saveas(fig1, ['figures\\qualityAssessment\\', filename, '.png']);
saveas(fig1, ['figures\\qualityAssessment\\', filename, '.eps'], 'epsc');
close(fig1);

filename = ['spgmRest_', sigDesc];
figPos = get(fig2, 'Position');
figPos(4) = 0.7 * figPos(4);
set(fig2, 'Position', figPos);
savefig(fig2, ['figures\\qualityAssessment\\', filename, '.fig']);
saveas(fig2, ['figures\\qualityAssessment\\', filename, '.png']);
saveas(fig2, ['figures\\qualityAssessment\\', filename, '.eps'], 'epsc');
close(fig2);

filename = ['spgm_diff_', sigDesc];
figPos = get(figDiff, 'Position');
figPos(4) = 0.7 * figPos(4);
set(figDiff, 'Position', figPos);
savefig(figDiff, ['figures\\qualityAssessment\\', filename, '.fig']);
saveas(figDiff, ['figures\\qualityAssessment\\', filename, '.png']);
saveas(figDiff, ['figures\\qualityAssessment\\', filename, '.eps'], 'epsc');
close(figDiff);

filename = ['LSD_', sigDesc];
figPos = get(figLSD, 'Position');
figPos(4) = 0.7 * figPos(4);
set(figLSD, 'Position', figPos);
savefig(figLSD, ['figures\\qualityAssessment\\', filename, '.fig']);
saveas(figLSD, ['figures\\qualityAssessment\\', filename, '.png']);
saveas(figLSD, ['figures\\qualityAssessment\\', filename, '.eps'], 'epsc');
close(figLSD);
