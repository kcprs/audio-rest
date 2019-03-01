classdef FindSpecPeaksTest < matlab.unittest.TestCase

    methods (Test)

        function testHighFreqLongSigNoPad(testCase)
            l = 2000;
            f = 2000;
            a = 0.7;
            thrs = 20 * log10(a) - 2;
            sig = getCosSig(l, f, a);
            p = acos(sig(ceil(l / 2) + 1) / a);
            [freqEst, ampEst, phsEst] = findSpecPeaks(sig, thrs, 1);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(ampEst, a, 'RelTol', 0.01);
            testCase.verifyEqual(phsEst, p, 'AbsTol', 0.01);
        end

        function testLowFreqLongSigNoPad(testCase)
            l = 2000;
            f = 100;
            a = 0.4;
            thrs = 20 * log10(a) - 2;
            sig = getCosSig(l, f, a);
            p = acos(sig(ceil(l / 2) + 1) / a);
            [freqEst, ampEst, phsEst] = findSpecPeaks(sig, thrs, 1);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(ampEst, a, 'RelTol', 0.02);
            testCase.verifyEqual(phsEst, p, 'AbsTol', 0.01);
        end

        function testHighFreqShortSigNoPad(testCase)
            l = 100;
            f = 2000;
            a = 0.8;
            thrs = 20 * log10(a) - 2;
            sig = getCosSig(l, f, a);
            p = acos(sig(ceil(l / 2) + 1) / a);
            [freqEst, ampEst, phsEst] = findSpecPeaks(sig, thrs, 1);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(ampEst, a, 'RelTol', 0.02);
            testCase.verifyEqual(phsEst, p, 'AbsTol', 0.02);
        end

        function testHighFreqLongSigWithPad(testCase)
            l = 2000;
            f = 2000;
            a = 0.9;
            thrs = 20 * log10(a) - 2;
            nfft = 2048;
            sig = getCosSig(l, f, a);
            p = acos(sig(ceil(l / 2) + 1) / a);
            [freqEst, ampEst, phsEst] = findSpecPeaks(sig, thrs, 1, nfft);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(ampEst, a, 'RelTol', 0.01);
            testCase.verifyEqual(phsEst, p, 'AbsTol', 0.01);
        end

        function testLowFreqLongSigWithPad(testCase)
            l = 2000;
            f = 100;
            a = 1;
            thrs = 20 * log10(a) - 2;
            nfft = 2048;
            sig = getCosSig(l, f, a);
            p = acos(sig(ceil(l / 2) + 1) / a);
            [freqEst, ampEst, phsEst] = findSpecPeaks(sig, thrs, 1, nfft);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(ampEst, a, 'RelTol', 0.02);
            testCase.verifyEqual(phsEst, p, 'AbsTol', 0.01);
        end

        function testHighFreqShortSigWithPad(testCase)
            l = 100;
            f = 2000;
            a = 0.2;
            thrs = 20 * log10(a) - 2;
            nfft = 2048;
            sig = getCosSig(l, f, a);
            p = acos(sig(ceil(l / 2) + 1) / a);
            [freqEst, ampEst, phsEst] = findSpecPeaks(sig, thrs, 1, nfft);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(ampEst, a, 'RelTol', 0.015);
            testCase.verifyEqual(phsEst, p, 'AbsTol', 0.01);
        end

        function testEmptyWithDefaults(testCase)
            l = 1000;
            npks = 10;
            sig = zeros(l, 1);
            [freqEst, ~, ~] = findSpecPeaks(sig, -2, npks);
            testCase.verifyEqual(freqEst, zeros(1, npks));
        end

        function testThreePeaks(testCase)
            l = 1000;
            nfft = 2048;
            f = [200, 500, 1000];
            a = [0.4, 0.2, 0.6];
            thrs = 20 * log10(min(a)) - 2;
            sig = getCosSig(l, f(1), a(1)) + ...
                getCosSig(l, f(2), a(2)) + ...
                getCosSig(l, f(3), a(3));

            [freqEst, ampEst, ~] = findSpecPeaks(sig, thrs, 3, nfft);
            [freqEst, I] = sort(freqEst);
            ampEst = ampEst(I);
            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(ampEst, a, 'RelTol', 0.01);
        end

    end

end
