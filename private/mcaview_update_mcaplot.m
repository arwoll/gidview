function handles = mcaview_update_mcaplot(handles)
% function mcaview_update_mcaplot(handles) updates the mcaplot, and also
% various labels in the GUI.  Alternatively, I might re-consture the
% different update functions as different update 'levels'.  The highest
% leverl (update_gui) is almost always followed by the rest, whereas lower
% levels are often used without having to do update_gui....

ecalmode = get(handles.ecalmode, 'Value') == get(handles.ecalmode, 'Max');
norm_to_ctr = get(handles.norm_to_ctr_toggle, 'Value') == 1;
if norm_to_ctr
    ctrs = get(handles.norm_ctr, 'String');
    norm_ctr = ctrs{get(handles.norm_ctr, 'Value')};
    norm_col = find(strcmp(norm_ctr, handles.scandata.spec.headers), 1);
    norm_ref = sscanf(get(handles.norm_ref, 'String'), '%f', 1);
end

if handles.scandata.spec.dims > 1
    warndlg('(mcaview_makeprofile : Higher-D plots disabed in gidview...');
else
    page = 1;
end

if handles.roi_index ~= 0 
    if ecalmode
        set(handles.roi_centroid_label, 'String', 'Delta:');
        set(handles.roi_centroid, 'String', sprintf('%6.2f', ...
            handles.scandata.roi(handles.roi_index).e_com))
    else
        set(handles.roi_centroid_label, 'String', 'Channel:');
        set(handles.roi_centroid, 'String', sprintf('%6.2f', ...
            handles.scandata.roi(handles.roi_index).ch_com));
    end
else
    handles.d_roi = [];
    handles.e_roi = [];
    handles.roi_rect = [];
end

%page = handles.page;


handles.scandata.depth = handles.scandata.spec.var1(:,handles.page);


ncolors = size(handles.colors, 1);

if isfield(handles.scandata, 'mcadata')
    low = str2double(get(handles.mca_scanplot_low, 'String'));
    high = str2double(get(handles.mca_scanplot_high, 'String'));
    ra = log([low high]);
    dtcorr_image = strcmp(get(handles.menu_options_dtcorrect_mcaplot, 'Checked'), 'on');
    axes(handles.mca_scanplot);
    if ecalmode 
        eaxis = handles.scandata.energy;
    else
        eaxis = handles.scandata.channels;
    end
    plotim = single(handles.scandata.mcadata(:, :,handles.page));
    if norm_to_ctr
        norm = handles.scandata.spec.data(norm_col, :, page);
        for k = 1:length(handles.scandata.depth)
            plotim(:, k) = plotim(:, k)*norm_ref/norm(k);
        end
    end
    if dtcorr_image 
        for k = 1:length(handles.scandata.depth)
            plotim(:,k) = plotim(:,k)*handles.scandata.dtcorr(k);
        end
    end
    
    imagesc(handles.scandata.depth, eaxis(2:end), log(plotim(2:end,:)+1), ra);
    if ecalmode
        % This is a kludge for gidview -- to make low delta appear low...
        axis xy
    end
    
    profile_strings = get(handles.profile_select, 'String');
    if ecalmode
        ylabel('Delta (deg)');
        profile_strings{1} = 'I vs. Delta';
    else
        ylabel('Channel');
        profile_strings{1} =  'I vs. Channel';
    end
    set(handles.profile_select, 'String', profile_strings);
    xlabel(handles.scandata.spec.mot1); %'Depth (mm)';
    
    if handles.n_rois>0
        for k=1:handles.n_rois
            rect = handles.scandata.roi(k).roi_rect;
            if ecalmode
                es = handles.scandata.energy([rect(1) rect(1) rect(2) rect(2) rect(1)]);
            else
                es = [rect(1) rect(1) rect(2) rect(2) rect(1)];
            end
            ds = handles.scandata.depth([rect(3) rect(4) rect(4) rect(3) rect(3)]);
            if k == handles.roi_index
                lw = 1.5; 
            else
                lw = 0.5;
            end
            lc = handles.colors(mod(k-1, ncolors)+1,:);
            line(ds, es, 'color', lc, 'LineWidth', lw, 'LineStyle', '-');
        end
    end 
end

