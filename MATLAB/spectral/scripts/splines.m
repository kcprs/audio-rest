% splines Interpolate sinusoidal tracks using splines

%% Set variable values
fs = 44100;
frmLen = 1024;
gapLen = 10 * frmLen;
sigLen = 8 * frmLen;
hopLen = 256;
numTrk = 16;
minTrkLen = 4;

% source = 'synth';
source = 'flute';
% source = 'sin';

%% Prepare source signal
if strcmp(source, 'flute')
    sig = audioread('audio/Flute.vib.ff.A4.wav');
elseif strcmp(source, 'sin')
    sig = getCosSig(sigLen, 440);
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
trksPre = trackSpecPeaks(sigPre, frmLen, hopLen, numTrk, minTrkLen);
sigPre = flipud(sigPre);

for trkIter = 1:numTrk
    trksPre(trkIter).reverse(length(sigPre))
end

[freqPre, magPre, phsPre, smplPre] = SinTrack.consolidateFMP(trksPre);

[~, sortIndPre] = sort(freqPre(end, :));
freqPre = freqPre(:, sortIndPre);
magPre = magPre(:, sortIndPre);
phsPre = phsPre(:, sortIndPre);

% Post-gap section
sigPost = sigDmg(gapEnd + 1:end);
trksPost = trackSpecPeaks(sigPost, frmLen, hopLen, numTrk, minTrkLen);
[freqPost, magPost, phsPost, smplPost] = SinTrack.consolidateFMP(trksPost);
smplPost = gapEnd + smplPost;

[~, sortIndPost] = sort(freqPost(1, :));
freqPost = freqPost(:, sortIndPost);
magPost = magPost(:, sortIndPost);
phsPost = phsPost(:, sortIndPost);

%% Match tracks across the gap 

%% Interpolate
numGapFrm = floor(gapLen / hopLen) + 3; % TODO: 3 is not general
dataRange = numGapFrm;
freqGap = zeros(numGapFrm, numTrk);
magGap = zeros(numGapFrm, numTrk);

for trkIter = 1:numTrk
    freqData = [freqPre(end - dataRange + 1:end, trkIter); ...
                freqPost(1:dataRange, trkIter)];
    magData = [magPre(end - dataRange+ 1:end, trkIter); ...
                magPost(1:dataRange, trkIter)];
    dataInd = [1:dataRange, dataRange + numGapFrm + (1:dataRange)];
    queryInd = dataRange + (1:numGapFrm);
    freqGap(:, trkIter) = interp1(dataInd, freqData, queryInd, 'spline');
    magGap(:, trkIter) = interp1(dataInd, magData, queryInd, 'spline');
end

freqGap = [freqPre(end, :); freqGap; freqPost(1, :)];
magGap = [magPre(end, :); magGap; magPost(1, :)];

smplGap = smplPre(end):hopLen:smplPost(1);

%% Plotting
subplot(2, 1, 1);
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

subplot(2, 1, 2);
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
