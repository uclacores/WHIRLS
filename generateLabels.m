function [start_idx, end_idx, flos, fhis] = generateLabels(data, fs, filtered_bw, time_resolution, power_bw, slide_window, snr_threshold, freq_resolution)
arguments
    data
    fs
    filtered_bw
    time_resolution
    power_bw = []
    slide_window = 3
    snr_threshold = 0
    freq_resolution = 0.1e6
end

% Compute time and frequency parameters of all transmissions in a signal.


if isempty(filtered_bw)
    filtered_bw = fs;
end

fft_window = min(128, length(data));
[psd, ~] = pwelch(data, fft_window, [], fft_window, fs, 'centered');
freq_idx = ceil((fs-filtered_bw)/2/fs*length(psd));
noise_floor = min(10*log10(psd(freq_idx+1:length(psd)-freq_idx-1)));

mov_window = max(floor(length(data)/fft_window), 1);
mov_overlap = 0;
movAvg = dsp.MovingAverage(mov_window, mov_overlap);
data_avg = movAvg(abs(data).^2/fs);
data_avg = 10*log10(data_avg);
[peaks, ~] = findpeaks(data_avg);
noise_floor = min(min(peaks), noise_floor);

% Find the transmissions using a low threshold and low resolution.
[start_idx, end_idx] = findTransmissions(data, fs, time_resolution, slide_window, snr_threshold, noise_floor);

% Use loose estimation of start indices.
if ~isempty(start_idx)
    end_idx(1:end-1) = floor((start_idx(2:end) + end_idx(1:end-1))/2);
    end_idx(end) = length(data);
    start_idx(2:end) = end_idx(1:end-1);
    start_idx(1) = 1;
end

