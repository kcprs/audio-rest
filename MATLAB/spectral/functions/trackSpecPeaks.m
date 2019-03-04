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
    %    trs       | -Inf (dBFS)   | Treshold magnitude for peak detection
    %    nfft      | 2048          | FFT size
    %    npks      | 1000          | Number of peaks to be found
    %    fs        | 44100         | Sampling frequency

    % Unpack struct with spectral peak detection arguments
    [trs, nfft, npks, fs] = unpackSPDArgs(spdArgs);

    % Calculate number of frames that will fit in the the given signal
    numFrames = floor((length(sig) - frmLen) / hopLen) + 1;
    
    freq = zeros(numFrames, npks);
    amp = zeros(numFrames, npks);
    phs = zeros(numFrames, npks);
    smpl = zeros(numFrames, 1);

    % Get frequency, amplitude and phase estimates for each frame.
    % Save the centre sample of each frame in vector smpl.
    for frmIter = 1:numFrames
        frmStart = 1 + (frmIter - 1) * hopLen;
        smpl(frmIter) = frmStart + ceil(frmLen / 2);
        [frmFreq, frmAmp, frmPhs] = ...
            findSpecPeaks(sig(frmStart:frmStart + frmLen - 1), ...
            trs, npks, nfft, fs);

        % Peak continuation - connect closest peaks between frames
        for pkIter = 1:npks
            prevFrmIterMod = mod(frmIter - 2, numFrames) + 1;
            [~, clstPkIndx] = min(abs(frmFreq - freq(prevFrmIterMod, pkIter)));
            freq(frmIter, pkIter) = frmFreq(clstPkIndx);
            frmFreq(clstPkIndx) = NaN;
            amp(frmIter, pkIter) = frmAmp(clstPkIndx);
            phs(frmIter, pkIter) = frmPhs(clstPkIndx);
        end

    end

end

function [trs, nfft, npks, fs] = unpackSPDArgs(spdArgs)

    if isfield(spdArgs, 'trs')
        trs = spdArgs.trs;
        spdArgs = rmfield(spdArgs, 'trs');
    else
        trs = -Inf;
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
        npks = 10;
    end

    if isfield(spdArgs, 'fs')
        fs = spdArgs.fs;
        spdArgs = rmfield(spdArgs, 'fs');
    else
        fs = 44100;
    end

    % Throw error if there are leftover fields in the given struct
    if numel(fieldnames(spdArgs)) ~= 0
        msg = "Unrecognised parameters passed to trackSpecPeak: ";
        fieldNames = strjoin(fieldnames(spdArgs), ', ');
        error(strcat(msg, fieldNames));
    end

end
