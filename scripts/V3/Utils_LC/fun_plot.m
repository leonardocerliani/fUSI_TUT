classdef fun_plot
    methods (Static)

        % Plot nonzero columns of TTLinfo
        function plotTTL(TTLinfo)
            colNames = TTLinfo_colNames();          % get column names
            colsToPlot = find(any(TTLinfo, 1));
            nCols = length(colsToPlot);
            figure;
            for i = 1:nCols
                colIdx = colsToPlot(i);
                subplot(nCols,1,i);
                plot(TTLinfo(:, colIdx), 'b-');
                % Show column name with channel number in parentheses
                ylabel(sprintf('ch %d\n%s', colIdx, colNames{colIdx}), 'Rotation',0);
                if i == 1, title('TTL Signals'); end
                if i == nCols, xlabel('Sample index'); end
                grid on;
            end
        end

        
        
        % Plot the movie of the pdi
        function pdi_movie(PDI, pdi)
            hFig = figure;
            colormap('gray');  % grayscale
        
            for t = 1:PDI.Dim.nt
                if ~isvalid(hFig)   % check if figure is still open
                    break            % exit loop if figure was closed
                end
        
                imagesc(pdi(:,:,t));
                axis image off;
                title(sprintf('Time frame %d / %d', t, PDI.Dim.nt));
                drawnow;
                pause(0.05);
            end
        end


    end
end
