% SPECTRALBASIC Audio restoration through spectral modelling with cubic
% polynomial interpolation of trajectories (see section 6.2 in the report)

% Before the script is used, setup.m must be ran to set global variable
% values and add required folders to workspace path. If the command 'clear all'
% is used, the setup script has to be ran again to reinstate global variables.

% Script returns processed signals in the following variables:
% sig - original signal
% sigDmg - damaged signal
% sigRest - restored signal
% Use MATLAB's audiowrite to save them to an audio file.

%% Set up global variable values
global fsGlobal
fs = fsGlobal;
almostNegInf = -100;

%% ----------- Script Settings - user editable --------------------
% Analysis settings
frmLen = 1024; % STFT frame length
hopLen = 256; % STFT hop length
numTrk = 60; % Number of sinusoidal tracks to be used for spectral modelling
minTrkLen = 8; % Minimum trajectory length

% Length of gap in samples - must be greater than frmLen and integer multiple of hopLen
gapLen = 10240;

% Select behaviour for trajectories without a match across the gap
noMatchBehaviour = "constant"; % Frequency stays constant
% noMatchBehaviour = "polynomial"; % Frequency is extrapolated using cubic polynomial

% Residual computation settings
resOrdAR = 50; % Order of the AR model used for residual restoration
smthRes = false; % Smooth residual spectrum before resynthesis?

% Plotting settings
xRange = 3; % Plotting range on x axis. Value of 1 corresponds to gap length.
freqLim = [0, 10000] / 1000; % Freq range
magMin = -70; % Lowest magnitude to be shown in the plot of magnitude trajectories

% Uncomment below to set audio source
% source = "saw";
% source = "sin";
% source = "audio/Flute.nonvib.A4.wav";
source = "audio/Flute.vib.A4.wav";
% source = "audio/Trumpet.nonvib.A4.wav";
% source = "audio/Trumpet.vib.A4.wav";

%% Prepare source signal
if contains(source, "audio/")
    sig = audioread(source);
    sigLen = length(sig);
elseif strcmp(source, 'sin')
    sigLen = fs;
    f = 440;
    sig = getCosSig(sigLen, f, -6);
else
    sigLen = fs;
    f0 = 880; % A5 note
    f1 = 1046.5; % C6 note
    f = logspace(log10(f0), log10(f1), sigLen).';

    arOrd = 0;
    sig = getSawSig(sigLen, f, -12);
    sig = sig + 0.002 * randn([sigLen, 1]);
end

%% ----------- end of Script Settings --------------------

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

% Convert SinTrack objects into a frequency, magnitude and phase matrices
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
        magPost(1, :), 0.1);
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

        if strcmp(noMatchBehaviour, "polynomial")
            dataInd = dataRange + numGapFrm + (1:dataRange).';
            queryInd = dataRange + (1:numGapFrm);
            freqPoly = polyfit(dataInd, freqDataPost, polyOrd);
            freqGap(:, trkIter) = polyval(freqPoly, queryInd);
        else
            freqGap(:, trkIter) = freqDataPost(1);
        end

        fadeIn = linspace(10^(almostNegInf / 20), 1, numGapFrm).';
        magGap(:, trkIter) = magDataPost(1) + 20 * log10(fadeIn);
    elseif all(isnan(freqDataPost))

        if strcmp(noMatchBehaviour, "polynomial")
            dataInd = (1:dataRange).';
            queryInd = dataRange + (1:numGapFrm);
            freqPoly = polyfit(dataInd, freqDataPre, polyOrd);
            freqGap(:, trkIter) = polyval(freqPoly, queryInd);
        else
            freqGap(:, trkIter) = freqDataPre(end);
        end

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
gapCentre = int64((gapStart + gapEnd) / 2);
plotStart = gapCentre - int64(0.5 * xRange * gapLen);
plotEnd = gapCentre + int64(0.5 * xRange * gapLen);

plotStart = max(1, plotStart);
plotEnd = min(length(sig), plotEnd);

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
plot(t(smplGap), freqGap / 1000, '--');
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
plot(t(smplGap), magGap, '--');
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

% Plot pre AR frequency response
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
title("AR Filter Fwd - Frequency Response");
xlabel("Frequency (kHz)");
ylabel("Magnitude (dB)");
xlim([0, 20000] / 1000);
grid on;
legend;

% Plot post AR frequency response
fig12 = figure(12);
global arBwdFreqResp;
% global arFreqVec;

arBwdFreqResp = 20 * log10(abs(arBwdFreqResp));
arBwdFreqResp = arBwdFreqResp - max(arBwdFreqResp);
plot(arFreqVec / 1000, arBwdFreqResp, 'DisplayName', "AR magnitude response");
hold on;
magSpec = 20 * log10(abs(fft(resPost, 2 * length(arFreqVec))));
magSpec = magSpec(1:length(arFreqVec));
magSpec = magSpec - max(magSpec);
plot(arFreqVec / 1000, magSpec, 'DisplayName', "Spectrum of the modelled signal");
hold off;
title("AR Filter Bwd - Frequency Response");
xlabel("Frequency (kHz)");
ylabel("Magnitude (dB)");
xlim([0, 20000] / 1000);
grid on;
legend;