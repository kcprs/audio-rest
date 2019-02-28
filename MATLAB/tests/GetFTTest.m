classdef GetFTTest < matlab.unittest.TestCase

    methods (Test)

        function testBasic(testCase)
            l = 1000;
            f = 2;
            a = 1;
            p = 0;
            fs = 1000;
            s = getCosSig(l, f, a, p, fs);

            [mag, phs] = getFT(s);

            [~, peakBin] = max(mag);

            testCase.verifyEqual(peakBin, f * l / fs + 1);
            testCase.verifyEqual(mag(peakBin), 0, 'AbsTol', 10e-3);
            testCase.verifyEqual(phs(peakBin), ...
                acos(s(ceil(l / 2) + 1) / a), 'AbsTol', 10e-7);
        end

    end

end
