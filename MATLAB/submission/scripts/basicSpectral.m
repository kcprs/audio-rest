% ARINTERP Interpolate sinusoidal tracks using AR Modelling

%% Set variable values
global fsGlobal
fs = fsGlobal;
frmLen = 2048;
gapLen = 4 * frmLen;
sigLen = 30 * frmLen;
hopLen = 256;
numTrk = 60;
minTrkLen = 20;
resOrdAR = 30;
almostNegInf = -100;

% source = "saw";
% source = "sin";
% source = "audio/Flute.nonvib.ff.A4.wav";
% source = "audio/Flute.vib.ff.A4.wav";
source = "audio/Trumpet.novib.mf.A4.wav";
% source = "audio/Trumpet.vib.mf.A4.wav";

%% Prepare source signal
if contains(source, "audio/")
    sig = audioread(source);
elseif strcmp(source, 'sin')
    f = 440; % + 2 * getSineSig(sigLen, 8);
    sig = getCosSig(sigLen, f, -6);
    % sig = sig + getCosSig(sigLen, 2 * f, -12, pi);
    % sig = sig + getCosSig(sigLen, 3 * f, -15, pi / 2);
    % sig = sig + getCosSig(sigLen, 4 * f, -18, 0.75 * pi);
    % sig = sig + getCosSig(sigLen, 5 * f, -21);
    % sig = sig + 0.1 * randn(size(sig)) ./ 6;
else
    f = 440; %logspace(log10(220), log10(440), sigLen).';
    m = -6; %linspace(-14, 0, sigLen).';

    sig = getSawSig(sigLen, f, m);
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

% Post-gap section
sigPost = sigDmg(gapEnd + 1:end);
trksPost = trackSpecPeaks(sigPost, frmLen, hopLen, numTrk, minTrkLen);
[freqPost, magPost, phsPost, smplPost] = SinTrack.consolidateFMP(trksPost);
smplPost = gapEnd + smplPost;

%% Match tracks across the gap
matches = NaN(numTrk, 2);

% Get closeness score
score = zeros(numTrk);

for trkIter = 1:numTrk
    score(trkIter, :) = trksPre(trkIter).getPkScore(freqPost(1, :), ...
        magPost(1, :));
end

% Assign trksPost to trksPre by finding lowest closeness scores
for trkIter = 1:numTrk
    % Find lowest closeness score and the corresponding track pair
    minScore = min(score, [], 'all');
    [trkPreInd, trkPostInd] = find(score == minScore, 1);

    if isempty(minScore) || isnan(minScore)
        break;
    end

    % Save peak values to the best fitting track
    matches(trkIter, :) = [trkPreInd, trkPostInd];

    % Clear column and row corresponding to the selected tracks
    score(trkPreInd, :) = NaN;
    score(:, trkPostInd) = NaN;
end

matches = matches(all(~isnan(matches), 2), :);

unmatchedPre = NaN(numTrk - sum(~isnan(matches(:, 1))), 2);
unmatchedPost = NaN(numTrk - sum(~isnan(matches(:, 2))), 2);
indexes = 1:numTrk;
unmatchedPre(:, 1) = indexes(~ismember(indexes, matches(:, 1)));
unmatchedPost(:, 2) = indexes(~ismember(indexes, matches(:, 2)));

matches = [matches; unmatchedPre; unmatchedPost];
numTrkGap = size(matches, 1);

% Reorder tracks based on matches
freqPreNew = NaN(size(freqPre, 1), numTrkGap);
magPreNew = NaN(size(magPre, 1), numTrkGap);
phsPreNew = NaN(size(phsPre, 1), numTrkGap);

freqPostNew = NaN(size(freqPost, 1), numTrkGap);
magPostNew = NaN(size(magPost, 1), numTrkGap);
phsPostNew = NaN(size(phsPost, 1), numTrkGap);

for trkIter = 1:numTrkGap
    trkPreInd = matches(trkIter, 1);
    trkPostInd = matches(trkIter, 2);

    if ~isnan(trkPreInd)
        freqPreNew(:, trkIter) = freqPre(:, trkPreInd);
        magPreNew(:, trkIter) = magPre(:, trkPreInd);
        phsPreNew(:, trkIter) = phsPre(:, trkPreInd);
    end

    if ~isnan(trkPostInd)
        freqPostNew(:, trkIter) = freqPost(:, trkPostInd);
        magPostNew(:, trkIter) = magPost(:, trkPostInd);
        phsPostNew(:, trkIter) = phsPost(:, trkPostInd);
    end

