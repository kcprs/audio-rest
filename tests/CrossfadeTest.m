classdef CrossfadeTest < matlab.unittest.TestCase

    methods (Test)
        function testOnes(testCase)
            len = 100;
            sig1 = ones(len, 1);
            sig2 = sig1;

            actual = crossfade(sig1, sig2);
            expected = ones(len, 1);
            testCase.verifyEqual(actual, expected);
        end     
    end

end
