% ARINTERP Interpolate sinusoidal tracks using AR Modelling

%% Set variable values
global fsGlobal
fs = fsGlobal;
frmLen = 1024;
gapLen = 40960;
sigLen = 100 * frmLen;
hopLen = 256;
numTrk = 60;
minTrkLen = 10;
resOrdAR = 50;
pitchOrdAR = 2;
magOrdAR = 2;
envOrdAR = 2;
almostNegInf = -100;
envWeight = 0.9;

% Residual computation settings
smthRes = false;

% Plotting settings
xRange = 10; % Plotting range on x axis. Value of 1 corresponds to gap length.
freqLim = [0, 10000] / 1000; % Freq range
magMin = -100; % Lowest magnitude to be shown in the plot of magnitude trajectories

% source = "saw";
% source = "sin";
% source = "audio/Flute.nonvib.A4.wav";
% source = "audio/Flute.vib.A4.wav";
% source = "audio/Trumpet.nonvib.A4.wav";
source = "audio/Trumpet.vib.A4.wav";

%% Prepare source signal
if contains(source, "audio/")
    sig = audioread(source);
elseif strcmp(source, 'sin')
    f = 100; % + 2 * getSineSig(sigLen, 8);
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
if strcmp(source, 'audio/PianoScale.wav')
    [sigDmg, gapStart, gapEnd] = makeGap(sig, gapLen, 80000);
elseif contains(source, "Guitar")
    [sigDmg, gapStart, gapEnd] = makeGap(sig, gapLen, 80000);
elseif contains(source, "Cello")
    [sigDmg, gapStart, gapEnd] = makeGap(sig, gapLen, 50000);
else
    [sigDmg, gapStart, gapEnd] = makeGap(sig, gapLen);
end

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
% Reorder tracks based on harmonics
maxHarmPre = round(max(freqPre(end, :)) / pitchPre(end));
maxHarmPost = round(max(freqPost(1, :)) / pitchPost(1));

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

%% Interpolate pitch -> frequencies and magnitudes
numGapFrm = floor((gapLen + frmLen) / hopLen) - 1;

% Find first & last frame with pitch within semitone up or down
firstUsablePitchPre = find(abs(log2(pitchPre / pitchPre(end))) > 1/12, 1, 'last') + 1;
lastUsablePitchPost = find(abs(log2(pitchPost / pitchPost(1))) > 1/12, 1, 'first') - 1;

if isempty(firstUsablePitchPre)
    firstUsablePitchPre = 1;
end

if isempty(lastUsablePitchPost)
    lastUsablePitchPost = length(pitchPost);
end

dataRangePitchPre = length(pitchPre) - firstUsablePitchPre;
dataRangePitchPost = lastUsablePitchPost;

pitchDataPre = pitchPre(end - dataRangePitchPre + 1:end);
pitchDataPost = pitchPost(1:dataRangePitchPost);
pitchGap = wfbar(pitchDataPre, pitchDataPost, numGapFrm, pitchOrdAR, true);

%% Interpolate amplitude envelope
% Find first & last frame with amplitude within 16 dB range
noteStartEnvPre = find(abs(envPredB - envPredB(end)) > 16, 1, 'last') + 1;
noteEndEnvPost = find(abs(envPostdB - envPostdB(1)) > 16, 1, 'first') - 1;

% Find fitting range
firstUsableEnvPre = find(abs(envPredB(noteStartEnvPre:end) - envPredB(end)) < 2, 1, 'first');
firstUsableEnvPre = firstUsableEnvPre + noteStartEnvPre;
lastUsableEnvPost = find(abs(envPostdB(1:noteEndEnvPost) - envPostdB(1)) < 2, 1, 'last') - 1;

if isempty(firstUsableEnvPre)
    firstUsableEnvPre = 1;
end

if isempty(lastUsableEnvPost)
    lastUsableEnvPost = length(envPostdB);
end

dataRangeEnvPre = length(envPredB) - firstUsableEnvPre;
dataRangeEnvPost = lastUsableEnvPost;

envDataPre = envPredB(end - dataRangeEnvPre + 1:end);
envDataPost = envPostdB(1:dataRangeEnvPost);
envGapdB = wfbar(envDataPre, envDataPost, numGapFrm, envOrdAR, true);
envGapInitdb = envPredB(end);
envGapEnddb = envPostdB(1);

%% Interpolate harmonic structure
fade = linspace(0, 1, numGapFrm).';
harmRatios = harmRatiosPre + fade .* (harmRatiosPost - harmRatiosPre);

freqGap = NaN(numGapFrm, numHarm);
magGap = NaN(numGapFrm, numHarm);

