% RESIDRESYNTH Resynthesis of the residual in spectral modelling synthesis

%% Set variable values
fs = 44100;
frmLen = 1024;
gapLen = 10 * frmLen;
sigLen = 16 * frmLen;
hopLen = 256;
numTrk = 10;
minTrkLen = 4;

source = 'flute';
% source = 'sin';

%% Prepare source signal
if strcmp(source, 'sin')
    sig = getCosSig(sigLen, 440);
else
    sig = audioread('audio/Flute.nonvib.ff.A4.wav');
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

%% Do linear interpolation over gap by applying peak continuation algorithm
% Prepare track array
trksGap(1, numTrk) = SinTrack();

for trkIter = 1:numel(trksGap)
    trksGap(trkIter).allocateFrm(2);
end

% Select last peaks from pre- section and first peaks from post- section
pkFreqGap = [freqPre(end, :); freqPost(1, :)];
pkMagGap = [magPre(end, :); magPost(1, :)];
pkPhsGap = [phsPre(end, :); phsPost(1, :)];
smplGap = [smplPre(end); gapEnd + smplPost(1)];

% Apply peak continuation over the gap
for frmIter = 1:2
    [trksGap.frmCursor] = deal(frmIter);
    peakCont(trksGap, pkFreqGap(frmIter, :), pkMagGap(frmIter, :), ...
        pkPhsGap(frmIter, :), smplGap(frmIter));
end

%% Synthesise gap signal
[freqGap, magGap, phsGap, ~] = SinTrack.consolidateFMP(trksGap);
sigGapLen = smplGap(2) - smplGap(1) + 1;
sinGap = resynth(freqGap, magGap, phsGap(1, :), sigGapLen - 1);

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
resGap = wfbar(resPre, resPost, gapLen);

%% Add reconstructed sinusoidal and residual
resGap = [resPre(frmLen / 2:end); resGap; resPost(1:frmLen / 2 + 1)];
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
sigRest(smplGap(1):smplGap(2)) = sigRest(smplGap(1):smplGap(2)) + sigGapXF;
sigRest(gapEnd + 1:end) = sigRest(gapEnd + 1:end) + sigPostXF;

%% Plotting
subplot(2, 2, 1);
plot(sigPre, 'DisplayName', 'pre- section');
hold on;
plot([NaN(gapEnd, 1); sigPost], 'DisplayName', 'post- section');
plot([NaN(smplGap(1), 1); sigGap], ':', 'DisplayName', 'reconstruction', ...
    'Color', 'black');
plot(smplGap, 0, 'x', 'DisplayName', 'transition');
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
plot(gapEnd + smplPost, freqPost);
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
plot(gapEnd + smplPost, magPost);
set(gca, 'ColorOrderIndex', 1);
plot(smplGap, magGap, ':');
hold off;
title('Sinusoidal tracks - magnitude');
ylabel('Magnitude in dBFS');
xlabel('Time in samples');
grid on;