% For each detected transmission, check for possible overlapping and find the frequency parameters
flos = [];
fhis = [];
cur_idx = 1;
while cur_idx <= length(start_idx)
    % Find the frequency parameters for the detected transmission using a higher threshold.
    data_segment = data(start_idx(cur_idx):end_idx(cur_idx));

    % [psd, f] = pwelch(data_segment, fft_window, [], fft_window, fs, 'centered');
    % figure;
    % plot(f, 10*log10(psd));

    [cur_flo, cur_fhi] = findFreqs(data_segment, fs, filtered_bw, freq_resolution, snr_threshold, power_bw, false, noise_floor);
    if isempty(cur_flo)
        start_idx = [start_idx(1:cur_idx-1), start_idx(cur_idx+1:end)];
        end_idx = [end_idx(1:cur_idx-1), end_idx(cur_idx+1:end)];
        continue;
    end

    % Bandstop the detected transmission and look for possible transmissions on other channels
    if xor(cur_flo <= -fs/2, cur_fhi >= fs/2)
        [wrapped_cur_flo, wrapped_cur_fhi] = findFreqs(data_segment, fs, filtered_bw, freq_resolution, snr_threshold, power_bw, true, noise_floor);
        filtered_data = freqFilter(data_segment, fs, cur_flo, cur_fhi, "bandstop", false);
        if wrapped_cur_flo <= 0
            cur_fhi = wrapped_cur_fhi;
        elseif  wrapped_cur_fhi >= fs
            cur_flo = wrapped_cur_flo;
        else
            cur_flo = wrapped_cur_flo;
            cur_fhi = wrapped_cur_fhi;
        end
        filtered_data = freqFilter(filtered_data, fs, wrapped_cur_flo, wrapped_cur_fhi, "bandstop", true);
    else
        filtered_data = freqFilter(data_segment, fs, cur_flo, cur_fhi, "bandstop", false);
    end

    [s_idx, ~] = findTransmissions(filtered_data, fs, time_resolution, slide_window, snr_threshold, noise_floor);

    % If more than one transmission exist in the current signal using a higher threshold.
    if ~isempty(s_idx)
        % Find all occupied channels in the detected signal.
        while ~isempty(s_idx)

            % Estimate and save the frequency parameters for the currently detected transmission
            [tmp_flo, tmp_fhi] = findFreqs(filtered_data, fs, filtered_bw, freq_resolution, snr_threshold, power_bw, false, noise_floor);
            % Bandstop the detected transmission and look for possible transmissions on other channels
            if isempty(tmp_flo)
                break;
            end

            if xor(tmp_flo <= -fs/2, tmp_fhi >= fs/2)
                [wrapped_tmp_flo, wrapped_tmp_fhi] = findFreqs(filtered_data, fs, filtered_bw, freq_resolution, snr_threshold, power_bw, true, noise_floor);
                filtered_data = freqFilter(filtered_data, fs, tmp_flo, tmp_fhi, "bandstop", false);
                if wrapped_tmp_flo <= 0
                    tmp_fhi = wrapped_tmp_fhi;
                elseif  wrapped_tmp_fhi >= fs
                    tmp_flo = wrapped_tmp_flo;
                else
                    tmp_flo = wrapped_tmp_flo;
                    tmp_fhi = wrapped_tmp_fhi;
                end
                filtered_data = freqFilter(filtered_data, fs, wrapped_tmp_flo, wrapped_tmp_fhi, "bandstop", true);
            else
                filtered_data = freqFilter(filtered_data, fs, tmp_flo, tmp_fhi, "bandstop", false);
            end
            cur_flo = [cur_flo, tmp_flo];
            cur_fhi = [cur_fhi, tmp_fhi];

            [s_idx, ~] = findTransmissions(filtered_data, fs, time_resolution, slide_window, snr_threshold, noise_floor);

        end
        s_idx = [];
        e_idx = [];
        t_idx = 1;

        % For each channel, find and save the transmission start/end time.
        while t_idx <= length(cur_flo)
            tmp_flo = cur_flo(t_idx);
            tmp_fhi = cur_fhi(t_idx);
            % Bandpass the transmissions with the saved frequency parameters
            if tmp_fhi > fs/2
                if tmp_flo >= 0
                    filtered_data = freqFilter(data_segment, fs, tmp_flo, tmp_fhi, "bandpass", true);
                else
                    filtered_data = freqFilter(data_segment, fs, tmp_fhi, tmp_flo+fs, "bandstop", true);                    
                end
            elseif tmp_flo > tmp_fhi
                filtered_data = freqFilter(data_segment, fs, tmp_fhi, tmp_flo, "bandstop", true);
            else
                filtered_data = freqFilter(data_segment, fs, tmp_flo, tmp_fhi, "bandpass", false);
            end

            % Find all transmissions with current frequency parameters using a higher resolution.
            [tmp_s, tmp_e] = findTransmissions(filtered_data, fs, time_resolution, slide_window, snr_threshold, noise_floor);
            
            % Match the size of frequency parameter lists if multiple transmissions exist.
            if tmp_fhi > fs/2
                new_tmp_flo = [-fs/2, tmp_flo];
                new_tmp_fhi = [tmp_fhi-fs, fs/2];
                tmp_flo = repmat(new_tmp_flo, length(tmp_s), 1);
                tmp_flo = tmp_flo(:)';
                tmp_fhi = repmat(new_tmp_fhi, length(tmp_s), 1);
                tmp_fhi = tmp_fhi(:)';
                tmp_s = [tmp_s, tmp_s];
                tmp_e = [tmp_e, tmp_e];
            elseif tmp_flo > tmp_fhi
                new_tmp_flo = [-fs/2, tmp_flo];
                new_tmp_fhi = [tmp_fhi, fs/2];
                tmp_flo = repmat(new_tmp_flo, length(tmp_s), 1);
                tmp_flo = tmp_flo(:)';
                tmp_fhi = repmat(new_tmp_fhi, length(tmp_s), 1);
                tmp_fhi = tmp_fhi(:)';
                tmp_s = [tmp_s, tmp_s];
                tmp_e = [tmp_e, tmp_e];
            else
                tmp_flo = repmat(tmp_flo, 1, length(tmp_s));
                tmp_fhi = repmat(tmp_fhi, 1, length(tmp_s));
            end
            
            cur_flo = [cur_flo(1:t_idx-1), tmp_flo, cur_flo(t_idx+1:end)];
            cur_fhi = [cur_fhi(1:t_idx-1), tmp_fhi, cur_fhi(t_idx+1:end)];
            s_idx = [s_idx, tmp_s];
            e_idx = [e_idx, tmp_e];
            
            t_idx = length(s_idx) + 1;
        end
        % Update the transmission start/end time lists.
        s_idx = s_idx + start_idx(cur_idx) - 1;
        e_idx = e_idx + start_idx(cur_idx) - 1;
        start_idx = [start_idx(1:cur_idx-1), s_idx, start_idx(cur_idx+1:end)];
        end_idx = [end_idx(1:cur_idx-1), e_idx, end_idx(cur_idx+1:end)];
    else
        % Update the transmission lists if only a single transmission exists in the band.

        if cur_fhi > fs/2
            if cur_flo >= 0
                filtered_data = freqFilter(data_segment, fs, cur_flo, cur_fhi, "bandpass", true);
            else
                filtered_data = freqFilter(data_segment, fs, cur_fhi, cur_flo+fs, "bandstop", true);                    
            end
        elseif cur_flo > cur_fhi
            filtered_data = freqFilter(data_segment, fs, cur_fhi, cur_flo, "bandstop", true);
        else
            filtered_data = freqFilter(data_segment, fs, cur_flo, cur_fhi, "bandpass", false);
        end
        [s_idx, e_idx] = findTransmissions(filtered_data, fs, time_resolution, slide_window, snr_threshold, noise_floor);
        s_idx = s_idx + start_idx(cur_idx) - 1;
        e_idx = e_idx + start_idx(cur_idx) - 1;

        if cur_fhi > fs/2
            new_flo = [-fs/2, cur_flo];
            new_fhi = [cur_fhi-fs, fs/2];
            cur_flo = repmat(new_flo, length(s_idx), 1);
            cur_flo = cur_flo(:)';
            cur_fhi = repmat(new_fhi, length(s_idx), 1);
            cur_fhi = cur_fhi(:)';  
            s_idx = [s_idx, s_idx];
            e_idx = [e_idx, e_idx];
        elseif cur_flo > cur_fhi
            new_flo = [-fs/2, cur_flo];
            new_fhi = [cur_fhi, fs/2];
            cur_flo = repmat(new_flo, length(s_idx), 1);
            cur_flo = cur_flo(:)';
            cur_fhi = repmat(new_fhi, length(s_idx), 1);
            cur_fhi = cur_fhi(:)';  
            s_idx = [s_idx, s_idx];
            e_idx = [e_idx, e_idx];
        else
            cur_flo = repmat(cur_flo, 1, length(s_idx));
            cur_fhi = repmat(cur_fhi, 1, length(s_idx));
        end
        
        start_idx = [start_idx(1:cur_idx-1), s_idx, start_idx(cur_idx+1:end)];
        end_idx = [end_idx(1:cur_idx-1), e_idx, end_idx(cur_idx+1:end)];
    end
    if ~isempty(s_idx)
        % Save the transmission frequency parameters.
        flos = [flos, cur_flo];
        fhis = [fhis, cur_fhi];
        cur_idx = cur_idx + length(cur_flo);
    end
end
end
