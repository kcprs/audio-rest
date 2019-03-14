classdef TrackSpecPeaksTest < matlab.unittest.TestCase

    methods (Test)

        function testBasic(testCase)
            fs = 44100;
            l = 2 * fs;
            f = [linspace(100, 1000, l).', linspace(1000, 3000, l).', ...
                    linspace(14000, 12000, l).'];
            m = [linspace(-14, 0, l).', linspace(0, -6, l).', ...
                    -6 + getCosSig(l, 1.3, -10)];

            s = getCosSig(l, f(:, 1), m(:, 1)) + ...
                getCosSig(l, f(:, 2), m(:, 2)) + ...
                getCosSig(l, f(:, 3), m(:, 3));

            trks = trackSpecPeaks(s, 1024, 256, 3, 0);
            [freqEst, magEst, ~, smpl] = SinTrack.consolidateFMP(trks);

            [~, sortInd] = sort(freqEst(1, :));
            freqEst = freqEst(:, sortInd);
            magEst = magEst(:, sortInd);

            testCase.verifyEqual(freqEst, f(smpl, :), 'RelTol', 0.01);
            testCase.verifyEqual(magEst, m(smpl, :), 'AbsTol', 1);
        end

    end

end
