classdef FindSpecPeaksIterTest < matlab.unittest.TestCase

    methods (Test)

        function testEmptyWithDefaults(testCase)
            l = 1000;
            sig = zeros(l, 1);
            specPeaks = findSpecPeaksIter(sig, -6);
            testCase.verifyEqual(specPeaks, double.empty(0, 2));
        end

        function testThreePeaks(testCase)
            l = 1000;
            nfft = 2048;
            f = [200; 500; 1000];
            a = [0.4; 0.2; 0.6];
            sig = getSineSig(l, f(1), a(1)) + ...
                getSineSig(l, f(2), a(2)) + ...
                getSineSig(l, f(3), a(3));

            specPeaks = findSpecPeaksIter(sig, -20, nfft);
            [fEst, I] = sort(specPeaks(:, 1));
            aEst = specPeaks(:, 2);
            aEst = aEst(I);
            testCase.verifyEqual(fEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(aEst, a, 'RelTol', 0.01);
        end

    end

end
