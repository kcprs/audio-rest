classdef GetSineSigTest < matlab.unittest.TestCase

    methods (Test)

        function testDefaultFs(testCase)
            freq = 440;
            len = 1000;
            fs = 44100;

            actual = getSineSig(freq, len);
            expected = sin(2 * pi * ((1:len)' - 1) * freq / fs);
            testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-13);
        end

        function testShortSineZeroPhase(testCase)
            actual = getSineSig(1, 4, 1, 0, 4);
            expected = [0; 1; 0; -1];

            testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-13);
        end

        function testShortSineHalfPiPhase(testCase)
            actual = getSineSig(1, 4, 1, 0.5 * pi, 4);
            expected = [1; 0; -1; 0];

            testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-13);
        end

        function testShortSinePiPhase(testCase)
            actual = getSineSig(1, 4, 1, pi, 4);
            expected = [0; -1; 0; 1];

            testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-13);
        end

        function testShortSineMinusHalfPiPhase(testCase)
            actual = getSineSig(1, 4, 1, -0.5 * pi, 4);
            expected = [-1; 0; 1; 0];

            testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-13);
        end

        function testVectorFreqConst(testCase)
            fs = 44100;
            len = 1000;
            freq = 440;
            actual = getSineSig(ones(len, 1) * freq, len, 1, 0);
            expected = sin(2 * pi * (1:len)' * freq / fs);

            testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-13);
        end

        function testVectorFreq(testCase)
            fs = 44100;
            len = 1000;
            f0 = 100;
            f1 = 200;
            freq = linspace(f0, f1, len)';
            phase = 0.5 * pi - 2 * pi * f0 / fs;
            actual = getSineSig(freq, len, 1, phase);
            t = linspace(0, len / fs, len)';
            expected = chirp(t, f0, len / fs, f1);

            err = expected - actual;
            disp(['max abs error:', num2str(max(abs(err)))]);

            testCase.verifyEqual(actual, expected, 'AbsTol', 0.02);
        end

        function testVectorAmp(testCase)
            fs = 44100;
            len = 1000;
            freq = 440;
            amp = linspace(0.1, 1, len)';
            actual = getSineSig(freq, len, amp, 0);

            indx = (1:len)';
            expected = amp(indx) .* sin(2 * pi * (indx - 1) * freq / fs);

            testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-13);
        end

    end

end
