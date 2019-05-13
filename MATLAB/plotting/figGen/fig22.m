fs = 44100;
sigLen = fs * 100/1000;
sigStart = 10000;
gapLen = 2000;
fitLen = 1000;
arOrd = 500;

sig = audioread('audio/Flute.nonvib.ff.A4.wav');
sig = sig(sigStart:sigStart + sigLen - 1);
sig = sig / max(sig);
[~, gapStart, gapEnd] = makeGap(sig, gapLen);

t = 1000 * (1:sigLen) / fs + 500;

n = (1:gapLen)';
w1 = 0.5 * (1 - cos(pi * (gapLen + n) / gapLen));
w2 = 1 - w1;

fig1 = figure(1);
sigNaN = sig;
sigNaN(gapStart + 1:gapEnd - 1) = NaN;
plot(t, sigNaN);
xlabel('Time (ms)');
ylabel('Amplitude');
xl = xlim;
yl = [-1.1, 1.1];
ylim(yl);
grid on;

fig2 = figure(2);
[gap1, ~] = burgPredict(sig, arOrd, gapStart, gapLen, fitLen);
gap1 = gap1 .* w1;
plot(t(1:gapStart), sig(1:gapStart));
hold on;
plot(t(gapStart:gapEnd), gap1, 'Color', [221, 49, 26] / 256);
p2 = plot(t(gapStart:gapEnd), w1, 'DisplayName', 'Cross-fade function', ...
    'Color', 'Black');
hold off;
xlabel('Time (ms)');
ylabel('Amplitude');
xlim(xl);
legend(p2);
ylim(yl);
grid on;

fig3 = figure(3);
[gap2, ~] = burgPredict(sig, arOrd, gapEnd, -gapLen, fitLen);
gap2 = gap2 .* w2;
plot(t(gapEnd:end), sig(gapEnd:end));
hold on;
plot(t(gapStart:gapEnd), gap2, 'Color', [221, 49, 26] / 256);
p3 = plot(t(gapStart:gapEnd), w2, 'DisplayName', 'Cross-fade function', ...
    'Color', 'Black');
hold off;
xlabel('Time (ms)');
ylabel('Amplitude');
xlim(xl);
legend(p3, 'Location', 'northwest');
ylim(yl);
grid on;

fig4 = figure(4);
plot(t, sigNaN);
hold on;
plot(t(gapStart:gapEnd), sig(gapStart:gapEnd), 'Color', [221, 49, 26] / 256);
hold off;
xlabel('Time (ms)');
ylabel('Amplitude');
xlim(xl);
ylim(yl);
grid on;

resizeFigure(fig1, 2, 0.5);
resizeFigure(fig2, 2, 0.5);
resizeFigure(fig3, 2, 0.5);
resizeFigure(fig4, 2, 0.5);

% filename = 'wfbar_gap';
% saveas(fig1, ['figures\\other\\', filename, '.eps'], 'epsc');
% saveas(fig1, ['figures\\other\\', filename, '.png']);

% filename = 'wfbar_fwd';
% saveas(fig2, ['figures\\other\\', filename, '.eps'], 'epsc');
% saveas(fig2, ['figures\\other\\', filename, '.png']);

% filename = 'wfbar_bwd';
% saveas(fig3, ['figures\\other\\', filename, '.eps'], 'epsc');
% saveas(fig3, ['figures\\other\\', filename, '.png']);

% filename = 'wfbar_rest';
% saveas(fig4, ['figures\\other\\', filename, '.eps'], 'epsc');
% saveas(fig4, ['figures\\other\\', filename, '.png']);
