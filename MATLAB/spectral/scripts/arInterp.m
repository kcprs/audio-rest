% ARINTERP Interpolate sinusoidal tracks using AR Modelling

%% Set variable values
fs = 44100;
frmLen = 1024;
gapLen = 30 * frmLen;
sigLen = 100 * frmLen;
hopLen = 256;
numTrk = 80;
minTrkLen = 10;
resOrdAR = 100;
pitchOrdAR = 2;
magOrdAR = 2;
envOrdAR = 4;
almostNegInf = -100;
envWeight = 0.5;

% source = "saw";
% source = "sin";
% source = "audio/Cello.arco.mf.sulC.A2.wav";
% source = "audio/Flute.nonvib.ff.A4.wav";
source = "audio/Flute.vib.ff.A4.wav";
% source = "audio/Guitar.mf.sulD.A3.wav";
% source = "audio/Guitar.mf.sulD.D3.wav";
% source = "audio/Horn.mf.A2.wav";
% source = "audio/Horn.mf.A4.wav";
% source = "audio/PianoScale.wav";
% source = "audio/Trumpet.novib.mf.A4.wav";
% source = "audio/Trumpet.novib.mf.D4.wav";
% source = "audio/Trumpet.vib.mf.A4.wav";
% source = "audio/Trumpet.vib.mf.D4.wav";
% source = "audio/Violin.arco.ff.sulG.A3.wav";
% source = "audio/Violin.arco.ff.sulG.A4.wav";
% source = "audio/Violin.arco.mf.sulA.A4.wav";

%% Prepare source signal
if contains(source, "audio/")
    sig = audioread(source);
elseif strcmp(source, 'sin')
    f = 440 + 2 * getSineSig(sigLen, 8);
    sig = getCosSig(sigLen, f, -6);
    sig = sig + getCosSig(sigLen, 3 * f, -6);
    sig = sig + getCosSig(sigLen, 6 * f, -12);
    sig = sig + getCosSig(sigLen, 7 * f, -14);
    % sig = sig + 0.1 * randn(size(sig));
else
    f = logspace(log10(220), log10(440), sigLen).';
    m = linspace(-14, 0, sigLen).';

    sig = getSawSig(sigLen, f, m);
end

%% Damage the source signal
if strcmp(source, 'audio/PianoScale.wav')
    [sigDmg, gapStart, gapEnd] = makeGap(sig, gapLen, 80000);
elseif contains(source, "Guitar")
    [sigDmg, gapStart, gapEnd] = makeGap(sig, gapLen, 80000);
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
[envPre, ~] = envelope(sigPre, hopLen, 'peak');
envPre = envPre(smplPre);

% Post-gap section
sigPost = sigDmg(gapEnd + 1:end);
trksPost = trackSpecPeaks(sigPost, frmLen, hopLen, numTrk, minTrkLen);
[freqPost, magPost, phsPost, smplPost] = SinTrack.consolidateFMP(trksPost);
pitchPost = trksPost(1).pitchEst;
[envPost, ~] = envelope(sigPost, hopLen, 'peak');
envPost = envPost(smplPost);
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

% Add matching information for harmonics only present at one
% side of the gap

for harmIter = 1:numHarm

    if all(isnan(magPre(end - magOrdAR:end, harmIter))) && ...
            all(isnan(magPost(1:magOrdAR + 1, harmIter)))
        continue;
    end

    if any(isnan(magPre(end - magOrdAR:end, harmIter)))
        magPre(end - magOrdAR:end, harmIter) = almostNegInf;
        harmRatiosPre(harmIter) = harmRatiosPost(harmIter);
    end

    if any(isnan(magPost(1:magOrdAR + 1, harmIter)))
        magPost(1:magOrdAR + 1, harmIter) = almostNegInf;
        harmRatiosPost(harmIter) = harmRatiosPre(harmIter);
    end

end

%% Interpolate pitch -> frequencies and magnitudes
numGapFrm = floor(gapLen / hopLen) + 3; % TODO: 3 is not general

