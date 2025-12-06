function [TXDelayWvl, XS, ZS, add_to_TXDelay] = delayVirtualSources2D(anglesRad, z0, speedOfSound)
    %[TXDelayWvl, XS, ZS, add_to_TXDelay] = delayVirtualSources2D(anglesRad, z0, speedOfSound)
    %   Will determine the transducer delay for a point source determined from the
    %   input angles (in radians) and z0 (in meters).
    %
    %   R. Waasdorp, 18-11-2021
    %

    % get stuff from workspace
    Trans = evalin('base', 'Trans');
    if ~strcmp(Trans.units, 'wavelengths')
        error('Trans.units has to be in wavelenghts');
    end

    % get some parameterscool(10)
    if ~exist('speedOfSound', 'var') || isempty(speedOfSound)
        Resource = evalin('base', 'Resource');
        speedOfSound = Resource.Parameters.speedOfSound;
    end
    
    Fc = Trans.frequency * 1e6;
    wvl = speedOfSound / Fc;
    X_El = Trans.ElementPos(:, 1) .* wvl; % element pos in m
    Z_El = Trans.ElementPos(:, 3) .* wvl; % element pos in m
    numAngles = numel(anglesRad);

    % virtual source position
    if numel(z0) == 1
        ZS = z0 .* ones(1, numAngles); % virtual source far away behind array for plane wave
    else
        ZS = z0;
    end
    XS = ZS .* tan(anglesRad);

    % transmit delays for steering (in seconds)
    TXDelay = zeros(numAngles, Trans.numelements);
    add_to_TXDelay = zeros(1, numAngles);
    for iTx = 1:numAngles
        TXDelay(iTx, :) = sqrt((X_El - XS(iTx)).^2 + ZS(iTx).^2) / speedOfSound;
        if z0 > 0
            % make focused wave if z0 > 0
            TXDelay(iTx, :) = -TXDelay(iTx, :);
        end
        add_to_TXDelay(iTx) = min(TXDelay(iTx, :));
        TXDelay(iTx, :) = TXDelay(iTx, :) - add_to_TXDelay(iTx);
    end

    % convert in units of wvl (as Verasonics needs)
    TXDelayWvl = TXDelay .* Fc;

    if numel(anglesRad) == 1
        plotPtSource(X_El, Z_El, XS, ZS, TXDelay, add_to_TXDelay, speedOfSound)
    end

end

function plotPtSource(X_El, Z_El, XS, ZS, TXDelay, add_to_TXDelay, speedOfSound)
    % - sqrt(((abs(x0) - L / 2) > 0) * pow(abs(x0) - L / 2, 2) + pow(z0, 2))
    X_El = X_El * 1e3;
    Z_El = Z_El * 1e3;
    XS = XS * 1e3;
    ZS = ZS * 1e3;
    nelem = numel(X_El);
    % L = max(X_El) - min(X_El);
    % dTX = sqrt(heaviside(abs(XS) - L / 2) * (abs(XS) - L / 2).^2 + ZS^2)
    % if ZS > 0
    %     [DistToElem2, iElem] = max(sqrt((X_El - XS).^2 + ZS.^2));
    % else
    %     [DistToElem2, iElem] = min(sqrt((X_El - XS).^2 + ZS.^2));
    % end
    % DistToElem2;
    % DistToElem = dTX;
    % DistToElem = DistToElem2
    % dz = sign(ZS) .* (DistToElem - sqrt(XS.^2 + ZS.^2));

    figure(4); clf;
    % figure(2); clf;
    subplot(121)
    plot(X_El, Z_El, '.-', 'linewidth', 2)
    hold on
    plot([0 XS], [0 ZS], 'k--', 'linewidth', 1)
    scatter(XS, ZS)
    drawcircle(XS, ZS, sqrt(XS.^2 + ZS.^2), 'k');
    dtang = abs(add_to_TXDelay * 1540) * 1e3;
    drawcircle(XS, ZS, dtang, 'k');
    ncir = 20;
    if ZS < 0
        dtangl = linspace(dtang, 2 * dtang, ncir);
    else
        dtangl = linspace(0, dtang, ncir);
    end
    for k = 1:ncir - 1
        drawcircle(XS, ZS, dtangl(k), 'r');
    end
    % plot([X_El(iElem), X_El(iElem)], [0 dz], 'bx-')

    % drawcircle(XS, ZS, DistToElem, 'r');
    % cmap = flip(cool(5));
    % for k = 1:5
    %     drawcircle(XS, ZS, DistToElem + sign(-ZS) * k * 20 * mean(diff(X_El)), 'color', cmap(k, :), 'linestyle', '--');
    % end
    daspect([1 1 1])
    xlim(X_El([1 end]) * 3)
    ylim(X_El([1 end]) * 3)
    set(gca, 'YDir', 'reverse')
    % title(sprintf('Transmitted wave with dz = %.2fmm', dz * 1e3))

    subplot(122)
    plot(1:nelem, TXDelay * 1e6, '.-')
    xlim([1 nelem])
    xticks(0:16:nelem)
    % title(sprintf('Delay in wavelengths dtoffset = %.2f\\mus', dz / speedOfSound * 1e6))
    ylabel('Delay in \lambda')
    ylim([0 2])
end
function h = drawcircle(x, y, r, varargin)
    %  h = drawcircle(x, y, r, varargin)
    th = 0:pi / 400:2 * pi;
    xunit = r * cos(th) + x;
    yunit = r * sin(th) + y;
    htmp = plot(xunit, yunit, varargin{:});
    if nargout == 1
        htmp = h;
    end
end
