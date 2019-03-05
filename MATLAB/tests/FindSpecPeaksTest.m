classdef FindSpecPeaksTest < matlab.unittest.TestCase

    methods (Test)

        function testHighFreqLongSigNoPad(testCase)
            l = 2000;
            f = 2000;
            a = 0.7;
            m = 20 * log10(a);
            thrs = 20 * log10(a) - 2;
            sig = getCosSig(l, f, m);
            p = acos(sig(ceil(l / 2) + 1) / a);
            [freqEst, magEst, phsEst] = findSpecPeaks(sig, thrs, 1);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(magEst, m, 'AbsTol', 1);
            testCase.verifyEqual(phsEst, p, 'AbsTol', 0.01);
        end

        function testLowFreqLongSigNoPad(testCase)
            l = 2000;
            f = 100;
            a = 0.4;
            m = 20 * log10(a);
            thrs = 20 * log10(a) - 2;
            sig = getCosSig(l, f, m);
            p = acos(sig(ceil(l / 2) + 1) / a);
            [freqEst, magEst, phsEst] = findSpecPeaks(sig, thrs, 1);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(magEst, m, 'AbsTol', 1);
            testCase.verifyEqual(phsEst, p, 'AbsTol', 0.01);
        end

        function testHighFreqShortSigNoPad(testCase)
            l = 100;
            f = 2000;
            a = 0.8;
            m = 20 * log10(a);
            thrs = 20 * log10(a) - 2;
            sig = getCosSig(l, f, m);
            p = acos(sig(ceil(l / 2) + 1) / a);
            [freqEst, magEst, phsEst] = findSpecPeaks(sig, thrs, 1);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(magEst, m, 'AbsTol', 1);
            testCase.verifyEqual(phsEst, p, 'AbsTol', 0.02);
        end

        function testHighFreqLongSigWithPad(testCase)
            l = 2000;
            f = 2000;
            a = 0.9;
            m = 20 * log10(a);
            thrs = 20 * log10(a) - 2;
            nfft = 2048;
            sig = getCosSig(l, f, m);
            p = acos(sig(ceil(l / 2) + 1) / a);
            [freqEst, magEst, phsEst] = findSpecPeaks(sig, thrs, 1, nfft);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(magEst, m, 'AbsTol', 1);
            testCase.verifyEqual(phsEst, p, 'AbsTol', 0.01);
        end

        function testLowFreqLongSigWithPad(testCase)
            l = 2000;
            f = 100;
            a = 1;
            m = 20 * log10(a);
            thrs = 20 * log10(a) - 2;
            nfft = 2048;
            sig = getCosSig(l, f, m);
            p = acos(sig(ceil(l / 2) + 1) / a);
            [freqEst, magEst, phsEst] = findSpecPeaks(sig, thrs, 1, nfft);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(magEst, m, 'AbsTol', 1);
            testCase.verifyEqual(phsEst, p, 'AbsTol', 0.01);
        end

        function testHighFreqShortSigWithPad(testCase)
            l = 100;
            f = 2000;
            a = 0.2;
            m = 20 * log10(a);
            thrs = 20 * log10(a) - 2;
            nfft = 2048;
            sig = getCosSig(l, f, m);
            p = acos(sig(ceil(l / 2) + 1) / a);
            [freqEst, magEst, phsEst] = findSpecPeaks(sig, thrs, 1, nfft);

            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(magEst, m, 'AbsTol', 1);
            testCase.verifyEqual(phsEst, p, 'AbsTol', 0.01);
        end

        function testEmptyWithDefaults(testCase)
            l = 1000;
            npks = 10;
            sig = zeros(l, 1);
            [freqEst, ~, ~] = findSpecPeaks(sig, -2, npks);
            testCase.verifyEqual(freqEst, NaN(1, npks));
        end

        function testThreePeaks(testCase)
            l = 1000;
            nfft = 2048;
            f = [200, 500, 1000];
            a = [0.4, 0.2, 0.6];
            m = 20 * log10(a);
            thrs = 20 * log10(min(a)) - 2;
            sig = getCosSig(l, f(1), m(1)) + ...
                getCosSig(l, f(2), m(2)) + ...
                getCosSig(l, f(3), m(3));

            [freqEst, magEst, ~] = findSpecPeaks(sig, thrs, 3, nfft);
            [freqEst, I] = sort(freqEst);
            magEst = magEst(I);
            testCase.verifyEqual(freqEst, f, 'RelTol', 0.01);
            testCase.verifyEqual(magEst, m, 'AbsTol', 1);
        end

    end

end