for harmIter = 1:numHarm
    magDataPre = magPre(end - dataRangeEnvPre + 1:end, harmIter);
    magDataPost = magPost(1:dataRangeEnvPost, harmIter);

    if all(isnan([magDataPre; magDataPost]))
        continue;
    end

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
        if any(isnan(magDataPre))
            firstUsable = find(isnan(magDataPre), 1, 'last') + 1;
            magDataPre = magDataPre(firstUsable:end);
        end
    
        if any(isnan(magDataPost))
            lastUsable = find(isnan(magDataPost), 1, 'first') - 1;
            magDataPost = magDataPost(1:lastUsable);
        end
    
        freqGap(:, harmIter) = pitchGap .* harmRatios(:, harmIter);
    
        % Magnitude of harmonic, as predicted from mag trajectory of this harmonic
        magHarmGap = wfbar(magDataPre, magDataPost, numGapFrm, magOrdAR, true);
    
        % Magnitude of harmonic, as predicted based on global envelope and
        % harmonic magnitude strength related to the global envelope
        harmRelStrength = linspace(magDataPre(end) - envGapInitdb, magDataPost(1) - envGapEnddb, numGapFrm).';
        envHarm = envGapdB + harmRelStrength;
    
        magGap(:, harmIter) = envHarm * envWeight + magHarmGap * (1 - envWeight);
    end

end

pitchGap = [pitchPre(end); pitchGap; pitchPost(1)];
freqGap = [freqPre(end, :); freqGap; freqPost(1, :)];
magGap = [magPre(end, :); magGap; magPost(1, :)];
envGapdB = [envPredB(end); envGapdB; envPostdB(1)];

smplGap = smplPre(end):hopLen:smplPost(1);

% Synthesise sinusoidal gap signal
sigGapLen = smplGap(end) - smplGap(1) + 1;
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
resRelStrength = linspace(envGapInitdb, envGapEnddb, numResFrm + 2).';
resRelStrength = resRelStrength(2:end - 1);
resAmpFrm = 10.^((envGapdBCut - resRelStrength) / 20);
resAmp = resAmpFrm(1) * ones(size(resGap));

for iter = 1:(numResFrm - 1)
    resAmp((iter - 1) * hopLen + 1:iter * hopLen + 1) = ...
        linspace(resAmpFrm(iter), resAmpFrm(iter + 1), hopLen + 1).';
end

resAmp = resAmp(1:end - 1); %TODO: Check if size adjustment is ok
resGap = resGap .* resAmp;
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
plot([t(smplPre(firstUsablePitchPre)), t(smplPost(lastUsablePitchPost))], ...
    [pitchPre(firstUsablePitchPre), pitchPost(lastUsablePitchPost)], 'x');
hold off;
title('Pitch trajectory');
ylabel('Pitch in Hz');
xlabel(['Time (', timeUnit, ')']);
xlim([t(plotStart), t(plotEnd)]);
ylim([420, 470]);
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
plot([t(smplPre(firstUsableEnvPre)), t(smplPost(lastUsableEnvPost))], ...
    [envPredB(firstUsableEnvPre), envPostdB(lastUsableEnvPost)], 'x');
hold off;
title('Global amplitude envelope');
xlabel(['Time (', timeUnit, ')']);
xlim([t(plotStart), t(plotEnd)]);
ylim([-30, 0]);
grid on;

% Save figures
switch source
    case "audio/Flute.nonvib.A4.wav"
        sigDesc = ['flute_gapLen_', num2str(gapLen)];
    case "audio/Flute.vib.A4.wav"
        sigDesc = ['fluteVib_gapLen_', num2str(gapLen)];
    case "audio/Trumpet.nonvib.A4.wav"
        sigDesc = ['trumpet_gapLen_', num2str(gapLen)];
    case "audio/Trumpet.vib.A4.wav"
        sigDesc = ['trumpetVib_gapLen_', num2str(gapLen)];
    case "saw"
        sigDesc = ['saw_', num2str(f0), '-', num2str(f1), ...
                    '_gapLen_', num2str(gapLen)];
end

% filename = [sigDesc, '_orig'];
% audiowrite(['audioExamples\\arInterp_', filename, '.wav'], sig, fs);

% filename = [sigDesc, '_dmg'];
% audiowrite(['audioExamples\\arInterp_', filename, '.wav'], sigDmg, fs);

% filename = [sigDesc, '_rest'];
% audiowrite(['audioExamples\\arInterp_', filename, '.wav'], sigRest, fs);

% filename = [sigDesc, '_t_orig'];
% resizeFigure(fig1, 1, 0.7);
% saveas(fig1, ['figures\\spectralModelling\\arInterp\\', filename, '.eps'], 'epsc');
% saveas(fig1, ['figures\\spectralModelling\\arInterp\\', filename, '.png']);
% close(fig1);