end

freqPre = freqPreNew;
magPre = magPreNew;
phsPre = phsPreNew;

freqPost = freqPostNew;
magPost = magPostNew;
phsPost = phsPostNew;

%% Interpolate sinusoidal tracks over the gap
numGapFrm = floor((gapLen + frmLen) / hopLen) - 1;
dataRange = 4;
polyOrd = 3;
freqGap = NaN(numGapFrm, numTrkGap);
magGap = NaN(numGapFrm, numTrkGap);

for trkIter = 1:numTrkGap
    freqDataPre = freqPre(end - dataRange + 1:end, trkIter);
    freqDataPost = freqPost(1:dataRange, trkIter);

    if all(isnan([freqDataPre; freqDataPost]))
        continue;
    end

    magDataPre = magPre(end - dataRange + 1:end, trkIter);
    magDataPost = magPost(1:dataRange, trkIter);

    % If no match, match with itself at zero amplitude
    if all(isnan(freqDataPre))
        freqGap(:, trkIter) = freqDataPost(1);
        fadeIn = linspace(10^(almostNegInf / 20), 0, numGapFrm).';
        magGap(:, trkIter) = magDataPost(1) + 20 * log10(fadeIn);
    elseif all(isnan(freqDataPost))
        freqGap(:, trkIter) = freqDataPre(end);
        fadeOut = linspace(0, 10^(almostNegInf / 20), numGapFrm).';
        magGap(:, trkIter) = magDataPre(end) + 20 * log10(fadeOut);
    else
        % If match exists, interpolate
        freqData = [freqDataPre; freqDataPost];
        magData = [magDataPre; magDataPost];

        dataInd = [1:dataRange, dataRange + numGapFrm + (1:dataRange)].';
        queryInd = dataRange + (1:numGapFrm);

        freqPoly = polyfit(dataInd, freqData, polyOrd);
        magPoly = polyfit(dataInd, magData, polyOrd);

        freqGap(:, trkIter) = polyval(freqPoly, queryInd);
        magGap(:, trkIter) = polyval(magPoly, queryInd);
    end

end

freqGap = [freqPre(end, :); freqGap; freqPost(1, :)];
magGap = [magPre(end, :); magGap; magPost(1, :)];

smplGap = smplPre(end):hopLen:smplPost(1);

%% Synthesise sinusoidal gap signal
sinGap = resynth(freqGap, magGap, phsPre(end, :), hopLen, phsPost(1, :));

%% Restore residual
% Compute residual of last frame of pre- section
resPre = getResidual(sigPre(end - frmLen + 1:end), freqPre(end, :), ...
        magPre(end, :), phsPre(end, :));

% Compute residual of first frame of post- section
resPost = getResidual(sigPost(2:frmLen+1), freqPost(1, :), magPost(1, :), ...
        phsPost(1, :));

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
freqLim = [0, 10000] / 1000;

% Mag range
magMin = -100;

% Convert from samples to ms
t = (1:length(sig)) / fs;
timeUnit = 's';

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

% Plot spectrogram difference
fig9 = figure(9);
spgmDiff(tSpgm, fSpgm, psdRest, psdSig);
ylim(freqLim)
xlim([t(plotStart), t(plotEnd)]);
title("Spectrogram difference: restoration - original");

% Plot lsd
fig10 = figure(10);
lsd = getLogSpecDist(psdRest, psdSig);
plot(tSpgm, lsd);
hold on;
lsdStartTime = t(gapStart);
lsdEndTime = t(gapEnd);
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
xlim([t(plotStart), t(plotEnd)]);
grid on;

% Save figures
switch source
    case "audio/Flute.nonvib.ff.A4.wav"
        sigDesc = 'flute';
    case "audio/Flute.vib.ff.A4.wav"
        sigDesc = 'fluteVib';
    case "audio/Trumpet.novib.mf.A4.wav"
        sigDesc = 'trumpet';
    case "audio/Trumpet.vib.mf.A4.wav"
        sigDesc = 'trumpetVib';
