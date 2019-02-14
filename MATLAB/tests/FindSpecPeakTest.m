classdef FindSpecPeakTest < matlab.unittest.TestCase

    methods (Test)

        function testHighFreqLongSigNoPad(testCase)
            f = 2000;
            l = 2000;
            sig = getSineSig(f, l);
            result = findSpecPeak(sig);

            testCase.verifyEqual(result, f, 'RelTol', 0.01);
        end

        function testLowFreqLongSigNoPad(testCase)
            f = 100;
            l = 2000;
            sig = getSineSig(f, l);
            result = findSpecPeak(sig);

            testCase.verifyEqual(result, f, 'RelTol', 0.01);
        end

        function testHighFreqShortSigNoPad(testCase)
            f = 2000;
            l = 100;
            sig = getSineSig(f, l);
            result = findSpecPeak(sig);

            testCase.verifyEqual(result, f, 'RelTol', 0.01);
        end

        function testHighFreqLongSigWithPad(testCase)
            f = 2000;
            l = 2000;
            nfft = 2048;
            sig = getSineSig(f, l);
            result = findSpecPeak(sig, nfft);

            testCase.verifyEqual(result, f, 'RelTol', 0.01);
        end

        function testLowFreqLongSigWithPad(testCase)
            f = 100;
            l = 2000;
            nfft = 2048;
            sig = getSineSig(f, l);
            result = findSpecPeak(sig, nfft);

            testCase.verifyEqual(result, f, 'RelTol', 0.01);
        end

        function testHighFreqShortSigWithPad(testCase)
            f = 2000;
            l = 100;
            nfft = 2048;
            sig = getSineSig(f, l);
            result = findSpecPeak(sig, nfft);

            testCase.verifyEqual(result, f, 'RelTol', 0.01);
        end

    end

end