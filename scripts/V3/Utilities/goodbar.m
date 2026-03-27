function hh = goodbar(data2plot,pMatrix,barX)


if nargin < 1
    error(message('MATLAB:narginchk:notEnoughInputs'));
end

if nargin < 2
    pMatrix = [];
    barX = 1:numel(data2plot);
end

if nargin < 3
    barX = 1:numel(data2plot);
end


% data to plot
barH = cellfun(@(x) mean(x,'omitnan'), data2plot);
barE = cellfun(@(x) std(x,'omitnan')./sqrt(numel(x)), data2plot);

pMatrix = round(pMatrix*1000)/1000;
pMatrix(pMatrix==0) = 0.001;

if size(barH,1) > size(barH,1)
    barH = barH';
end
% parameter for error bar tick
tickLength = 0.1*min(diff(barX));
tickColor = [0,0,0]; % black
tickWidth = 1.5;
verticalTick = 0.02*range(barH);

hold(gca,'on')
for ib = 1:numel(barH)
    hh(ib) = bar(barX(ib),barH(ib),'EdgeAlpha',1,'Facealpha',0,'LineWidth',tickWidth);
    hpt(ib) = scatter(repmat(barX(ib),1,numel(data2plot{ib})),data2plot{ib},'filled','MarkerFaceColor',[0.5 0.5 0.5],'MarkerFaceAlpha',0.35);
    if ~isempty(barE)

        if barH(ib) >= 0
        line([barX(ib),barX(ib)],[barH(ib),barH(ib)+barE(ib)],'color',tickColor,'linewidth',tickWidth)
         line([barX(ib)-tickLength/2,barX(ib)+tickLength/2],[barH(ib)+barE(ib),barH(ib)+barE(ib)],'color',tickColor,'linewidth',tickWidth)
        elseif barH(ib) < 0
            line([barX(ib),barX(ib)],[barH(ib),barH(ib)-barE(ib)],'color',tickColor,'linewidth',tickWidth)
             line([barX(ib)-tickLength/2,barX(ib)+tickLength/2],[barH(ib)-barE(ib),barH(ib)-barE(ib)],'color',tickColor,'linewidth',tickWidth)
        end
       
    end
    
end

addH = zeros(size(barH));

if ~isempty(pMatrix)
    if all(size(pMatrix) == [numel(barH),numel(barH)])
        for i = 1:size(pMatrix,1)
            for j = 1:size(pMatrix,2)
                if ~isnan(pMatrix(i,j))
                    if i==j
                         text(barX(i)-2*tickLength,1.05*barH(i)+max(barE),['p = ' num2str(pMatrix(i,j))])
                    else
                        line([barX(i),barX(j)],[1.04*max([barH(i),barH(j)])+max(barE)+max(addH(i),addH(j)), ...
                            1.04*max([barH(i),barH(j)])+max(barE)+max(addH(i),addH(j))],'color',tickColor,'linewidth',tickWidth)
                        line([barX(i),barX(i)],[1.04*max([barH(i),barH(j)])+max(barE)+max(addH(i),addH(j))-verticalTick, ...
                            1.04*max([barH(i),barH(j)])+max(barE)+max(addH(i),addH(j))],'color',tickColor,'linewidth',tickWidth)
                        line([barX(j),barX(j)],[1.04*max([barH(i),barH(j)])+max(barE)+max(addH(i),addH(j))-verticalTick, ...
                            1.04*max([barH(i),barH(j)])+max(barE)+max(addH(i),addH(j))],'color',tickColor,'linewidth',tickWidth)
                        text(mean([barX(i),barX(j)]-3*tickLength),1.075*max([barH(i),barH(j)])+max(barE)+max(addH(i),addH(j)),['p = ' num2str(pMatrix(i,j))])
                        addH([i,j]) = addH([i,j])+0.075*max(barH);
                    end
                end
            end      
        end
        
        
        
    else
        error(message('Incorrect size of p value matrix.'));
    end
end

 % ylim([0,max(barH)+2*max(barE)])

end

