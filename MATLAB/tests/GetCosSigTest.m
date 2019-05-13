classdef GetCosSigTest < matlab.unittest.TestCase

    methods (Test)

        function testDefaults(testCase)
            % Test default values of input arguments
            global fsGlobal
            fs = fsGlobal;
            freq = 440;
            len = 1000;

            actual = getCosSig(len, freq);
            expected = cos(2 * pi * ((1:len)' - 1) * freq / fs);
            testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-12);
        end

        function testShortCosPhase(testCase)
            % Test phase argument on a simple example
            phases = [0, 0.5 * pi, pi, -0.5 * pi];
            expected = [1; 0; -1; 0; ];

            for iter = 1:length(phases)
                actual = getCosSig(4, 1, 0, phases(iter), 4);

                testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-12);
                expected = circshift(expected, -1);
            end

        end

        function testVectorFreqConst(testCase)
            % Test passing frequency as a vector
            global fsGlobal
            fs = fsGlobal;
            len = 1000;
            freq = 440;
            actual = getCosSig(len, ones(len, 1) * freq, 0, 0);
            expected = cos(2 * pi * ((1:len) - 1)' * freq / fs);

            testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-12);
        end

        function testVectorMag(testCase)
            % Test passing magnitude as a vector
            global fsGlobal
            fs = fsGlobal;
            len = 1000;
            freq = 440;
            mag = linspace(-20, 0, len)';
            actual = getCosSig(len, freq, mag, 0);

            indx = (1:len)';
            expected = 10.^(mag(indx) / 20) .* ...
                cos(2 * pi * (indx - 1) * freq / fs);

            testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-12);
        end

        function testEndPhase(testCase)
            % Test if end phase matches prediction when frequency varies over time
            global fsGlobal
            fs = fsGlobal;
            len = 1000;
            numTests = 100;
            startFreq = linspace(100, 10000, numTests);

            for iter = 1:numTests
                freq = linspace(startFreq(iter), 20, len);
                sig = getCosSig(len, freq);
                w = 2 * pi * freq / fs;
                expected = mod(sum(w(1:end - 1)), 2 * pi);
                actual = acos(sig(end));

                if sig(end) > sig(end - 1)
                    actual = 2 * pi - actual;
                end

                testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-12);
            end

        end

    end

end
