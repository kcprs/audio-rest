sig = audioread("audio/Flute.nonvib.ff.A4.wav");

[sigDmg, gapStart, gapEnd] = makeGap(sig, 1000);
sigDmg(gapStart:gapEnd) = NaN;

sigZoom = sig(gapStart - 1000: gapEnd + 1000);
sigDmgZoom = sigDmg(gapStart - 2000: gapEnd + 2000);

plot(sigDmgZoom, 'DisplayName', 'Damaged signal');

grid on;
title('Gap of 1000 samples (23 ms for fs = 44100)');
xlabel('Time in samples');
legend;