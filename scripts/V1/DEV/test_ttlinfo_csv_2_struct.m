
tbl = readtable('ttlinfo_colnames.csv');
tbl.Name = matlab.lang.makeValidName(tbl.Name);  % ensure valid field names
col = cell2struct(num2cell(tbl.Channel), tbl.Name, 1);

col.Time
col.ShockOBSCTLStim