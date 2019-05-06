% ARINTERP Interpolate sinusoidal tracks using AR Modelling

%% Set variable values
global fsGlobal
fs = fsGlobal;
frmLen = 1024;
gapLen = 10 * frmLen;
sigLen = 0.5 * fs;
hopLen = 256;
numTrk = 60;
minTrkLen = 8;
resOrdAR = 100;
almostNegInf = -100;
smthRes = false;

% source = "saw";
% source = "sin";
% source = "audio/Flute.nonvib.ff.A4.wav";
source = "audio/Flute.vib.ff.A4.wav";
% source = "audio/Trumpet.novib.mf.A4.wav";
% source = "audio/Trumpet.vib.mf.A4.wav";

%% Prepare source signal
if contains(source, "audio/")
    sig = audioread(source);
    sigLen = length(sig);
elseif strcmp(source, 'sin')
    f = 440; % + 2 * getSineSig(sigLen, 8);
    sig = getCosSig(sigLen, f, -6);
    % sig = sig + getCosSig(sigLen, 2 * f, -12, pi);
    % sig = sig + getCosSig(sigLen, 3 * f, -15, pi / 2);
    % sig = sig + getCosSig(sigLen, 4 * f, -18, 0.75 * pi);
    % sig = sig + getCosSig(sigLen, 5 * f, -21);
    % sig = sig + 0.1 * randn(size(sig)) ./ 6;
else
    f0 = 880; % A5 note
    f1 = 1046.5; % C6 note
    f = logspace(log10(f0), log10(f1), sigLen).';

    arOrd = 0;
    sig = getSawSig(sigLen, f, -12);
end

%% Damage the source signal
[sigDmg, gapStart, gapEnd] = makeGap(sig, gapLen);

%% Analyse pre- and post-gap sections
% Pre-gap section
sigPre = sigDmg(1:gapStart - 1);
sigPre = flipud(sigPre);
trksPre = trackSpecPeaks(sigPre, frmLen, hopLen, numTrk, minTrkLen);
sigPre = flipud(sigPre);

for trkIter = 1:numTrk
    trksPre(trkIter).reverse(length(sigPre))
end

[freqPre, magPre, phsPre, smplPre] = SinTrack.consolidateFMP(trksPre);
pitchPre = trksPre(1).pitchEst;

% Post-gap section
sigPost = sigDmg(gapEnd + 1:end);
trksPost = trackSpecPeaks(sigPost, frmLen, hopLen, numTrk, minTrkLen);
[freqPost, magPost, phsPost, smplPost] = SinTrack.consolidateFMP(trksPost);
smplPost = gapEnd + smplPost;
pitchPost = trksPost(1).pitchEst;

%% Match tracks across the gap
% Reorder based on harmonics
maxHarmPre = round(max(freqPre(end, :)) / trksPre(1).pitchEst(end));
maxHarmPost = round(max(freqPost(1, :)) / trksPost(1).pitchEst(1));

numHarm = max(maxHarmPre, maxHarmPost);

freqHarmPre = NaN(size(freqPre, 1), numHarm);
harmRatiosPre = NaN(1, numHarm);
magHarmPre = NaN(size(magPre, 1), numHarm);
phsHarmPre = NaN(size(phsPre, 1), numHarm);

freqHarmPost = NaN(size(freqPost, 1), numHarm);
harmRatiosPost = NaN(1, numHarm);
magHarmPost = NaN(size(magPost, 1), numHarm);
phsHarmPost = NaN(size(phsPost, 1), numHarm);

for trkIter = 1:numTrk
    [harmNumPre, harmRatioPre] = trksPre(trkIter).getHarmNum(-1);
    [harmNumPost, harmRatioPost] = trksPost(trkIter).getHarmNum(1);

    if harmNumPre >= 1
        freqHarmPre(:, harmNumPre) = freqPre(:, trkIter);
        harmRatiosPre(harmNumPre) = harmRatioPre;
        magHarmPre(:, harmNumPre) = magPre(:, trkIter);
        phsHarmPre(:, harmNumPre) = phsPre(:, trkIter);
    end

    if harmNumPost >= 1
        freqHarmPost(:, harmNumPost) = freqPost(:, trkIter);
        harmRatiosPost(harmNumPost) = harmRatioPost;
        magHarmPost(:, harmNumPost) = magPost(:, trkIter);
        phsHarmPost(:, harmNumPost) = phsPost(:, trkIter);
    end

