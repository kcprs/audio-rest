classdef GetFTTest < matlab.unittest.TestCase

    methods (Test)

        function testBasic(testCase)
            l = 1000;
            f = 2;
            a = 1;
            m = 20 * log10(a);
            p = 0;
            fs = 1000;
            s = getCosSig(l, f, m, p, fs);

            [mag, phs, nfft] = getFT(s);

            [~, peakBin] = max(mag);

            testCase.verifySize(mag, [1, nfft]);
            testCase.verifyEqual(peakBin, f * nfft / fs + 1);
            testCase.verifyEqual(mag(peakBin), m, 'AbsTol', 10e-3);
            testCase.verifyEqual(phs(peakBin), ...
                acos(s(ceil(l / 2) + 1) / a), 'AbsTol', 10e-7);
        end

    end

end
