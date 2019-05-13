classdef GetMSETest < matlab.unittest.TestCase

    methods (Test)

        function testZero(testCase)
            sigLen = 1000;
            sig = getSinSig(sigLen, 440);

            expected = 0;
            actual = getMSE(sig, sig);

            testCase.verifyEqual(actual, expected);
        end

        function testOne(testCase)
            sigLen = 1000;
            sig = ones(sigLen, 1);
            pred = zeros(sigLen, 1);

            expected = 1;
            actual = getMSE(sig, pred);

            testCase.verifyEqual(actual, expected);
        end

    end

end