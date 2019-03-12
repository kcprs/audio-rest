classdef SinTrack < handle
    %SINTRACK A single sinusoidal track in spectral modelling synthesis

    properties
        freq; % Vector containing frequency values at consecutive frames
        mag; % Vector containing magnitude values at consecutive frames
        phs; % Vector containing phase values at consecutive frames
        smpl; % Vector containing indexes of centre samples of frames
        frmCursor; % Cursor for iterating over frames
    end

    methods (Access = public)

        function allocateFrm(obj, numFrm)
            % ALLOCATEFRM Allocate frequency, magnitude, phase & smpl vectors
            obj.freq = zeros(numFrm, 1);
            obj.mag = zeros(numFrm, 1);
            obj.phs = zeros(numFrm, 1);
            obj.smpl = zeros(numFrm, 1);
        end

        function pkScore = getPkScore(obj, pkFreq, pkMag, maxJump)
            % GETPKSCORE Compute peak score for each peak in current frame
            % based on the previous peak in track
            [prevFreq, ~, ~] = obj.getPreviousFMP();

            if isnan(prevFreq)
                % If new track, pick peak with largest magnitude
                pkScore = 44100 - pkMag;
            else
                % Otherwise pick closest peak within maxJump range
                freqDist = abs(pkFreq - prevFreq);
                freqDist(freqDist > maxJump) = NaN;
                pkScore = freqDist;
            end

        end

        function setFMP(obj, freq, mag, phs)
            % SETFMP Set frequency, magnitude and phase values for
            % current frame
            obj.freq(obj.frmCursor) = freq;
            obj.mag(obj.frmCursor) = mag;
            obj.phs(obj.frmCursor) = phs;
        end

        function saveSmpl(obj, smpl)
            % SAVESMPL Save index of the centre sample of the current frame
            obj.smpl(obj.frmCursor) = smpl;
        end

        function reverse(obj, sigLen)
            % REVERSE Reverse track information in time
            obj.freq = flipud(obj.freq);
            obj.mag = flipud(obj.mag);
            obj.phs = -flipud(obj.phs);
            obj.smpl = flipud(obj.smpl);
            obj.smpl = sigLen - obj.smpl + 1;
        end

    end

    methods (Access = private)

        function [prevF, prevM, prevP] = getPreviousFMP(obj)
            % GETPREVIOUSFMP Return frequency, magnitude and phase values
            % of the previous peak in track
            if obj.frmCursor > 1
                prevF = obj.freq(obj.frmCursor - 1);
                prevM = obj.mag(obj.frmCursor - 1);
                prevP = obj.phs(obj.frmCursor - 1);
            else
                prevF = NaN;
                prevM = NaN;
                prevP = NaN;
            end

        end

    end

    methods (Static)

        function [fMat, mMat, pMat, smpl] = consolidateFMP(trkVector)
            % CONSOLIDATEFMP Create matrices of frequency, magnitude and
            % phase values from a vector of SinTrack objects
            numTrk = numel(trkVector);
            numFrm = length(trkVector(1).freq);

            fMat = zeros(numFrm, numTrk);
            mMat = zeros(numFrm, numTrk);
            pMat = zeros(numFrm, numTrk);

            for trkIter = 1:numTrk
                fMat(:, trkIter) = trkVector(trkIter).freq;
                mMat(:, trkIter) = trkVector(trkIter).mag;
                pMat(:, trkIter) = trkVector(trkIter).phs;
            end

            smpl = trkVector(1).smpl;

        end

    end

end
