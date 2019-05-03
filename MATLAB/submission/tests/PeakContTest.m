classdef PeakContTest < matlab.unittest.TestCase

    methods (Test)

        function testBasic(testCase)
            numTrk = 3;
            numFrm = 5;

            trks(1, numTrk) = SinTrack();

            for iter = 1:numel(trks)
                trks(iter).initTrk(numFrm);
            end

            pkFreq = [101, 104, 107, 110, 112; ...
                    101, 105, 106, 109, 114; ...
                    102, 104, 107, 108, 111; ...
                    103, 104, 106, 109, 112; ...
                    102, 105, 105, 110, 111];
            pkMag = [100, 90, 80, 70, 60; ...
                    101, 91, 81, 71, 61; ...
                    102, 92, 82, 72, 62; ...
                    104, 94, 84, 74, 64; ...
                    105, 95, 85, 75, 65];
            pkPhs = pkFreq;

            for iter = 1:size(pkFreq, 1)
                [trks.frmCursor] = deal(iter);
                peakCont(trks, pkFreq(iter, :), pkMag(iter, :), ...
                    pkPhs(iter, :), iter, NaN);
            end

            [freq, mag, phs, ~] = SinTrack.consolidateFMP(trks);

            expFreq = pkFreq(:, 1:3);
            expMag = pkMag(:, 1:3);
            expPhs = pkPhs(:, 1:3);

            testCase.verifyEqual(freq, expFreq);
            testCase.verifyEqual(mag, expMag);
            testCase.verifyEqual(phs, expPhs);
        end

        function testDeathBirth(testCase)
            numTrk = 3;
            numFrm = 5;

            trks(1, numTrk) = SinTrack();

            for iter = 1:numel(trks)
                trks(iter).initTrk(numFrm);
            end

            pkFreq = {[101, 104, 107]; ...
                [101, 105]; ...
                [102, 104, 107]; ...
                [103, 104, 106]; ...
                [102, 105, 105]};
            pkMag = {[100, 90, 80]; ...
                [101, 91]; ...
                [102, 92, 82]; ...
                [104, 94, 84]; ...
                [105, 95, 85]};
            pkPhs = pkFreq;

            for iter = 1:size(pkFreq, 1)
                [trks.frmCursor] = deal(iter);
                peakCont(trks, pkFreq{iter}, pkMag{iter}, ...
                    pkPhs{iter}, iter, NaN);
            end

            [freq, mag, phs, ~] = SinTrack.consolidateFMP(trks);

            expFreq = [101, 104, 107; ...
                        101, 105, NaN; ...
                        102, 104, 107; ...
                        103, 104, 106; ...
                        102, 105, 105];
            expMag = [100, 90, 80; ...
                    101, 91, NaN; ...
                    102, 92, 82; ...
                    104, 94, 84; ...
                    105, 95, 85];
            expPhs = expFreq;

            testCase.verifyEqual(freq, expFreq);
            testCase.verifyEqual(mag, expMag);
            testCase.verifyEqual(phs, expPhs);
        end

    end

end
