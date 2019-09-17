classdef needlemanWunsch
    %NEEDLEMANWUNSCH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        gapPenalty = -5;
        mismatchPenalty = -5;
        matchAward = 20;
        smallDistAward = 5
    end
    
    methods (Static)
        %%
        function out = matchScore(alpha, beta)
            out = -abs(alpha-beta);
        end
        %%
        %dif
        function [LogAligned,NirsAligned,BlockAligned] = AlignNeedlemanWunsch(mSeq1,mSeq2,BlockInfo)
            %NEEDLEMANWUNSCH Construct an instance of this class
            % mSeq1 should be diff of Log times
            % mSeq2 should be diff of NIRS times
            
            %   Detailed explanation goes here
            tolerance = .2;
            
            if(nargin<2)
                return;
            end
            
            if ~exist('BlockInfo','var')
                BlockInfo = cell(length(mSeq2),1);
            end
            
            %             mSeq1 = [NaN;mSeq1];
            %             mSeq2 = [NaN;mSeq2];% need to pad a nan value to work better with the score table
            seq1Len = length(mSeq1);
            seq2Len = length(mSeq2);
            %             nw_score = NaN(seq1Len,seq2Len);
            %             nw_score(:,1,1) = mSeq1(:);
            %             nw_score(1,:,1) = mSeq2(:);
            
            
            LogAligned = {};%using cells because we need to be able to represent
            NirsAligned = {};
            BlockAligned = cell(0,size(BlockInfo,2));
            D=0;
            R=0;
            b_index = 1;
            a_index = 1;
            while(a_index<seq1Len&&b_index<seq2Len)
                
                fprintf('Comparing %g in mSeq1 with %g in mSeq2\n',a_index,b_index)
                
                
                if(abs(mSeq1(a_index)-mSeq2(b_index))<tolerance)
                    
                    fprintf('%02.1f and %02.1f within tolerance\n\n',mSeq1(a_index),mSeq2(b_index));
                    
                    score_current = needlemanWunsch.matchScore(mSeq2(b_index),mSeq1(a_index));
                    score_right = needlemanWunsch.matchScore(mSeq2(b_index),sum(mSeq1(a_index+1-R:a_index+1)));
                    score_down = needlemanWunsch.matchScore(sum(mSeq2(b_index+1-D:b_index+1)),mSeq1(a_index));
                    %score_next = needlemanWunsch.matchScore(mSeq2(b_index+1),mSeq1(a_index+1));
                    
                    % all scores are negative, so take max to get closest
                    % value to zero
                    best_cost = max([...
                        score_current,...
                        score_right+needlemanWunsch.gapPenalty*(R+1),...
                        score_down+needlemanWunsch.gapPenalty*(1+D)...
                        ]);
                    
                    if(best_cost == score_current)
                        LogAligned(end+1) = {mSeq1(a_index)};
                        NirsAligned(end+1) = {mSeq2(b_index)};
                        BlockAligned(end+1,:) = BlockInfo(a_index,:);
                        downflag = false;
                        rightflag = false;
                        R = 0;
                        D = 0;
                        a_index=a_index+1;
                        b_index=b_index+1;
                    elseif(best_cost == score_right+needlemanWunsch.gapPenalty*R)
                        a_index=a_index+1;
                        LogAligned(end+1) = {mSeq1(a_index)};
                        NirsAligned(end+1) = {nan};
                        BlockAligned(end+1,:) = BlockInfo(a_index,:);
                        R=R+1;
                    elseif(best_cost == score_down+needlemanWunsch.gapPenalty*D)
                        b_index=b_index+1;
                        NirsAligned(end+1) = {mSeq2(a_index)};
                        LogAligned(end+1) = {nan};
                        BlockAligned(end+1,:) = {'missing'};
                        D=D+1;
                    else
                        BlockAligned(end+1,:) = BlockInfo(a_index,:);
                        a_index=a_index+1;
                        b_index=b_index+1;
                    end

                    
                else
                    if(mSeq1(a_index)>mSeq2(b_index))
                        fprintf('%02.1f > %02.1f ',mSeq1(a_index),mSeq2(b_index));
                        if b_index==1
                            fprintf('Passing over presumed start trigger\n\n');
                            NirsAligned(end+1) = {mSeq2(b_index)};
                            LogAligned(end+1) = {nan};
                            BlockAligned(end+1,:) = {'start'};
                            b_index=b_index+1;%if seq1 is greater then we need to gap before it and recompare
                            D=D+1;
                        else
                            fprintf('Splitting the larger time diff in mSeq1\n\n');
                            LogAligned(end+1) = {mSeq2(b_index)};
                            mSeq1(a_index) = mSeq1(a_index) - mSeq2(b_index);
                            NirsAligned(end+1) = {nan};
                            BlockAligned(end+1,:) = {'missing'};
                            b_index=b_index+1;%if seq1 is greater then we need to gap before it and recompare
                            D=D+1;
                        end
                        
                    else
                        fprintf('%02.1f < %02.1f ',mSeq1(a_index),mSeq2(b_index));
                        if b_index==1
                            fprintf('Passing over presumed start trigger\n\n');
                            NirsAligned(end+1) = {mSeq2(b_index)};
                            LogAligned(end+1) = {nan};
                            BlockAligned(end+1,:) = {'start'};
                            b_index=b_index+1;
                            D=D+1;
                        else
                            fprintf('Splitting the larger time diff in mSeq2\n\n');
                            NirsAligned(end+1) = {mSeq1(a_index)};
                            mSeq2(b_index) = mSeq2(b_index)-mSeq1(a_index);
                            LogAligned(end+1) = {nan};
                            BlockAligned(end+1,:) = BlockInfo(a_index,:);
                            a_index=a_index+1;
                            R=R+1;
                        end
                        
                    end
                    
                end
            end
            %were at the end. Append the missed value
            LogAligned(end+1) = {mSeq1(a_index)};
            NirsAligned(end+1)= {mSeq2(b_index)};
            a_index= a_index+1;
            b_index= b_index+1;
            
            %Catch all the stragglers
            while a_index<=seq1Len
                LogAligned(end+1)= {mSeq1(a_index)};
                NirsAligned(end+1)= {nan};
                %BlockAligned(end+1,:) = BlockInfo(a_index,:);
                a_index= a_index +1;
                
            end
            while b_index<=seq2Len
                NirsAligned(end+1)= {mSeq2(b_index)};
                LogAligned(end+1)= {nan};
                %BlockAligned(end+1,:) = BlockInfo(b_index,:);
                b_index= b_index +1;
            end
            BlockAligned = [BlockAligned;BlockInfo(a_index-1:end,:)];            
            if size(BlockAligned,1) < (length(NirsAligned)+1)
                BlockAligned(end+1,:) = {'stop'};
            end
            NirsAligned(cellfun(@isnan,NirsAligned)) = LogAligned(cellfun(@isnan,NirsAligned));
            
            
        end
        function nirsTimes = reconstructFromAlignedDiff(nirsDiff,logDiff,nirsStartTime)
            if(nargin<3)
                disp('Too few parameters,cannot align');
                return;
            end
            if(isa(nirsDiff,'cell')&&isa(logDiff,'cell'))
                nirsDiff = transpose(cell2mat(nirsDiff));
                logDiff = transpose(cell2mat(logDiff));
            end
            nirsTimes = cumsum([nirsStartTime;nirsDiff]);
        end
        
        
        
        
        
        
        
        
        
        
        
        %% Done
        %not Needed
        %https://github.com/SPIN-Scorcerer/Error-Analysis/blob/master/error_analysis_code.py
        function outputDist = charLevenshtein(seq1,seq2, normalized,maxDist)
            if(nargin<4)
                if(~exist('maxDist',1))
                    maxDist = -1;
                end
                if(normalized=='')
                    normalized=0;%false
                end
            end
            if(nargin<3)
                if(~exist('maxDist',1))
                    maxDist = -1;
                end
                if(normalized=='')
                    normalized=0;%false
                end
            end
            if(noramlized)
                return; %%not yet implemented
            end
            
            if(seq1==seq2)
                outputDist = 0;
                return;
            end
            len1 = length(seq1);
            len2 = length(seq2);
            
            if(max_dist>=0 && abs(len1-len2)>maxDist)
                outputDist = -1;
                return;
            end
            
            if len1==0
                outputDist = len2;
                return;
            end
            
            if len2 == 0
                outputDist = len1;
                return;
            end
            
            if(len1<len2)
                tmp = len1;
                len1 = len2;
                len2 = tmp;
                clear(tmp);
                tmp = seq1;
                seq1 = seq2;
                seq2 = tmp;
                clear(tmp);
                
            end
            column = zeros(len2+1,1);
            for x = 2:len2+1
                column(0) =x;
                last = x-1;
                
                for y= 2:len2+1
                    old = column(y);
                    cost = (seq1(x-1)~=seq2(y-1));%%
                    column(y) = min(last+cost,column(y)+1,column(y-1)+1);
                    last = old;
                    
                end
                if max_dist>=0 && min(column)>maxdist
                    outputDist = -1;
                    return;
                end
                
            end
            if(maxDist>=0 && column(len2)>maxDist)
                outputDist = -1;
                return;
            end
            outputDist =column(len2);
            return;
            
        end
        %%
        
        
        
        
        
        
        %%the function to find path with shortest cost; I'm not really
        %%familiar with Matlab so i'm just gonna put down my thoughts here:
        %%take in the two difference vectors(converted from the fNirs and
        %%python file) and the difference table that we just computed in
        %%method intLevenshtein.
        %%use a double for-loop to parse through the 2d array
        %%3 cases that we should consider: 1. if two values are pretty much
        %%the same, then sum+=cost; 2. they are not close and none of them
        %%is a gap  3. the two values are not close but one of them is a
        %%gap, then we would need to add the previous value to the current
        %%one
        
        
    end
end