end

freqPre = freqHarmPre;
magPre = magHarmPre;
phsPre = phsHarmPre;

freqPost = freqHarmPost;
magPost = magHarmPost;
phsPost = phsHarmPost;

% Add matching information for harmonics only present at one side of the gap
for harmIter = 1:numHarm

    if isnan(freqPre(end, harmIter))
        freqPre(end, harmIter) = freqPost(1, harmIter);
        magPre(end, harmIter) = almostNegInf;
    end

    if isnan(freqPost(1, harmIter))
        freqPost(1, harmIter) = freqPre(end, harmIter);
        magPost(1, harmIter) = almostNegInf;
    end

end

%% Interpolate
numGapFrm = floor((gapLen + frmLen) / hopLen) - 1;
dataRange = 4;
polyOrd = 3;

pitchData = [pitchPre(end - dataRange + 1:end); pitchPost(1:dataRange)];
dataInd = [1:dataRange, dataRange + numGapFrm + (1:dataRange)].';
queryInd = dataRange + (1:numGapFrm).';
pitchPoly = polyfit(dataInd, pitchData, polyOrd);
pitchGap = polyval(pitchPoly, queryInd);

%% Interpolate harmonic structure
fade = linspace(0, 1, numGapFrm).';
harmRatios = harmRatiosPre + fade .* (harmRatiosPost - harmRatiosPre);

freqGap = NaN(numGapFrm, numHarm);
magGap = NaN(numGapFrm, numHarm);

for harmIter = 1:numHarm
    freqGap(:, harmIter) = pitchGap .* harmRatios(:, harmIter);

    magData = [magPre(end - dataRange + 1:end, harmIter); ...
                magPost(1:dataRange, harmIter)];

    magPoly = polyfit(dataInd, magData, polyOrd);
    magGap(:, harmIter) = polyval(magPoly, queryInd);
end

pitchGap = [pitchPre(end); pitchGap; pitchPost(1)];
freqGap = [freqPre(end, :); freqGap; freqPost(1, :)];
magGap = [magPre(end, :); magGap; magPost(1, :)];

smplGap = smplPre(end):hopLen:smplPost(1);

%% Synthesise sinusoidal gap signal
sinGap = resynth(freqGap, magGap, phsPre(end, :), hopLen, phsPost(1, :));

%% Restore residual
% Find number of active tracks in pre and post sections
preActive = 0;
postActive = 0;

for iter = 1:numHarm

    if ~isnan(freqPre(end, iter))
        preActive = preActive + 1;
    end

    if ~isnan(freqPost(1, iter))
        postActive = postActive + 1;
    end

end

% Compute residual of last frame of pre- section
resPre = getResidual(sigPre(end - frmLen + 1:end), -Inf, preActive, smthRes);

% Compute residual of first frame of post- section
resPost = getResidual(sigPost(2:frmLen + 1), -Inf, postActive, smthRes);

% Morph between pre- and post- residuals over the gap
resGap = wfbar(resPre, resPost, gapLen, resOrdAR);

% Concatenate with half frame of known signal from either side
% This is to match the size of sinSig
resGap = [resPre(frmLen / 2:end); resGap; resPost(1:frmLen / 2)];

%% Add reconstructed sinusoidal and residual
sigGap = sinGap + resGap;

%% Insert reconstructed signal into the gap
% Prepare cross-fades
xfPre = linspace(1, 0, frmLen / 2).';
xfPost = linspace(0, 1, frmLen / 2).';

% Apply cross-fades
sigPreXF = sigPre;
sigPreXF(end - frmLen / 2 + 1:end) = ...
    sigPreXF(end - frmLen / 2 + 1:end) .* xfPre;
sigPostXF = sigPost;
sigPostXF(1:frmLen / 2) = sigPostXF(1:frmLen / 2) .* xfPost;
sigGapXF = sigGap;
sigGapXF(1:frmLen / 2) = sigGapXF(1:frmLen / 2) .* (1 - xfPre);
sigGapXF(end - frmLen / 2 + 1:end) = ...
    sigGapXF(end - frmLen / 2 + 1:end) .* (1 - xfPost);

