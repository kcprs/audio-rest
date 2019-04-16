fs = 4096;
len = 4096;
freqDiv = 16;
sig = getSineSig(len, fs / freqDiv);
win = hann(len);

sigWin = sig .* win;

subplot(2, 1, 1);
plot(sigWin);
title("Windowed sine wave at frequency f0");
set(gca, 'xtick', []);

nfft = len * 10;
[mag, ~] = getFT(sig, nfft, 'hann');
subplot(2, 1, 2);
plot(mag(1:460));

title("Spectrum of the window shifted to f0");

[~, maxInd] = max(mag);
names = {'f0'};
set(gca, 'xtick', maxInd, 'xticklabel', names)
ylabel('Magnitude spectrum in dBFS');
