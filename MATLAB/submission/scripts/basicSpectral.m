% ARINTERP Interpolate sinusoidal tracks using AR Modelling

%% Set variable values
global fsGlobal
fs = fsGlobal;
frmLen = 1024;
gapLen = 4096;
hopLen = 256;
numTrk = 60;
minTrkLen = 8;
resOrdAR = 50;
almostNegInf = -100;
smthRes = false;

source = "saw";
% source = "sin";
% source = "audio/Flute.nonvib.ff.A4.wav";
% source = "audio/Flute.vib.ff.A4.wav";
% source = "audio/Trumpet.novib.mf.A4.wav";
% source = "audio/Trumpet.vib.mf.A4.wav";

%% Prepare source signal
if contains(source, "audio/")
    sig = audioread(source);
    sigLen = length(sig);
elseif strcmp(source, 'sin')
    sigLen = fs;
    f = 440; % + 2 * getSineSig(sigLen, 8);
    sig = getCosSig(sigLen, f, -6);
    % sig = sig + getCosSig(sigLen, 2 * f, -12, pi);
    % sig = sig + getCosSig(sigLen, 3 * f, -15, pi / 2);
    % sig = sig + getCosSig(sigLen, 4 * f, -18, 0.75 * pi);
    % sig = sig + getCosSig(sigLen, 5 * f, -21);
    % sig = sig + 0.1 * randn(size(sig)) ./ 6;
else
    sigLen = fs;
    f0 = 880; % A5 note
    f1 = 1046.5; % C6 note
    f = logspace(log10(f0), log10(f1), sigLen).';

    arOrd = 0;
    sig = getSawSig(sigLen, f, -12);
    sig = sig + 0.002 * randn([sigLen, 1]);
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
        magPost(1, :), 0.05);
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

    % If no match, extrapolate frequency and fade out magnitude
    if all(isnan(freqDataPre))
        dataInd = dataRange + numGapFrm + (1:dataRange).';
        queryInd = dataRange + (1:numGapFrm);
        freqPoly = polyfit(dataInd, freqDataPost, polyOrd);
        freqGap(:, trkIter) = polyval(freqPoly, queryInd);
        
        fadeIn = linspace(10^(almostNegInf / 20), 1, numGapFrm).';
        magGap(:, trkIter) = magDataPost(1) + 20 * log10(fadeIn);
    elseif all(isnan(freqDataPost))
        dataInd = (1:dataRange).';
        queryInd = dataRange + (1:numGapFrm);
        freqPoly = polyfit(dataInd, freqDataPre, polyOrd);
        freqGap(:, trkIter) = polyval(freqPoly, queryInd);

        fadeOut = linspace(1, 10^(almostNegInf / 20), numGapFrm).';
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
% Find number of active tracks in pre and post sections
preActive = 0;
postActive = 0;

for iter = 1:numTrk
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
resPost = getResidual(sigPost(1:frmLen), -Inf, postActive, smthRes);

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
plotStart = gapStart - round(0.3 * gapLen);
plotEnd = gapEnd + round(0.3 * gapLen);
% plotStart = 14883;
% plotEnd = 29218;

% Freq range
freqLim = [0, 20000] / 1000;

% Mag range
magMin = -70;

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
fig11 = figure(11);
global arFwdFreqResp;
global arFreqVec;

arFwdFreqResp = 20 * log10(abs(arFwdFreqResp));
arFwdFreqResp = arFwdFreqResp - max(arFwdFreqResp);
plot(arFreqVec / 1000, arFwdFreqResp, 'DisplayName', "AR magnitude response");
hold on;
magSpec = 20 * log10(abs(fft(resPre, 2 * length(arFreqVec))));
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
% audiowrite(['submission\\audioExamples\\poly_', filename, '.wav'], sig, fs);

% filename = [sigDesc, '_dmg'];
% audiowrite(['submission\\audioExamples\\poly_', filename, '.wav'], sigDmg, fs);

% filename = [sigDesc, '_rest'];
% audiowrite(['submission\\audioExamples\\poly_', filename, '.wav'], sigRest, fs);

