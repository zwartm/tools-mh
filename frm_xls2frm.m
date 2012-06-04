function dsT = frm_xls2frm(xlsFileName, sheet)
%FRM_XLS2FRM: read xls with header row; convert to struct by col title
% 
%   ds = FRM_XLS2FRM(xlsFileName, sheet)
%
%   ds is a structure.  The first row is treated as a header line and the
%   cell contents are used as field names in the structure. 
%   Each field is a vector from the column contents.  If there is mixed
%   numeric and string data, a raw cell vector is returned.  If only
%   numeric data we return a numeric vector, else a text vector.
%
%   Uses Apache POI Java library for Excel file processing
%
%   See also: FRM_*
% 
%  MH - http://github.com/histed/tools-mh

% histed 120530: created

if nargin < 2, sheet = 1; end

xc = frm_constants;

[raw, typeMat] = frm_xlsreadpoi(xlsFileName, sheet);

% remove header line
dsT.colNames = raw(1,:);
raw = raw(2:end,:);  
% convert to a structe
dsT.nCols = length(dsT.colNames);
dsT.nRows = size(raw,1);

isSomeNum = any(typeMat(2:end,:) == xc.typeNums.NUMERIC,1);
isSomeText = any(typeMat(2:end,:) == xc.typeNums.STRING,1);
emptyIx = cellfun(@isempty, raw(:,:));

removeColsIx = false(size(dsT.colNames));
for iC=1:dsT.nCols
    tFN = dsT.colNames{iC};
    % sanitize fname
    if isempty(tFN)
        assert(all(emptyIx(:,iC)), 'empty column name but data in rows below');
        removeColsIx(iC) = true;
        continue;
    elseif isnan(tFN)
        tFN = sprintf('Column%02d', iC);
    else
        tFN = strrep(tFN, sprintf('\n'), '');
        tFN = regexprep(tFN, '[-\(\)]', '_');  % misc punct w/ underscores
        tFN = genvarname(tFN);
        tFN = regexprep(tFN, '_$', '');  % misc punct w/ underscores
    end
    %if strcmp(tFN, 'DateTimeStarted'), keyboard, end

    if isSomeNum(iC) && isSomeText(iC)
        tV = raw(:,iC);
    elseif isSomeNum(iC) && ~isSomeText(iC)
        tV = celleqel2mat_padded(raw(:,iC), NaN);
    elseif ~isSomeNum(iC) && ~isSomeText(iC)
        % empty
        tV = nan(size(raw,1),1);
    else % ~isSomeNum && isSomeText
        tV = raw(:,iC);
        eIx = emptyIx(:,iC);
        [tV{eIx}] = deal('');    % convert double empties to char 
        %tV = cellstr(tV);  % this trims blanks, so just leave as straight cell
    end
        
    dsT.(tFN) = tV(:)';
end
dsT.colNames = dsT.colNames(~removeColsIx);
dsT.nCols = length(dsT.colNames);