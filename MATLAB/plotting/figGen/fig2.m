sig = audioread("audio/Flute.vib.ff.A4.wav");
sig = sig(20000:25000);

gapLen = 1000;
[sigDmg, gapStart, gapEnd] = makeGap(sig, gapLen);

plotStart = gapStart - round(2 * gapLen);
plotEnd = gapEnd + round(2 * gapLen);

sigNaN = sig;
sigNaN(gapStart:gapEnd) = NaN;
plot(sigNaN)
hold on;
% set(gca, 'ColorOrderIndex', 1);
% plot(gapStart - 1:gapEnd + 1, sig(gapStart - 1:gapEnd + 1), '--');
% plot((gapStart - 1:gapEnd + 1), sigGap, 'Color', [221, 49, 26] / 256);
xlabel('Time in samples');
ylabel('Amplitude');
xlim([plotStart, plotEnd]);
text(2400, 0, '?', 'FontSize', 20)
grid on;
hold off;

resizeFigure(gcf, 1, 0.7);
% filename = '1000_missing_samples';
% saveas(gcf, ['figures\\other\\', filename, '.eps'], 'epsc');
% saveas(gcf, ['figures\\other\\', filename, '.png']);
