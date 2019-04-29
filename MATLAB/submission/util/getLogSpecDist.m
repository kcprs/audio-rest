function lsd = getLogSpecDist(psd1, psd2, p)
    %GETLOGSPECDIST Compute log-spectrum distance between two PSD spectra
    %   lsd = getLogSpecDist(psd1, psd2, p) returns log-spectrum distance
    %   between PSD spectra psd1 and psd2. For p = 1 the result is the
    %   absolute LSD and for p = 2 the result is the quadratic distance
    % 
    %   lsd = getLogSpecDist(psd1, psd2) uses default value of p = 1

    if size(psd1) ~= size(psd2)
        error("Size mismatch: psd1 and psd2 must be the same size!");
    end

    if nargin < 3
        p = 1;
    end

    K = size(psd1, 2);
    lsd = (sum(abs(10 * log10(abs(psd1 ./ psd2)).^p), 2) / K).^(1 / p);
end