% Put everything together
sigRest = zeros(size(sig));
sigRest(1:gapStart - 1) = sigPreXF;
sigRest(smplGap(1):smplGap(end)) = sigRest(smplGap(1):smplGap(end)) + sigGapXF;
sigRest(gapEnd + 1:end) = sigRest(gapEnd + 1:end) + sigPostXF;

%% Plotting
% Determine signal range to be plotted
plotStart = gapStart - round(0.8 * gapLen);
plotEnd = gapEnd + round(0.8 * gapLen);

% Freq range
freqLim = [0, 8000] / 1000;

% Mag range
magMin = -100;

% Convert from samples to s or ms
if sigLen > fs
    t = (1:length(sig)) / fs;
    timeUnit = 's';
else
    t = 1000 * (1:length(sig)) / fs;
    timeUnit = 'ms';
end

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

% Plot signal with gap
fig2 = figure(2);
sigNaN = sig;
sigNaN(gapStart:gapEnd) = NaN;
plot(t, sigNaN);
hold on;
env = ones(length(sig), 1);
fadeOut = linspace(1, 0, gapStart - smplGap(1));
fadeIn = linspace(0, 1, smplGap(end) - gapEnd);
env(smplGap(1):gapStart - 1) = fadeOut;
env(gapStart:gapEnd) = NaN;
env(gapEnd:smplGap(end) - 1) = fadeIn;
pEnv = plot(t, env, '--', 'Color', 'Black', 'DisplayName', 'Crossfade envelope');
hold off;
title('Damaged signal');
ylabel("Amplitude");
xlabel(['Time (', timeUnit, ')']);
xlim([t(plotStart), t(plotEnd)]);
legend(pEnv, 'Location', 'southeast');
grid on;

% Plot reconstructed signal within gap
fig3 = figure(3);
plot(t(smplGap(1):smplGap(end)), sigGap, 'Color', [221, 49, 26] / 256);
hold on;
env(isnan(env)) = 0;
env = 1 - env;
env(env == 0) = NaN;
pEnv = plot(t, env, '--', 'Color', 'Black', 'DisplayName', 'Crossfade envelope');
hold off;
title('Restoration of the missing signal');
ylabel("Amplitude");
xlabel(['Time (', timeUnit, ')']);
xlim([t(plotStart), t(plotEnd)]);
legend(pEnv, 'Location', 'southeast');
grid on;

% Plot the restored signal
fig4 = figure(4);
sigRestNaN = sigRest;
sigRestNaN(smplGap(1) + 1:smplGap(end) - 1) = NaN;
plot(t, sigRestNaN);
hold on;
plot(t(smplGap(1):smplGap(end)), sigRest(smplGap(1):smplGap(end)), ...
    'Color', [221, 49, 26] / 256);
hold off;
title("Fully restored signal");
ylabel("Amplitude");
xlabel(['Time (', timeUnit, ')']);
xlim([t(plotStart), t(plotEnd)]);
ylim(ylimWoRect);
grid on;

% Plot sinusoidal tracks - frequency
fig5 = figure(5);
plot(t(smplPre), freqPre / 1000);
hold on;
set(gca, 'ColorOrderIndex', 1);
plot(t(smplPost), freqPost / 1000);
set(gca, 'ColorOrderIndex', 1);
plot(t(smplGap), freqGap / 1000, ':');
hold off;
title('Sinusoidal tracks - frequency');
ylabel('Frequency (kHz)');
xlabel(['Time (', timeUnit, ')']);
ylim(freqLim)
xlim([t(plotStart), t(plotEnd)]);
grid on;

% Plot sinusoidal tracks - magnitude
fig6 = figure(6);
plot(t(smplPre), magPre);
hold on;
set(gca, 'ColorOrderIndex', 1);
plot(t(smplPost), magPost);
set(gca, 'ColorOrderIndex', 1);
plot(t(smplGap), magGap, ':');
hold off;
title('Sinusoidal tracks - magnitude');
ylabel('Magnitude (dBFS)');
xlabel(['Time (', timeUnit, ')']);
xlim([t(plotStart), t(plotEnd)]);
magLim = ylim;
magLim(1) = magMin;
ylim(magLim);
grid on;

% Plot original spectrogram
fig7 = figure(7);
[tSpgm, fSpgm, psdSig] = spgm(sig);
ylim(freqLim)
xlim([t(plotStart), t(plotEnd)]);
title("Original - spectrogram");