% Find first & last frame with pitch within semitone up or down
firstUsablePre = find(abs(log2(pitchPre / pitchPre(end))) > 1/12, 1, 'last') + 1;
lastUsablePost = find(abs(log2(pitchPost / pitchPost(1))) > 1/12, 1, 'first') - 1;

if isempty(firstUsablePre)
    firstUsablePre = 1;
end

if isempty(lastUsablePost)
    lastUsablePost = length(pitchPost);
end

dataRangePre = length(pitchPre) - firstUsablePre;
dataRangePost = lastUsablePost;

pitchDataPre = pitchPre(end - dataRangePre + 1:end);
pitchDataPost = pitchPost(1:dataRangePost);
pitchGap = wfbar(pitchDataPre, pitchDataPost, numGapFrm, pitchOrdAR);

%% Interpolate amplitude envelope
envDataPre = envPre(end - dataRangePre + 1:end);
envDataPost = envPost(1:dataRangePost);
envGap = wfbar(envDataPre, envDataPost, numGapFrm, envOrdAR);
envGapdB = 20 * log10(envGap);
envGapInitdb = 20 * log10(envPre(end));
envGapEnddb = 20 * log10(envPost(1));

%% Interpolate harmonic structure
fade = linspace(0, 1, numGapFrm).';
harmRatios = harmRatiosPre + fade .* (harmRatiosPost - harmRatiosPre);

freqGap = NaN(numGapFrm, numHarm);
magGap = NaN(numGapFrm, numHarm);

for harmIter = 1:numHarm
    magDataPre = magPre(end - dataRangePre + 1:end, harmIter);
    magDataPost = magPost(1:dataRangePost, harmIter);

    if all(isnan([magDataPre; magDataPost]))
        continue;
    end

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
    magHarmGap = wfbar(magDataPre, magDataPost, numGapFrm, magOrdAR);

    % Magnitude of harmonic, as predicted based on global envelope and
    % harmonic magnitude strength related to the global envelope
    harmRelStrength = linspace(magDataPre(end) - envGapInitdb, magDataPost(1) - envGapEnddb, numGapFrm).';
    envHarm = envGapdB + harmRelStrength;

    magGap(:, harmIter) = envHarm * envWeight + magHarmGap * (1 - envWeight);
end

pitchGap = [pitchPre(end); pitchGap; pitchPost(1)];
freqGap = [freqPre(end, :); freqGap; freqPost(1, :)];
magGap = [magPre(end, :); magGap; magPost(1, :)];
envGap = [envPre(end); envGap; envPost(1)];

smplGap = smplPre(end):hopLen:smplPost(1);

%% Synthesise sinusoidal gap signal
sigGapLen = smplGap(end) - smplGap(1) + 1;
sinGap = resynth(freqGap, magGap, phsPre(end, :), hopLen, phsPost(1, :));

%% Resynthesise sinusoidal and residual of last frame of pre- section
% Build the signal from the middle outwards since phase is known for
% The middle of the frame
% TODO: Take spectrum changes into account
sinPreFwd = resynth([freqPre(end, :); freqPre(end, :)], ...
    [magPre(end, :); magPre(end, :)], phsPre(end, :), frmLen / 2);
sinPreBwd = resynth([freqPre(end, :); freqPre(end, :)], ...
    [magPre(end, :); magPre(end, :)], -phsPre(end, :), frmLen / 2 - 1);
sinPre = [flipud(sinPreBwd); sinPreFwd(2:end)];

resPre = sigPre(end - frmLen + 1:end) - sinPre;

%% Resynthesise sinusoidal and residual of first frame of post- section
% Build the signal from the middle outwards since phase is known for
% The middle of the frame
% TODO: Take spectrum changes into account
sinPostFwd = resynth([freqPost(1, :); freqPost(1, :)], ...
    [magPost(1, :); magPost(1, :)], phsPost(1, :), frmLen / 2 - 1);
