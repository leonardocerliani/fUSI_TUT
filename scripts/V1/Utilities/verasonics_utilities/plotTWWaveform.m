function plotTWWaveform(TWin, P)
    n = numel(TWin);
    [~, ~, ~, ~, TWout] = computeTWWaveform(TWin); % create TWout
    Fs = 250e6; % Fs waveform (s)
    tv = cell(n, 1); % time vector waveform
    dispName = cell(n, 1);
    Trans = evalin('base', 'Trans');

    % create waveforms
    for k = 1:n
        tv{k} = ((1:TWout(k).numsamples).' / Fs) * 1e6;
        if strcmp(TWin(k).type, 'parametric')
            Pa = TWin(k).Parameters;
            dispName{k} = sprintf('Fc: %.2f, D: %.2f, Nc: %i, P %i', ...
                Pa(1), Pa(2), Pa(3) / 2, Pa(4)); % Parameters: [Trans.frequency, P.DutyCycle, P.NbHalfCycle, 1]
        else
            dispName{k} = 'todo';
        end
    end

    tpeak = TWout(1).peak * P.lambda * 1e-3/1540;

    % plot waveforms
    figure(91); clf;
    subplot(311)
    hold on
    for k = 1:n
        ph(k) = plot(tv{k}, TWout(k).Wvfm2Wy, 'DisplayName', dispName{k});
    end
    yline(0);
    xline(tpeak * 1e6, 'r--');
    xline(2 * tpeak * 1e6, 'r--');
    legend(ph);
    ylim([-1 1])
    xlabel('time (\mus)')
    title('Simulated Transmit Waveforms')
    subplot(312)
    hold on
    for k = 1:n
        ph(k) = plot(tv{k}, TWout(k).TriLvlWvfm_Sim, 'DisplayName', dispName{k});
    end
    yline(0);
    legend(ph);
    ylim([-1 1])
    xlabel('time (\mus)')
    title('Input signal')

    % fft
    Fs = 250e6; % Sampling frequency
    T = 1 / Fs; % Sampling period
    L = TWout(1).numsamples * 2; % Length of signal
    t = (0:L - 1) * T; % Time vector
    fv = Fs * (1:L) / L;
    W = fft(TWout(1).Wvfm2Wy, L);
    [~, wi] = max(W(1:ceil(L / 2)));

    % figure(92); clf;
    subplot(313)
    plot(fv * 1e-6, abs(W))
    title(sprintf('Fc intended: %.3f - Simulated: %.3f', P.TWFreq, fv(wi) * 1e-6))
    hold on
    xline(P.TWFreq);
    xline(fv(wi) * 1e-6, '--');
    xlim(Trans.Bandwidth .* [0.5 1.5])
    % xlim(P.TWFreq .* [0.5 2.5])
end

% tv_1 = (1:numsamples_1).' / fs; % us
% tv_2 = (1:numsamples_2).' / fs; % us

% % compare to fc probe (Trans.frequency)
% wf_p = sin(2 * pi * Trans.frequency * tv_2);

% figure(); clf;
% plot(tv_1, wf_1);
% hold on;
% plot(tv_2, wf_2);
% % plot(tv_2, wf_p + 2.5);
% % legend('image', 'push', 'reference fc probe')
% legend('TW1', 'TW2')

% %% Some fft stuff
% if false
%     Fs = 250e6; % Sampling frequency
%     T = 1 / Fs; % Sampling period
%     L = numsamples_2; % Length of signal
%     t = (0:L - 1) * T; % Time vector

%     fv = Fs * (1:L) / L;

%     W = fft(wf_2);

%     figure(99); clf;
%     plot(fv * 1e-6, abs(W))
%     xlim([0 fv(end) * 1e-6/2])
% end
