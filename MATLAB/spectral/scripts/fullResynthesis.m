% FULLRESYNTHESIS Resynthesise given signal using sinusoidal modelling

fs = 44100;
frmLen = 1024;
hopLen = 256;
numTrk = 20;

% source = 'synth';
source = 'flute';

if strcmp(source, 'flute')
    s = audioread('audio/Flute.nonvib.ff.A4.wav');
else
    l = 200 * frmLen;
    f = [linspace(100, 2000, l).', linspace(1000, 3000, l).', ...
            linspace(14000, 12000, l).'];
    m = [linspace(-14, 0, l).', linspace(0, -6, l).', ...
            -6 + getCosSig(l, 1.3, -10)];

    s = getCosSig(l, f(:, 1), m(:, 1)) + ...
        getCosSig(l, f(:, 2), m(:, 2)) + ...
        getCosSig(l, f(:, 3), m(:, 3));
end

trks = trackSpecPeaks(s, frmLen, hopLen, numTrk);
[freqEst, magEst, phsEst, smpl] = SinTrack.consolidateFMP(trks);

if strcmp(source, 'flute')
    plotPeakTracking(freqEst, magEst, smpl);
else
    plotPeakTrackingGT(f, freqEst, m, magEst, smpl);
end

initPhs = phsEst(1, :);
s1 = resynth(freqEst, magEst, initPhs, hopLen);
sCropped = s(frmLen/2 + 1:frmLen/2 + length(s1));
sDiff = sCropped - s1;