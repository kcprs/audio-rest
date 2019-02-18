classdef GetCosSigTest < matlab.unittest.TestCase

    methods (Test)

    function testCos(testCase)
        freq = 440;
        len = 1000;
        fs = 44100;

        actual = getCosSig(len, freq);
        expected = cos(2 * pi * ((1:len)' - 1) * freq / fs);
        testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-12);
    end

    end

end