fs = 44100;
frmLen = 1024;
hopLen = 256;
l = 200 * frmLen;
f = [linspace(100, 2000, l).', linspace(1000, 3000, l).', ...
        linspace(14000, 12000, l).'];
a = [linspace(0.2, 1, l).', linspace(1, 0.5, l).', ...
        0.5 + getCosSig(l, 1.3, 0.3)];

s = getCosSig(l, f(:, 1), a(:, 1)) + ...
    getCosSig(l, f(:, 2), a(:, 2)) + ...
    getCosSig(l, f(:, 3), a(:, 3));

% s = audioread('audio/Flute.nonvib.ff.A4.wav');
[freqEst, ampEst, phsEst, smpl] = trackSpecPeaks(s, frmLen, hopLen, 3);

% plotPeakTrackingGT(f, freqEst, a, ampEst, smpl);
% plotPeakTracking(freqEst, ampEst, smpl);
initPhs = phsEst(1, :);
s1 = resynth(freqEst, ampEst, initPhs, hopLen);
sCropped = s(1+512:end-511);
sDiff = sCropped - s1;