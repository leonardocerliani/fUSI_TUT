function idx = searchEventList(Event, field, number, show)
% idx = searchEventList(Event, field, number, show)
%
% R. Waasdorp - r.waasdorp@tudelft.nl - 14-09-2022

    if ~exist('show','var')
        show = false;
    end

    c = {Event.(field)};
    idx = [];
    for k =1:numel(c)
        if any(c{k}==number)
            idx(end+1)=k;
        end
    end
    
    if show
        for k = idx
            fprintf('Event(%i): \n', k)
            disp(Event(k))
        end
    end

end

