classdef GetChirpSigTest < matlab.unittest.TestCase

    methods (Test)

        function testChirp(testCase)
            f0 = 0;
            f1 = 500;
            fs = 44100;
            duration = 2;

            t = linspace(0, 2, duration * fs)';
            expected = chirp(t, 0, 1, f1 / duration);
            actual = getChirpSig(f0, f1, fs * duration);
            testCase.verifyEqual(expected, actual);
        end

    end

end
