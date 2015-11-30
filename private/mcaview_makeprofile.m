function handles = mcaview_makeprofile(handles)
% function mcaview_makeprofile(handles)
%
% Generates profiles for profile plots.  
%
% Settings are determined by uicontrols listed as fields of
% handles.roi_state, and the userdata stored in handles.(handles.roi_vars)
%
% For version 0.94, the complete state used to construct an roi is
% retained, so that rois can be modifed and edited.
%
% implementation:
%   scandata.roi(N).state{} : state of  uicontrols and
%                                 any other details that would effect the
%                                 generation of the energy profile, e.g.
%                                 the roi dimensions, page number(?), etc.
%   scandata.roi(N).roi_rect, d_roi, e_roi (handles userdata for making profile)
%   scandata.roi(N).x,y,fwhm, e_com, ch_com, delta [,z[,v]] (as in older versions.)  
%
% NEW: dstep is the size of a distance step, used in the calculation of
% peak area, scandata.roi(N).area. (currently only used in energy profiles.
%
% Things that must be handled for mcaview_update:
% 1. if ~isempty(scandata.roi) ( implied that length(scandata.roi) >
%       handles.current_roi)
%          update roi_state according to scandata.roi(N).roi_state
%
%  2. Ennable/ disable ROI next/previous buttons
%     Update context menus, attached to both next and previous buttons, that
%     allow user to go directly to a particular ROI.
%
% ROI_next/previous callbacks:
%    
%    change handles.current_roi to new roi. Call mcaview_update, which gets
%    scandata.roi(handles.current_roi).roi_state, and update all
%    uicontrols, including var2page and var3page.

% DO I REALLY NEED ALL THREE OF THE FOLLOWING CHECKS
if isempty(handles.d_roi) || isempty(handles.e_roi)
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%           Initialize new_roi                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The FIELDNAMES of handles.roi_state are the uicontrol tags whose
% properties we need.  But for some of the uicontrols, we need the 'String'
% property, and for others we need the 'Value' property.  So the value of
% handles.roi_state.(tag_name) is string 'String' or 'Value' -- the
% property we need to access for that particular uicontrol...
%
% There is a sharp distinction between handles.roi_state and new_roi.state:
% e.g. handles.roi_state.profile_select = 'Value', whereas
% roi.state.profile_select = 1..6

state_tags = fieldnames(handles.roi_state);
for k = 1:length(state_tags)
    new_roi.state.(state_tags{k}) = get(handles.(state_tags{k}), handles.roi_state.(state_tags{k}));
end
% Grab the value of those userdata variables that are used within
% makeprofile
for k = 1:length(handles.roi_vars)
    new_roi.(handles.roi_vars{k}) = handles.(handles.roi_vars{k});
end

new_roi.type = handles.PROFILE_NAMES{new_roi.state.profile_select};
% new_roi.sym = new_roi.state.roi_sym;
new_roi.x = []; new_roi.y = []; new_roi.z = []; new_roi.v = [];
new_roi.delta = []; new_roi.e_com = []; new_roi.ch_com = []; new_roi.e_fwhm = [];
new_roi.ch_fwhm = []; new_roi.fwhm = [];new_roi.compare = []; new_roi.chi = [];
new_roi.area = []; new_roi.norm_ctr = []; new_roi.norm = [];

if handles.scandata.spec.dims > 1
    warndlg('(mcaview_makeprofile : Higher-D plots disabed in gidview...');
%     page = (new_roi.state.var3page - 1) * handles.scandata.spec.size(2) + ...
%             new_roi.state.var2page;
else
    page = 1;
end

d_roi = new_roi.d_roi;
e_roi = new_roi.e_roi;

% handles.roi_shape can be 1(box), 2(vertical) or 3(horizontal)
box = new_roi.state.roi_shape;

% bksub can be 1(none), 2(gaussian), 3(linear bksub), or 4 (quad bksub)
bksub =  new_roi.state.bksub;
if bksub == 3 || bksub == 4  % CHECK THE MATH BELOW on LEFT & RIGHT BKGD!!!
    left_bkgd = eval(get(handles.left_bkgd, 'String'));
    right_bkgd = eval(get(handles.right_bkgd, 'String'));
    bkgd = [left_bkgd right_bkgd] - e_roi(1)+1;
    if bksub == 3
        mode = 'lin';
    else
        mode = 'quad';
    end
elseif bksub == 2
    mode = 'lin';  % Vestigal variable
end
showfits = strcmp(get(handles.menu_options_showfits, 'Checked'), 'on');

dtcorr = strcmp(new_roi.state.profile_dtcorr, 'on') && ...
    length(handles.scandata.dtcorr)>1;

norm_to_ctr = new_roi.state.norm_to_ctr_toggle == 1;
if norm_to_ctr
    ctrs = get(handles.norm_ctr, 'String');
    new_roi.norm_ctr = ctrs{new_roi.state.norm_ctr};
    norm_col = find(strcmp(new_roi.norm_ctr, ...
        handles.scandata.spec.headers), 1);
    norm_ref = sscanf(new_roi.state.norm_ref, '%f', 1);
end

image=single(handles.scandata.mcadata(:,:,page));

switch new_roi.type
    case handles.PROFILE_NAMES{1} % Energy 
        % Calculate intensity vs. energy for a certain depth range
        if box == 2
            d_roi = 1:size(image,2);
        elseif box == 3
            e_roi = 1:size(image,1);
        end

        image = image(e_roi, d_roi);
        delta = sqrt(image);
        
        if dtcorr
            for k = 1:size(image,2)
                image(:, k) = image(:, k)*handles.scandata.dtcorr(d_roi(k), page);
                if length(handles.scandata.dtdel) > 1
                    delta(:,k) = delta(:,k)*handles.scandata.dtdel(d_roi(k), page);
                else
                    delta(:,k) = delta(:,k)*handles.scandata.dtdel;
                end
            end
        end
        
        if norm_to_ctr
            new_roi.norm = handles.scandata.spec.data(norm_col, d_roi, page);
            for k = 1:size(image,2)
                image(:, k) = image(:, k)*norm_ref/new_roi.norm(k);
                delta(:,k) = delta(:,k)*norm_ref/new_roi.norm(k);
            end
        end        
        
        % Background subtration, normalization, etc should be added here...
        if length(d_roi)>1
            %             i_vs_d = sum(image(e_roi, d_roi));
            %             peak_data = find_peak(row(handles.scandata.depth(d_roi)), i_vs_d);
            %             new_roi.e_com = peak_data.com;
            i_vs_e = sum(image,2);
            delta = sqrt(sum(delta.^2,2));
            dstep  = handles.scandata.spec.var1(2)-handles.scandata.spec.var1(1);
        else
            %             new_roi.com = handles.scandata.depth(d_roi);
            i_vs_e = image;
            delta = sqrt(delta.^2);
            dstep = 1;
        end
        
        i_vs_e = double(i_vs_e);
%        chan = handles.scandata.channels(e_roi);
        chan = handles.scandata.energy(e_roi);
        
        switch bksub
            case 1
                peak_data = find_peak(chan, i_vs_e);
                %area = peak_data.area;
                %ch_com = peak_data.com;
            case  2
                peak_data = gauss_fit(chan, i_vs_e, 'mode', mode);
                %area = peak_data.area;
                %ch_com = peak_data.com;
                if showfits
                    showplots(chan, i_vs_e, peak_data.compare, peak_data.chi);
                end
            case {3,4}
                peak_data = find_peak(chan, i_vs_e, 'mode', mode, 'back', bkgd);
                %area = peak_data.area;
                %ch_com = peak_data.com;
                if showfits
                    showplots(chan, i_vs_e, peak_data.bkgd);
                end
            case {5,6}
                if bksub == 6
                    peak = '2';
                else
                    peak = '1';
                end
                peak_data = gauss_fit_double(chan, i_vs_e, 'peak', peak);
                if isempty(peak_data)
                    return
                end
                %area = peak_data.area;
                %ch_com = peak_data.com;
                if showfits
                    showplots(chan, i_vs_e, peak_data.compare, peak_data.chi,...
                            'marks',peak_data.com);
                end
        end
        area = peak_data.area;
        ch_com = peak_data.com;
        ch_fwhm = peak_data.fwhm;

        new_roi.x = channel2energy(handles.scandata.channels(e_roi), handles.scandata.ecal);
        new_roi.y = i_vs_e;

        if isfield(peak_data, 'compare')
            new_roi.compare = peak_data.compare;
        end

        if isfield(peak_data, 'chi')
            new_roi.chi = peak_data.chi;
        end
        
        
        new_roi.area = area*dstep;
        new_roi.delta = delta;

%        peak_data = find_peak(new_roi.x,new_roi.y);
        new_roi.ch_com = ch_com;
        new_roi.ch_fwhm = ch_fwhm;
        new_roi.e_com = channel2energy(ch_com, handles.scandata.ecal);
        new_roi.e_fwhm = channel2energy(ch_com + ch_fwhm/2.0, handles.scandata.ecal)-...
            channel2energy(ch_com - ch_fwhm/2.0, handles.scandata.ecal);

        %new_roi.counts = peak_data.counts;
        %new_roi.delta = peak_data.delta;
    case handles.PROFILE_NAMES{2} % Depth
        % Calculate intensity vs. depth for a certain energy range.  

        if length(d_roi) > 1
            i_vs_e = double(sum(image(e_roi, d_roi), 2));
        else
            errordlg('For depth profile, ROI must contain more than one depth point');
            return
        end
        
%        chan = handles.scandata.channels(e_roi);
        chan = handles.scandata.energy(e_roi);
        if box == 2
            d_roi = 1:size(image,2);
        elseif box == 3
            e_roi = 1:size(image,1);
        end

        roi = double(image(e_roi, d_roi));

        if length(e_roi) == 1
            y = roi;
            ch_com = chan;
            ch_fwhm = 1;
        else
            switch bksub
                case 1
                    peak_data = find_peak(chan, i_vs_e);
                    %ch_com = peak_data.com;
                    %fwhm = peak_data.fwhm;
                    y = sum(roi); % sums over depth points.
                    delta = sqrt(y);
                case  2
                    peak_data = gauss_fit(chan, roi, 'mode', mode, 'sampley', i_vs_e);
                    y = peak_data.area;
                    delta = sqrt(y); % This is sort of kosher, but better would be fit pars
                    %ch_com = peak_data.com;
                    %fwhm = peak_data.fwhm;
                    if showfits
                        showplots(chan, roi, peak_data.compare, peak_data.chi);
                    end
                case {3,4}
                    %peak_data = find_peak(chan, i_vs_e, 'mode', mode, 'back', bkgd);
                    %ch_com = peak_data.com;
                    %fwhm = peak_data.fwhm;
                    peak_data = find_peak(chan, roi, 'mode', mode, 'back', bkgd);
                    y = peak_data.area;
                    delta = sqrt(y);
                    if showfits
                        showplots(chan, roi, peak_data.bkgd);
                    end
                case {5,6}
                    if bksub == 6
                        peak = '2';
                    else
                        peak = '1';
                    end
                    peak_data = gauss_fit_double(chan, roi, 'sampley', i_vs_e,'peak', peak);
                    if isempty(peak_data)
                        return
                    end
                    y = peak_data.area;
                    %fwhm = peak_data.fwhm;
                    delta = sqrt(y); % This is sort of kosher, but better would be fit pars
                    %ch_com = peak_data.com;
                    if showfits
                        showplots(chan, roi, peak_data.compare, peak_data.chi,...
                            'marks',peak_data.com);
                    end
            end
            ch_com = peak_data.com;
            ch_fwhm = peak_data.fwhm;
        end % if bksub

        if dtcorr
            deadcorr = handles.scandata.dtcorr(d_roi, page)';
            if length(handles.scandata.dtdel) > 1
                dead_delta = handles.scandata.dtdel(d_roi, page)';
            else
                dead_delta = handles.scandata.dtdel;
            end
        else
            deadcorr = 1;
            dead_delta = 1;
        end
        
        if isfield(peak_data, 'compare')
            new_roi.compare = column(peak_data.compare);
        end

        if isfield(peak_data, 'chi')
            new_roi.chi = column(peak_data.chi);
        end
        
        new_roi.x = handles.scandata.spec.var1(d_roi,page);
        new_roi.delta = column(delta .* dead_delta);
        new_roi.y = column(y.*deadcorr);
        if norm_to_ctr
            new_roi.norm = column(handles.scandata.spec.data(norm_col, d_roi, page));
            new_roi.y = new_roi.y.*norm_ref./new_roi.norm;
            new_roi.delta = new_roi.delta.*norm_ref./new_roi.norm;
        end
        new_roi.ch_com = ch_com;
        new_roi.ch_fwhm = ch_fwhm;
        new_roi.e_com = channel2energy(ch_com, handles.scandata.ecal);
        new_roi.e_fwhm = channel2energy(ch_com + ch_fwhm/2.0, handles.scandata.ecal)-...
            channel2energy(ch_com - ch_fwhm/2.0, handles.scandata.ecal);
        
        peak_data = find_peak(new_roi.x,new_roi.y);
        new_roi.fwhm = peak_data.fwhm;


end

if ~isfield(handles.scandata, 'roi') || isempty(handles.scandata.roi)
    target_index = 1;
    handles.scandata.roi = new_roi;
elseif strcmp(get(handles.mode, 'String'), 'new')  && ...
        ~isequal(handles.roi_rect, handles.scandata.roi(handles.roi_index).roi_rect)
    target_index = length(handles.scandata.roi)+1;
    handles.scandata.roi(target_index) = new_roi;
else
    target_index = handles.roi_index;    
    handles.scandata.roi(target_index) = new_roi;
end
handles.roi_index = target_index;
handles.n_rois = length(handles.scandata.roi);
handles.scandata_saved = 0;

function [image, delta] = dtcorrect(image, delta, deadcorr, dead_delta)
% dtcorrect is a utility used by make_aplot, to modularize the computation
% of dead-time-corrected spectra.  image, and delta are already the correct
% dimensions, wherease deadcorr and dead_delta have the full dimensions of
% the data array. In other words, image has the dimensions deadcorr(d_roi,
% spectra).

for k = 1:size(image,2)*size(image, 3)
    image(:,k) = image(:,k) .* deadcorr(k);
    if ~isempty(dead_delta > 1)
        delta(:,k) = delta(:,k) .* dead_delta(k);
    end
end