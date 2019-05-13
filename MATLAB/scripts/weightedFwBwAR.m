% WEIGHTEDFWBWAR Fix a gap in a signal using a weighted forward-backward
% predictor

%% Set up variable values
global fsGlobal
fs = fsGlobal;

% Uncomment below to set audio source and corresponding variables
% source = "sine";
source = "saw";
% source = "flute";
% source = "flute.vib";
% source = "trumpet";
% source = "trumpet.vib";

fitLen = 2048; % Length of fitting section in samples
gapLen = 4096; % Length of gap in samples

% Set source-specific variable values
switch source
    case "sine"
        sigLen = fs; % Total length of damaged signal in samples
        f0 = 100;
        arOrd = 2;
        sig = getSinSig(sigLen, f0);
    case "saw"
        sigLen = fs; % Total length of damaged signal in samples
        f0 = 880; % A5 note
        f1 = 1046.5; % C6 note
        f = logspace(log10(f0), log10(f1), sigLen).';

        arOrd = 0;
        sig = getSawSig(sigLen, f, -12);
        sig = sig + 0.002 * randn([sigLen, 1]);
    case "flute"
        arOrd = 0;
        sig = audioread("Flute.nonvib.A4.wav");
    case "flute.vib"
        arOrd = 0;
        sig = audioread("Flute.vib.A4.wav");
    case "trumpet"
        arOrd = 0;
        sig = audioread("Trumpet.nonvib.A4.wav");
    case "trumpet.vib"
        arOrd = 0;
        sig = audioread("Trumpet.vib.A4.wav");
end

sigLen = length(sig);

%% Damage the signal
[sigDmg, gapStart, gapEnd] = makeGap(sig, gapLen);

%% Restoration
% Pick out pre- and post- gap section for model fitting
pre = sig(gapStart - fitLen:gapStart - 1);
post = sig(gapEnd + 1:gapEnd + fitLen);

% Predict signal in gap
[sigGap, ordFw, ordBw] = wfbar(pre, post, gapLen, arOrd);

% Replace gap with predicted signal
sigRest = sigDmg;
sigRest(gapStart:gapEnd) = sigGap;

%% Plotting
% Determine signal range to be plotted
plotStart = gapStart - fitLen - round(0.5 * (gapLen + fitLen));
plotEnd = gapEnd + fitLen + round(0.5 * (gapLen + fitLen));

% Freq range
freqLim = [0, 20000] / 1000;

% Convert from samples to s or ms
if sigLen > fs
    t = (1:length(sig)) / fs;
    timeUnit = 's';
else
    t = 1000 * (1:length(sig)) / fs;
    timeUnit = 'ms';
end

% Pad prediction so that the plot is continuous
sigGap = [sigRest(gapStart - 1); sigGap; sigRest(gapEnd + 1)];

% Plot the original signal
fig1 = figure(1);
plot(t, sig);
hold on;
ylimWoRect = ylim;
rectHeight = 1.1 * max(abs(sigGap));
rectangle('Position', [t(gapStart), -rectHeight, t(gapLen), 2 * rectHeight]);
hold off;
title(['Original signal and gap boundaries (gap len: ', num2str(gapLen), ...
        ' samples)']);
ylabel("Amplitude");
xlabel(['Time (', timeUnit, ')']);
xlim([t(plotStart), t(plotEnd)]);
ylim(ylimWoRect);
grid on;

% Plot the restored signal
fig2 = figure(2);
sigNaN = sigRest;
sigNaN(gapStart - fitLen:gapEnd + fitLen) = NaN;
plot(t, sigNaN);
hold on;
% Plot restoration in gap
plot(t(gapStart - 1:gapEnd + 1), sigGap, 'Color', [221, 49, 26] / 256);
% Mark fitting areas
plot(t(gapStart - fitLen:gapStart - 1), ...
    sig(gapStart - fitLen:gapStart - 1), ...
    'Color', [31, 140, 12] / 256);
plot(t(gapEnd + 1:gapEnd + fitLen), sig(gapEnd + 1:gapEnd + fitLen), ...
    'Color', [31, 140, 12] / 256);
hold off;

