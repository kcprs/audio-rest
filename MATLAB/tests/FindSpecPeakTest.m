classdef FindSpecPeakTest < matlab.unittest.TestCase

    methods (Test)

        function testHighFreqLongSig(testCase)
            f = 2000;
            l = 10000;
            sig = getSineSig(f, l);
            result = findSpecPeak(sig);

            testCase.verifyEqual(result, f, 'RelTol', 0.01);
        end

        function testLowFreqLongSig(testCase)
            f = 100;
            l = 10000;
            sig = getSineSig(f, l);
            result = findSpecPeak(sig);

            testCase.verifyEqual(result, f, 'RelTol', 0.05);
        end

        function testHighFreqShortSig(testCase)
            f = 2000;
            l = 100;
            sig = getSineSig(f, l);
            result = findSpecPeak(sig);

            testCase.verifyEqual(result, f, 'RelTol', 0.01);
        end

        function testLowFreqShortSig(testCase)
            f = 100;
            l = 400;
            sig = getSineSig(f, l);
            result = findSpecPeak(sig);

            testCase.verifyEqual(result, f, 'RelTol', 0.1);
        end

    end

end