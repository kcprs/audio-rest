function [trks, pitch] = trackSpecPeaks(sig, frmLen, hopLen, numTrk, minTrjLen, trs)
    %TRACKSPECPEAKS Track spectral peaks in given signal over time
    %   [trks, pitch] = trackSpecPeaks(sig, frmLen, hopLen, numTrk, minTrjLen, trs)
    %   returns SinTrack objects containing frequency, magnitude and phase
    %   information of numTrk spectral peaks in signal sig over time and
    %   pitch vector containing pitch estimate at each analysis frame.
    %   Arguments frmLen and hopLen are respectively the length of analysis
    %   frames and of hop between consecutive frames. The argument trs is
    %   the threshold magnitude for peak detection.
    %
    %   [trks] = trackSpecPeaks(sig, frmLen, hopLen, numTrk, minTrjLen)
    %   uses default values of trs = -Inf.

    if nargin < 6
        trs = -Inf;
    end

    % Calculate number of frames that will fit in the the given signal
    numFrames = floor((length(sig) - frmLen) / hopLen) + 1;

    % Prepare vector of numTrk SinTrack objects
    trks(1, numTrk) = SinTrack();

    for iter = 1:numel(trks)
        trks(iter).initTrk(numFrames);
        trks(iter).setMinTrjLen(minTrjLen);
    end

    % Prepare pitch vector
    pitch = zeros(numFrames, 1);

    % Get frequency, magnitude and phase estimates for each frame.
    % Pass them to the peak continuation function, which assigns peaks to
    % sinusoid tracks.
    for frmIter = 1:numFrames
        % Update frame cursors
        [trks.frmCursor] = deal(frmIter);

        % Compute frame start sample index
        frmStart = 1 + (frmIter - 1) * hopLen;

        % Compute index of centre sample in frame
        smpl = frmStart + ceil(frmLen / 2);

        % Detect spectral peaks in frame
        [pkFreq, pkMag, pkPhs] = ...
            findSpecPeaks(sig(frmStart:frmStart + frmLen - 1), trs, 0);

        % Save pitch in frame based on freqs of 5 highest peaks
        [~, highestPks] = sort(pkMag, 'desc');
        pitchEstFreq = pkFreq(highestPks);
        pitchEstFreq = pitchEstFreq(1:min(5, length(pitchEstFreq)));
        pitchEst = estPitch(pitchEstFreq, 3);
        pitch(frmIter) = pitchEst;

        % Assign spectral peaks to SinTracks
        peakCont(trks, pkFreq, pkMag, pkPhs, smpl, pitchEst);
    end

end

function [trs, nfft] = unpackSPDArgs(spdArgs)

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

    % Throw error if there are leftover fields in the given struct
    if numel(fieldnames(spdArgs)) ~= 0
        msg = "Unrecognised parameters passed to trackSpecPeak: ";
        fieldNames = strjoin(fieldnames(spdArgs), ', ');
        error(strcat(msg, fieldNames));
    end

end