if arOrd == 0
    ordDesc = ['ordFw = ', num2str(ordFw), ', ordBw = ', num2str(ordBw)];
else
    ordDesc = ['ord = ', num2str(arOrd)];
end

title(['Fully restored signal (', ordDesc, ', fitLen = ', ...
        num2str(fitLen), ')']);
ylabel("Amplitude");
xlabel(['Time (', timeUnit, ')']);
xlim([t(plotStart), t(plotEnd)]);
ylim(ylimWoRect);
grid on;

% Plot original spectrogram
fig3 = figure(3);
[tSpgm, fSpgm, psdSig] = spgm(sig);
ylim(freqLim)
xlim([t(plotStart), t(plotEnd)]);
title("Original - spectrogram");

% Plot restoration spectrogram
fig4 = figure(4);
[~, ~, psdRest] = spgm(sigRest);
ylim(freqLim)
xlim([t(plotStart), t(plotEnd)]);
title("Restoration - spectrogram");

% Plot spectrogram difference
fig5 = figure(5);
spgmDiff(tSpgm, fSpgm, psdRest, psdSig);
ylim(freqLim)
xlim([t(plotStart), t(plotEnd)]);
title("Spectrogram difference: restoration - original");

% Plot lsd
fig6 = figure(6);
lsd = getLogSpecDist(psdRest, psdSig);
plot(tSpgm, lsd);
hold on;
lsdStartTime = t(gapStart);
lsdEndTime = t(gapEnd);

if sigLen <= fs
    lsdStartTime = lsdStartTime / 1000;
    lsdEndTime = lsdEndTime / 1000;
end

lsdStartIdx = find(tSpgm >= lsdStartTime, 1, 'first');
lsdEndIdx = find(tSpgm <= lsdEndTime, 1, 'last');
rectangle('Position', [tSpgm(lsdStartIdx), 0, ...
                        tSpgm(lsdEndIdx) - tSpgm(lsdStartIdx), ...
                        max(lsd) + 1]);
hold off;
gapLSD = mean(lsd(lsdStartIdx:lsdEndIdx));
title(['LSD between original and restored signal. Avg over gap: ', ...
        num2str(gapLSD, 3), ' dB']);
xlabel(['Time (', timeUnit, ')']);
ylabel("LSD (dB)");

if sigLen > fs
    xlim([t(plotStart), t(plotEnd)]);
else
    xlim([t(plotStart), t(plotEnd)] / 1000);
end

grid on;

% Plot AR frequency response
fig7 = figure(7);
global arFwdFreqResp;
global arFreqVec;

arFwdFreqResp = 20 * log10(abs(arFwdFreqResp));
arFwdFreqResp = arFwdFreqResp - max(arFwdFreqResp);
plot(arFreqVec / 1000, arFwdFreqResp, 'DisplayName', "AR magnitude response");
hold on;
magSpec = 20 * log10(abs(fft(pre, 2 * length(arFreqVec))));
magSpec = magSpec(1:length(arFreqVec));
magSpec = magSpec - max(magSpec);
plot(arFreqVec / 1000, magSpec, 'DisplayName', "Spectrum of the modelled signal");
hold off;
title("AR Filter - Frequency Response");
xlabel("Frequency (kHz)");
ylabel("Magnitude (dB)");
xlim([0, 20000] / 1000);
grid on;
legend;

% Plot Z-domain
fig8 = figure(8);
global arFwdCoeffs;
zplane(1, arFwdCoeffs);
title("AR Filter - Pole-Zero Plot");

