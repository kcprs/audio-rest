% ARINTERP Interpolate sinusoidal tracks using AR Modelling

%% Set variable values
global fsGlobal
fs = fsGlobal;
frmLen = 2048;
gapLen = 10 * frmLen;
sigLen = 6 * frmLen;
hopLen = 256;
numTrk = 20;
minTrkLen = 10;
resOrdAR = 100;
pitchOrdAR = 2;
magOrdAR = 2;
envOrdAR = 2;
almostNegInf = -100;
envWeight = 1;

% source = "saw";
% source = "sin";
% source = "matchTest";
% source = "audio/Cello.arco.mf.sulC.A2.wav";
% source = "audio/Flute.nonvib.ff.A4.wav";
% source = "audio/Flute.vib.ff.A4.wav";
% source = "audio/Guitar.mf.sulD.A3.wav";
% source = "audio/Guitar.mf.sulD.D3.wav";
% source = "audio/Horn.mf.A2.wav";
% source = "audio/Horn.mf.A4.wav";
% source = "audio/PianoScale.wav";
source = "audio/Trumpet.novib.mf.A4.wav";
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
    f = 100; % + 2 * getSineSig(sigLen, 8);
    sig = getCosSig(sigLen, f, -6);
    sig = sig + getCosSig(sigLen, 2 * f, -12, pi);
    sig = sig + getCosSig(sigLen, 3 * f, -15, pi / 2);
    % sig = sig + getCosSig(sigLen, 4 * f, -18, 0.75 * pi);
    % sig = sig + getCosSig(sigLen, 5 * f, -21);
    % sig = sig + 0.1 * randn(size(sig)) ./ 6;
elseif strcmp(source, 'matchTest')
    f = 200;
    sig1 = getCosSig(sigLen / 2, f, -6);
    sig1 = sig1 + getCosSig(sigLen / 2, 2 * f, -12, pi);
    sig1 = sig1 + getCosSig(sigLen / 2, 3 * f, -15, pi / 2);

    sig2 = getCosSig(sigLen / 2, f, -6);
    sig2 = sig2 + getCosSig(sigLen / 2, 2 * f + 50, -12, pi);
    sig2 = sig2 + getCosSig(sigLen / 2, 5 * f, -15, pi / 2);

    sig = [sig1; sig2];
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

% Restore residual
% Synthesise sinusoidal gap signal
% sigGapLen = smplGap(end) - smplGap(1) + 1;
% sinGap = resynth(freqGap, magGap, phsPre(end, :), hopLen, phsPost(1, :));

% % Synthesise residual of last frame of pre- section
% resPre = getResidual(sigPre(end - frmLen + 1:end), freqPre(end, :), ...
    %     magPre(end, :), phsPre(end, :));

% % Synthesise residual of first frame of post- section
% resPost = getResidual(sigPost(1:frmLen), freqPost(1, :), magPost(1, :), ...
    %     phsPost(1, :));

% % Morph between pre- and post- residuals over the gap
% resGap = wfbar(resPre, resPost, gapLen, resOrdAR);

%% Add reconstructed sinusoidal and residual
sigGap = sinGap; % + resGap;

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
title(['Sinusoidal tracks - frequency (gap len: ', num2str(gapLen), ')']);
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
title(['Sinusoidal tracks - magnitude (gap len: ', num2str(gapLen), ')']);
ylabel('Magnitude in dBFS');
xlabel('Time in samples');
grid on;
