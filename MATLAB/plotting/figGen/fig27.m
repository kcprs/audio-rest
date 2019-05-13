sigLen = 32;
nfft = 2048;

win = hann(sigLen);
omega = 2 * 2 * nfft / sigLen;
omega = omega + 8; % Botch to make overlap look nicer

w1 = nfft / 4 - round(omega / 2);
w2 = w1 + omega;

w1Plot = 2 * pi * w1 / nfft;
w2Plot = 2 * pi * w2 / nfft;

winSpec = 20 * log10(abs(fft(win, nfft)));
% winSpec = real(fft(win, nfft));
winSpec = fftshift(winSpec);
winSpec1 = circshift(winSpec, w1);
winSpec2 = circshift(winSpec, w2);

w = linspace(-pi, pi, nfft);

plot(w, winSpec1);
hold on;
plot(w, winSpec2);
yl = ylim;
plot([w1Plot, w1Plot], [-100, 100], '--', 'Color', 'Black');
plot([w2Plot, w2Plot], [-100, 100], '--', 'Color', 'Black');

y = max(winSpec);

hold off;
grid on;
xlim([0, pi]);
ylim([-80, 40]);
% ylim(yl);
xlabel('Normalised Frequency \omega (rad/sample)');
annotation('doublearrow', [0.4, 0.6], [0.9, 0.9]);
% 'String', '\Deltaf = B_{M}'

% resizeFigure(fig4, 2, 0.5);

% filename = 'wfbar_gap';
% saveas(fig1, ['figures\\other\\', filename, '.eps'], 'epsc');
% saveas(fig1, ['figures\\other\\', filename, '.png']);
