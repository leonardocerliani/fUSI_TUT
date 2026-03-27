function filterToolRW(P)
    % Copyright Verasonics, Inc.  All world-wide rights and remedies under all
    % intellectual property laws and industrial property laws are reserved.
    % Verasonics Registered U.S. Patent and Trademark Office.
    %
    % Notice:
    %   This file is provided by Verasonics to end users as a programming
    %   tool for the Verasonics Vantage Research Ultrasound System.
    %   Verasonics makes no claims as to the functionality or intended
    %   application of this program and the user assumes all responsibility
    %   for its use
    %
    % File name: filterTool.m
    %
    % Verasonics Provides a Filter Design Tool to
    % 1) Visualize the default filter and design the customized filter in off-line mode
    % 2) Program the decimRate, sampleMode, low-pass and band-pass filter
    %    of the Vantage system, as well as visualize the effect on image in real-time
    %
    % 07-Jun-2019 --- Multiple fields should be used to determine the filter sets
    % 07-Nov-2016 --- Support multiple filter sets based on the InputFilter

    % If filterTool is a called by EventAnalysisTool, plot the LPF and BPF
    % from a specfic rcvNum indicated in the Event Table.

    VDASG3 = [];
    VDASInterleave = [];
    DefaultLPF = [];
    DefaultBPF = [];
    setDefaultValue();

    LPFParam = [];
    BPFParam = [];
    RcvParam = [];
    setupParam(P)

    whos
    LPFParam.cutoffFreqMHz = 10;
    LPFParam.kaiserBeta = 1;
    LPFParam = computeLPFresponse(RcvParam, LPFParam)

    plotLPF(LPFParam)

    % computeLPF()
    % computeBPF()

    % keyboard

    %% =========================================================================
    % functions
    % ==========================================================================

    function computeLPF

        % Define coefficients for CGD lowpass filter and plot the response,
        % using parameter values in LPFParam structure.

        if evalin('base', '~exist(''LPFParam'',''var'')')
            assignin('base', 'LPFParam', LPFParam);
            assignin('base', 'BPFParam', BPFParam);
        end

        nQ = 15; % number of magnitude bits for coefficient quantization
        Nfilt = RcvParam.decimFactor; % subsampling used in VDAS
        LPFxlim = RcvParam.ADCRate / 2;

        % If Fs is 4/3 samples per wavelength, limit will be changed to HPF
        if RcvParam.BPFfilterNum == 4
            win = 'high';
        else % cutoff frequency must less than Nyquist Frequency
            win = 'low';
        end

        ctffFreq = LPFParam.cutoffFreqMHz / LPFxlim; % Needs to be normalized to Nyquist frequency

        % Set up parameters for calculating the frequency response:
        Nfft = 1024; % size of the fft
        Fsteps = LPFxlim * (0:2 / Nfft:1);
        step = 4 * Nfilt / Nfft; % size of one step in our normalized-to-Fc frequency units

        if ctffFreq >= 0.99
            % ALL PASS
            LPFParam.cutoffFreqMHz = LPFxlim;
            Fout = zeros(1, Nfft);
            LPFParam.LPFcoef = [zeros(1, 11), 1];
            fcoef = [LPFParam.LPFcoef, fliplr(LPFParam.LPFcoef(1:end - 1))];
        else
            %% Coef calculation
            % if enabled this section calculates coefficients using Kaiser window function:
            % Compute coefficients using Kaiser window:

            kbeta = LPFParam.kaiserBeta;
            wndw = kaiser(LPFParam.numTaps, kbeta);
            fcoef = fir1(LPFParam.numTaps - 1, ctffFreq, win, wndw);

            % Make sure coefficient values are symmetric
            fcoef = (fcoef + fliplr(fcoef)) / 2;

            % Now quantize to coefNbits resolution
            fcoef = (round(fcoef * 2^nQ)) / (2^nQ); % 16 bits for Gen3 CGD design
            LPFParam.LPFcoef = fcoef(1:12);
        end
        Fout = 20 * log10(abs(fft(fcoef, Nfft)));
        LPFParam.Fout = Fout;

        plotFilterVSX = 0;
        if plotFilterVSX
            %% now find passband and stopband for selected filter
            if ~isequal(fcoef, LPFParam.DefaultCoef(1, :))

                acceptRange = 0.01;
                ind1 = find(abs((Fout + 3) ./ Fout) < acceptRange);
                ind2 = find(abs((Fout + 20) ./ Fout) < acceptRange);

                status = 0;
                while status ~= 1
                    if isempty(ind1) || isempty(ind2)
                        acceptRange = acceptRange + 0.01;
                        ind1 = find(abs((Fout + 3) ./ Fout) < acceptRange);
                        ind2 = find(abs((Fout + 20) ./ Fout) < acceptRange);
                        if acceptRange > 0.05
                            status = 1;
                        end
                    else
                        status = 1;
                    end
                end
            end

            %% plot LPF or HPF
            % If Fs is 4/3 samples per wavelength with decimFactor = 2, Nfilt will be 9
            % for HPF

            % PLOT DEFAULT FILTER
            FoutDefault = LPFParam.DefaultFout;
            axeLPF = findobj('Tag', 'figLPF');
            axes(axeLPF),
            plot(Fsteps, FoutDefault((1:Nfft / 2 + 1)), Fsteps, Fout(1:Nfft / 2 + 1), 'r');

            ylim([-60, 10]);
            xlim([0 LPFxlim]);
            xlabel('Frequency (MHz)', 'FontUnits', 'normalized');
            ylabel('Amplitude Response in dB', 'FontUnits', 'normalized');

            dBfreq1 = Fsteps(ind1(1));
            dBfreq2 = Fsteps(ind2(1));
            fbw = dBfreq1 / RcvParam.TransFreq * 100;

            nbw = 0.8; % fractional bandwidth over which we will count the noise
            nsum = 1;
            ncount = 1;
            if Nfilt > 1 % no subsampling and thus no aliasing if nfilt = 1
                nsum = 0;
                ncount = 0;
                for i = 3:2:2 * Nfilt - 1 % only the odd harmonics will alias to Fc
                    for j = round((i - nbw / 2) / step + 1):round((i + nbw / 2) / step + 1)
                        nsum = nsum + 10^(Fout(j) / 10); % sum noise power from each fft spectral point
                        ncount = ncount + 1; % cumulative count of points summed, for normalization
                    end
                end
            end
            aliasnoise = 10 * log(nsum / ncount); % normalized total aliased noise power in dB

            title({['-3 dB bandwidth ' num2str(fbw, '%3.0f') ' %  with cutoff frequency ', num2str(dBfreq1, '%1.2f'), ' MHz']; ...
                    ['Stopband -20 dB point ' num2str(dBfreq2, '%1.2f'), ' MHz']; ...
                    ['aliased noise power ' num2str(aliasnoise, '%.1f') ' dB using ' num2str(nbw, '%.2f')]}, 'FontUnits', 'normalized');

            line([0 LPFxlim], [3 3], 'color', 'black', 'LineStyle', '--');
            line([0 LPFxlim], [-3 -3], 'color', 'black', 'LineStyle', '--');
            line([0 LPFxlim], [-20 -20], 'color', 'black', 'LineStyle', '--');

            % freqFilt is the frequency limit after decimation, so customer will be
            % able to know the actual frequency range after LPF and subsampling

            if 1 < Nfilt % && (Nfilt<9)
                line([RcvParam.decimRate / 2 RcvParam.decimRate / 2], [-60 10], 'color', 'blue', 'LineStyle', '--');
                text(RcvParam.decimRate / 2, -15, '\leftarrow', 'FontSize', 10);
                text(RcvParam.decimRate / 2, -15.4, '      Frequency limit after subsampling', 'FontUnits', 'normalized');
                line([LPFParam.cutoffFreqMHz LPFParam.cutoffFreqMHz], [-6 10], 'color', 'red', 'LineStyle', '--');

            end

            assignin('base', 'LPFParam', LPFParam);
        end
    end

    function computeBPF
        % Function to compute the CGD bandpass filter coefficients and plot the
        % filter's frequency response.  Coefficient values are saved in the
        % BPFParam structure, for importing into VSX after exiting the coef
        % development script.

        % Because the sample rate at the point right before bandpass filter
        % (Receive.InputFilterCoefs) is 4*RcvParam.TransFreq, the Nyquist for the
        % bandpass filter will be always 2*RcvParam.TransFreq. Therefore, if fmax is
        % awlays 2, Fc will be center freq/Transquency

        % In the case of NS200BWI smapleMode, BPF will become a HPF.

        if evalin('base', '~exist(''BPFParam'',''var'')')
            assignin('base', 'BPFParam', BPFParam);
            assignin('base', 'LPFParam', LPFParam);
        end

        showTitle = 1;

        if RcvParam.interleave % HPF calculation

            nQ = 15; % number of magnitude bits for coefficient quantization
            Nfft = 1024;

            if isempty(BPFParam.BPFcoef)

                ctffFreq = BPFParam.centerFreqMHz / (RcvParam.decimRate / 4);

                if ctffFreq > 0.99
                    ctffFreq = 0.99;
                    BPFParam.centerFreqMHz = ctffFreq * RcvParam.decimRate / 4;
                end

                kbeta = BPFParam.bndwdth;
                wndw = kaiser(BPFParam.numTaps, kbeta);
                fcoef = fir1(BPFParam.numTaps - 1, ctffFreq, 'high', wndw);

                % Make sure coefficient values are symmetric
                fcoef = (fcoef + fliplr(fcoef)) / 2;

            else
                fcoef = [BPFParam.BPFcoef, fliplr(BPFParam.BPFcoef(1:end - 1))];
                if isequal(BPFParam.modified, 0) && max(abs(BPFParam.BPFcoef - BPFParam.DefaultCoef)) > 1e-4
                    showTitle = 0;
                    set(UI.CenterFreqValue, 'String', 'Custom');
                    set(UI.bwValue, 'String', 'Custom');
                end
            end

            % Now quantize to coefNbits resolution
            fcoef = (round(fcoef * 2^nQ)) / (2^nQ); % 16 bits for Gen3 CGD design
            BPFParam.BPFcoef = fcoef(1:(BPFParam.numTaps + 1) / 2); %
            Fout = 20 * log10(abs(fft(fcoef, Nfft)));
            BPFParam.Fout = Fout;
            BPFxlim = RcvParam.decimRate / 2;
            Fsteps = BPFxlim * (1 / Nfft:1 / Nfft:1);

            if ~isequal(fcoef, LPFParam.DefaultCoef(1, :))
                Fout = 20 * log10(abs(fft(fcoef, Nfft)));

                acceptRange = 0.01;
                ind1 = find(abs((Fout + 3) ./ Fout) < acceptRange);
                ind2 = find(abs((Fout + 20) ./ Fout) < acceptRange);

                status = 0;
                while status ~= 1
                    if isempty(ind1) || isempty(ind2)
                        acceptRange = acceptRange + 0.01;
                        ind1 = find(abs((Fout + 3) ./ Fout) < acceptRange);
                        ind2 = find(abs((Fout + 20) ./ Fout) < acceptRange);
                        if acceptRange > 0.05, status = 1; showTitle = 0; end
                    else
                        status = 1;
                    end
                end
            end

            arrow1 = findall(0, 'Tag', 'arrow1'); if ishandle(arrow1), delete(arrow1); end
            arrow2 = findall(0, 'Tag', 'arrow2'); if ishandle(arrow2), delete(arrow2); end

            axeBPF = findobj('Tag', 'figBPF');
            axes(axeBPF); % select the display figure for updating

            % 0.62 is the bottom corner of the BPF
            plot(Fsteps, BPFParam.DefaultFout, Fsteps, Fout, 'r');
            xlim([0 BPFxlim]), ylim(BPFParam.Rangsel); title('');
            if AutoUpdateLegend
                legend('Default', 'Design', 'AutoUpdate', 'off');
            else
                legend('Default', 'Design');
            end
            x1 = 0.62 + 0.35 * (RcvParam.TransFreq / BPFxlim);
            y1 = 0.15;
            y2 = 0.1;
            annotation('Textarrow', [x1, x1], [y1, y2], 'Color', 'b', 'LineWidth', 1, ...
                'String', 'Trans.frequency', 'TextColor', 'k', 'FontUnits', 'normalized', ...
                'TextMargin', 65, 'Tag', 'arrow1');
            line([BPFxlim / 2 BPFxlim / 2], [-70 5], 'color', 'b', 'LineStyle', '--');

            if showTitle
                dBfreq1 = Fsteps(ind1(1));
                dBfreq2 = Fsteps(ind2(1));
                fbw = dBfreq1 / RcvParam.TransFreq * 100;
                nbw = 0.8; % fractional bandwidth over which we will count the noise

                nsum = 0;
                ncount = 0;
                for i = 3:2:1 % only the odd harmonics will alias to Fc
                    for j = round((i - nbw / 2) / step + 1):round((i + nbw / 2) / step + 1)
                        nsum = nsum + 10^(Fout(j) / 10); % sum noise power from each fft spectral point
                        ncount = ncount + 1; % cumulative count of points summed, for normalization
                    end
                end
                aliasnoise = 10 * log(nsum / ncount); % normalized total aliased noise power in dB
                title({['-3 dB bandwidth ' num2str(fbw, '%3.0f') ' %  with cutoff frequency ', num2str(dBfreq1, '%1.2f'), ' MHz']; ...
                        ['Stopband -20 dB point ' num2str(dBfreq2, '%1.2f'), ' MHz']; ...
                        ['aliased noise power ' num2str(aliasnoise, '%.1f') ' dB using ' num2str(nbw, '%.2f')]}, 'FontUnits', 'normalized');
            else
                title('')
            end

            line([0 BPFxlim], [3 3], 'color', 'black', 'LineStyle', '--');
            line([0 BPFxlim], [-3 -3], 'color', 'black', 'LineStyle', '--');
            line([0 BPFxlim], [-20 -20], 'color', 'black', 'LineStyle', '--');

        else % Regular BPF calculation and plot

            %% step 1: Initialize parameters

            nQ = 15; % number of magnitude bits for coefficient quantization
            Nfilt = RcvParam.BPFfilterNum; % find which filter we're processing

            % Set up parameters for calculating the frequency response:
            Nfft = 1024; % size of the fft
            Fout = -100 * ones(1, Nfft); % array for fft results
            FoutDefault = -100 * ones(1, Nfft);

            bndwdth = BPFParam.bndwdth; % The value has been modified to be within [0.1 2] range
            BWrange = [2; 1; 0.5; 0.6];
            if bndwdth > BWrange(Nfilt)
                bndwdth = BWrange(Nfilt);
            elseif bndwdth < 0.1
                bndwdth = 0.1;
            end

            Freqrange = [0.1 1.9; 0.5 1.5; 0.75 1.25; 2.1 3.9]; % allowed range for center frequency

            if Nfilt == 4
                % in this case, 2<cetFreq<4, and 0.1<bandwidth<0.6
                BPFxlim = RcvParam.decimRate;
                ctrFreq = BPFParam.centerFreqMHz / (BPFxlim / 4);
                Fsteps = BPFxlim * (1 / Nfft:1 / Nfft:1); % scale the frequency steps so Fc is always 1 (and Nyquist limit is at BPFxlim)
            else
                BPFxlim = RcvParam.decimRate / 2;
                ctrFreq = BPFParam.centerFreqMHz / (BPFxlim / 2);
                Fsteps = BPFxlim * (0:2 / Nfft:1); % scale the frequency steps so Fc is always 1 (and Nyquist limit is at BPFxlim)
            end

            % Check the Freq is within correct range
            if ctrFreq * (1 + bndwdth / 2) > Freqrange(Nfilt, 2)
                ctrFreq = Freqrange(Nfilt, 2) / (1 + bndwdth / 2);
                if ctrFreq * (1 - bndwdth / 2) < Freqrange(Nfilt, 1)
                    ctrFreq = sum(Freqrange(Nfilt, :)) / 2;
                end

            elseif ctrFreq * (1 - bndwdth / 2) < Freqrange(Nfilt, 1)
                ctrFreq = Freqrange(Nfilt, 1) / (1 - bndwdth / 2);
                if ctrFreq * (1 + bndwdth / 2) > Freqrange(Nfilt, 2)
                    ctrFreq = sum(Freqrange(Nfilt, :)) / 2;
                end
            end

            % Have correct value shown in the GUI
            if Nfilt == 4
                BPFParam.centerFreqMHz = BPFxlim * ctrFreq / 4;
                BPFParam.bndwdth = bndwdth;
                bndwdth = (ctrFreq / (4 - ctrFreq)) * bndwdth;

                ctrFreq = 4 - ctrFreq; % Aliasing to 0-2 range for filter coef determination
                Freqrange(Nfilt, :) = Freqrange(1, :);
                BPFParam.centerFreq = ctrFreq;
            else
                BPFParam.centerFreq = ctrFreq;
                BPFParam.bndwdth = bndwdth;
                BPFParam.centerFreqMHz = ctrFreq * BPFxlim / 2;
            end

            %% step 2: Create frequency point array for firpm function

            hxsn = 0.5 * BPFParam.xsnwdth;
            apm = [0 0 1 1 0 0]; % amplitude points for the firpm function
            fpm = [0 .1 .4 .5 .9 1]; % frequency points for the firpm function; actual values will be set below

            FL = (1 - bndwdth / 2) * ctrFreq; % normalized band edges
            FH = (1 + bndwdth / 2) * ctrFreq;
            if FH > Freqrange(Nfilt, 2)
                FH = Freqrange(Nfilt, 2);
            end
            if FL < Freqrange(Nfilt, 1)
                FL = Freqrange(Nfilt, 1);
            end

            FL = FL / 2; % scale to units used by fft for 4X sampling
            FH = FH / 2;
            hxsn = hxsn / 2;

            % set nominal values  for fpm vector [0 FL-hxsn FL+hxsn FH-hxsn FH+hxsn 1] but check
            % for overlaps and restrict transition width if necessary:
            fpm(2) = max((FL - hxsn), .001); % don't let low edge of transition band go to zero or below
            fpm(5) = min((FH + hxsn), .999); % don't let high edge of transition band go to one or above
            if (FL + hxsn) < (FH - hxsn) % make sure passband edges are in ascending order
                fpm(3) = max(fpm(2) + .001, FL + hxsn); % keep transition band edges in correct order too
                fpm(4) = min(fpm(5) - .001, FH - hxsn);
            else
                fpm(3) = (FL + FH) / 2 - .001; % stay in the middle if hxsn is too big
                fpm(4) = (FL + FH) / 2 + .001;
            end

            %% step 3: get firpm coeff's
            if isempty(BPFParam.BPFcoef)

                fcoef = firpm((BPFParam.numTaps - 1), fpm, apm); % compute FIR coef's using firpm function

                % Make sure coefficient values are symmetric
                fcoef = (fcoef + fliplr(fcoef)) / 2;

                % Now null out the DC term
                DC = sum(fcoef);
                fcoef(BPFParam.DCnulltap) = fcoef(BPFParam.DCnulltap) - DC / 2; % adjust coef to null DC
                fcoef = fliplr(fcoef); % flip to do it again on the other end
                fcoef(BPFParam.DCnulltap) = fcoef(BPFParam.DCnulltap) - DC / 2;

                % Now normalize gain at Fc, quantize, etc.
                testresp = abs(fft(fcoef, Nfft));

                FLindx = round(fpm(3) * Nfft / 2 + 1); % bandwidth limits for gain normalization
                FHindx = round(fpm(4) * Nfft / 2 + 1);

                % compute average gain over passband, but don't let it go below .01
                Fcgain = max(sum(testresp(FLindx:FHindx)) / (FHindx - FLindx + 1), .01);
                fcoef = fcoef / Fcgain; % note scaling preserves zero at DC

                % Now quantize to coefNbits resolution
                fcoef = round(fcoef * 2^nQ);
                DC = sum(fcoef); % remove any DC offset from the rounding
                ctrtap = round(BPFParam.numTaps(1) / 2);
                fcoef(ctrtap) = fcoef(ctrtap) - DC; % offset center coef, to preserve integer steps
                fcoef = fcoef / (2^nQ);

                BPFParam.BPFcoef = fcoef(1:(BPFParam.numTaps + 1) / 2); %
            else
                fcoef = [BPFParam.BPFcoef, fliplr(BPFParam.BPFcoef(1:end - 1))];
                if isequal(BPFParam.modified, 0) && max(abs(BPFParam.BPFcoef - BPFParam.DefaultCoef)) > 1e-4
                    %                     ~isequal(BPFParam.BPFcoef,BPFParam.DefaultCoef)
                    set(UI.CenterFreqValue, 'String', 'Custom');
                    set(UI.bwValue, 'String', 'Custom');
                    showTitle = 0;
                end
            end

            %% step 4: compute frequency response and find passband and stopband
            Fout(:) = 20 * log10(abs(fft(fcoef, Nfft)));

            if Nfilt == 4
                FoutLeft = Fout;
                Fout(1:Nfft / 2 + 1) = -100;
                FoutLeft(Nfft / 2 + 1:end) = -100;
                FoutDefault(1:Nfft / 2 + 1) = BPFParam.DefaultFout(1:Nfft / 2 + 1);
            else
                Fout = Fout(1:length(Fsteps));
                FoutDefault = BPFParam.DefaultFout;
            end

            ind1 = find(Fout + 3 > 0);
            ind2 = find(Fout + 20 > 0);
            ind3 = find(Fout + 6 > 0);

            pbL = Fsteps(ind1(1)); % -3 dB point at low end in relative frequency units
            pbH = Fsteps(ind1(end));
            fbw = 100 * (pbH - pbL) / BPFParam.centerFreqMHz;

            stpL = Fsteps(ind2(1)); % stpbd is the frequency at which response first goes above -20 dB; note i=1 means DC or F=0
            stpH = Fsteps(ind2(end)); % stpbd is the frequency at which response first goes above -20 dB; note i=1 means DC or F=0

            %% Plot BPF

            arrow1 = findall(0, 'Tag', 'arrow1'); if ishandle(arrow1); delete(arrow1); end
            arrow2 = findall(0, 'Tag', 'arrow2'); if ishandle(arrow2); delete(arrow2); end

            axeBPF = findobj('Tag', 'figBPF');
            axes(axeBPF); % select the display figure for updating

            % 0.62 is the bottom corner of the BPF
            if Nfilt == 4
                plot(Fsteps, FoutDefault, Fsteps, Fout, 'r', Fsteps, FoutLeft, 'r--');
                x1 = 0.62 + 0.35 * (BPFParam.centerFreqMHz / BPFxlim);
                x2 = 0.62 + 0.35 * (1 - BPFParam.centerFreqMHz / BPFxlim);
                y1 = 0.15;
                y2 = 0.1;
                annotation('Textarrow', [x1, x1], [y1, y2], 'Color', 'b', 'LineWidth', 1, ...
                    'String', 'Center Frequency', 'TextColor', 'k', 'FontUnits', 'normalized', ...
                    'TextMargin', 65, 'Tag', 'arrow1');
                annotation('Textarrow', [x2, x2], [y1, y2], 'Color', 'b', 'LineWidth', 1, ...
                    'String', 'Aliasing Center Frequency', 'TextColor', 'k', 'FontUnits', 'normalized', ...
                    'TextMargin', 85, 'Tag', 'arrow2');
            else
                plot(Fsteps, FoutDefault(1:length(Fsteps)), Fsteps, Fout, 'r');
                x1 = 0.62 + 0.35 * (RcvParam.TransFreq / BPFxlim);
                y1 = 0.15;
                y2 = 0.1;
                annotation('Textarrow', [x1, x1], [y1, y2], 'Color', 'b', 'LineWidth', 1, ...
                    'String', 'Trans.frequency', 'TextColor', 'k', 'FontUnits', 'normalized', ...
                    'TextMargin', 65, 'Tag', 'arrow1');
            end

            if Nfilt == 2 || Nfilt == 3
                titleStr = 'Green lines show Nyquist limit.';
            else
                titleStr = '';
            end

            ylim(BPFParam.Rangsel);
            xlim([0 BPFxlim]);
            xlabel('Frequency (MHz)', 'FontUnits', 'Normalized');
            ylabel('Amplitude Response in dB', 'FontUnits', 'Normalized');
            if showTitle
                title({['-3 dB bandwidth ' num2str(fbw, '%3.0f') ' % (from ' num2str(pbL, '%1.2f') '  to ' num2str(pbH, '%1.2f'), ' MHz']; ...
                        ['Stopband -20 dB points ' num2str(stpL, '%1.2f') '  to  ' num2str(stpH, '%1.2f'), ' MHz']; ...
                        titleStr}, 'FontUnits', 'Normalized');
            end
            line([0 BPFxlim], [3 3], 'color', 'black', 'LineStyle', '--');
            line([0 BPFxlim], [-3 -3], 'color', 'black', 'LineStyle', '--');
            line([0 BPFxlim], [-20 -20], 'color', 'black', 'LineStyle', '--');

            freq = RcvParam.decimRate / 4;

            if Nfilt == 2
                line([0.5 * freq 0.5 * freq], [-60 -3], 'color', 'g', 'LineStyle', '--', 'LineWidth', 1.5);
                line([1.5 * freq 1.5 * freq], [-60 -3], 'color', 'g', 'LineStyle', '--', 'LineWidth', 1.5);
            elseif Nfilt == 3
                line([0.75 * freq 0.75 * freq], [-60 -3], 'color', 'g', 'LineStyle', '--', 'LineWidth', 1.5);
                line([1.25 * freq 1.25 * freq], [-60 -3], 'color', 'g', 'LineStyle', '--', 'LineWidth', 1.5);
            end

            if ~isequal(length(ind3), length(Fsteps))
                line([Fsteps(ind3(1)) Fsteps(ind3(1))], [-6 10], 'color', 'red', 'LineStyle', '--');
                line([Fsteps(ind3(end) + 1) Fsteps(ind3(end) + 1)], [-6 10], 'color', 'red', 'LineStyle', '--');
            end

        end

        assignin('base', 'BPFParam', BPFParam);
        if isequal(BPFParam.modified, 1)
            BPFParam.BPFcoef = [];
        end
    end

    % RcvParam = freqCorrection(RcvParam) is used to obtain correct
    % decimSampleRate supported by VDAS
    function RcvParam = freqCorrection(RcvParam)

        % - Determine the Receive.ADCRate and Receive.decimFactor based on RcvParam.TransFreq
        % used and return to base workspace
        [~, RcvParam.freqIdx] = min(abs(RcvParam.VDAS.decimRate - RcvParam.decimRate));
        RcvParam.ADCRate = RcvParam.VDAS.ADCRate(RcvParam.freqIdx);
        RcvParam.decimRate = RcvParam.VDAS.decimRate(RcvParam.freqIdx);
        RcvParam.decimFactor = RcvParam.VDAS.decimFactor(RcvParam.freqIdx);
        RcvParam.demodFreq = RcvParam.VDAS.demodFreq(RcvParam.freqIdx);

        if strcmp(RcvParam.sampleMode, 'BS67BW') && isequal(RcvParam.decimFactor, 2)
            RcvParam.LPFfilterNum = 9;
        else
            RcvParam.LPFfilterNum = RcvParam.decimFactor;
        end

    end

    function setupParam(P)
        % Get RcvParam(setValue) name from base workspace.
        RcvParam.TransFreq = evalin('base', 'Trans.frequency');

        % Get Receive from workspace, if LowPassCoef or InputFilter exists, the
        % filterTool will plot the frequency response of the filter. If not, the
        % filterTool will start from the default filter.
        RcvParam.interleave = P.useInterleave;
        RcvParam.VDAS = VDASG3; % default

        RcvParam.decimRate = 4 * P.demodFrequency;
        if P.useInterleave
            RcvParam.sampleMode = 'NS200BWI';
        else
            RcvParam.sampleMode = 'NS200BW';
        end

        switch RcvParam.sampleMode
            case 'NS200BW'
                RcvParam.BPFfilterNum = 1;
                RcvParam.sampleModeStr = {'NS200BW'; 'BS100BW'; 'BS50BW'; 'custom'};
            case 'NS200BWI'
                RcvParam.BPFfilterNum = 5;
                RcvParam.interleave = 1;
                RcvParam.VDAS = VDASInterleave;
                RcvParam.sampleModeStr = {'NS200BWI'; 'custom'};
            case 'BS100BW'
                error('not implemented')
                RcvParam.BPFfilterNum = 2;
                RcvParam.sampleModeStr = {'NS200BW'; 'BS100BW'; 'BS50BW'; 'custom'};
            case 'BS67BW'
                error('not implemented')
                RcvParam.VDAS = VDASG3FourThird;
                RcvParam.BPFfilterNum = 4;
                RcvParam.sampleModeStr = {'BS67BW', 'custom'};
            case 'BS50BW'
                error('not implemented')
                RcvParam.BPFfilterNum = 3;
                RcvParam.sampleModeStr = {'NS200BW'; 'BS100BW'; 'BS50BW'; 'custom'};
            case 'custom'
                error('not implemented')
                RcvParam.BPFfilterNum = 1;
                RcvParam.sampleModeStr = {'custom'};
            otherwise
                error('filterTool: Unrecognized Receive(%d).sampleMode.\n', rcvInd);
        end

        % Third, determine LPF and BPF
        LPFParam.LPFcoef = [];
        BPFParam.BPFcoef = [];

        RcvParam = freqCorrection(RcvParam);
        RcvParam.sampleModeStr = {'NS200BW'; 'NS200BWI'; 'BS100BW'; 'BS67BW'; 'BS50BW'; 'custom'};

        % other parameters for LPF and BPF
        LPFParam.numTaps = 23;
        LPFParam.cutoffFreqMHz = RcvParam.demodFreq * DefaultLPF.cutoff(RcvParam.LPFfilterNum);
        LPFParam.kaiserBeta = DefaultLPF.beta(RcvParam.LPFfilterNum);
        LPFParam.DefaultCoef = DefaultLPF.coef(RcvParam.LPFfilterNum, :);
        LPFParam.DefaultFout = DefaultLPF.Fout(RcvParam.LPFfilterNum, :);

        BPFParam.numTaps = 41;
        BPFParam.allPass = 0;
        BPFParam.centerFreqMHz = RcvParam.demodFreq; if RcvParam.BPFfilterNum == 5, BPFParam.centerFreqMHz = RcvParam.demodFreq / 2; end
        BPFParam.bndwdth = DefaultBPF.bndwdth(RcvParam.BPFfilterNum); % initial value for each filter's bandwidth in units relative to Fc
        BPFParam.xsnwdth = DefaultBPF.xsnwdth(RcvParam.BPFfilterNum); % initial value for width of each filter's transition bands, in units relative to Fc
        BPFParam.DCnulltap = [1 1 1 1]; % default tap position for DC zeroing
        BPFParam.Rangsel = [-90 10]; % Range to use for freq. response plots
        BPFParam.DefaultCoef = DefaultBPF.coef(RcvParam.BPFfilterNum, :);
        BPFParam.DefaultFout = DefaultBPF.Fout(RcvParam.BPFfilterNum, :);

        assignin('base', 'RcvParam', RcvParam);
        assignin('base', 'LPFParam', LPFParam);
        assignin('base', 'BPFParam', BPFParam);
    end

    %% =========================================================================
    % function to get the defaults
    % ==========================================================================
    function setDefaultValue()
        SR = zeros(74, 2); % Compute 74 entries from 250MHz to 2.5MHz.
        k = 1;
        for i = 1:100
            f = 250 / i;
            for j = 8:-1:1, if (i / j - floor(i / j)) < .0001, break, end, end
            if (i / j <= 25), SR(k, 1) = f; SR(k, 2) = j; k = k + 1; end
        end
        % Correct the decimation factors in the first part of the table (easier to specify than compute).
        SR(1:25, 2) = [1, 1, 1, 1, 1, 1, 1, 2, 1, 2, 1, 3, 1, 2, 3, 4, 1, 3, 1, 5, 3, 2, 1, 6, 5];

        Idx67BW = sort([find(SR(:, 2) == 1); find(SR(:, 2) == 2)]);
        SR67BW = SR(Idx67BW, :);
        ADCRate = SR(:, 1) .* SR(:, 2);

        VDASG3.decimRate = SR(4:end, 1);
        VDASG3.decimFactor = SR(4:end, 2);
        VDASG3.ADCRate = ADCRate(4:end);
        VDASG3.demodFreq = VDASG3.decimRate / 4;

        VDASInterleave.decimRate = SR(2:4, 1);
        VDASInterleave.decimFactor = SR(2:4, 2);
        VDASInterleave.ADCRate = ADCRate(2:4) / 2;
        VDASInterleave.demodFreq = VDASInterleave.decimRate / 4;

        % VDASG3FourThird.decimRate = SR67BW(4:end, 1);
        % VDASG3FourThird.decimFactor = SR67BW(4:end, 2);
        % VDASG3FourThird.ADCRate = SR67BW(4:end, 1) .* SR67BW(4:end, 2);
        % VDASG3FourThird.demodFreq = VDASG3FourThird.decimRate / 4 * 3;

        Nfft = 1024;

        % ==== Default LPF parameters for Vantage ====
        DefaultLPF.cutoff = [2.00 1.83 1.81 1.72 1.79 1.76 1.80 1.89 0.69];
        DefaultLPF.beta = [0.0 3.6 2.82 2.10 3.00 1.80 1.00 0.70 3.59];

        DefaultLPF.coef = [ ...
                            [+0.0000 +0.0000 +0.0000 +0.0000 +0.0000 +0.0000 +0.0000 +0.0000 +0.0000 +0.0000 +0.0000 +1.0000]; ...
                            [-0.0004 +0.0063 +0.0038 -0.0139 -0.0137 +0.0234 +0.0359 -0.0328 -0.0868 +0.0398 +0.3105 +0.4559]; ...
                            [-0.0057 -0.0005 +0.0115 +0.0197 +0.0095 -0.0208 -0.0497 -0.0411 +0.0285 +0.1444 +0.2545 +0.2997]; ...
                            [+0.0110 +0.0072 -0.0042 -0.0202 -0.0334 -0.0337 -0.0128 +0.0311 +0.0914 +0.1538 +0.2008 +0.2183]; ...
                            [-0.0006 -0.0058 -0.0130 -0.0191 -0.0192 -0.0084 +0.0161 +0.0531 +0.0972 +0.1394 +0.1699 +0.1810]; ...
                            [-0.0137 -0.0183 -0.0194 -0.0148 -0.0030 +0.0163 +0.0419 +0.0710 +0.1001 +0.1248 +0.1414 +0.1472]; ...
                            [-0.0212 -0.0198 -0.0139 -0.0031 +0.0124 +0.0315 +0.0528 +0.0744 +0.0942 +0.1101 +0.1205 +0.1240]; ...
                            [-0.0192 -0.0144 -0.0060 +0.0060 +0.0208 +0.0376 +0.0552 +0.0722 +0.0873 +0.0992 +0.1067 +0.1093]; ...
                            [+0.0030 +0.0034 -0.0093 -0.0068 +0.0214 +0.0106 -0.0441 -0.0141 +0.0932 +0.0166 -0.3135 +0.4820]];

        coefLPF = [DefaultLPF.coef fliplr(DefaultLPF.coef(:, 1:end - 1))];
        DefaultLPF.Fout = 20 * log10(abs(fft(coefLPF', Nfft)))';

        % ==== BPF will be applied based on the samples per wavelength ====
        DefaultBPF.bndwdth = [1.0800 0.8300 0.3700 0.6000 4.0];
        DefaultBPF.xsnwdth = [0.4000 0.3400 0.3200 0.4000 0.4];

        DefaultBPF.coef = zeros(5, 21);
        DefaultBPF.coef(1, :) = [ ...
                                -0.00113 +0.00000 -0.00116 +0.00000 +0.00549 +0.00000 +0.00720 ...
                                +0.00000 -0.01419 +0.00000 -0.02640 +0.00000 +0.02606 +0.00000 ...
                                +0.07816 +0.00000 -0.03671 +0.00000 -0.30786 +0.00000 +0.54108];

        % BPF #2 (2 samples per wavelength, default coef row 2):
        DefaultBPF.coef(2, :) = [ ...
                            +0.00034 +0.00000 +0.00244 +0.00000 -0.00629 +0.00000 -0.00333 ...
                                +0.00000 +0.02188 +0.00000 -0.00897 +0.00000 -0.04745 +0.00000 ...
                                +0.06076 +0.00000 +0.07294 +0.00000 -0.30048 +0.00000 +0.41632];

        % BPF #3 (1 sample per wavelength, default coef row 3):
        DefaultBPF.coef(3, :) = [ ...
                            -0.00162 +0.00000 +0.00568 +0.00000 -0.01065 +0.00000 +0.01349 ...
                                +0.00000 -0.00858 +0.00000 -0.00955 +0.00000 +0.04312 +0.00000 ...
                                -0.08841 +0.00000 +0.13550 +0.00000 -0.17130 +0.00000 +0.18463];

        % BPF #4 (4/3 samples per wavelength aliased, default coef row 4):
        DefaultBPF.coef(4, :) = [ ...
                            -0.00159 +0.00000 -0.00549 +0.00000 -0.01157 +0.00000 -0.02066 ...
                                +0.00000 -0.03275 +0.00000 -0.04721 +0.00000 -0.06281 +0.00000 ...
                                -0.07785 -0.00003 -0.09039 -0.00003 -0.09875 -0.00003 +0.89832];

        % BPF #5 (interleave, default coef row 5):
        DefaultBPF.coef(5, :) = [ ...
                            +0.00000 +0.00214 +0.00000 -0.00409 +0.00000 +0.00693 +0.00000 ...
                                -0.01093 +0.00000 +0.01654 +0.00000 -0.02457 +0.00000 +0.03665 ...
                                +0.00000 -0.05713 +0.00000 +0.10217 +0.00000 -0.31735 +0.50067];

        coefBPF = [DefaultBPF.coef fliplr(DefaultBPF.coef(:, 1:end - 1))];
        DefaultBPF.Fout = 20 * log10(abs(fft(coefBPF', Nfft)))';

    end
end

%% =============================================================================
% different scope
% ==============================================================================
function LPFParam = computeLPFresponse(RcvParam, LPFParam)

    % Define coefficients for CGD lowpass filter and plot the response,
    % using parameter values in LPFParam structure.
    nQ = 15; % number of magnitude bits for coefficient quantization
    Nfilt = RcvParam.decimFactor; % subsampling used in VDAS
    LPFxlim = RcvParam.ADCRate / 2;

    % If Fs is 4/3 samples per wavelength, limit will be changed to HPF
    if RcvParam.BPFfilterNum == 4
        error('not implemented')
        LPFParam.win = 'high';
    else % cutoff frequency must less than Nyquist Frequency
        LPFParam.win = 'low';
    end

    ctffFreq = LPFParam.cutoffFreqMHz / LPFxlim; % Needs to be normalized to Nyquist frequency

    % Set up parameters for calculating the frequency response:

    Nfft = 1024; % size of the fft
    Fsteps = 2 * LPFxlim * (0:Nfft - 1) / Nfft;
    step = 4 * Nfilt / Nfft; % size of one step in our normalized-to-Fc frequency units

    if ctffFreq >= 0.99
        % ALL PASS
        LPFParam.cutoffFreqMHz = LPFxlim;
        Fout = zeros(1, Nfft);
        LPFParam.LPFcoef = [zeros(1, 11), 1];
        fcoef = [LPFParam.LPFcoef, fliplr(LPFParam.LPFcoef(1:end - 1))];
        Fout = 20 * log10(abs(fft(fcoef, Nfft)));
    else
        %% Coef calculation
        % if enabled this section calculates coefficients using Kaiser window function:
        % Compute coefficients using Kaiser window:

        win = LPFParam.win;
        kbeta = LPFParam.kaiserBeta;
        wndw = kaiser(LPFParam.numTaps, kbeta);
        fcoef = fir1(LPFParam.numTaps - 1, ctffFreq, win, wndw);

        % Make sure coefficient values are symmetric
        fcoef = (fcoef + fliplr(fcoef)) / 2;

        % Now quantize to coefNbits resolution
        fcoef = (round(fcoef * 2^nQ)) / (2^nQ); % 16 bits for Gen3 CGD design
        LPFParam.LPFcoef = fcoef(1:12);
        Fout = 20 * log10(abs(fft(fcoef, Nfft)));
    end

    LPFParam.Fout = Fout;
    LPFParam.FV = Fsteps;
end

function matchLPF(LPFParam, FoutIntended)

end

function plotLPF(LPFParam)
    disp('PLOT')

    % determine butter freq response
    Nfft = numel(LPFParam.Fout);
    Fs = 62.5;
    Fc = 10;
    wndw = kaiser(LPFParam.numTaps, LPFParam.kaiserBeta);
    [b, a] = fir1(LPFParam.numTaps - 1, Fc / (Fs / 2), LPFParam.win, wndw);
    [fres, fv] = freqz(b, a, Nfft, 'whole', Fs);
    fres_log = 20 * log10(fres);

    figure(1); clf;
    plot(LPFParam.FV, LPFParam.DefaultFout, 'r');
    hold on
    plot(LPFParam.FV, LPFParam.Fout, 'b');
    plot(fv, fres_log, 'g');
    legend('Default LPF', 'Set LPF', 'butter')

end

%% =============================================================================
% function retriveParam()
%     % Get RcvParam(setValue) name from base workspace. If not running with SetUp
%     % script, the default Trans.frequency is 5.208 but can be modified in the GUI
%     if evalin('base', 'exist(''Trans'',''var'')')
%         RcvParam.TransFreq = evalin('base', 'Trans.frequency');
%     else
%         RcvParam.TransFreq = 5.208;
%         RcvParam.decimRate = 4 * RcvParam.TransFreq;
%     end

%     % Get Receive from workspace, if LowPassCoef or InputFilter exists, the
%     % filterTool will plot the frequency response of the filter. If not, the
%     % filterTool will start from the default filter.
%     RcvParam.interleave = 0;
%     RcvParam.VDAS = VDASG3; % default

%     if evalin('base', 'exist(''Receive'',''var'')')
%         Receive = evalin('base', 'Receive');
%         % Check for sampleMode or samplesPerWave attributes provided; if not found, set defaults
%         if ~isfield(Receive(rcvInd), 'sampleMode')
%             if isfield(Receive(rcvInd), 'samplesPerWave') % for backwards compatibility
%                 switch Receive(rcvInd).samplesPerWave
%                     case 4
%                         Receive(rcvInd).sampleMode = 'NS200BW';
%                     case 2
%                         Receive(rcvInd).sampleMode = 'BS100BW';
%                     case 4/3
%                         Receive(rcvInd).sampleMode = 'BS67BW';
%                     case 1
%                         Receive(rcvInd).sampleMode = 'BS50BW';
%                     otherwise
%                         Receive(rcvInd).sampleMode = 'custom';
%                         Receive(rcvInd).decimSampleRate = Receive(rcvInd).samplesPerWave * RcvParam.TransFreq;
%                 end
%             else
%                 Receive(rcvInd).sampleMode = 'NS200BW'; % default sampleMode if not provided.
%             end
%         end

%         RcvParam.sampleMode = Receive(rcvInd).sampleMode;

%         % Set target decimSampleRate - if provided, use it, otherwise use (4 or 4/3)*Trans.frequency.
%         if isfield(Receive(rcvInd), 'decimSampleRate') && ~isempty(Receive(rcvInd).decimSampleRate)
%             RcvParam.decimRate = Receive(rcvInd).decimSampleRate;
%         else
%             % if demodFrequency is provided, decimRate will be 4*demodFrequency
%             if isfield(Receive(rcvInd), 'demodFrequency') && ~isempty(Receive(rcvInd).demodFrequency)
%                 RcvParam.decimRate = 4 * Receive(rcvInd).demodFrequency;
%             elseif strcmp(Receive(rcvInd).sampleMode, 'BS67BW')
%                 RcvParam.decimRate = (4/3) * RcvParam.TransFreq;
%             else
%                 RcvParam.decimRate = 4 * RcvParam.TransFreq;
%             end
%         end

%         switch RcvParam.sampleMode
%             case 'NS200BW'
%                 RcvParam.BPFfilterNum = 1;
%                 Receive(rcvInd).samplesPerWave = RcvParam.decimRate / RcvParam.TransFreq;
%                 RcvParam.sampleModeStr = {'NS200BW'; 'BS100BW'; 'BS50BW'; 'custom'};
%             case 'NS200BWI'
%                 RcvParam.BPFfilterNum = 5;
%                 RcvParam.interleave = 1;
%                 RcvParam.VDAS = VDASInterleave;
%                 Receive(rcvInd).samplesPerWave = RcvParam.decimRate / (2 * RcvParam.TransFreq);
%                 RcvParam.sampleModeStr = {'NS200BWI'; 'custom'};
%             case 'BS100BW'
%                 RcvParam.BPFfilterNum = 2;
%                 Receive(rcvInd).samplesPerWave = RcvParam.decimRate / (2 * RcvParam.TransFreq);
%                 RcvParam.sampleModeStr = {'NS200BW'; 'BS100BW'; 'BS50BW'; 'custom'};
%             case 'BS67BW'
%                 RcvParam.VDAS = VDASG3FourThird;
%                 RcvParam.BPFfilterNum = 4;
%                 Receive(rcvInd).samplesPerWave = RcvParam.decimRate / RcvParam.TransFreq;
%                 RcvParam.sampleModeStr = {'BS67BW', 'custom'};
%             case 'BS50BW'
%                 RcvParam.BPFfilterNum = 3;
%                 Receive(rcvInd).samplesPerWave = RcvParam.decimRate / (4 * RcvParam.TransFreq);
%                 RcvParam.sampleModeStr = {'NS200BW'; 'BS100BW'; 'BS50BW'; 'custom'};
%             case 'custom'
%                 RcvParam.BPFfilterNum = 1;
%                 Receive(rcvInd).samplesPerWave = RcvParam.decimRate / RcvParam.TransFreq;
%                 RcvParam.sampleModeStr = {'custom'};
%             otherwise
%                 error('filterTool: Unrecognized Receive(%d).sampleMode.\n', rcvInd);
%         end

%         % Third, determind LPF and BPF
%         if ~isfield(Receive(rcvInd), 'LowPassCoef')
%             LPFParam.LPFcoef = [];
%         else
%             % user-defined filter exists; if of V1 size expand it to be
%             % compatible with Gen3

%             if size(Receive(rcvInd).LowPassCoef, 2) == 6
%                 Receive(rcvInd).LowPassCoef = [zeros(1, 6), Receive(rcvInd).LowPassCoef];
%             end
%             LPFParam.LPFcoef = Receive(rcvInd).LowPassCoef;
%         end

%         if ~isfield(Receive(rcvInd), 'InputFilter')
%             BPFParam.BPFcoef = [];
%         else
%             if size(Receive(rcvInd).InputFilter, 2) == 6
%                 % looks like a V1 filter provided by user so expand it to Gen3 size
%                 Buffer = zeros(1, 21);
%                 for ntap = 1:6
%                     Buffer(1, 9 + 2 * ntap) = Receive(rcvInd).InputFilter(:, ntap);
%                 end
%                 Receive(rcvInd).InputFilter = Buffer;
%                 clear Buffer
%             end

%             BPFParam.BPFcoef = Receive(rcvInd).InputFilter;
%         end

%     else
%         % default is 1 for NS200BW sampleMode
%         RcvParam.BPFfilterNum = 1;
%         RcvParam.sampleMode = 'NS200BW';
%         RcvParam.sampleModeStr = {'NS200BW'; 'BS100BW'; 'BS50BW'; 'custom'};
%         LPFParam.LPFcoef = [];
%         BPFParam.BPFcoef = [];
%     end

%     RcvParam = freqCorrection(RcvParam);
%     RcvParam.sampleModeStr = {'NS200BW'; 'NS200BWI'; 'BS100BW'; 'BS67BW'; 'BS50BW'; 'custom'};

%     % other parameters for LPF and BPF
%     LPFParam.numTaps = 23;
%     LPFParam.cutoffFreqMHz = RcvParam.demodFreq * DefaultLPF.cutoff(RcvParam.LPFfilterNum);
%     LPFParam.kaiserBeta = DefaultLPF.beta(RcvParam.LPFfilterNum);
%     LPFParam.DefaultCoef = DefaultLPF.coef(RcvParam.LPFfilterNum, :);
%     LPFParam.DefaultFout = DefaultLPF.Fout(RcvParam.LPFfilterNum, :);
%     LPFParam.modified = 0;

%     BPFParam.numTaps = 41;
%     BPFParam.allPass = 0;
%     BPFParam.centerFreqMHz = RcvParam.demodFreq; if RcvParam.BPFfilterNum == 5, BPFParam.centerFreqMHz = RcvParam.demodFreq / 2; end
%     BPFParam.bndwdth = DefaultBPF.bndwdth(RcvParam.BPFfilterNum); % initial value for each filter's bandwidth in units relative to Fc
%     BPFParam.xsnwdth = DefaultBPF.xsnwdth(RcvParam.BPFfilterNum); % initial value for width of each filter's transition bands, in units relative to Fc
%     BPFParam.DCnulltap = [1 1 1 1]; % default tap position for DC zeroing
%     BPFParam.Rangsel = [-90 10]; % Range to use for freq. response plots
%     BPFParam.DefaultCoef = DefaultBPF.coef(RcvParam.BPFfilterNum, :);
%     BPFParam.DefaultFout = DefaultBPF.Fout(RcvParam.BPFfilterNum, :);
%     BPFParam.modified = 0;

%     assignin('base', 'RcvParam', RcvParam);
%     assignin('base', 'LPFParam', LPFParam);
%     assignin('base', 'BPFParam', BPFParam);
% end
% ==============================================================================
