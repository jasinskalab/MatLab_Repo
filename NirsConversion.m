%% Add NIRS Toolbox to your path
addpath(genpath('/Users/jasinskagroup/Documents/MATLAB/NirsToolbox'));

%% Import data
raw = nirs.io.loadDirectory('GroupAnalyses',{'group','subject','task'});
try 
    save(['/Volumes/data/Data/ben-IC/raw_analyzir_groupdata_' date '.mat'],'raw');
catch
    save(['raw_analyzir_groupdata_' date '.mat'],'raw');
end
%% Adjust stim durations
% Manually with the GUI
%raw = nirs.viz.StimUtil(raw);