sinPostBwd = resynth([freqPost(1, :); freqPost(1, :)], ...
    [magPost(1, :); magPost(1, :)], -phsPost(1, :), frmLen / 2);
sinPost = [flipud(sinPostBwd); sinPostFwd(2:end)];

resPost = sigPost(1:frmLen) - sinPost;

%% Morph between pre- and post- residuals over the gap
resGap = wfbar(resPre, resPost, gapLen, resOrdAR);
resGap = [resPre(frmLen / 2:end); resGap; resPost(1:frmLen / 2)];

%% Apply magnitude variation based on amp envelope of sinusoidal
[envSinGap, ~] = envelope(sinGap, hopLen, 'peak');

% Normalise and cross-fade so that start and end amplitude is 1
envGapPre = envSinGap / envSinGap(1);
envGapPost = envSinGap / envSinGap(end);
fade = linspace(0, 1, length(envSinGap)).';
envNorm = envGapPre .* (1 - fade) + envGapPost .* fade;

% Apply envelope
resGap = resGap .* envNorm;

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
figure(1);
subplot(2, 2, 1);
plot(sigPre, 'DisplayName', 'pre- section');
hold on;
plot([NaN(gapEnd, 1); sigPost], 'DisplayName', 'post- section');
plot([NaN(smplGap(1), 1); sigGap], ':', 'DisplayName', 'reconstruction', ...
    'Color', 'black');
plot([smplGap(1), smplGap(end)], [0, 0], 'x', 'DisplayName', 'transitions');
title('Damaged signal and reconstructed waveform')
xlabel('Time in samples');
legend;
hold off;

subplot(2, 2, 3);
plot(sigRest, 'DisplayName', 'Final restored signal');
hold on;
rectangle('Position', [gapStart, min(sigRest), gapLen, ...
                        max(sigRest) - min(sigRest)], ...
    'FaceColor', [1, 0, 0, 0.1], ...
    'EdgeColor', 'none');
hold off;
title('Fully restored signal')
xlabel('Time in samples');

subplot(2, 2, 2);
plot(smplPre, freqPre);
hold on;
set(gca, 'ColorOrderIndex', 1);
plot(smplPost, freqPost);
set(gca, 'ColorOrderIndex', 1);
plot(smplGap, freqGap, ':');
hold off;
title('Sinusoidal tracks - frequency');
ylabel('Frequency in Hz');
xlabel('Time in samples');
grid on;

subplot(2, 2, 4);
plot(smplPre, magPre);
hold on;
set(gca, 'ColorOrderIndex', 1);
plot(smplPost, magPost);
set(gca, 'ColorOrderIndex', 1);
plot(smplGap, magGap, ':');
hold off;
title('Sinusoidal tracks - magnitude');
ylabel('Magnitude in dBFS');
xlabel('Time in samples');
grid on;

figure(2);
subplot(2, 1, 1);
plot(smplPre, pitchPre);
hold on;
set(gca, 'ColorOrderIndex', 1);
plot(smplPost, pitchPost);
set(gca, 'ColorOrderIndex', 1);
plot(smplGap, pitchGap, ':');
plot([smplPre(firstUsablePre), smplPost(lastUsablePost)], ...
    [pitchPre(firstUsablePre), pitchPost(lastUsablePost)], 'x');
hold off;
title('Pitch estimate over time');
ylabel('Pitch in Hz');
xlabel('Time in samples');
grid on;

subplot(2, 1, 2);
plot(smplPre, envPre);
hold on;
set(gca, 'ColorOrderIndex', 1);
plot(smplPost, envPost);
set(gca, 'ColorOrderIndex', 1);
plot(smplGap, envGap, ':');
plot([smplPre(firstUsablePre), smplPost(lastUsablePost)], ...
    [envPre(firstUsablePre), envPost(lastUsablePost)], 'x');
hold off;
title('Global envelope over time');
xlabel('Time in samples');
grid on;
