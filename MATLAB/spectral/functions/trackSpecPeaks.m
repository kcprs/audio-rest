function [freq, amp, phs, smpl] = trackSpecPeaks(sig, frmLen, hopLen, spdArgs)
    %TRACKSPECPEAKS Track spectral peaks in given signal over time
    %   [freq, amp, phs, smpl] = trackSpecPeaks(sig, frmLen, hopLen, spdArgs)
    %   returns matrices containing frequency, amplitude and phase
    %   information of spectral peaks in signal sig over time. Matrices
    %   freq, amp and phs are of size numFrames x npks, where numFrames is
    %   the number of frames analysed and npks is the number of spectral
    %   peaks detected. Vector smpl contains indexes of centre samples of
    %   frames that were analysed. Arguments frmLen and hopLen are
    %   respectively the length of analysis frames and of hop between
    %   consecutive frames. spdArgs is a struct containing arguments for
    %   spectral peak detection. Available fields for spdArgs are listed
    %   below:
    %   
    %   field name | default value | description
    %   -----------|---------------|----------------------------------------
    %    trs       | -20 (dBFS)   | Treshold magnitude for peak detection 
    %    nfft      | 2048          | FFT size
    %    npks      | 1000          | Number of peaks to be found
    %    fs        | 44100         | Sampling frequency

    [trs, nfft, npks, fs] = unpackSPDArgs(spdArgs);

    numFrames = floor((length(sig) - frmLen) / hopLen) + 1;

    freq = zeros(numFrames, npks);
    amp = zeros(numFrames, npks);
    phs = zeros(numFrames, npks);
    smpl = zeros(numFrames, 1);

    for it = 1:numFrames
        sInd = 1 + (it - 1) * hopLen;
        smpl(it) = sInd + ceil(frmLen / 2);
        [freq(it, :), amp(it, :), phs(it, :)] = ...
            findSpecPeaks(sig(sInd:sInd + frmLen - 1), trs, npks, nfft, fs);
    end

end

function [trs, nfft, npks, fs] = unpackSPDArgs(spdArgs)

    if isfield(spdArgs, 'trs')
        trs = spdArgs.trs;
        spdArgs = rmfield(spdArgs, 'trs');
    else
        trs = -20;
    end

    if isfield(spdArgs, 'nfft')
        nfft = spdArgs.nfft;
        spdArgs = rmfield(spdArgs, 'nfft');
    else
        nfft = 2048;
    end

    if isfield(spdArgs, 'npks')
        npks = spdArgs.npks;
        spdArgs = rmfield(spdArgs, 'npks');
    else
        npks = 1000;
    end

    if isfield(spdArgs, 'fs')
        fs = spdArgs.fs;
        spdArgs = rmfield(spdArgs, 'fs');
    else
        fs = 44100;
    end

    if numel(fieldnames(spdArgs)) ~= 0
        msg = "Unrecognised parameters passed to trackSpecPeak: ";
        fieldNames = strjoin(fieldnames(spdArgs), ', ');
        error(strcat(msg, fieldNames));
    end

end
