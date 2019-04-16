% SPLINES Interpolate sinusoidal tracks using splines

%% Set variable values
fs = 44100;
frmLen = 1024;
gapLen = 20 * frmLen;
sigLen = 100 * frmLen;
hopLen = 256;
numTrk = 20;
minTrkLen = 4;
resOrdAR = 100;
almostNegInf = -100;
polyOrd = 2;

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
% source = "audio/Violin.5th.wav";

%% Prepare source signal
if contains(source, "audio/")
    sig = audioread(source);
elseif strcmp(source, 'sin')
    f = logspace(log10(300), log10(600), sigLen).' + 5 * getSineSig(sigLen, 10);
    sig = getCosSig(sigLen, f, -6);
    sig = sig + getCosSig(sigLen, 3 * f, -6);
    sig = sig + getCosSig(sigLen, 4 * f, -12);
    sig = sig + getCosSig(sigLen, 6 * f, -14);
    sig = sig + 0.1 * randn(size(sig));
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

% Post-gap section
sigPost = sigDmg(gapEnd + 1:end);
trksPost = trackSpecPeaks(sigPost, frmLen, hopLen, numTrk, minTrkLen);
[freqPost, magPost, phsPost, smplPost] = SinTrack.consolidateFMP(trksPost);
smplPost = gapEnd + smplPost;

%% Match tracks across the gap
% Reorder based on harmonics
maxHarmPre = round(max(freqPre(end, :)) / trksPre(1).pitchEst(end));
maxHarmPost = round(max(freqPost(1, :)) / trksPost(1).pitchEst(1));

numHarm = max(maxHarmPre, maxHarmPost);

freqHarmPre = NaN(size(freqPre, 1), numHarm);
magHarmPre = NaN(size(magPre, 1), numHarm);
phsHarmPre = NaN(size(phsPre, 1), numHarm);

freqHarmPost = NaN(size(freqPost, 1), numHarm);
magHarmPost = NaN(size(magPost, 1), numHarm);
phsHarmPost = NaN(size(phsPost, 1), numHarm);

for trkIter = 1:numTrk
    harmNumPre = trksPre(trkIter).getHarmNum(-1);
    harmNumPost = trksPost(trkIter).getHarmNum(1);

    if harmNumPre >= 1
        freqHarmPre(:, harmNumPre) = freqPre(:, trkIter);
        magHarmPre(:, harmNumPre) = magPre(:, trkIter);
        phsHarmPre(:, harmNumPre) = phsPre(:, trkIter);
    end

    if harmNumPost >= 1
        freqHarmPost(:, harmNumPost) = freqPost(:, trkIter);
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
numGapFrm = floor(gapLen / hopLen) + 3; % TODO: 3 is not general
dataRange = numGapFrm;
freqGap = NaN(numGapFrm, numHarm);
magGap = NaN(numGapFrm, numHarm);

for trkIter = 1:numHarm
    freqData = [freqPre(end - dataRange + 1:end, trkIter); ...
                freqPost(1:dataRange, trkIter)];

    if all(isnan(freqData))
        continue;
    end

    magData = [magPre(end - dataRange + 1:end, trkIter); ...
                magPost(1:dataRange, trkIter)];

    dataInd = [1:dataRange, dataRange + numGapFrm + (1:dataRange)].';
    queryInd = dataRange + (1:numGapFrm);

    freqPoly = polyfit(dataInd, freqData, polyOrd);
    magPoly = polyfit(dataInd, magData, polyOrd);

    freqGap(:, trkIter) = polyval(freqPoly, queryInd);
    magGap(:, trkIter) = polyval(magPoly, queryInd);
end

freqGap = [freqPre(end, :); freqGap; freqPost(1, :)];
magGap = [magPre(end, :); magGap; magPost(1, :)];

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

%% Add reconstructed sinusoidal and residual
resGap = [resPre(frmLen / 2:end); resGap; resPost(1:frmLen / 2)];
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
title(['Sine tracks - frequency (gap len: ', num2str(gapLen), ...
         ', poly order: ', num2str(polyOrd), ', fitRange: ', ...
         num2str(dataRange), ')']);
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
title(['Sine tracks - magnitude (gap len: ', num2str(gapLen), ...
         ', poly order: ', num2str(polyOrd), ', fitRange: ', ...
         num2str(dataRange), ')']);
ylabel('Magnitude in dBFS');
xlabel('Time in samples');
grid on;
