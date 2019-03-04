function plotPeakTracking(fEst, aEst, smpl)
    % Strip zeros - NaN will not show on the plot
    fEst(fEst == 0) = NaN;
    aEst(aEst == 0) = NaN;

    subplot(2, 1, 1);
    semilogy(smpl, fEst);
    hold off;
    title('Frequency Estimation');
    xlabel('Time in samples');
    ylabel('Frequency in Hz');
    grid on;

    subplot(2, 1, 2);
    plot(smpl, aEst);
    hold off;
    title('Amplitude Estimation');
    xlabel('Time in samples');
    ylabel('Amplitude of sinusoidal components');
    grid on;
end
