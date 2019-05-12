sig = audioread("audio/Flute.vib.ff.A4.wav");
sig = sig(20000:20500);

gapLen = 20;
[sigDmg, gapStart, gapEnd] = makeGap(sig, gapLen);

plotStart = gapStart - round(2 * gapLen);
plotEnd = gapEnd + round(2 * gapLen);

dataRange = 10;
dataInd = [(gapStart - dataRange):(gapStart - 1), (gapEnd + 1):(gapEnd + dataRange)].';
data = sig(dataInd);

dataInd = dataInd - gapStart;

p = polyfit(dataInd, data, 8);

sigGap = polyval(p, (gapStart:gapEnd) - gapStart);

sigGap = [sig(gapStart - 1), sigGap, sig(gapEnd + 1)];

sigNaN = sig;
sigNaN(gapStart:gapEnd) = NaN;
plot(sigNaN)
hold on;
set(gca, 'ColorOrderIndex', 1);
plot(gapStart - 1:gapEnd + 1, sig(gapStart - 1:gapEnd + 1), '--');
plot((gapStart - 1:gapEnd + 1), sigGap, 'Color', [221, 49, 26] / 256);
xlabel('Time in samples');
ylabel('Amplitude');
xlim([plotStart, plotEnd]);
grid on;
hold off;

% filename = '20_missing_samples';
% resizeFigure(gcf, 1, 0.7);
% saveas(gcf, ['figures\\other\\', filename, '.eps'], 'epsc');
% saveas(gcf, ['figures\\other\\', filename, '.png']);
