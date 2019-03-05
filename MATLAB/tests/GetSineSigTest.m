classdef GetSineSigTest < matlab.unittest.TestCase

    methods (Test)

        function testDefaultFs(testCase)
            freq = 440;
            len = 1000;
            fs = 44100;

            actual = getSineSig(len, freq);
            expected = sin(2 * pi * ((1:len)' - 1) * freq / fs);
            testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-13);
        end

        function testShortSineZeroPhase(testCase)
            actual = getSineSig(4, 1, 0, 0, 4);
            expected = [0; 1; 0; -1];

            testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-13);
        end

        function testShortSineHalfPiPhase(testCase)
            actual = getSineSig(4, 1, 0, 0.5 * pi, 4);
            expected = [1; 0; -1; 0];

            testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-13);
        end

        function testShortSinePiPhase(testCase)
            actual = getSineSig(4, 1, 0, pi, 4);
            expected = [0; -1; 0; 1];

            testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-13);
        end

        function testShortSineMinusHalfPiPhase(testCase)
            actual = getSineSig(4, 1, 0, -0.5 * pi, 4);
            expected = [-1; 0; 1; 0];

            testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-13);
        end

        function testVectorFreqConst(testCase)
            fs = 44100;
            len = 1000;
            freq = 440;
            actual = getSineSig(len, ones(len, 1) * freq, 0, 0);
            expected = sin(2 * pi * ((1:len) - 1)' * freq / fs);

            testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-13);
        end

        function testVectorMag(testCase)
            fs = 44100;
            len = 1000;
            freq = 440;
            mag = linspace(-20, 0, len)';
            actual = getSineSig(len, freq, mag, 0);

            indx = (1:len)';
            expected = 10.^(mag(indx) / 20) .* ...
                sin(2 * pi * (indx - 1) * freq / fs);

            testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-13);
        end

        function testEndPhase(testCase)
            fs = 44100;
            len = 1000;
            freq = linspace(10, 20, len);
            sig = getSineSig(len, freq);
            w = 2 * pi * freq / fs;
            expected = mod(sum(w(1:end - 1)), 2 * pi);
            actual = asin(sig(end));

            if sig(end) < sig(end - 1)
                actual = pi - actual;
            end

            testCase.verifyEqual(actual, expected);
        end

    end

end
