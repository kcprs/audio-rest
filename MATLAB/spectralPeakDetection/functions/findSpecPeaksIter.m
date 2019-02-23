function specPeaks = findSpecPeaksIter(sig, trshld, nfft, npks, fs)
    %FINDSPECPEAKSITER Find multiple spectral peaks in the given signal
    %   specPeaks = FINDSPECPEAKSITER(sig, trshld, nfft, npks, fs) returns
    %   a matrix containing information about npks most prominent frequency
    %   components of the given signal sig, that is all spectral peaks with 
    %   magnitude above the threshold trshld in dBFS. The returned matrix is
    %   empty if no peaks are found. Otherwise, the matrix is of size N x 2,
    %   where N is the number of peaks found. Matrix columns correspond to
    %   frequency and amplitude estimates, respectively. Analysis is done
    %   using fft of size nfft.
    %
    %   specPeaks = FINDSPECPEAKSITER(sig, trshld, nfft, npks) uses default
    %   value of fs = 44100.
    % 
    %   specPeaks = FINDSPECPEAKSITER(sig, trshld, nfft) uses default values
    %   of fs = 44100 and npeaks = 20.
    %
    %   specPeaks = FINDSPECPEAKSITER(sig, trshld) uses default values
    %   of fs = 44100, npeaks = 20 and nfft = length(sig).

    if nargin < 5
        fs = 44100;
    end

    if nargin < 4
        npks = 20;
    end

    sigLen = length(sig);

    if nargin < 3
        nfft = sigLen;
    end
    
    specPeaks = zeros(npks, 2);
    cursor = 1;

    while cursor < length(specPeaks)
        [f, a] = findSpecPeak(sig, nfft, fs);

        if 20 * log10(a) < trshld
            cursor = cursor - 1;
            break;
        end

        specPeaks(cursor, :) = [f, a];
        cursor = cursor + 1;

        sinEst = getSineSig(sigLen, f, a);
        sig = sig - sinEst;
    end

    if cursor == 0
        specPeaks = double.empty(0, 2);
    else
        specPeaks = specPeaks(1:cursor, :);
    end

end
