sig = audioread("audio/Trumpet.novib.mf.A4.wav");
spgm(sig);

ylim([0, 20]);

resizeFigure(gcf, 1, 0.8);
% filename = 'note_spgm';
% saveas(gcf, ['figures\\other\\', filename, '.eps'], 'epsc');
% saveas(gcf, ['figures\\other\\', filename, '.png']);