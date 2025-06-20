function [start_idx, end_idx] = findTransmissions(data, fs, time_resolution, slide_window, snr_threshold, noise_floor)
arguments
    data
    fs
    time_resolution
    slide_window = 3
    snr_threshold = 20
    noise_floor = []
end

% Make sure the data is column vector.
[row, ~] = size(data);
if row == 1
    data = data.';
end

mov_window = fs*time_resolution;
exponents = ceil(log2(mov_window));
mov_window = 2^exponents;
mov_window = min(mov_window, length(data));

% Find the smoothed signal power by moving Average.
mov_overlap = 0;
movAvg = dsp.MovingAverage(mov_window, mov_overlap);
data_avg = movAvg(abs(data).^2/fs);
data_avg = 10*log10(data_avg);

[peaks, peak_locs] = findpeaks(data_avg);

time_noise_floor = min(peaks);

if isempty(noise_floor)
    noise_floor = min(peaks);
end


if time_noise_floor > noise_floor
    start_power_threshold = noise_floor + snr_threshold;
    end_power_threshold = noise_floor + snr_threshold/2;
else
    start_power_threshold = noise_floor + snr_threshold;
    end_power_threshold = min(noise_floor + snr_threshold/2, time_noise_floor + snr_threshold);
end

% Repeatedly find all transmissions in a signal.
peak_start_idx = [];
peak_end_idx = [];
cur_idx = 1;

% Examine the remaining signal if it is longer than the slide_window
while cur_idx < length(peaks) - slide_window + 1
    % Find a transmission start on the remaining signal.
    cur_start = findStart(peaks(cur_idx:end), start_power_threshold, slide_window);
    % If the function detects a transmission, it will return the index of
    % the starting point. Then, add the offset back to the detected
    % starting index and save to the list.
    if cur_start ~= 0 && length(peaks(cur_start+cur_idx-1:end)) > slide_window
        cur_start = cur_start + cur_idx - 1;
        peak_start_idx = [peak_start_idx, cur_start];
    else
        % The function returns [] if no transmission is detected.
        % In such cases, break the loop.
        break;
    end
    % The findEnd function will only be used on a signal starting with a
    % transmission.
    cur_end = findEnd(peaks(cur_start+slide_window:end), end_power_threshold, slide_window);
    cur_end = cur_end + cur_start + slide_window - 1;
    peak_end_idx = [peak_end_idx, cur_end];
    cur_idx = cur_end + 1;
    
end

% Convert the indices back to the original scale.
start_idx = [];
end_idx = [];
if ~isempty(peak_start_idx)
    for cur_idx=1:length(peak_start_idx)
        cur_start = peak_start_idx(cur_idx);
        cur_start = peak_locs(cur_start);
        cur_end = peak_end_idx(cur_idx);
        cur_end = peak_locs(cur_end);
        start_idx = [start_idx, cur_start];
        end_idx = [end_idx, cur_end];
    end
    % end_idx
    start_idx = max(1, start_idx * (mov_window-mov_overlap) + mov_overlap - mov_window/2);
    end_idx = min(length(data), end_idx * (mov_window-mov_overlap) + mov_overlap + mov_window/2);

    if peak_end_idx(end) == length(peaks) || end_idx(end) > length(data)
        end_idx(end) = length(data);
    end

end

% Clear objects to avoid possible undefiend behaviors/memory leak.
clear movVar;


end