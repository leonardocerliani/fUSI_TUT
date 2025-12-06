classdef DataInventoryApp < matlab.apps.AppBase

    properties (Access = public)
        UIFigure             matlab.ui.Figure
        UITable              matlab.ui.control.Table
        SelectFolderButton   matlab.ui.control.Button
        DoneButton           matlab.ui.control.Button
    end

    properties (Access = private)
        Data table
        RootDir string = ""
        SubDataPaths string
        SubAnatPaths string
    end

    methods (Access = private)

        function SelectFolderButtonPushed(app, ~, ~)
            folder = uigetdir(pwd, 'Select Root Folder');
            if isequal(folder,0), return; end
            app.RootDir = string(folder);

            % Load CSV as strings
            opts = detectImportOptions('data_inventory.csv');
            opts = setvartype(opts, {'Condition','subData','subAnat'}, 'string');
            app.Data = readtable('data_inventory.csv', opts);

            % Prepare table columns
            nRows = height(app.Data);
            Select = false(nRows,1);
            Conditions = app.Data.Condition;
            SubData = app.Data.subData;
            SubAnat = app.Data.subAnat;

            % Find paths for each row
            app.SubDataPaths = strings(nRows,1);
            app.SubAnatPaths = strings(nRows,1);
            for i = 1:nRows
                % subData
                d = dir(fullfile(app.RootDir,'**','Data_analysis','**',"run-"+SubData(i)));
                d = d([d.isdir]);
                if ~isempty(d), app.SubDataPaths(i) = fullfile(d(1).folder,d(1).name); end

                % subAnat
                d = dir(fullfile(app.RootDir,'**','Data_analysis','**',"run-"+SubAnat(i)));
                d = d([d.isdir]);
                if ~isempty(d), app.SubAnatPaths(i) = fullfile(d(1).folder,d(1).name); end
            end

            % Store paths internally
            app.SubDataPaths = app.SubDataPaths;
            app.SubAnatPaths = app.SubAnatPaths;

            % Build table
            T = table(Select, Conditions, SubData, SubAnat);
            app.UITable.Data = T;
            app.UITable.ColumnEditable = [true false false false];
            app.UITable.ColumnWidth = {50,'auto','auto','auto'};
        end

        function DoneButtonPushed(app, ~, ~)
            tbl = app.UITable.Data;
            if isempty(tbl), return; end

            selectedIdx = find(tbl.Select);

            subDataPath = app.SubDataPaths(selectedIdx);
            subAnatPath = app.SubAnatPaths(selectedIdx);

            disp('subDataPath =');
            disp(cellstr(subDataPath));
            disp('subAnatPath =');
            disp(cellstr(subAnatPath));
        end

        function createComponents(app)
            app.UIFigure = uifigure('Name','Data Inventory','Position',[200 200 800 420]);

            app.UITable = uitable(app.UIFigure, ...
                'Position',[20 80 760 320]);

            app.SelectFolderButton = uibutton(app.UIFigure, 'push', ...
                'Text','Select Root Folder','Position',[20 20 160 40], ...
                'ButtonPushedFcn',@app.SelectFolderButtonPushed);

            app.DoneButton = uibutton(app.UIFigure, 'push', ...
                'Text','Done','Position',[200 20 100 40], ...
                'ButtonPushedFcn',@app.DoneButtonPushed);
        end
    end

    methods (Access = public)
        function app = DataInventoryApp
            createComponents(app)
        end
    end
end
