classdef FindSpecPeakTest < matlab.unittest.TestCase

    methods (Test)

        function testHighFreqLongSigNoPad(testCase)
            l = 2000;
            f = 2000;
            a = 0.7;
            sig = getSineSig(l, f, a);
            [freqEst, ampEst] = findSpecPeak(sig);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(ampEst, a, 'RelTol', 0.01);
        end

        function testLowFreqLongSigNoPad(testCase)
            l = 2000;
            f = 100;
            a = 0.4;
            sig = getSineSig(l, f, a);
            [freqEst, ampEst] = findSpecPeak(sig);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(ampEst, a, 'RelTol', 0.02);
        end

        function testHighFreqShortSigNoPad(testCase)
            l = 100;
            f = 2000;
            a = 0.8;
            sig = getSineSig(l, f, a);
            [freqEst, ampEst] = findSpecPeak(sig);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(ampEst, a, 'RelTol', 0.02);
        end

        function testHighFreqLongSigWithPad(testCase)
            l = 2000;
            f = 2000;
            a = 0.9;
            nfft = 2048;
            sig = getSineSig(l, f, a);
            [freqEst, ampEst] = findSpecPeak(sig, nfft);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(ampEst, a, 'RelTol', 0.01);
        end

        function testLowFreqLongSigWithPad(testCase)
            l = 2000;
            f = 100;
            a = 1;
            nfft = 2048;
            sig = getSineSig(l, f, a);
            [freqEst, ampEst] = findSpecPeak(sig, nfft);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(ampEst, a, 'RelTol', 0.01);
        end

        function testHighFreqShortSigWithPad(testCase)
            l = 100;
            f = 2000;
            a = 0.2;
            nfft = 2048;
            sig = getSineSig(l, f, a);
            [freqEst, ampEst] = findSpecPeak(sig, nfft);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(ampEst, a, 'RelTol', 0.015);
        end

        function testLowRes(testCase)
            f = 30;
            l = 1000;
            sig = getSineSig(l, f);
            [freqEst, ~] = findSpecPeak(sig);

            testCase.verifyEqual(freqEst, 0);
        end

    end

end