% filename = [sigDesc, '_t_orig'];
% resizeFigure(fig1, 1, 0.7);
% saveas(fig1, ['figures\\spectralModelling\\basicRestoration\\', filename, '.eps'], 'epsc');
% saveas(fig1, ['figures\\spectralModelling\\basicRestoration\\', filename, '.png']);
% close(fig1);

% filename = [sigDesc, '_t_gap'];
% resizeFigure(fig2, 1, 0.7);
% saveas(fig2, ['figures\\spectralModelling\\basicRestoration\\', filename, '.eps'], 'epsc');
% saveas(fig2, ['figures\\spectralModelling\\basicRestoration\\', filename, '.png']);
% close(fig2);

% filename = [sigDesc, '_t_sigGap'];
% resizeFigure(fig3, 1, 0.7);
% saveas(fig3, ['figures\\spectralModelling\\basicRestoration\\', filename, '.eps'], 'epsc');
% saveas(fig3, ['figures\\spectralModelling\\basicRestoration\\', filename, '.png']);
% close(fig3);

% filename = [sigDesc, '_t_rest'];
% resizeFigure(fig4, 1, 0.7);
% saveas(fig4, ['figures\\spectralModelling\\basicRestoration\\', filename, '.eps'], 'epsc');
% saveas(fig4, ['figures\\spectralModelling\\basicRestoration\\', filename, '.png']);
% close(fig4);

filename = [sigDesc, '_trk_freq'];
resizeFigure(fig5, 1, 0.7);
saveas(fig5, ['figures\\spectralModelling\\basicRestoration\\', filename, '.eps'], 'epsc');
saveas(fig5, ['figures\\spectralModelling\\basicRestoration\\', filename, '.png']);
close(fig5);

filename = [sigDesc, '_trk_mag'];
resizeFigure(fig6, 1, 0.7);
saveas(fig6, ['figures\\spectralModelling\\basicRestoration\\', filename, '.eps'], 'epsc');
saveas(fig6, ['figures\\spectralModelling\\basicRestoration\\', filename, '.png']);
close(fig6);

filename = [sigDesc, '_spgm_orig'];
resizeFigure(fig7, 1, 1);
saveas(fig7, ['figures\\spectralModelling\\basicRestoration\\', filename, '.eps'], 'epsc');
saveas(fig7, ['figures\\spectralModelling\\basicRestoration\\', filename, '.png']);
close(fig7);

filename = [sigDesc, '_spgm_rest'];
resizeFigure(fig8, 1, 1);
saveas(fig8, ['figures\\spectralModelling\\basicRestoration\\', filename, '.eps'], 'epsc');
saveas(fig8, ['figures\\spectralModelling\\basicRestoration\\', filename, '.png']);
close(fig8);

% filename = [sigDesc, '_spgm_diff'];
% resizeFigure(fig9, 1, 0.7);
% saveas(fig9, ['figures\\spectralModelling\\basicRestoration\\', filename, '.eps'], 'epsc');
% saveas(fig9, ['figures\\spectralModelling\\basicRestoration\\', filename, '.png']);
% close(fig9);

% filename = [sigDesc, '_lsd'];
% resizeFigure(fig10, 1, 0.7);
% saveas(fig10, ['figures\\spectralModelling\\basicRestoration\\', filename, '.eps'], 'epsc');
% saveas(fig10, ['figures\\spectralModelling\\basicRestoration\\', filename, '.png']);
% close(fig10);

% filename = [sigDesc, '_resFrqResp'];
% resizeFigure(fig11, 1, 0.7);
% saveas(fig11, ['figures\\spectralModelling\\basicRestoration\\', filename, '.eps'], 'epsc');
% saveas(fig11, ['figures\\spectralModelling\\basicRestoration\\', filename, '.png']);
% close(fig11);

function resizeFigure(figHandle, xFact, yFact)
    figPos = get(figHandle, 'Position');
    figPos(3) = xFact * figPos(3);
    figPos(4) = yFact * figPos(4);
    set(figHandle, 'Position', figPos);
end
