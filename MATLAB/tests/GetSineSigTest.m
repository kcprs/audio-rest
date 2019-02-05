classdef GetSineSigTest < matlab.unittest.TestCase

    methods (Test)

        function testSine(testCase)
            freq = 440;
            len = 1000;
            fs = 44100;

            actual = getSineSig(freq, len);
            expected = sin(2 * pi * (1:len)' * freq / fs);
            testCase.verifyEqual(actual, expected);
        end

    end

end
