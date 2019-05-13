fs = 44100;
sigLen = fs;

partLen = sigLen / 4;

sig = [getCosSig(partLen, 16000);
    getCosSig(partLen, 12000);
    getCosSig(partLen, 10000);
    getCosSig(partLen, 8000)];

fig1 = figure(1);
spgm(sig, true, 4096);

fig2 = figure(2);
spgm(sig, true, 128);

% resizeFigure(fig1, 1, 0.8);
% filename = 'spgm_long_frame';
% saveas(fig1, ['figures\\other\\', filename, '.eps'], 'epsc');
% saveas(fig1, ['figures\\other\\', filename, '.png']);

% resizeFigure(fig2, 1, 0.8);
% filename = 'spgm_short_frame';
% saveas(fig2, ['figures\\other\\', filename, '.eps'], 'epsc');
% saveas(fig2, ['figures\\other\\', filename, '.png']);
