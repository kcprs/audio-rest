% NOTE: Before running this script, call setup() to add required folders
% to MATLAB path and set global variable values.

%% Set up variable values
global fsGlobal
fs = fsGlobal;

sigLen = fs;

% source = "sines";
source = "phaseDemo";

switch source
    case "sines"
        sig1 = getCosSig(sigLen, 10000 + 1000 * getSinSig(sigLen, 4));
        sig2 = getCosSig(sigLen, linspace(200, 20000, sigLen));
    case "phaseDemo"
        gapLen = 10000;
        gapStart = (sigLen - gapLen) / 2;
        gapEnd = gapStart + gapLen - 1;
        f = 10000;

        sig1 = getCosSig(sigLen, f);
        sig2 = sig1;
        sig2(gapStart:gapEnd) = getCosSig(gapLen, f);
end

fig1 = figure(1);
[t, f, psd1] = spgm(sig1);

switch source
    case "sines"
        title("Spectrogram of signal x_1 - a time-varying sinusoid");
    case "phaseDemo"
        title("Spectrogram of the original signal");
end

fig2 = figure(2);
[~, ~, psd2] = spgm(sig2);

switch source
    case "sines"
        title("Spectrogram of signal x_2 - another time-varying sinusoid");
    case "phaseDemo"
        title("Spectrogram of the reconstruction with incorrect phase");
end

figDiff = figure(3);
spgmDiff(t, f, psd1, psd2);

switch source
    case "sines"
        title("Spectrogram difference: PSD(x_1) - PSD(x_2)");
    case "phaseDemo"
        title("Spectrogram difference: restoration - original");
end

switch source
    case "phaseDemo"
        sigLenNew = 2000;
        gapLen = round(sigLenNew * gapLen / sigLen);
        sigLen = sigLenNew;
        gapStart = (sigLen - gapLen) / 2;
        gapEnd = gapStart + gapLen - 1;
        smplShift = 50;

        sig = getCosSig(sigLen, 200);
        gapSig = [sig(gapStart - 1); ...
                sig(gapStart + smplShift:gapEnd + smplShift); ...
                sig(gapEnd + 1)];

        figTm = figure(4);
        % Plot original signal with gap in the middle
        sigNaN = sig;
        sigNaN(gapStart:gapEnd) = NaN;
        plot(sigNaN);
        hold on;

        % Plot the original signal within the gap
        plot(gapStart - 1:gapEnd + 1, sig(gapStart - 1:gapEnd + 1), ...
            '--', 'Color', [170, 170, 170] / 256);

        % Plot the restored signal
        plot(gapStart - 1:gapEnd + 1, gapSig, 'Color', [219, 61, 21] / 256);
        hold off;

        title("Reconstruction in time domain (time & frequency not to scale)");
        ylabel("Amplitude");
        ylim([-1.2, 1.2])
        xticks([]);
        grid on;
end

% Save figures
switch source
    case "sines"
        sigDesc = 'sinusoids';
    case "phaseDemo"
        sigDesc = 'phaseDemo';
end

filename = ['spgm1_', sigDesc];
figPos = get(fig1, 'Position');
figPos(4) = 0.7 * figPos(4);
set(fig1, 'Position', figPos);
savefig(fig1, ['figures\\qualityAssessment\\', filename, '.fig']);
saveas(fig1, ['figures\\qualityAssessment\\', filename, '.png']);
saveas(fig1, ['figures\\qualityAssessment\\', filename, '.eps'], 'epsc');
close(fig1);

filename = ['spgm2_', sigDesc];
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

switch source
    case "phaseDemo"
        filename = ['spgm_tm_', sigDesc];
        figPos = get(figTm, 'Position');
        figPos(4) = 0.7 * figPos(4);
        set(figTm, 'Position', figPos);
        savefig(figTm, ['figures\\qualityAssessment\\', filename, '.fig']);
        saveas(figTm, ['figures\\qualityAssessment\\', filename, '.png']);
        saveas(figTm, ['figures\\qualityAssessment\\', filename, '.eps'], 'epsc');
        close(figTm);
end
