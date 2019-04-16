sig = getSineSig(1000, 90);
[sigDmg, gapStart, gapEnd] = makeGap(sig, 100);
sigDmg(gapStart:gapEnd) = NaN;

plot(sigDmg, 'DisplayName', 'Damaged signal');
hold on;

linFix = linspace(sigDmg(gapStart - 1), sigDmg(gapEnd + 1), gapEnd - gapStart + 3);
fixInd = (gapStart-1):(gapEnd+1);

plot(fixInd, linFix, '--', 'DisplayName', 'Simple linear reconstruction');
hold off;
grid on;
title('Gap of 100 samples (2.3 ms for fs = 44100)');
xlabel('Time in samples');
legend;