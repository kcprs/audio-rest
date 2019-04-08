% GAPSINRESYNTH Restore gap in given signal using sinusoidal modelling

%% Set variable values
fs = 44100;
gapLen = 10000;
frmLen = 1024;
sigLen = 6 * frmLen;
hopLen = 256;
numTrk = 50;
minTrjLen = 4;

% source = 'synth';
source = 'flute';
% source = 'sin';
% source = 'deathBirth';

%% Prepare source signal
if strcmp(source, 'flute')
    sig = audioread('audio/Flute.nonvib.ff.A4.wav');
elseif strcmp(source, 'sin')
    sig = getCosSig(sigLen, 440);
elseif strcmp(source, 'deathBirth')
    sig = getCosSig(sigLen, 440, -6);
    addSig = getCosSig(ceil(sigLen / 2), 880, -6);
    sig(ceil(sigLen / 4):ceil(sigLen / 4) + length(addSig) - 1) = ...
        sig(ceil(sigLen / 4):ceil(sigLen / 4) + length(addSig) - 1) + addSig;
else
    f = [linspace(100, 2000, sigLen).', linspace(1000, 3000, sigLen).', ...
            linspace(14000, 12000, sigLen).'];
    m = [linspace(-14, 0, sigLen).', linspace(0, -6, sigLen).', ...
            -6 + getCosSig(sigLen, 1.3, -10)];

    sig = getCosSig(sigLen, f(:, 1), m(:, 1)) + ...
        getCosSig(sigLen, f(:, 2), m(:, 2)) + ...
        getCosSig(sigLen, f(:, 3), m(:, 3));
end

%% Damage the source signal
[sigDmg, gapStart, gapEnd] = makeGap(sig, gapLen);

%% Analyse pre- and post-gap sections
% Pre-gap section
sigPre = sigDmg(1:gapStart - 1);
sigPre = flipud(sigPre);
trksPre = trackSpecPeaks(sigPre, frmLen, hopLen, numTrk, minTrjLen);
sigPre = flipud(sigPre);

for trkIter = 1:numTrk
    trksPre(trkIter).reverse(length(sigPre))
end

[freqPre, magPre, phsPre, smplPre] = SinTrack.consolidateFMP(trksPre);

% Post-gap section
sigPost = sigDmg(gapEnd + 1:end);
trksPost = trackSpecPeaks(sigPost, frmLen, hopLen, numTrk, minTrjLen);
[freqPost, magPost, phsPost, smplPost] = SinTrack.consolidateFMP(trksPost);

%% Do linear interpolation over gap by applying peak continuation algorithm
% Prepare track array
trksGap(1, numTrk) = SinTrack();

for trkIter = 1:numel(trksGap)
    trksGap(trkIter).initTrk(2);
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
sigGap = resynth(freqGap, magGap, phsGap(1, :), sigGapLen - 1);

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
