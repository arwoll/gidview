function mcaview_plot_profile(handles)
% function mcaview_plot_profile(handles) Plots all of the profiles in
% handles.profiles.  Doesn't pay attention to hold, but only scale and
% norm.  The disposition of the hold toggle button in the GUI affects how
% many profiles are allowed.  It also prints a legend, using the numerical
% values in handles.profile.e_com.

axes(handles.profile);
p = get(gca, 'Position');
cla reset;

if handles.roi_index == 0 || ~isfield(handles.scandata, 'roi') || isempty(handles.scandata.roi)
    set(gca, 'Position', p);
    return
end

% If plotting multiple profiles, find all of the profiles of the same type
type = handles.PROFILE_NAMES{handles.scandata.roi(handles.roi_index).state.profile_select}; 
if ~any(strcmp(type, {'xy','xz','yz','volume'})) &&  ...
        strcmp(get(handles.profile_sethold, 'String'),'All')
    nprofiles = find(strcmp(type,{handles.scandata.roi.type}));
else
    nprofiles = handles.roi_index;  
end

profiles = handles.scandata.roi(nprofiles);

norm = strcmp(get(handles.profile_setnorm, 'String'),'on');

logscale = strcmp(get(handles.profile_setlog, 'String'),'Log');
if logscale
    loglin = 'log';
else
    loglin = 'lin';
end

ncolors = size(handles.colors, 1);

switch type
    case handles.PROFILE_NAMES(1:2) %energy/scan profile
        labels = cellstr(num2str([profiles.e_com]', 4)); % 4 digit precision
        fwhm = cellstr(num2str([profiles.fwhm]', 4));
        labels = strcat('E=',labels, ' : \Delta=', fwhm);
        % for k = 1:length(labels)
        %     labels{k} = [labels{k} '/' num2str(profiles(k).fwhm)];
        % end

        %load elamdb
%         elamdb=handles.elamdb;
        %%%%%%%%%%%%%%%%%%%%%%%%% Make the plot %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        plot_chan = 0;
        if strcmp(type, handles.PROFILE_NAMES{1})
            if get(handles.ecalmode, 'Value') == get(handles.ecalmode, 'Max')
                xlabel 'Delta (deg)';
            else
                xlabel 'Channel';
                plot_chan = 1;
            end
            fenergy = cell(length(profiles));
            fintensity = cell(length(profiles));
        else
            xlabel([handles.scandata.spec.mot1 ' (mm)']);
        end

        hold on
        for k=1:length(profiles)
            % Plot each profile in profiles, cycling through the colors
            if norm
                y = profiles(k).y/max(profiles(k).y);
            else
                y = profiles(k).y;
            end
            if plot_chan
                x = profiles(k).e_roi;
            else
                x = profiles(k).x;
            end
            if handles.roi_index == nprofiles(k)
                lw = 3;
            else
                lw = 0.5;
            end
            plot(x, y, 'LineWidth', lw, ...
                'Color', handles.colors(mod(nprofiles(k)-1, ncolors)+1,:));

        end % for loop through profiles
        hold off
        grid on
        set(handles.profile, 'YScale', loglin, 'Color', [0 0 .5625]);

        %%%%%%%%%%%%%%%%%%%%%%%%% Label Plot %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %        legend(labels, 'Location', 'EastOutside', 'FontSize', 10);

        set((get(gca, 'XLabel')), 'FontSize', 16);
        if norm
            ylabel 'Intensity (normalized)';
        else
            ylabel 'Intensity (counts)';
        end
        set((get(gca, 'YLabel')), 'FontSize', 16);
    otherwise
        warndlg('(mcaview_plot_profile : Higher-D plots disabed in gidview...');
end
set(gca, 'Position', p);
