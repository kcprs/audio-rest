fs = 44100;
sigLen = 2048 + 256;
sig = getCosSig(sigLen, 1000);

aLen = 256;
aSt = (sigLen - aLen) / 2;
aDFT = 20 * log10(abs(fft(sig(aSt:aSt + aLen - 1) .* hann(aLen))));
fa = linspace(0, fs, aLen);

bLen = 1024;
bSt = (sigLen - bLen) / 2;
bDFT = 20 * log10(abs(fft(sig(bSt:bSt + bLen - 1) .* hann(bLen))));
fb = linspace(0, fs, bLen);

cLen = 2048;
cSt = (sigLen - cLen) / 2;
cDFT = 20 * log10(abs(fft(sig(cSt:cSt + cLen - 1) .* hann(cLen))));
fc = linspace(0, fs, cLen);

t = 1000 * (1:sigLen) / fs;

fig1 = figure(1);
plot(fa, aDFT, 'Color', [221, 49, 26] / 256, 'DisplayName', [num2str(aLen), ' samples']);
hold on;
plot(fb, bDFT, 'Color', [31, 140, 12] / 256, 'DisplayName', [num2str(bLen), ' samples']);
plot(fc, cDFT, 'Color', [66, 134, 244] / 256, 'DisplayName', [num2str(cLen), ' samples']);
hold off;
ylabel('Magnitude (dB)');
xlabel('Frequency (Hz)');
xlim([0, 2000]);
legend;
grid on;

fig2 = figure(2);
plot(t, sig, 'Color', 'black');
ylabel('Amplitude');
xlabel('Time (ms)');
xlim([0, 1000 * sigLen / fs])

dim = [1000 * aSt / fs, -1.1, 1000 * aLen / fs, 2.2];
rectangle('Position', dim, 'EdgeColor', [221, 49, 26] / 256, 'LineWidth', 1);

dim = [1000 * bSt / fs, -1.2, 1000 * bLen / fs, 2.4];
rectangle('Position', dim, 'EdgeColor', [31, 140, 12] / 256, 'LineWidth', 1);

dim = [1000 * cSt / fs, -1.3, 1000 * cLen / fs, 2.6];
rectangle('Position', dim, 'EdgeColor', [66, 134, 244] / 256, 'LineWidth', 1);
grid on;

filename = 'uncertainty_f';
resizeFigure(fig1, 1, 0.9);
saveas(fig1, ['figures\\other\\', filename, '.eps'], 'epsc');
saveas(fig1, ['figures\\other\\', filename, '.png']);

filename = 'uncertainty_t';
resizeFigure(fig2, 1, 0.9);
saveas(fig2, ['figures\\other\\', filename, '.eps'], 'epsc');
saveas(fig2, ['figures\\other\\', filename, '.png']);
