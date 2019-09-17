classdef prep_PStast
    
    %PREP_PSTAST Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods
        function obj = prep_PStask(inputArg1,inputArg2)
            %PREP_PSTAST Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end
        %%
        %SubjectID        - ID of subject to run
        %log_path         - location of log files in directory (should be located
        %inside behavioural)
        %nirs_output_path - Location of nirs files that will be copied to a
        %nirs_sorted Folder
        
        %{
        Possible Exceptions:
        Empty Dir Struct(L:34) - if Nirs_sorted doesnt exist dir will return
        an empty set which may cause undefined behaviour
        
        
        %}
        function outputArg = prep_CIV_task(subjectID,log_path,nirs_output_path)
            %If exists then log_path is good otherwise we should look for
            %another path. Right now error checking will just be throw
            %exception
            if(~exists(log_path))
                error("log folder not found in directory");
            elseif(exists([pwd filesep '*/*/Print_Speech/data/']))
                log_path = [pwd filesep subjectID '/*/*.log'];
            end
            if(exists(nirs_output_path))
                nirs_path=nirs_output_path;
            elseif(exists([pwd filesep '*/*/Print_Speech/data/']))
                nirs_path = [pwd filesep subjectID '/*.nirs'];
            else
                error("nirs folder not found in directory");
            end
            
            %log_path = [pwd filesep '*/*/Print_Speech/data/'];
            %nirs_path = [pwd filesep 'NIRS_sorted'];
            %subject_id = '03_10_02';
            
            nirs_subjs = dir('NIRS_sorted');
            nirs_subjs = nirs_subjs([nirs_subjs.isdir]);
            
            nirs_files = [];
            raw = nirs.core.Data;
            nirs_subjs = dir('NIRS_sorted');
            nirs_subjs = nirs_subjs([nirs_subjs.isdir]);
            
            nirs_files = [];
            raw = nirs.core.Data;
            
            for sid = 3:length(nirs_subjs)
                subject_id = nirs_subjs(sid).name;
                
                %% Find all the log files and nirs files for a subject and match them up
                
                % Search for the log files and nirs files, and compare the times in their
                % filenames. If times are within 1 minute of each other, they get matched
                [logicalArr, ps_nirs_sorted, ps_log_sorted] = match_ps_stims.match_files(subject_id,nirs_path,log_path);
                
                % Copy the log file from the log path to the nirs path
                %match_ps_stims.cpNirsToLog(ps_log_sorted,ps_nirs_sorted(1).folder)
                
                if ~isempty(ps_nirs_sorted)
                    nirs_files = [nirs_files; ps_nirs_sorted];
                    for i = 1:length(ps_nirs_sorted)
                        
                        try
                            
                            [status,logDiffs1,nirsDiffs1,info] = NirsDataMatching.run([ps_nirs_sorted(i).folder filesep ps_nirs_sorted(i).name], [log_path filesep ps_log_sorted(i).name]);
                            [logDiffs2, nirsDiffs2, blocklabels] = needlemanWunsch.AlignNeedlemanWunsch(logDiffs1,nirsDiffs1,info.BlockText);
                            
                            nirs_inferred = needlemanWunsch.reconstructFromAlignedDiff(nirsDiffs2,logDiffs2,info.SortedNirsTriggerTimes(1));
                            
                            %         disp('Old NIRS times:')
                            %         info.SortedNirsTriggerTimes
                            
                            blockstims = cellfun(@(x) strcmp(x,'selectBlock'),blocklabels(:,1));
                            blocklabels(blockstims,3) = cellfun(@(x) ['Condition' x(end-1)],blocklabels(blockstims,3),'UniformOutput',false);
                            
                            %         disp('Reconstructed NIRS times:')
                            %         [num2cell(nirs_inferred) blocklabels(:,3)]
                            
                            cond_names = unique(blocklabels(:,3));
                            outcell = cell(length(blocklabels(:,3)),length(cond_names)*4);
                            for c = 1:length(cond_names)
                                outcell{1,(c-1)*4+1} = [cond_names{c} '@onset'];
                                outcell{1,(c-1)*4+2} = [cond_names{c} '@duration'];
                                outcell{1,(c-1)*4+3} = [cond_names{c} '@amplitude'];
                                outcell{1,(c-1)*4+4} = [''];
                                
                                matches = find(ismember(blocklabels(:,3),cond_names(c)));
                                for row = 1:length(matches)
                                    outcell{row+1,(c-1)*4+1} = nirs_inferred(matches(row));
                                    outcell{row+1,(c-1)*4+2} = 10;
                                    outcell{row+1,(c-1)*4+3} = 1;
                                end
                            end
                            outtable = table(outcell);
                            [~, sheetname, ~] = fileparts(ps_nirs_sorted(i).name);
                            writetable(outtable,['stimulus_onsets_aligned_' date '.xls'],'WriteVariableNames',false,'Sheet',sheetname);
                            raw(end+1) = nirs.io.loadDotNirs([ps_nirs_sorted(i).folder filesep ps_nirs_sorted(i).name]);
                            raw(end).demographics('subject') = subject_id;
                            
                        catch
                            errorfile = fopen(['error_file_' date '.txt'],'a');
                            try
                                fprintf(errorfile,'Problem with %s and %s\n',ps_nirs_sorted(i).name,ps_log_sorted(i).name);
                            catch
                                fprintf(errorfile,'Problem with %s\n',ps_nirs_sorted(i).name);
                            end
                        end
                        
                    end
                end
            end
            raw = raw(2:end);
            raw_stim = nirs.design.read_excel2stim(raw,'stimulus_onsets_aligned_03-Apr-2019.xls');
            %% Remove Stim_Channel2 (the on/off signal for a run)
            rm_ch = nirs.modules.DiscardStims;
            rm_ch.listOfStims = {'stim_channel2','stim_channel5'};
            raw_stim2 = rm_ch.run(raw_stim);
            
            raw_stim2 = nirs.design.change_stimulus_duration(raw_stim2,'start',0.1);
            
            for i = 1:length(raw_stim2)
                if ~isempty(raw_stim2(i).stimulus('stop'))
                    raw_stim2(i) = nirs.design.change_stimulus_duration(raw_stim2(i),'stop',0.1);
                end
            end
            
            %% Trim baseline data (stim_channel2, in this case)
            % We can improve our model fit by removing all the pre- and post-experiment
            % data, which is often full of motion artifacts and other unsavory bits
            trim_job = nirs.modules.TrimBaseline;
            trim_job.resetTime = 'start'; % The stim signal cut dat
            trim_job.preBaseline = 0; % Cut 0 sec to the left of start
            raw_stim2 = trim_job.run(raw_stim2);
            
            trim_job = nirs.modules.TrimBaseline;
            trim_job.resetTime = 'stop'; % The stim signal cut dat
            trim_job.postBaseline = 0; % Cut 0 sec to the right of stop
            raw_stim2 = trim_job.run(raw_stim2);
            
            %% Rename Stims
            mv_stim = nirs.modules.RenameStims;
            mv_stim.listOfChanges = {...
                'Condition1','visword';...
                'Condition2','vispseudo';...
                'Condition3','visfalse';...
                'Condition4','audword';...
                'Condition5','audpseudo';...
                'Condition6','audfalse';...
                };
            raw_stim2 = mv_stim.run(raw_stim2);
            
            %% Preprocess the data
            preproc = nirs.modules.OpticalDensity;
            preproc = BeerLambertLaw_nLambda(preproc);
            preproc = nirs.modules.Resample(preproc);
            HB_data = preproc.run(raw_stim2);
            
            %% Model
            % GLM to estimate task-level effects
            glm_job = nirs.modules.GLM;
            glm_job.type = '?';
            glm_job.type = 'AR-IRLS'
            RunLevelStats = glm_job.run(HB_data);
            
            % Same LME model used in ANOVA now with t-stats for post-hoc testing
            lme_job = nirs.modules.MixedEffects;
            lme_job.formula='beta ~ -1 + cond + (1|subject)';
            lme_job.dummyCoding = 'full' ;
            HbModel = lme_job.run(RunLevelStats);
            HbModel.probe = headdim2probe1020(HbModel.probe);
            %HbModel.draw('tstat',[],'q<0.05')
            
            audwordish = HbModel.ttest('audword-audfalse');
            audwordish.draw('tstat',[],'q<0.01');
            
            visstim = HbModel.ttest('visfalse-audfalse');
            visstim.draw('tstat',[],'q<0.01');
        end
    end
end

