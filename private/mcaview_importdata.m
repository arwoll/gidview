function [handles, varargout] = mcaview_importdata(handles)
% function handles = mcaview_importdata(handles)
%
% mcaview_importdata is the back-end for importing scans into mcaview.  It
% is the GUI-aware bridge between mcaview and lower-level immport functions
% openmca and openspec.  Depending on the type of scan retrieved, it
% updates the GUI (e.g. sets visibility of uicontrols).


loadpath = handles.loadpath;
name = get(handles.mcafile_select,'String');

errors.code = 0;

% Get extension 
ind = max(find(name == '.'));

if isempty(ind)
    extn = '';
else
    extn = name(ind:end);
end

fullname = fullfile(loadpath,name);

% -------------------------------------------------------------------------
% ----------------   Load pre-existing matlab file        -----------------
% -------------------------------------------------------------------------
% Test for match with '*.mat'.  There is a warning if the 'complete' flag 
% is false within scandata.spec or if scandata.spec is a missing field.
% -------------------------------------------------------------------------
 
if strcmp(extn, '.mat')
    if ~exist(fullname, 'file')
        % matlab file requested but not found.
        errors = add_error(errors, 1, sprintf('File %s not found',name));
    else
        % Success -- requested matfile is found. Load scandata and return.
        scandata_present = whos('-file',fullname,'scandata');
        if isempty(scandata_present)
            errors = add_error(errors,1, ...
                sprintf('Error opening file %s: variable "scandata" not present',name));
        else
            load(fullname,'scandata');
            if ~isfield(scandata, 'spec') || ~scandata.spec.complete
                errors=add_error(errors, 2,...
                    'Warning: scandata present but spec data are missing or incomplete');
            end
        end
    end
elseif strcmp(extn, '.xml')
    [scandata, errors] = bessy_xml_parse(fullname);
else
    % The function openmca can now handle property/value pairs to specificy
    % such as MCA_channels, mcaformat, ecal, and dead time parameters... In
    % future these will be grabbed from other GUI objects or from handles. 
    if strcmp(handles.mcaformat, 'spec') && ~isempty(handles.loadscan)
        [scandata, errors] = openmca(fullname,'ecal',handles.ecal, ...
            'dead', handles.dead, 'mcaformat', handles.mcaformat, 'scan', handles.loadscan);
    else
        [scandata, errors] = openmca(fullname,'ecal',handles.ecal, ...
            'dead', handles.dead, 'mcaformat', handles.mcaformat);
    end
end

if nargout > 1
    varargout{1} = errors(end).code
end

switch errors(end).code
    case 0
    case 2
        warndlg(strvcat({errors(:).msg}));
    case 1
        errordlg(strvcat({errors(:).msg}));
        set(handles.mcafile_select,'String', handles.current_file);
        return
    otherwise
        errordlg(sprintf('Unrecognized error code %s',errors(end).code));
        return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Check for non-zero mcadata  %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mcamax = max(max(scandata.mcadata(2:end,:)));
if mcamax == 0
    errors = add_error(errors,1, ...
        'Scaling error, no non-zero mcadata channels found');
    errordlg(strvcat({errors(:).msg}));
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%      NEW DATA SUCCESSFULLY LOADED       %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%     UPDATE GUI   %%%%%%%%%%%%%%%%

frz = get(handles.mca_scanplot_frz, 'Value') == 1;
if ~frz 
    mn = 1 || min(scandata.mcadata(:));
    set(handles.mca_scanplot_low, 'String', num2str(mn));
    set(handles.mca_scanplot_high, 'String', num2str(mcamax));
end

set(handles.scan_number, 'String', sprintf('%d', scandata.spec.scann));
set(handles.scan_string, 'String', scandata.spec.scanline);

% complete is:
%  -1 if scan was aborted and following scan detected
%   0 if scan was aborted but eof is reached
%   1 if scan is complete
bg = 'ryg';
bg = bg(scandata.spec.complete+2);

set(handles.completed_spectra, 'String', ...
    sprintf('   Completed Spectra: %d',scandata.spec.npts), ...
    'BackgroundColor', bg);

ctrs = get(handles.norm_ctr, 'String');
ctrval = get(handles.norm_ctr, 'Value');
if iscell(ctrs)
    ctr = ctrs{ctrval};
    match = find(strcmp(ctr, scandata.spec.ctrs), 1);
else
    match = 1;
end

if isempty(match)
    warndlg(['Warning, counter ' ctr ' not found in this scan']);
    match = 1;
elseif match ~= ctrval
    warndlg(['Warning, counter ' ctr ' seems to have switched position']);
end
set(handles.norm_ctr, 'String', scandata.spec.ctrs);
set(handles.norm_ctr, 'Value', match);


profile_strings = get(handles.profile_select, 'String');
if scandata.spec.dims >= 1
    profile_strings{2} = sprintf('I vs. %s', scandata.spec.mot1);
end

set(handles.profile_select, 'String', profile_strings);

callbackstr = ['handles = guidata(gcbo);'...
    'handles.loadpath = ''' handles.current_path ''';'...
    'handles.mcaformat = ''' handles.current_mcaformat ''';' ...
    'handles.dead = get(gcbo, ''UserData'');' ... %''' handles.dead.key ''';' ...
    'set(handles.mcafile_select, ''String'', ''' handles.current_file ''');'...
    'gidview(''mcafile_select_Callback'', gcbo,[],handles);'];
if ~isempty(handles.current_file)
    m = findobj(handles.menu_file_openrecent, 'Label', handles.current_file);
    if isempty(m)
        recent = get(handles.menu_file_openrecent,'Children');
        % IN future, permute these so that most recent is at the top
        uimenu(handles.menu_file_openrecent,...
            'Label', handles.current_file, ...
            'Callback', callbackstr, ...
            'UserData', handles.current_dead);
        if length(recent) > 14
            delete(recent(end));
        end
    else
        set(m, 'Callback', callbackstr, ...
            'UserData', handles.current_dead);
    end
    set(handles.menu_file_openrecent, 'Enable', 'on');
end

%%%%%%%%%%%%%%     UPDATE HANDLES USERDATA   %%%%%%%%%%%%%%%%


handles.mcaformat = scandata.mcaformat;
handles.dead = scandata.dead;
set(handles.menu_file_openprior, 'Label', 'Open prior type');
set(handles.menu_file_openprior, 'Enable', 'on');

handles.current_path = loadpath;
handles.current_file = name;
handles.current_mcaformat = scandata.mcaformat;
handles.current_dead = scandata.dead;

handles.scandata = scandata;

if ~isfield(handles.scandata, 'roi') || isempty(handles.scandata.roi)
    handles.roi_index = 0;
    handles.n_rois = 0;
    % set(handles.current_roi_show, 'String', '0/0');
else
    handles.n_rois = length(handles.scandata.roi);
    handles.roi_index = 1;
    % set(handles.current_roi_show, 'String', sprintf('1/%d', handles.n_rois));
end

if isfield(handles.scandata, 'ecal')
    handles.ecal = handles.scandata.ecal;
end
handles.scandata_saved = 1;
handles = mcaview_update_gui(handles);
handles = mcaview_update_mcaplot(handles);
mcaview_plot_profile(handles);