% filename = [sigDesc, '_t_gap'];
% resizeFigure(fig2, 1, 0.7);
% saveas(fig2, ['figures\\spectralModelling\\arInterp\\', filename, '.eps'], 'epsc');
% saveas(fig2, ['figures\\spectralModelling\\arInterp\\', filename, '.png']);
% close(fig2);

% filename = [sigDesc, '_t_sigGap'];
% resizeFigure(fig3, 1, 0.7);
% saveas(fig3, ['figures\\spectralModelling\\arInterp\\', filename, '.eps'], 'epsc');
% saveas(fig3, ['figures\\spectralModelling\\arInterp\\', filename, '.png']);
% close(fig3);

% filename = [sigDesc, '_t_rest'];
% resizeFigure(fig4, 1, 0.7);
% saveas(fig4, ['figures\\spectralModelling\\arInterp\\', filename, '.eps'], 'epsc');
% saveas(fig4, ['figures\\spectralModelling\\arInterp\\', filename, '.png']);
% close(fig4);

% filename = [sigDesc, '_trk_freq'];
% resizeFigure(fig5, 1, 0.7);
% saveas(fig5, ['figures\\spectralModelling\\arInterp\\', filename, '.eps'], 'epsc');
% saveas(fig5, ['figures\\spectralModelling\\arInterp\\', filename, '.png']);
% close(fig5);

% filename = [sigDesc, '_trk_mag'];
% resizeFigure(fig6, 1, 0.7);
% saveas(fig6, ['figures\\spectralModelling\\arInterp\\', filename, '.eps'], 'epsc');
% saveas(fig6, ['figures\\spectralModelling\\arInterp\\', filename, '.png']);
% close(fig6);

% filename = [sigDesc, '_spgm_orig'];
% resizeFigure(fig7, 1, 0.8);
% saveas(fig7, ['figures\\spectralModelling\\arInterp\\', filename, '.eps'], 'epsc');
% saveas(fig7, ['figures\\spectralModelling\\arInterp\\', filename, '.png']);
% close(fig7);

% filename = [sigDesc, '_spgm_rest'];
% resizeFigure(fig8, 1, 0.8);
% saveas(fig8, ['figures\\spectralModelling\\arInterp\\', filename, '.eps'], 'epsc');
% saveas(fig8, ['figures\\spectralModelling\\arInterp\\', filename, '.png']);
% close(fig8);

% filename = [sigDesc, '_spgm_diff'];
% resizeFigure(fig9, 1, 0.8);
% saveas(fig9, ['figures\\spectralModelling\\arInterp\\', filename, '.eps'], 'epsc');
% saveas(fig9, ['figures\\spectralModelling\\arInterp\\', filename, '.png']);
% close(fig9);

% filename = [sigDesc, '_lsd'];
% resizeFigure(fig10, 1, 0.7);
% saveas(fig10, ['figures\\spectralModelling\\arInterp\\', filename, '.eps'], 'epsc');
% saveas(fig10, ['figures\\spectralModelling\\arInterp\\', filename, '.png']);
% close(fig10);

% filename = [sigDesc, '_resFrqRespFwd'];
% resizeFigure(fig11, 1, 0.7);
% saveas(fig11, ['figures\\spectralModelling\\arInterp\\', filename, '.eps'], 'epsc');
% saveas(fig11, ['figures\\spectralModelling\\arInterp\\', filename, '.png']);
% close(fig11);

% filename = [sigDesc, '_resFrqRespBwd'];
% resizeFigure(fig12, 1, 0.7);
% saveas(fig12, ['figures\\spectralModelling\\arInterp\\', filename, '.eps'], 'epsc');
% saveas(fig12, ['figures\\spectralModelling\\arInterp\\', filename, '.png']);
% close(fig12);

% filename = [sigDesc, '_pitch'];
% resizeFigure(fig13, 1, 0.7);
% saveas(fig13, ['figures\\spectralModelling\\arInterp\\', filename, '.eps'], 'epsc');
% saveas(fig13, ['figures\\spectralModelling\\arInterp\\', filename, '.png']);
% close(fig13);

% filename = [sigDesc, '_globAmp'];
% resizeFigure(fig14, 1, 0.7);
% saveas(fig14, ['figures\\spectralModelling\\arInterp\\', filename, '.eps'], 'epsc');
% saveas(fig14, ['figures\\spectralModelling\\arInterp\\', filename, '.png']);
% close(fig14);

function resizeFigure(figHandle, xFact, yFact)
    figPos = get(figHandle, 'Position');
    figPos(3) = xFact * figPos(3);
    figPos(4) = yFact * figPos(4);
    set(figHandle, 'Position', figPos);
end
