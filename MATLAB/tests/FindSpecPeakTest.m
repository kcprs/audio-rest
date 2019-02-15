classdef FindSpecPeakTest < matlab.unittest.TestCase

    methods (Test)

        function testHighFreqLongSigNoPad(testCase)
            f = 2000;
            l = 2000;
            sig = getSineSig(l, f);
            [freqEst, ~, ampEst] = findSpecPeak(sig);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(ampEst, 1, 'RelTol', 0.01);
        end

        function testLowFreqLongSigNoPad(testCase)
            f = 100;
            l = 2000;
            sig = getSineSig(l, f);
            [freqEst, ~, ampEst] = findSpecPeak(sig);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(ampEst, 1, 'RelTol', 0.011);
        end

        function testHighFreqShortSigNoPad(testCase)
            f = 2000;
            l = 100;
            sig = getSineSig(l, f);
            [freqEst, ~, ampEst] = findSpecPeak(sig);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(ampEst, 1, 'RelTol', 0.01);
        end

        function testHighFreqLongSigWithPad(testCase)
            f = 2000;
            l = 2000;
            nfft = 2048;
            sig = getSineSig(l, f);
            [freqEst, ~, ampEst] = findSpecPeak(sig, nfft);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(ampEst, 1, 'RelTol', 0.01);
        end

        function testLowFreqLongSigWithPad(testCase)
            f = 100;
            l = 2000;
            nfft = 2048;
            sig = getSineSig(l, f);
            [freqEst, ~, ampEst] = findSpecPeak(sig, nfft);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(ampEst, 1, 'RelTol', 0.01);
        end

        function testHighFreqShortSigWithPad(testCase)
            f = 2000;
            l = 100;
            nfft = 2048;
            sig = getSineSig(l, f);
            [freqEst, ~, ampEst] = findSpecPeak(sig, nfft);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(ampEst, 1, 'RelTol', 0.015);
        end

    end

end