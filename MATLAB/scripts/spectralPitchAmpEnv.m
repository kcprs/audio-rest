% SPECTRALPITCHAMPENV Audio restoration through spectral modelling with
% pitch tracking and amplitude envelope prediction
%  (see section 6.5 in the report)

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

% Residual computation settings
resOrdAR = 50; % Order of the AR model used for residual restoration
smthRes = false; % Smooth residual spectrum before resynthesis?

% Weight of amplitude prediction applied to magnitude trajectories
% (see report section 6.5.1)
envWeight = 0.9;

% Plotting settings
xRange = 3; % Plotting range on x axis. Value of 1 corresponds to gap length.
freqLim = [0, 10000] / 1000; % Freq range
magMin = -100; % Lowest magnitude to be shown in the plot of magnitude trajectories

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
    sigLen = 0.5 * fs;
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

[freqPre, magPre, phsPre, smplPre] = SinTrack.consolidateFMP(trksPre);
pitchPre = trksPre(1).pitchEst;
[envPreUpper, envPreLower] = envelope(sigPre, hopLen, 'peak');
envPre = (envPreUpper - envPreLower) / 2;
envPre = envPre(smplPre);
envPredB = 20 * log10(abs(envPre));

% Post-gap section
sigPost = sigDmg(gapEnd + 1:end);
trksPost = trackSpecPeaks(sigPost, frmLen, hopLen, numTrk, minTrkLen);
[freqPost, magPost, phsPost, smplPost] = SinTrack.consolidateFMP(trksPost);
pitchPost = trksPost(1).pitchEst;
[envPostUpper, envPostLower] = envelope(sigPost, hopLen, 'peak');
envPost = (envPostUpper - envPostLower) / 2;
envPost = envPost(smplPost);
envPostdB = 20 * log10(abs(envPost));
smplPost = gapEnd + smplPost;

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

%% Interpolate pitch
numGapFrm = floor((gapLen + frmLen) / hopLen) - 1;
fitRange = 4;
polyOrd = 3;

pitchData = [pitchPre(end - fitRange + 1:end); pitchPost(1:fitRange)];
dataInd = [1:fitRange, fitRange + numGapFrm + (1:fitRange)].';
queryInd = fitRange + (1:numGapFrm).';
pitchPoly = polyfit(dataInd, pitchData, polyOrd);
pitchGap = polyval(pitchPoly, queryInd);

%% Interpolate amplitude envelope
envData = [envPredB(end - fitRange + 1:end); envPostdB(1:fitRange)];
envPoly = polyfit(dataInd, envData, polyOrd);
envGapdB = polyval(envPoly, queryInd);
envGapInitdb = envPredB(end);
envGapEnddb = envPostdB(1);

%% Interpolate harmonic structure
fade = linspace(0, 1, numGapFrm).';
harmRatios = harmRatiosPre + fade .* (harmRatiosPost - harmRatiosPre);

freqGap = NaN(numGapFrm, numHarm);
magGap = NaN(numGapFrm, numHarm);

for harmIter = 1:numHarm
    magDataPre = magPre(end - fitRange + 1:end, harmIter);
    magDataPost = magPost(1:fitRange, harmIter);

    % If no match, extrapolate frequency and fade out magnitude
    if isnan(harmRatiosPre(harmIter))
        freqGap(:, harmIter) = pitchGap .* harmRatiosPost(1, harmIter);
        fadeIn = linspace(10^(almostNegInf / 20), 1, numGapFrm).';
        magGap(:, harmIter) = magDataPost(1) + 20 * log10(fadeIn);
    elseif isnan(harmRatiosPost(harmIter))
        freqGap(:, harmIter) = pitchGap .* harmRatiosPre(end, harmIter);
        fadeOut = linspace(1, 10^(almostNegInf / 20), numGapFrm).';
        magGap(:, harmIter) = magDataPre(end) + 20 * log10(fadeOut);
    else
        % If match exists, interpolate
        freqGap(:, harmIter) = pitchGap .* harmRatios(:, harmIter);

        magData = [magPre(end - fitRange + 1:end, harmIter); ...
                magPost(1:fitRange, harmIter)];

    magPoly = polyfit(dataInd, magData, polyOrd);
    magGapIndividual = polyval(magPoly, queryInd);

    magRel = linspace(magPre(end, harmIter) - envGapInitdb, ...
        magPost(1, harmIter) - envGapEnddb, numGapFrm).';
    magGapEnv = envGapdB + magRel;

    magGap(:, harmIter) = magGapEnv * envWeight + magGapIndividual * (1 - envWeight);
    end

