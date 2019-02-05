function output = crossfade(sig1, sig2)
    %CROSSFADE Crossfades two signals using a raised cosine weight function.
    %   output = CROSSFADE(sig1, sig2) applies weight function to signals
    %   sig1 (weight == 1 at index 0) and sig2 (weight == 0 at index 0),
    %   then sums them and returns the result.
    
    if length(sig1) ~= length(sig2)
        error('Given signals are not the same length!');
    end
    
    len = length(sig1);
    n = (1:len)';
    
    % Raised cosine weight function as described in:
    % W. Etter, "Restoration of a discrete-time signal segment by
    % interpolation based on the left-sided and right-sided autoregressive
    % parameters", IEEE Transactions on Signal Processing,
    % vol. 44, no. 5, pp. 1124-1135, 1996.
    w1 = 0.5 * (1 - cos(pi * (len + n) / len));
    w2 = 1 - w1;
    
    sig1w = sig1 .* w1;
    sig2w = sig2 .* w2;
    output = sig1w + sig2w;
end
