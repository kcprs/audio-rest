classdef PeakContTest < matlab.unittest.TestCase

    methods (Test)

        function testBasic(testCase)
            numTrk = 3;
            numFrm = 5;

            trks(1, numTrk) = SinTrack();

            for iter = 1:numel(trks)
                trks(iter).allocate(numFrm);
            end

            pkFreq = [1, 4, 7, 10, 12;
                1, 5, 6, 9, 14;
                2, 4, 7, 8, 11;
                3, 4, 6, 9, 12;
                2, 5, 5, 10, 11];
            pkMag = [1, 4, 7, 10, 12;
                1, 5, 6, 9, 14;
                2, 4, 7, 8, 11;
                3, 4, 6, 9, 12;
                2, 5, 5, 10, 11];
            pkPhs = [1, 4, 7, 10, 12;
                1, 5, 6, 9, 14;
                2, 4, 7, 8, 11;
                3, 4, 6, 9, 12;
                2, 5, 5, 10, 11];

            for iter = 1:size(pkFreq, 1)
                [trks.frmCursor] = deal(iter);
                peakCont(trks, pkFreq(iter, :), pkMag(iter, :), ...
                    pkPhs(iter, :), iter);
            end

            [freq, mag, phs, ~] = SinTrack.consolidateFMP(trks);

            expFreq = [1, 4, 7;
                    1, 5, 6;
                    2, 4, 7;
                    3, 4, 6;
                    2, 5, 5];
            expMag = [1, 4, 7;
                1, 5, 6;
                2, 4, 7;
                3, 4, 6;
                2, 5, 5];
            expPhs = [1, 4, 7;
                1, 5, 6;
                2, 4, 7;
                3, 4, 6;
                2, 5, 5];

            testCase.verifyEqual(freq, expFreq);
            testCase.verifyEqual(mag, expMag);
            testCase.verifyEqual(phs, expPhs);
        end

    end

end
