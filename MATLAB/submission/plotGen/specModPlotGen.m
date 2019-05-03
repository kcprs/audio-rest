% FULLSINRESYNTH Resynthesise given signal using spectral modelling
global fsGlobal
fs = fsGlobal;
frmLen = 2048;
hopLen = 256;
numTrk = 30;
minTrjLen = 10;

% source = "saw";
% source = "flute";
% source = "flute.vib";
source = "trumpet";
% source = "trumpet.vib";

switch source
    case "saw"
        sigLen = 20 * frmLen;

        sig = getSawSig(sigLen, 440);
    case "flute"
        sig = audioread('audio/Flute.nonvib.ff.A4.wav');
    case "flute.vib"
        sig = audioread('audio/Flute.vib.ff.A4.wav');
    case "trumpet"
        sig = audioread('audio/Trumpet.novib.mf.A4.wav');
    case "trumpet.vib"
        sig = audioread('audio/Trumpet.vib.mf.A4.wav');
end

[trks, pitch] = trackSpecPeaks(sig, frmLen, hopLen, numTrk, minTrjLen);
[freqEst, magEst, phsEst, smpl] = SinTrack.consolidateFMP(trks);

%% Plotting
figSpgm = figure(1);
spgm(sig);
freqLim = [0, 10000] / 1000;
ylim(freqLim);
tLim = xlim;

switch source
    case "saw"
        desc = 'Sawtooth wave @ 440 Hz';
    case "flute"
        desc = 'Flute note @ 440 Hz';
    case "flute.vib"
        desc = 'Flute note @ 440 Hz with vibrato and tremolo';
    case "trumpet"
        desc = 'Trumpet note @ 440 Hz';
    case "trumpet.vib"
        desc = 'Trumpet note @ 440 Hz with vibrato and tremolo';
end
title([desc, '- spectrogram']);

% Convert time to ms
if strcmp(source, "saw")
    t = 1000 * smpl / fs;
else
    t = smpl / fs;
end

figFreq = figure(2);
plot(t, freqEst / 1000);
title([desc, ' - frequency trajectories']);

if strcmp(source, "saw")
    xlabel('Time (ms)');
else
    xlabel('Time (s)');
end

ylabel('Frequency in kHz');
ylim(freqLim);
xlim(tLim);
grid on;

figMag = figure(3);
plot(t, magEst);
title([desc, ' - magnitude trajectories']);

if strcmp(source, "saw")
    xlabel('Time (ms)');
else
    xlabel('Time (s)');
end

ylabel('Magnitude (dBFS)');

if ~strcmp(source, "saw")
        magLim = ylim;
        magLim(1) = -100;
        ylim(magLim);
end

xlim(tLim);
grid on;

% Save figures
switch source
    case "saw"
        sigDesc = 'saw';
    case "flute"
        sigDesc = 'flute';
    case "flute.vib"
        sigDesc = 'fluteVib';
    case "trumpet"
        sigDesc = 'trumpet';
    case "trumpet.vib"
        sigDesc = 'trumpetVib';
end

filename = [sigDesc, '_trkFreq_minLen_', num2str(minTrjLen)];
figPos = get(figFreq, 'Position');
figPos(3) = 1.6 * figPos(3);
figPos(4) = 0.6 * figPos(4);
set(figFreq, 'Position', figPos);
savefig(figFreq, ['figures\\spectralModelling\\modelling\\', filename, '.fig']);
saveas(figFreq, ['figures\\spectralModelling\\modelling\\', filename, '.png']);
saveas(figFreq, ['figures\\spectralModelling\\modelling\\', filename, '.eps'], 'epsc');
close(figFreq);

filename = [sigDesc, '_trkMag_minLen_', num2str(minTrjLen)];
figPos = get(figMag, 'Position');
figPos(3) = 1.6 * figPos(3);
figPos(4) = 0.6 * figPos(4);
set(figMag, 'Position', figPos);
savefig(figMag, ['figures\\spectralModelling\\modelling\\', filename, '.fig']);
saveas(figMag, ['figures\\spectralModelling\\modelling\\', filename, '.png']);
saveas(figMag, ['figures\\spectralModelling\\modelling\\', filename, '.eps'], 'epsc');
close(figMag);

filename = [sigDesc, '_spgm_minLen_', num2str(minTrjLen)];
figPos = get(figSpgm, 'Position');
figPos(3) = 1.6 * figPos(3);
figPos(4) = 0.6 * figPos(4);
set(figSpgm, 'Position', figPos);
savefig(figSpgm, ['figures\\spectralModelling\\modelling\\', filename, '.fig']);
saveas(figSpgm, ['figures\\spectralModelling\\modelling\\', filename, '.png']);
saveas(figSpgm, ['figures\\spectralModelling\\modelling\\', filename, '.eps'], 'epsc');
close(figSpgm);
