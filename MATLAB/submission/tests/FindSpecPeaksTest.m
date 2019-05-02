classdef FindSpecPeaksTest < matlab.unittest.TestCase

    methods (Test)

        function testEstAccuracy(testCase)
            l = 2048;
            numTests = 1000;

            freqExp = linspace(50, 20000, numTests);
            magExp = linspace(0, -60, numTests);

            for iter = 1:numTests
                sig = getCosSig(l, freqExp(iter), magExp(iter));
                [freqEst, magEst, ~] = findSpecPeaks(sig, -Inf, 1);

                testCase.verifyEqual(freqEst, freqExp(iter), 'RelTol', 0.001);
                ampEst = 10^(magEst/20);
                ampExp = 10^(magExp(iter)/20);
                % Relax tolerance to 1% for amplitude 
                testCase.verifyEqual(ampEst, ampExp, 'RelTol', 0.01);
            end
        end

    end

end
