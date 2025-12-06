function idx = ttlcol(col_name)
% Return index of a TTLinfo column by name

    colNames = TTLinfo_colNames();  % get the centralized list
    idx = find(strcmpi(colNames, col_name), 1);
    
    if isempty(idx)
        error('Column "%s" not found.', col_name);
    end
end
