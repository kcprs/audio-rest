freq = freqPre(1:20, :);
smpl = smplPre(1:20, :);

for iter = 1:20
    plot(smpl, freq, 'x');
    hold on;
    con = freq(1:iter, :);
    set(gca, 'ColorOrderIndex', 1);
    plot(smpl(1:iter), con);

    hold off;
    title('Sinusoid tracks - frequency');
    ylabel('Frequency in Hz');
    xlabel('Time in samples');
    grid on;

    filename = strcat("anim/frame", num2str(iter), ".png");
    saveas(gcf, filename);
end