% Save figures and audio
switch source
    case "sine"
        sigDesc = ['wfbAR_sine_', num2str(f0), '_arOrd_', ...
                    num2str(arOrd), '_gapLen_', num2str(gapLen), ...
                    '_fitLen_', num2str(fitLen)];
    case "saw"
        sigDesc = ['wfbAR_saw_', num2str(f0), '-', num2str(f1), ...
                    '_arOrd_', num2str(arOrd), ...
                    '_gapLen_', num2str(gapLen), ...
                    '_fitLen_', num2str(fitLen)];
    case "flute"
        sigDesc = ['wfbAR_flute_arOrd_', num2str(arOrd), ...
                    '_gapLen_', num2str(gapLen), ...
                    '_fitLen_', num2str(fitLen)];
    case "flute.vib"
        sigDesc = ['wfbAR_fluteVib_arOrd_', num2str(arOrd), ...
                    '_gapLen_', num2str(gapLen), ...
                    '_fitLen_', num2str(fitLen)];
    case "trumpet"
        sigDesc = ['wfbAR_trumpet_arOrd_', num2str(arOrd), ...
                    '_gapLen_', num2str(gapLen), ...
                    '_fitLen_', num2str(fitLen)];
    case "trumpet.vib"
        sigDesc = ['wfbAR_trumpetVib_arOrd_', num2str(arOrd), ...
                    '_gapLen_', num2str(gapLen), ...
                    '_fitLen_', num2str(fitLen)];
end

% filename = [sigDesc, '_orig'];
% audiowrite(['audioExamples\\', filename, '.wav'], sig, fs);

% filename = [sigDesc, '_dmg'];
% audiowrite(['audioExamples\\', filename, '.wav'], sigDmg, fs);

% filename = [sigDesc, '_rest'];
% audiowrite(['audioExamples\\', filename, '.wav'], sigRest, fs);

% filename = [sigDesc, '_t_orig'];
% resizeFigure(fig1, 1, 0.7);
% saveas(fig1, ['figures\\arModelling\\wfbar\\', filename, '.eps'], 'epsc');
% saveas(fig1, ['figures\\arModelling\\wfbar\\', filename, '.png']);
% close(fig1);

% filename = [sigDesc, '_t_sigGap'];
% resizeFigure(fig2, 1, 0.7);
% saveas(fig2, ['figures\\arModelling\\wfbar\\', filename, '.eps'], 'epsc');
% saveas(fig2, ['figures\\arModelling\\wfbar\\', filename, '.png']);
% close(fig2);

% filename = [sigDesc, '_spgm_orig'];
% resizeFigure(fig3, 1, 0.7);
% saveas(fig3, ['figures\\arModelling\\wfbar\\', filename, '.eps'], 'epsc');
% saveas(fig3, ['figures\\arModelling\\wfbar\\', filename, '.png']);
% close(fig3);

% filename = [sigDesc, '_spgm_rest'];
% resizeFigure(fig4, 1, 0.7);
% saveas(fig4, ['figures\\arModelling\\wfbar\\', filename, '.eps'], 'epsc');
% saveas(fig4, ['figures\\arModelling\\wfbar\\', filename, '.png']);
% close(fig4);

% filename = [sigDesc, '_spgm_diff'];
% resizeFigure(fig5, 1, 0.7);
% saveas(fig5, ['figures\\arModelling\\wfbar\\', filename, '.eps'], 'epsc');
% saveas(fig5, ['figures\\arModelling\\wfbar\\', filename, '.png']);
% close(fig5);

% filename = [sigDesc, '_lsd'];
% resizeFigure(fig6, 1, 0.7);
% saveas(fig6, ['figures\\arModelling\\wfbar\\', filename, '.eps'], 'epsc');
% saveas(fig6, ['figures\\arModelling\\wfbar\\', filename, '.png']);
% close(fig6);

% filename = [sigDesc, '_freqResp'];
% resizeFigure(fig7, 1, 0.7);
% saveas(fig7, ['figures\\arModelling\\wfbar\\', filename, '.eps'], 'epsc');
% saveas(fig7, ['figures\\arModelling\\wfbar\\', filename, '.png']);
% close(fig7);

% filename = [sigDesc, '_zPlane'];
% resizeFigure(fig8, 1, 0.7);
% saveas(fig8, ['figures\\arModelling\\wfbar\\', filename, '.eps'], 'epsc');
% saveas(fig8, ['figures\\arModelling\\wfbar\\', filename, '.png']);
% close(fig8);

function resizeFigure(figHandle, xFact, yFact)
    figPos = get(figHandle, 'Position');
    figPos(3) = xFact * figPos(3);
    figPos(4) = yFact * figPos(4);
    set(figHandle, 'Position', figPos);
end