end

% filename = [sigDesc, '_t_orig_gapLen_', num2str(gapLen)];
% resizeFigure(fig1, 1, 0.6);
% saveas(fig1, ['figures\\spectralModelling\\basicRestoration\\', filename, '.eps'], 'epsc');
% saveas(fig1, ['figures\\spectralModelling\\basicRestoration\\', filename, '.png']);
% close(fig1);

% filename = [sigDesc, '_t_gap_gapLen_', num2str(gapLen)];
% resizeFigure(fig2, 1, 0.6);
% saveas(fig2, ['figures\\spectralModelling\\basicRestoration\\', filename, '.eps'], 'epsc');
% saveas(fig2, ['figures\\spectralModelling\\basicRestoration\\', filename, '.png']);
% close(fig2);

% filename = [sigDesc, '_t_sigGap_gapLen_', num2str(gapLen)];
% resizeFigure(fig3, 1, 0.6);
% saveas(fig3, ['figures\\spectralModelling\\basicRestoration\\', filename, '.eps'], 'epsc');
% saveas(fig3, ['figures\\spectralModelling\\basicRestoration\\', filename, '.png']);
% close(fig3);

% filename = [sigDesc, '_t_rest_gapLen_', num2str(gapLen)];
% resizeFigure(fig4, 1, 0.6);
% saveas(fig4, ['figures\\spectralModelling\\basicRestoration\\', filename, '.eps'], 'epsc');
% saveas(fig4, ['figures\\spectralModelling\\basicRestoration\\', filename, '.png']);
% close(fig4);

% filename = [sigDesc, '_trk_freq_gapLen_', num2str(gapLen)];
% resizeFigure(fig5, 1, 0.6);
% saveas(fig5, ['figures\\spectralModelling\\basicRestoration\\', filename, '.eps'], 'epsc');
% saveas(fig5, ['figures\\spectralModelling\\basicRestoration\\', filename, '.png']);
% close(fig5);

% filename = [sigDesc, '_trk_mag_gapLen_', num2str(gapLen)];
% resizeFigure(fig6, 1, 0.6);
% saveas(fig6, ['figures\\spectralModelling\\basicRestoration\\', filename, '.eps'], 'epsc');
% saveas(fig6, ['figures\\spectralModelling\\basicRestoration\\', filename, '.png']);
% close(fig6);

% filename = [sigDesc, '_spgm_orig_gapLen_', num2str(gapLen)];
% resizeFigure(fig7, 1, 0.6);
% saveas(fig7, ['figures\\spectralModelling\\basicRestoration\\', filename, '.eps'], 'epsc');
% saveas(fig7, ['figures\\spectralModelling\\basicRestoration\\', filename, '.png']);
% close(fig7);

% filename = [sigDesc, '_spgm_rest_gapLen_', num2str(gapLen)];
% resizeFigure(fig8, 1, 0.6);
% saveas(fig8, ['figures\\spectralModelling\\basicRestoration\\', filename, '.eps'], 'epsc');
% saveas(fig8, ['figures\\spectralModelling\\basicRestoration\\', filename, '.png']);
% close(fig8);

% filename = [sigDesc, '_spgm_diff_gapLen_', num2str(gapLen)];
% resizeFigure(fig9, 1, 0.6);
% saveas(fig9, ['figures\\spectralModelling\\basicRestoration\\', filename, '.eps'], 'epsc');
% saveas(fig9, ['figures\\spectralModelling\\basicRestoration\\', filename, '.png']);
% close(fig9);

% filename = [sigDesc, '_lsd_gapLen_', num2str(gapLen)];
% resizeFigure(fig10, 1, 0.6);
% saveas(fig10, ['figures\\spectralModelling\\basicRestoration\\', filename, '.eps'], 'epsc');
% saveas(fig10, ['figures\\spectralModelling\\basicRestoration\\', filename, '.png']);
% close(fig10);

function resizeFigure(figHandle, xFact, yFact)
    figPos = get(figHandle, 'Position');
    figPos(3) = xFact * figPos(3);
    figPos(4) = yFact * figPos(4);
    set(figHandle, 'Position', figPos);
end
