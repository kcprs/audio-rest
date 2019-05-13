p1 = 0.8 * exp(1j * 0.2 * pi);
p2 = 0.99 * exp(1j * 0.45 * pi);
p3 = 0.87 * exp(1j * 0.8 * pi);

p1conj = 0.8 * exp(-1j * 0.2 * pi);
p2conj = 0.99 * exp(-1j * 0.45 * pi);
p3conj = 0.87 * exp(-1j * 0.8 * pi);

p = [p1, p2, p3, p1conj, p2conj, p3conj];
[b, a] = zp2tf([], p, 1);

fig1 = figure(1);
zplane(b, a);
hold on;
title('Z-plane')
grid on;

text(real(p1) + 0.06, imag(p1) + 0.02, 'p_{1} = 0.8e^{0.2\pij}', ...
    'FontSize', 12, 'Color', [214, 63, 8] / 256);
text(real(p2) + 0.06, imag(p2) + 0.02, 'p_{2} = 0.99e^{0.45\pij}', ...
    'FontSize', 12, 'Color', [8, 170, 27] / 256);
text(real(p3) + 0.06, imag(p3) + 0.02, 'p_{3} = 0.87e^{0.8\pij}', ...
    'FontSize', 12, 'Color', [8, 35, 169] / 256);

xl = xlim;
yl = ylim;

r = 2;
ang = 0.1 * pi;
plot([0, r * cos(ang)], [0, r * sin(ang)], '--', 'Color', [0.7, 0.7, 0.7]);

r = 0.5;
ang = 0.1 * pi;
angPl = linspace(0, ang, 100);
plot([0, r * cos(angPl)], [0, r * sin(angPl)], 'Color', [0.7, 0.7, 0.7]);
text(0.35, 0.08, '\omega', 'FontSize', 14, 'Color', [0.7, 0.7, 0.7]);

hold off;

xlim(xl);
ylim(yl);

fig2 = figure(2);
freqz(b, a, 1000);
[h, w] = freqz(b, a, 1000);
hPlot = 20 * log10(abs(h));
wPlot = linspace(0, 1, 1000);
plot(wPlot, hPlot);
title('Magnitude Response');
xlabel('Normalised Frequency \omega (\times \pi rad/sample)');
ylabel('Magnitude (dB)');
grid on;

text(0.1, 4, 'Peak due to p_{1}', 'Color', [214, 63, 8] / 256);
text(0.48, 27, 'Peak due to p_{2}', 'Color', [8, 170, 27] / 256);
text(0.7, 5, 'Peak due to p_{3}', 'Color', [8, 35, 169] / 256);

% filename = 'digFilt_zPlane';
% saveas(fig1, ['figures\\other\\', filename, '.eps'], 'epsc');
% saveas(fig1, ['figures\\other\\', filename, '.png']);

% filename = 'digFilt_magResp';
% saveas(fig2, ['figures\\other\\', filename, '.eps'], 'epsc');
% saveas(fig2, ['figures\\other\\', filename, '.png']);
