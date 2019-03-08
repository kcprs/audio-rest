% GAPRESYNTHESIS Restore gap in given signal using sinusoidal modelling

fs = 44100;
gapLen = 1000;
frmLen = 1024;
sigLen = 10 * frmLen;
hopLen = 256;
numTrk = 1;

% source = 'synth';
% source = 'flute';
source = 'sin';

if strcmp(source, 'flute')
    sig = audioread('audio/Flute.nonvib.ff.A4.wav');
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

[sigDmg, gapStart, gapEnd] = makeGap(sig, gapLen);
sigPre = sigDmg(1:gapStart - 1);
sigPre = flipud(sigPre);
trksPre = trackSpecPeaks(sigPre, frmLen, hopLen, numTrk);
sigPre = flipud(sigPre);

for trkIter = 1:numTrk
    trksPre(trkIter).reverse(length(sigPre))
end

[freqPre, magPre, phsPre, smplPre] = SinTrack.consolidateFMP(trksPre);

numHopGap = ceil(gapLen / hopLen) + 2;

freqGap = repmat(freqPre(end, :), [numHopGap, 1]);
magGap = repmat(magPre(end, :), [numHopGap, 1]);

sigGap = resynth(freqGap, magGap, phsPre(end, :), hopLen);

xfSmplPre = smplPre(end);

sigRest = zeros(size(sig));
fadeSigPre = [ones(xfSmplPre, 1); linspace(1, 0, frmLen / 2 + 1).'];
sigRest(1:length(sigPre)) = sigPre .* fadeSigPre;

fadeSigGap = [linspace(0, 1, frmLen / 2).'; ...
            ones(length(sigGap) - frmLen / 2, 1)];
sigRest(xfSmplPre:xfSmplPre + length(sigGap) - 1) = ...
    sigRest(xfSmplPre:xfSmplPre + length(sigGap) - 1) + sigGap .* fadeSigGap;

plot(sigPre, '--', 'DisplayName', 'sigPre');
hold on;
plot([NaN(xfSmplPre, 1); sigGap], ':', 'DisplayName', 'sigGap');
plot(sigRest, 'DisplayName', 'sigRest');
plot(xfSmplPre, 0, 'x', 'DisplayName', 'transition');
legend;
hold off;