% Plot restoration spectrogram
fig8 = figure(8);
[~, ~, psdRest] = spgm(sigRest);
ylim(freqLim)
xlim([t(plotStart), t(plotEnd)]);
title("Restoration - spectrogram");

% % Plot spectrogram difference
% fig9 = figure(9);
% spgmDiff(tSpgm, fSpgm, psdRest, psdSig);
% ylim(freqLim)
% xlim([t(plotStart), t(plotEnd)]);
% title("Spectrogram difference: restoration - original");

% % Plot lsd
% fig10 = figure(10);
% lsd = getLogSpecDist(psdRest, psdSig);
% plot(tSpgm, lsd);
% hold on;
% lsdStartTime = t(gapStart);
% lsdEndTime = t(gapEnd);

% if sigLen <= fs
%     lsdStartTime = lsdStartTime / 1000;
%     lsdEndTime = lsdEndTime / 1000;
% end

% lsdStartIdx = find(tSpgm >= lsdStartTime, 1, 'first');
% lsdEndIdx = find(tSpgm <= lsdEndTime, 1, 'last');
% rectangle('Position', [tSpgm(lsdStartIdx), 0, ...
%                         tSpgm(lsdEndIdx) - tSpgm(lsdStartIdx), ...
%                         max(lsd) + 1]);
% hold off;
% gapLSD = mean(lsd(lsdStartIdx:lsdEndIdx));
% title(['LSD between original and restored signal. Avg over gap: ', ...
%         num2str(gapLSD, 3), ' dB']);
% xlabel(['Time (', timeUnit, ')']);
% ylabel("LSD (dB)");

% if sigLen > fs
%     xlim([t(plotStart), t(plotEnd)]);
% else
%     xlim([t(plotStart), t(plotEnd)] / 1000);
% end

% grid on;

% % Plot AR frequency response
% fig11 = figure(11);
% global arFwdFreqResp;
% global arFreqVec;

% arFwdFreqResp = 20 * log10(abs(arFwdFreqResp));
% arFwdFreqResp = arFwdFreqResp - max(arFwdFreqResp);
% plot(arFreqVec / 1000, arFwdFreqResp, 'DisplayName', "AR magnitude response");
% hold on;
% magSpec = 20 * log10(abs(fft(resPre, 2 * length(arFreqVec))));
% magSpec = magSpec(1:length(arFreqVec));
% magSpec = magSpec - max(magSpec);
% plot(arFreqVec / 1000, magSpec, 'DisplayName', "Spectrum of the modelled signal");
% hold off;
% title("AR Filter - Frequency Response");
% xlabel("Frequency (kHz)");
% ylabel("Magnitude (dB)");
% xlim([0, 20000] / 1000);
% grid on;
% legend;

% Plot pitch
fig12 = figure(12);
plot(t(smplPre), pitchPre);
hold on;
set(gca, 'ColorOrderIndex', 1);
plot(t(smplPost), pitchPost);
set(gca, 'ColorOrderIndex', 1);
plot(t(smplGap), pitchGap, ':');
hold off;
title('Pitch trajectory');
ylabel('Pitch in Hz');
xlabel(['Time (', timeUnit, ')']);
grid on;

% Save figures
switch source
    case "audio/Flute.nonvib.ff.A4.wav"
        sigDesc = ['flute_gapLen_', num2str(gapLen)];
    case "audio/Flute.vib.ff.A4.wav"
        sigDesc = ['fluteVib_gapLen_', num2str(gapLen)];
    case "audio/Trumpet.novib.mf.A4.wav"
        sigDesc = ['trumpet_gapLen_', num2str(gapLen)];
    case "audio/Trumpet.vib.mf.A4.wav"
        sigDesc = ['trumpetVib_gapLen_', num2str(gapLen)];
    case "saw"
        sigDesc = ['saw_', num2str(f0), '-', num2str(f1), ...
                    '_gapLen_', num2str(gapLen)];
end

% filename = [sigDesc, '_orig'];
% audiowrite(['submission\\audioExamples\\pitch_', filename, '.wav'], sig, fs);

% filename = [sigDesc, '_dmg'];
% audiowrite(['submission\\audioExamples\\pitch_', filename, '.wav'], sigDmg, fs);

% filename = [sigDesc, '_rest'];
% audiowrite(['submission\\audioExamples\\pitch_', filename, '.wav'], sigRest, fs);

