classdef match_ps_stims
    
    methods(Static)
        function [logicalArr,ps_nirs_sorted,ps_log_sorted]= match_files(subject_id,path_to_nirs,path_to_pylog)
            ps_log_files_LIV = dir([path_to_pylog subject_id filesep '_printspeech*.log']);
            ps_log_files_CIV = dir([path_to_pylog subject_id filesep [subject_id '*'] filesep '*printspeech*.csv']);
            
            if(isempty(ps_log_files_CIV))
               match_ps_stims.match_files_LIV(subject_id,path_to_nirs,path_to_pylog);
            elseif(isempty(ps_log_files_LIV))
               match_ps_stims.match_files_CIV(subject_id,path_to_nirs,path_to_pylog);
            else
                throw("No stim files found");
                logicalArr = -1;
                return
            end
            
            %if result is -1 we didnt find .log or .csv files
            
            
            
        end
        
        function [logicalArr,ps_nirs_sorted,ps_log_sorted] = match_files_LIV(subject_id,path_to_nirs,path_to_pylog)
            
            %MATCH_FILES takes two lists: the Psychopy files and the .nirs
            %files for a given participant and tries to re-match them with
            %each other based on the times encoded in the filenames.
            %
            %Results are returned as a logical array of dimensions:
            %[nirs_files x log_files] and two sorted lists of files.
            %
            %A log file is also updated: match_files_log_[date].txt
            
            % Open the log file
            logfile = ['match_files_log_' date '.txt'];
            logfile = fopen(logfile,'a');
                        
            % Generate a list of the python .log files
            ps_log_files = dir([path_to_pylog filesep subject_id '_printspeech*.log']);
            % If no files are found, it might be because there are _ in the
            % subject_id. Try stripping those out and search again
            if isempty(ps_log_files)
                subject_id_temp = subject_id;
                subject_id_temp(regexp(subject_id,'[[a-z],[A-Z],_]'))=[];
                ps_log_files = dir([path_to_pylog filesep subject_id_temp '_printspeech*.log']);
            end
            % Discard any files smaller than 200KiB (definitely false-starts)
            ps_log_files = ps_log_files(arrayfun(@(x) x.bytes>200000, ps_log_files));
            
            % Generate a list of the python .log files
            ps_nirs_files = dir([path_to_nirs filesep subject_id filesep 'ps' filesep '*.nirs']);
            % Discard any files smaller than 1MiB (definitely false-starts)
            ps_nirs_files = ps_nirs_files(arrayfun(@(x) x.bytes>1000000, ps_nirs_files));
            
            fprintf(logfile,'%s: Found %g .log files and %g .nirs files. ',subject_id,length(ps_log_files),length(ps_nirs_files));

            logicalArr = zeros(length(ps_nirs_files),length(ps_log_files));
            for log_i = 1:length(ps_log_files)
                logtime = datetime(ps_log_files(log_i).name(end-19:end-4),'InputFormat','yyyy_MMM_dd_HHmm','TimeZone','Africa/Abidjan');
                for nirs_i = 1:length(ps_nirs_files)
                    nirstime = datetime(datetime(ps_nirs_files(nirs_i).name(end-19:end-5),'InputFormat','yyyyMMdd_HHmmss','Timezone','America/New_York'),'TimeZone','Africa/Abidjan');
                    logicalArr(nirs_i,log_i) = abs(nirstime-logtime)<minutes(1);
                end
            end
            
            [~, log_order] = sort([ps_log_files.datenum]);
            ps_log_sorted = ps_log_files(log_order);
            [nirs_order, ~, ~] = find(logicalArr(:,log_order));
            ps_nirs_sorted = ps_nirs_files(nirs_order);
            
            if all(sum(logicalArr,1)==1) && all(sum(logicalArr,2)==1)
                fprintf(logfile,'One-to-one matches found!\n');
                fclose(logfile);
            else
                fprintf(logfile,'No solution found!\n');
                ps_log_sorted = [];
                ps_nirs_sorted = [];
                fclose(logfile);
            end
        end
        
        
        
        
        
        function [logicalArr,ps_nirs_sorted,ps_log_sorted] = match_files_CIV(subject_id,path_to_nirs,path_to_pylog)
            
            %MATCH_FILES takes two lists: the Psychopy files and the .nirs
            %files for a given participant and tries to re-match them with
            %each other based on the times encoded in the filenames.
            %
            %Results are returned as a logical array of dimensions:
            %[nirs_files x log_files] and two sorted lists of files.
            %
            %A log file is also updated: match_files_log_[date].txt
            
            % Open the log file
            logfile = ['match_files_log_' date '.txt'];
            logfile = fopen(logfile,'a');
                        
            % Generate a list of the python .log files
            ps_log_files = dir([path_to_pylog subject_id filesep [subject_id '*'] filesep '*printspeech*.csv']);
            % If no files are found, it might be because there are _ in the
            % subject_id. Try stripping those out and search again
            if isempty(ps_log_files)
                subject_id_temp = subject_id;
                subject_id_temp(regexp(subject_id,'[[a-z],[A-Z],_]'))=[];
                ps_log_files = dir([path_to_pylog subject_id filesep [subject_id '*'] filesep '*printspeech*.csv']);
            end
            % Discard any files smaller than 200KiB (definitely false-starts)
            %ps_log_files = ps_log_files(arrayfun(@(x) x.bytes>200000, ps_log_files));
            
            % Generate a list of the python .log files
            ps_nirs_files = dir([path_to_nirs filesep subject_id filesep 'ps' filesep '*.txt']);
            % Discard any files smaller than 1MiB (definitely false-starts)
            ps_nirs_files = ps_nirs_files(arrayfun(@(x) x.bytes>1000000, ps_nirs_files));
            
            fprintf(logfile,'%s: Found %g .log files and %g .nirs files. ',subject_id,length(ps_log_files),length(ps_nirs_files));

            logicalArr = zeros(length(ps_nirs_files),length(ps_log_files));
            for log_i = 1:length(ps_log_files)
                try
                    logtime = datetime(ps_log_files(log_i).name(end-19:end-4),'InputFormat','yyyy_MMM_dd_HHmm','TimeZone','Africa/Abidjan');
                catch
                    logtime = datetime(ps_log_files(log_i).name(end-19:end-4),'InputFormat','yyyy_MMM_dd_HHmm','TimeZone','Africa/Abidjan');
                end
                for nirs_i = 1:length(ps_nirs_files)
                    nirstime = datetime(datetime(ps_nirs_files(nirs_i).name(end-18:end-4),'InputFormat','yyyyMMdd_HHmmss','Timezone','America/New_York'),'TimeZone','Africa/Abidjan');
                    logicalArr(nirs_i,log_i) = abs(nirstime-logtime)<minutes(1);
                end
            end
            
            [~, log_order] = sort([ps_log_files.datenum]);
            ps_log_sorted = ps_log_files(log_order);
            [nirs_order, ~, ~] = find(logicalArr(:,log_order));
            ps_nirs_sorted = ps_nirs_files(nirs_order);
            
            if all(sum(logicalArr,1)==1) && all(sum(logicalArr,2)==1)
                fprintf(logfile,'One-to-one matches found!\n');
                fclose(logfile);
            else
                fprintf(logfile,'No solution found!\n');
                ps_log_sorted = [];
                ps_nirs_sorted = [];
                fclose(logfile);
            end
        end
        function cpNirsToLog(ps_log_sorted,nirsSubjPath)
            
            for log_i = 1:length(ps_log_sorted)
                [status,msg] = copyfile([ps_log_sorted(log_i).folder filesep ps_log_sorted(log_i).name],nirsSubjPath);
                if ~status
                    disp msg
                end
            end
        end
        function run()
        end
        
        
        
    end
end



