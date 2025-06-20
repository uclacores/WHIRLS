function index = findEnd(peaks, threshold, slide_window)
arguments
    peaks
    threshold
    slide_window = 3
end

% The end of a transmission is detected if:
%   1. Within a slide_window, the peaks are decreasing monotonically,
%      and the last peak is lower than the threshold.
%   2. Within a slide_window, all peaks are lower than the threshold.
%   3. The peak array has been exhausted.
%      (When the transmission is not completed within the signal.)

for end_idx = 1:length(peaks)-slide_window+1
    cur_idx = end_idx;
    if peaks(cur_idx) < threshold
        while (cur_idx < end_idx+slide_window-1) && (peaks(cur_idx) < threshold)
            cur_idx = cur_idx + 1;
        end
        if cur_idx == end_idx+slide_window-1
            if peaks(cur_idx) < threshold
                cur_idx = end_idx;
                break;
            end
        end
    else
        while (cur_idx < end_idx+slide_window-1) && (peaks(cur_idx) > peaks(cur_idx+1))
            cur_idx = cur_idx + 1;
        end
        if cur_idx == end_idx+slide_window-1
            if peaks(cur_idx) < threshold
                break;
            end
        end
    end
end
if length(peaks) < slide_window
    index = length(peaks);
else
    index = min(end_idx+slide_window-1, length(peaks));
end


end