% filename = [sigDesc, '_t_orig'];
% resizeFigure(fig1, 1, 0.7);
% saveas(fig1, ['figures\\spectralModelling\\pitchInformed\\', filename, '.eps'], 'epsc');
% saveas(fig1, ['figures\\spectralModelling\\pitchInformed\\', filename, '.png']);
% close(fig1);

% filename = [sigDesc, '_t_gap'];
% resizeFigure(fig2, 1, 0.7);
% saveas(fig2, ['figures\\spectralModelling\\pitchInformed\\', filename, '.eps'], 'epsc');
% saveas(fig2, ['figures\\spectralModelling\\pitchInformed\\', filename, '.png']);
% close(fig2);

% filename = [sigDesc, '_t_sigGap'];
% resizeFigure(fig3, 1, 0.7);
% saveas(fig3, ['figures\\spectralModelling\\pitchInformed\\', filename, '.eps'], 'epsc');
% saveas(fig3, ['figures\\spectralModelling\\pitchInformed\\', filename, '.png']);
% close(fig3);

% filename = [sigDesc, '_t_rest'];
% resizeFigure(fig4, 1, 0.7);
% saveas(fig4, ['figures\\spectralModelling\\pitchInformed\\', filename, '.eps'], 'epsc');
% saveas(fig4, ['figures\\spectralModelling\\pitchInformed\\', filename, '.png']);
% close(fig4);

% filename = [sigDesc, '_trk_freq'];
% resizeFigure(fig5, 1, 0.7);
% saveas(fig5, ['figures\\spectralModelling\\pitchInformed\\', filename, '.eps'], 'epsc');
% saveas(fig5, ['figures\\spectralModelling\\pitchInformed\\', filename, '.png']);
% close(fig5);

% filename = [sigDesc, '_trk_mag'];
% resizeFigure(fig6, 1, 0.7);
% saveas(fig6, ['figures\\spectralModelling\\pitchInformed\\', filename, '.eps'], 'epsc');
% saveas(fig6, ['figures\\spectralModelling\\pitchInformed\\', filename, '.png']);
% close(fig6);

% filename = [sigDesc, '_spgm_orig'];
% resizeFigure(fig7, 1, 0.7);
% saveas(fig7, ['figures\\spectralModelling\\pitchInformed\\', filename, '.eps'], 'epsc');
% saveas(fig7, ['figures\\spectralModelling\\pitchInformed\\', filename, '.png']);
% close(fig7);

% filename = [sigDesc, '_spgm_rest'];
% resizeFigure(fig8, 1, 0.7);
% saveas(fig8, ['figures\\spectralModelling\\pitchInformed\\', filename, '.eps'], 'epsc');
% saveas(fig8, ['figures\\spectralModelling\\pitchInformed\\', filename, '.png']);
% close(fig8);

% filename = [sigDesc, '_spgm_diff'];
% resizeFigure(fig9, 1, 0.7);
% saveas(fig9, ['figures\\spectralModelling\\pitchInformed\\', filename, '.eps'], 'epsc');
% saveas(fig9, ['figures\\spectralModelling\\pitchInformed\\', filename, '.png']);
% close(fig9);

% filename = [sigDesc, '_lsd'];
% resizeFigure(fig10, 1, 0.7);
% saveas(fig10, ['figures\\spectralModelling\\pitchInformed\\', filename, '.eps'], 'epsc');
% saveas(fig10, ['figures\\spectralModelling\\pitchInformed\\', filename, '.png']);
% close(fig10);

% filename = [sigDesc, '_resFrqResp'];
% resizeFigure(fig11, 1, 0.7);
% saveas(fig11, ['figures\\spectralModelling\\pitchInformed\\', filename, '.eps'], 'epsc');
% saveas(fig11, ['figures\\spectralModelling\\pitchInformed\\', filename, '.png']);
% close(fig11);

% filename = [sigDesc, '_pitch'];
% resizeFigure(fig12, 1, 0.7);
% saveas(fig12, ['figures\\spectralModelling\\pitchInformed\\', filename, '.eps'], 'epsc');
% saveas(fig12, ['figures\\spectralModelling\\pitchInformed\\', filename, '.png']);
% close(fig12);

function resizeFigure(figHandle, xFact, yFact)
    figPos = get(figHandle, 'Position');
    figPos(3) = xFact * figPos(3);
    figPos(4) = yFact * figPos(4);
    set(figHandle, 'Position', figPos);
end
