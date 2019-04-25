% FULLSINRESYNTH Resynthesise given signal using sinusoidal modelling
global fsGlobal
fs = fsGlobal;
frmLen = 1024;
hopLen = 256;
numTrk = 20;
minTrjLen = 4;

% source = 'synth';
% source = 'flute';
source = 'piano';

if strcmp(source, 'flute')
    sig = audioread('audio/Flute.nonvib.ff.A4.wav');
elseif strcmp(source, 'piano')
    sig = audioread('audio/PianoScale.wav');
else
    l = 200 * frmLen;
    f = [linspace(100, 2000, l).', linspace(1000, 3000, l).', ...
            linspace(14000, 12000, l).'];
    m = [linspace(-14, 0, l).', linspace(0, -6, l).', ...
            -6 + getCosSig(l, 1.3, -10)];

    sig = getCosSig(l, f(:, 1), m(:, 1)) + ...
        getCosSig(l, f(:, 2), m(:, 2)) + ...
        getCosSig(l, f(:, 3), m(:, 3));
end

% spdArgs.trs = -80;
[trks, pitch] = trackSpecPeaks(sig, frmLen, hopLen, numTrk, minTrjLen);%, spdArgs);
[freqEst, magEst, phsEst, smpl] = SinTrack.consolidateFMP(trks);

if strcmp(source, 'synth')
    plotPeakTrackingGT(f, freqEst, m, magEst, smpl);
else
    plotPeakTracking(freqEst, magEst, smpl);
end

figure(2);
plot(smpl, pitch);

initPhs = phsEst(1, :);
sigRest = resynth(freqEst, magEst, initPhs, hopLen);
sCropped = sig(frmLen/2 + 1:frmLen/2 + length(sigRest));
sDiff = sCropped - sigRest;