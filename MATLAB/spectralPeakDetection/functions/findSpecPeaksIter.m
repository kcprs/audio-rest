function specPeaks = findSpecPeaksIter(sig, trshld, nfft, fs)
    %FINDSPECPEAKSITER Find multiple spectral peaks in the given signal
    %   specPeaks = FINDSPECPEAKSITER(sig, trshld, nfft, fs) returns a matrix
    %   containing information about most prominent frequency components of
    %   the given signal sig, that is all spectral peaks with magnitude
    %   above the threshold trshld in dB. The returned matrix is empty if
    %   no peaks are found. Otherwise, the matrix is of size N x 3, where N
    %   is the number of peaks found. Matrix columns correspond to
    %   frequency, magnitude and amplitude estimates, respectively. Analysis
    %   is done using fft of size nfft.
    %
    %   specPeaks = FINDSPECPEAKSITER(sig, trshld, nfft) uses default value
    %   of fs = 44100.
    %
    %   specPeaks = FINDSPECPEAKSITER(sig, trshld) uses default values
    %   of fs = 44100 and nfft = length(sig).

    if nargin < 4
        fs = 44100;
    end

    nsig = length(sig);

    if nargin < 3
        nfft = nsig;
    end

    % Pre-allocate for speed, assuming there will never be more than 2000
    % peaks detected.
    specPeaks = zeros(2000, 3);

    cursor = 1;

    while cursor < length(specPeaks)
        [f, m, a] = findSpecPeak(sig, nfft, fs);

        if m < trshld
            cursor = cursor - 1;
            break;
        end

        specPeaks(cursor, :) = [f, m, a];
        cursor = cursor + 1;

        sinEst = getSineSig(nsig, f, a);
        sig = sig - sinEst;
    end

    if cursor == 0
        specPeaks = [];
    else
        specPeaks = specPeaks(1:cursor, :);
    end

end
