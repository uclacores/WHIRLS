function [flo, fhi] = findFreqs(data, fs, filtered_bw, freq_resolution, snr_threshold, power_bw, wrapped_signal, noise_floor)
arguments
    data
    fs
    filtered_bw
    freq_resolution = 0.1e6
    snr_threshold = 3
    power_bw = []
    wrapped_signal = false
    noise_floor = []
end

slide_window = 3;


if isempty(filtered_bw)
    filtered_bw = fs;
end

% Compute the fft_window based on the sampling rate and the desired
% frequency resolution.
fft_window = fs/freq_resolution;
exponents = ceil(log2(fft_window));
fft_window = 2^exponents;
fft_window = min(fft_window, length(data));

% Compute the resulted PSD and find the bandwidth accordingly.
if wrapped_signal
    [psd, f] = pwelch(data, fft_window, [], fft_window, fs, 'twosided');
else
    [psd, f] = pwelch(data, fft_window, [], fft_window, fs, 'centered');
end

if isempty(noise_floor)
    freq_idx = ceil((fs-filtered_bw)/2/fs*length(psd));
    noise_floor = min(10*log10(psd(freq_idx+1:length(psd)-freq_idx-1)));
end

log_psd = 10*log10(psd);
max_power = max(log_psd);

if max_power - noise_floor < snr_threshold 
    flo = [];
    fhi = [];
    return;    
end

if isempty(power_bw)
    power_bw = (max_power - noise_floor)/2;
end

[~, flo, fhi, ~] = powerbw(psd, f, [], power_bw);

if wrapped_signal
    low_freq_idx = max(1, floor(flo/fs*length(psd)));
    high_freq_idx = min(length(psd), ceil(fhi/fs*length(psd)));
else
    low_freq_idx = max(1, floor(flo/fs*length(psd) + length(psd)/2));
    high_freq_idx = min(length(psd), ceil(fhi/fs*length(psd) + length(psd)/2));
end

new_power_bw = [];
while isempty(new_power_bw)
    if low_freq_idx == 1 && high_freq_idx == length(psd)
        break;
    end

    low_edge_idx = max(1, low_freq_idx-slide_window+1);
    out_of_detect = sum(log_psd(low_edge_idx:low_freq_idx-1) > max_power-power_bw);
    if out_of_detect > 0
        low_edge_idx = find(log_psd(1:low_freq_idx-1) <= max_power-power_bw, 1, 'last');
        if isempty(low_edge_idx)
            low_freq_idx = 1;
        else
            low_freq_idx = low_edge_idx;
        end
        if log_psd(low_freq_idx) > noise_floor
            new_power_bw = max_power - log_psd(low_freq_idx);
        end
    end

    high_edge_idx = min(length(psd), high_freq_idx+slide_window-1);
    out_of_detect = sum(log_psd(high_freq_idx+1:high_edge_idx) > max_power-power_bw);
    if out_of_detect > 0
        high_edge_idx = find(log_psd(high_freq_idx+1:end) <= max_power-power_bw, 1);
        if isempty(high_edge_idx)
            high_freq_idx = length(psd);
        else
            high_freq_idx = high_freq_idx + high_edge_idx;
        end
        if log_psd(high_freq_idx) > noise_floor
            if isempty(new_power_bw)
                new_power_bw = max_power - log_psd(high_freq_idx);
            else
                new_power_bw = max(new_power_bw, max_power - log_psd(high_freq_idx));
            end
        end
    end
    if isempty(new_power_bw)
        break;
    else
        power_bw = new_power_bw;
        new_power_bw = [];
    end
end

% Convert the indices into frequency edges.
if wrapped_signal
    flo = low_freq_idx / length(psd) * fs;
    fhi = high_freq_idx / length(psd) * fs;
else
    flo = low_freq_idx / length(psd) * fs - fs/2;
    fhi = high_freq_idx / length(psd) * fs - fs/2;
end


end