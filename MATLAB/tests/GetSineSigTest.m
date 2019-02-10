classdef GetSineSigTest < matlab.unittest.TestCase

    methods (Test)

        function testLongSineZeroPhase(testCase)
            freq = 440;
            len = 1000;
            fs = 44100;

            actual = getSineSig(freq, len);
            expected = sin(2 * pi * ((1:len)' - 1) * freq / fs);
            testCase.verifyEqual(actual, expected);
        end

        function testShortSineZeroPhase(testCase)
            actual = getSineSig(1, 4, 0, 4);
            expected = [0; 1; 0; -1];

            testCase.verifyEqual(actual, expected, 'AbsTol', 0.00001);
        end

        function testShortSineHalfPiPhase(testCase)
            actual = getSineSig(1, 4, 0.5 * pi, 4);
            expected = [1; 0; -1; 0];

            testCase.verifyEqual(actual, expected, 'AbsTol', 0.00001);
        end

        function testShortSinePiPhase(testCase)
            actual = getSineSig(1, 4, pi, 4);
            expected = [0; -1; 0; 1];

            testCase.verifyEqual(actual, expected, 'AbsTol', 0.00001);
        end

        function testShortSineMinusHalfPiPhase(testCase)
            actual = getSineSig(1, 4, -0.5 * pi, 4);
            expected = [-1; 0; 1; 0];

            testCase.verifyEqual(actual, expected, 'AbsTol', 0.00001);
        end

    end

end
