classdef SinTrack < handle
    %SINTRACK A single sinusoidal track in spectral modelling synthesis

    properties
        freq; % Vector containing frequency values at consecutive frames
        mag; % Vector containing magnitude values at consecutive frames
        phs; % Vector containing phase values at consecutive frames
        smpl; % Vector containing indexes of centre samples of frames
        frmCursor; % Cursor for iterating over frames
        sinceBirthCntr; % Counter of frames since last track birth
        minTrjLen; % Min length (in frames) of single continuous trajectory
        pitchEst; % Vector containing pitch estimate values at each frame
    end

    methods (Access = public)

        function initTrk(obj, numFrm)
            % INITTRK Initialise track
            obj.freq = zeros(numFrm, 1);
            obj.mag = zeros(numFrm, 1);
            obj.phs = zeros(numFrm, 1);
            obj.smpl = zeros(numFrm, 1);
            obj.pitchEst = zeros(numFrm, 1);
            obj.sinceBirthCntr = 0;
            obj.minTrjLen = 0;
        end

        function pkScore = getPkScore(obj, pkFreq, pkMag, maxJump)
            % GETPKSCORE Compute peak score for each peak in current frame
            % based on the previous peak in track
            [prevFreq, ~, ~] = obj.getRelIndFMP(-1);

            if isnan(prevFreq)
                % If new track, pick peak with largest magnitude
                % Shift by fs to let continuing tracks to be selected first
                % since peaks are assigned from lowest to highest score.
                pkScore = 44100 - pkMag;
            else
                % Otherwise pick closest peak within maxJump range
                freqDist = abs(pkFreq - prevFreq);
                freqDist(freqDist > maxJump) = NaN;
                pkScore = freqDist;
            end

        end

        function setMinTrjLen(obj, minTrjLen)
            % SETMINTRJLEN Set min length (in frames) for a track trajectory
            obj.minTrjLen = minTrjLen;
        end

        function setFMP(obj, freq, mag, phs)
            % SETFMP Set frequency, magnitude and phase values for
            % current frame

            % Set values
            obj.freq(obj.frmCursor) = freq;
            obj.mag(obj.frmCursor) = mag;
            obj.phs(obj.frmCursor) = phs;

            % Check if track dies in this frame
            if isnan(freq) || obj.frmCursor == length(obj.freq)
                % Track died - check if it was longer than minimum length
                % If not, clear from current frame until most recent birth
                if obj.sinceBirthCntr < obj.minTrjLen
                    clrCursor = obj.frmCursor;

                    while clrCursor > 0 && (~isnan(obj.freq(clrCursor)) ...
                            || clrCursor == obj.frmCursor)
                        obj.freq(clrCursor) = NaN;
                        obj.mag(clrCursor) = NaN;
                        obj.phs(clrCursor) = NaN;

                        clrCursor = clrCursor - 1;
                    end

                end

                % Reset counter
                obj.sinceBirthCntr = 0;
            else
                % Otherwise increase counter
                obj.sinceBirthCntr = obj.sinceBirthCntr + 1;
            end

        end

        function saveSmpl(obj, smpl)
            % SAVESMPL Save index of the centre sample of the current frame
            obj.smpl(obj.frmCursor) = smpl;
        end

        function savePitch(obj, pitch)
            % SAVEPITCH Save pitch estimate for current frame
            obj.pitchEst(obj.frmCursor) = pitch;
        end

        function reverse(obj, sigLen)
            % REVERSE Reverse track information in time
            obj.freq = flipud(obj.freq);
            obj.mag = flipud(obj.mag);
            obj.phs = -flipud(obj.phs);
            obj.smpl = flipud(obj.smpl);
            obj.smpl = sigLen - obj.smpl + 1;
            obj.pitchEst = flipud(obj.pitchEst);
        end

        function harmNum = getHarmNum(obj, frmInd)
            % GETHARNUM Returns N, where the frequency stored in this track
            % at frame frmInd is the Nth harmonic of pitch estimate at this
            % frame. Use frmInd < 1 to select last frame.

            if frmInd < 1
                frmInd = length(obj.freq);
            end

            harmNum = round(obj.freq(frmInd) / obj.pitchEst(frmInd));
        end

    end

    methods (Access = private)

        function [prevF, prevM, prevP] = getRelIndFMP(obj, relInd)
            % GETRELINDFMP Return frequency, magnitude and phase values
            % at index relInd relative to current frame
            if obj.frmCursor + relInd >= 1
                prevF = obj.freq(obj.frmCursor + relInd);
                prevM = obj.mag(obj.frmCursor + relInd);
                prevP = obj.phs(obj.frmCursor + relInd);
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
