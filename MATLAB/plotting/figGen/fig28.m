fs = 44100;

freq = freqPre(20:40, :);
smpl = smplPre(20:40, :);

t = 1000 * smpl / fs;

plot(t, freq, 'x', 'Color', 'Black');
hold on;
con = freq(1:10, :);
plot(t(1:10), con, 'Color', 'Black');

hold off;
title('Sinusoid trajectories - frequency');
ylabel('Frequency (Hz)');
xlabel('Time (ms)');
ylim([0, 4000]);
xlim([160, 200])
grid on;

% resizeFigure(gcf, 1, 0.7);
% filename = 'peak_cont';
% saveas(gcf, ['figures\\other\\', filename, '.eps'], 'epsc');
% saveas(gcf, ['figures\\other\\', filename, '.png']);