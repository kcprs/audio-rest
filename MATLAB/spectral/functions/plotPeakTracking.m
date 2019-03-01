function plotPeakTracking(fEst, aEst, smpl)
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
