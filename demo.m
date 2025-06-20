%% Load OTA data

close all;
clear all;
clc;
data_file = 'data/drone_1200_00.mat'; % Data file to test
data = load(data_file);
data = data.data;
if ~iscolumn(data)
    data = data.';
end

%% Plot raw data

fs = 50e6; % Sampling rate
effective_duration = 50; % Visualize a small portion of the data for faster processing
freq_resolution = .05e6; % Plotting resolution
frequency_unit = 1e6; % Plotting units
time_unit = 1e3; % Plotting units

effective_duration = effective_duration * fs * 1e-3;
test_data = data(1:effective_duration);

plot_spectrogram(test_data, fs, freq_resolution, frequency_unit, time_unit);

%% Label the signal using WHIRLS

snr_threshold = 20; % Log-scale SNR threshold for labeling
freq_resolution = .1e6; % Frequency resolution for labeling 
time_resolution = 1e-6; % Time resolution for labeling
slide_window = 3; % Slide window size for labeling

power_bw = []; % Empty by default;
               % If more prior knowledge is known about the signal,
               % set power_bw to the actual SNR of the signal to obtain
               % tighter labels.
filtered_bw = fs; % Filtered bandwidth - no need to change unless there's oversampling

[start_idx, end_idx, flos, fhis] = generateLabels(test_data, fs, filtered_bw, ...
                                                  time_resolution, power_bw, ...
                                                  slide_window, snr_threshold, freq_resolution);

%% Plot labeled data

fcs = (flos + fhis)/2; % Compute center frequencies
bws = fhis - flos; % Compute bandwidths

freq_resolution = .05e6; % Plotting resolution
frequency_unit = 1e6; % Plotting units
time_unit = 1e3; % Plotting units
ids = []; % ID list if transmitter labels are assigned
plot_spectrogram(test_data, fs, freq_resolution, ...
                 frequency_unit, time_unit, start_idx, end_idx, fcs, bws, ids);

