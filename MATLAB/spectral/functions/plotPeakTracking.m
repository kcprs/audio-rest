function plotPeakTracking(fgt, fEst, agt, aEst, smpl)
    subplot(2, 2, 1);
    semilogy(fgt, '--');
    hold on;
    set(gca, 'ColorOrderIndex', 1);
    semilogy(smpl, fEst);
    hold off;
    title('Frequency Estimation');
    xlabel('Time in samples');
    ylabel('Frequency in Hz');
    grid on;

    subplot(2, 2, 3);
    plot(agt, '--');
    hold on;
    set(gca, 'ColorOrderIndex', 1);
    plot(smpl, aEst);
    hold off;
    title('Amplitude Estimation');
    xlabel('Time in samples');
    ylabel('Amplitude of sinusoidal components');
    grid on;

    subplot(2, 2, 2);
    fgtSmpl = fgt(smpl, :);
    fRelErr = (fEst - fgtSmpl) ./ fgtSmpl;
    fRelErr = 100 * fRelErr;
    plot(smpl, fRelErr);
    title('Frequency Estimation - Relative Error');
    xlabel('Time in samples');
    ylabel('Relative error');
    grid on;
    ytickformat(gca, 'percentage');

    subplot(2, 2, 4);
    agtSmpl = agt(smpl, :);
    aRelErr = (aEst - agtSmpl) ./ agtSmpl;
    aRelErr = 100 * aRelErr;
    plot(smpl, aRelErr);
    title('Amplitude Estimation - Relative Error');
    xlabel('Time in samples');
    ylabel('Relative error');
    grid on;
    ytickformat(gca, 'percentage');
end
