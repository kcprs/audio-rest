classdef fftMagTest < matlab.unittest.TestCase

    methods (Test)

        function testBasic(testCase)
            s = getCosSig(1000, 100, 1, 0, 1000);
            magSpec = fftMag(s, 1000);
            [peak, peakInd] = max(magSpec);

            testCase.verifyEqual(peak, 0, 'AbsTol', 0.01);
            testCase.verifyEqual(peakInd, 101);
        end

    end

end