function [base, num] = mca_strip_pt(mcafile)
% function base = mca_strip_pt(namestr)
% Where mcafile is a filename string WITH EXTENSION ALREADY REMOVED, and
% has the form 'name_pt', returns only 'name_'. An empty string is returned
% if no underscores are found or if the 'pt' is not numeric.
%

underscores = find(mcafile == '_'); % find gives the indices of '_'s
if ~isempty(underscores)
    last_str = mcafile(underscores(end)+1:end);
    num = str2double(last_str); % get the number..
    if isnan(num) && strncmp(last_str, 'scan', 4) && length(last_str) > 4
        num = str2double(last_str(5:end));
    end
    if ~isnan(num)
        base = mcafile(1:underscores(end)-1);
        return
    end
end

% Makes it hear if no underscores or if pt is non-numeric
base='';