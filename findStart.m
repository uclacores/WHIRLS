function index = findStart(peaks, threshold, slide_window)
arguments
    peaks
    threshold
    slide_window = 3
end

% The start of a transmission is detected if:
%   1. Within a slide_window, the peaks are increasing monotonically,
%      and the last peak is greater than the threshold.
%      (The signal starts with noise, and transmission starts later.)
%   2. Within a slide_window, all the peaks are greater than the threshold.
%      (When the signal starts with an ongoing transmission.)

index = 0;
if length(peaks) >= slide_window
    for start_idx = 1:length(peaks)-slide_window+1
        cur_idx = start_idx;
        if peaks(cur_idx) > threshold
             while (cur_idx < start_idx+slide_window-1) && (peaks(cur_idx) > threshold)
                cur_idx = cur_idx + 1;
             end
        else
            while (cur_idx < start_idx+slide_window-1) && (peaks(cur_idx) < peaks(cur_idx+1))
                cur_idx = cur_idx + 1;
            end
        end
        if cur_idx == start_idx+slide_window-1 && peaks(cur_idx) > threshold
            index = start_idx;
            break;
        end
    end
end


end