end

pitchGap = [pitchPre(end); pitchGap; pitchPost(1)];
freqGap = [freqPre(end, :); freqGap; freqPost(1, :)];
magGap = [magPre(end, :); magGap; magPost(1, :)];
envGapdB = [envPredB(end); envGapdB; envPostdB(1)];

smplGap = smplPre(end):hopLen:smplPost(1);

%% Synthesise sinusoidal gap signal
sinGap = resynth(freqGap, magGap, phsPre(end, :), hopLen, phsPost(1, :));

%% Restore residual
% Compute residual of last frame of pre- section
resPre = getResidual(sigPre(end - frmLen + 1:end), -Inf, 0, smthRes);

% Compute residual of first frame of post- section
resPost = getResidual(sigPost(1:frmLen), -Inf, 0, smthRes);

% Morph between pre- and post- residuals over the gap
resGap = wfbar(resPre, resPost, gapLen, resOrdAR);

% Apply interpolated gap envelope to residual
numResFrm = numGapFrm - frmLen / hopLen + 2;
envGapdBCut = envGapdB(frmLen / (2 * hopLen) + 1:end - frmLen / (2 * hopLen));
resRelMag = linspace(envGapInitdb, envGapEnddb, numResFrm + 2).';
resRelMag = resRelMag(2:end - 1);
resAmpFrm = 10.^((envGapdBCut - resRelMag) / 20);
resAmp = resAmpFrm(1) * ones(size(resGap));

for iter = 1:(numResFrm - 1)
    resAmp((iter - 1) * hopLen + 1:iter * hopLen + 1) = ...
        linspace(resAmpFrm(iter), resAmpFrm(iter + 1), hopLen + 1).';
end

resAmp = resAmp(1:end - 1);
resGap = resGap .* resAmp;

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

% Plot pitch
trksGapOrig = trackSpecPeaks(sig, frmLen, hopLen, numTrk, minTrkLen);
[~, ~, ~, smplGapOrig] = SinTrack.consolidateFMP(trksGapOrig);
pitchGapOrig = trksGapOrig(1).pitchEst;
pitchGapOrig = interp1(smplGapOrig, pitchGapOrig, smplGap);

fig13 = figure(13);
plot(t(smplPre), pitchPre);
hold on;
set(gca, 'ColorOrderIndex', 1);
plot(t(smplPost), pitchPost);
plot(t(smplGap), pitchGapOrig, 'Color', [0.7, 0.7, 0.7]);
plot(t(smplGap), pitchGap, 'Color', [221, 49, 26] / 256);
hold off;
title('Pitch trajectory');
ylabel('Pitch (Hz)');
xlabel(['Time (', timeUnit, ')']);
xlim([t(plotStart), t(plotEnd)]);
ylim([400, 500]);
grid on;

% Plot amplitude envelope
[envUpper, envLower] = envelope(sig, hopLen, 'peak');
envGapOrig = (envUpper - envLower) / 2;
envGapOrig = 20 * log10(envGapOrig(smplGap));

fig14 = figure(14);
plot(t(smplPre), envPredB);
hold on;
set(gca, 'ColorOrderIndex', 1);
plot(t(smplPost), envPostdB);
plot(t(smplGap), envGapOrig, 'Color', [0.7, 0.7, 0.7]);
plot(t(smplGap), envGapdB, 'Color', [221, 49, 26] / 256);
hold off;
title('Global amplitude envelope');
ylabel('Amplitude (dBFS)');
xlabel(['Time (', timeUnit, ')']);
xlim([t(plotStart), t(plotEnd)]);
grid on;