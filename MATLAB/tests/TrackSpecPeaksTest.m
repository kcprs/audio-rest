classdef TrackSpecPeaksTest < matlab.unittest.TestCase

    methods (Test)

        function testBasic(testCase)
            fs = 44100;
            l = 2 * fs;
            f = [linspace(100, 1000, l).', linspace(1000, 3000, l).', ...
                    linspace(14000, 12000, l).'];
            a = [linspace(0.2, 1, l).', linspace(1, 0.5, l).', ...
                    0.5 + getCosSig(l, 1.3, 0.3)];

            s = getCosSig(l, f(:, 1), a(:, 1)) + ...
                getCosSig(l, f(:, 2), a(:, 2)) + ...
                getCosSig(l, f(:, 3), a(:, 3));

            spdParams.npks = 3;
            [freqEst, ampEst, ~, smpl] = ...
                trackSpecPeaks(s, 1024, 256, spdParams);
            testCase.verifyEqual(freqEst, f(smpl, :), 'RelTol', 0.01);
            testCase.verifyEqual(ampEst, a(smpl, :), 'RelTol', 0.01);
            % plotPeakTrackingGT(f, freqEst, a, ampEst, smpl);
        end

    end

end
