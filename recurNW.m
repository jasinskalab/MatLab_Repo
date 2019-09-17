classdef recurNW
    %RECURNW Summary of this class goes here
    %   This algorith works through every possible path that could occur
    %   
    properties
        minTotalCost;
        minCostPath;
        minFlag = 0;
        minUpdates = 0;
        j_compare;
        i_compare;
        i_max;
        j_max;
        nirsDiffSeq;
        pyDiffSeq;
        gapPenalty;
    end
    properties(Constant)
        gapPenaltyConst = -5;
        
    end
    methods(Static)
        
        function pathFig = plotPath(path, i_labels, j_labels)
            
            pathFig = figure;
            plot(path(:,2),path(:,1),'-o');
            set(gca,'Ydir','reverse')
            xlim([0,path(end,2)+1])
            ylim([0,path(end,1)+1])
            grid on
            
            labels = cell(size(path,1),1);
            for pt = 1:size(path,1)
                labels{pt} = [ num2str(round(i_labels(path(pt,1)),2)) ',' num2str(round(j_labels(path(pt,2)),2)) ];
            end
            text(path(:,2)-.4,path(:,1)-.25,labels)
        end
        
        function score = calcScore(one,two)
            score = -abs(diff([one;two]));
        end
        
        function obj = recur(obj,currCost,currPath,i,j)
            %this is our basic recursion entry call all recursion will
            %occur from this function. 
            
            if((i<obj.i_max||j<obj.j_max)&&(j>0&&i>0))
                obj.gapPenalty = obj.gapPenaltyConst;
                if(i==1&&j==1)
                    obj.gapPenalty = 0;
                end
                
                %First call to enter into the recursion. It will
                %systematically go through every one of the possible
                %combinations of down,right and next
                %these three moves are the only possible moves we can take
                %through this matrix
                
                [currCost,currPath,i,j,obj] = recurNW.down(obj,currCost,currPath,i,j);
                [currCost,currPath,i,j,obj] = recurNW.right(obj,currCost,currPath,i,j);
                [currCost,currPath,i,j,obj] = recurNW.next(obj,currCost,currPath,i,j);
                
                
            end
            
            
            
        end
        
        function [currCost,currPath,i,j,obj] = down(obj,currCost,currPath,i,j)%
            %this function will be the down recursion (i direction) 
            %
            
            
            %save our initial state so we can return to it;
            j_start = j;
            i_start = i-1;
            retPath = currPath;
            retCost = currCost;
            retCompareVector = [obj.i_compare,obj.j_compare];
            %ensure we are not in the bottom row already
            if(i<obj.i_max&&j~=obj.j_max)
                %keeps track of the current cost of a row or column based
                %on the gaps weve made. Only used in down and right
                if(i+j~=2)%if this is the first element ie (1,1)
                    obj.i_compare = obj.i_compare+obj.nirsDiffSeq(i);
                end
                %update our current path with the current i&j
                currPath = [currPath;i,j];
                i=i+1;
                currCost = obj.gapPenalty+currCost;% + recurNW.calcScore(obj.nirsDiffSeq(i),obj.pyDiffSeq(j));
                %recursion step
                obj = recurNW.recur(obj,currCost,currPath,i,j);
            elseif(i>=obj.i_max)%we in j
                %finish up the j sequence
                while(j<obj.j_max)
                    currCost = currCost + obj.gapPenalty;
                    if(i+j~=2)%make sure we arent on the first element
                        obj.j_compare= obj.j_compare+obj.pyDiffSeq(j);
                    end
                    currPath = [currPath;i,j];
                    j= j+1;
                end
                [~,~,~,~,obj] = recurNW.next(obj,currCost,currPath,i,j);
            end
            %return to our initial conditions to help us step out;
            obj.i_compare = retCompareVector(1);
            obj.j_compare = retCompareVector(2);
            i = i_start;
            j = j_start;
            currPath = retPath(1:end-1,:);
            currCost = retCost;
        end
        
        function [currCost,currPath,i,j,obj] = right(obj,currCost,currPath,i,j)
            %this function will be the right recursion (j direction)
            
            
            j_start = j-1;%since its incremented after appending to path
            i_start = i;
            retPath = currPath;
            retCost = currCost;
            retCompareVector = [obj.i_compare,obj.j_compare];
            %ensure we are not in the rightmost column already;
            if(j<obj.j_max&&i~=obj.i_max)
                
                if(isempty(obj.j_compare)||(i==1&&j==1))
                    obj.j_compare = 0;
                end
                
                
                
                %keeps track of the current cost of a row or column based
                %on the gaps weve made. Only used in down and right
                if(i+j~=2)
                    obj.j_compare = obj.j_compare + obj.pyDiffSeq(j);
                end
                %update our current path with the current i&j
                currPath = [currPath;i,j];
                j=j+1;
                currCost = obj.gapPenalty + currCost;% + recurNW.calcScore(obj.nirsDiffSeq(i),obj.pyDiffSeq(j));
                %recursion step
                obj = recurNW.recur(obj,currCost,currPath,i,j);
            elseif(j>=obj.j_max)%we in i
               
                
                %finish up the i sequence
                while(i<obj.i_max)
                    currCost = currCost + obj.gapPenalty;
                    if(i+j~=2)%make sure we arent on the first element
                        obj.i_compare= obj.i_compare+obj.nirsDiffSeq(i);
                    end
                    %these things should only happen if we are not
                    %comparing the values ie i and j != max
                    currPath = [currPath;i,j];
                    i=i+1;
                    
                end
                [~,~,~,~,obj] = recurNW.next(obj,currCost,currPath,i,j);
            end
            obj.i_compare = retCompareVector(1);
            obj.j_compare = retCompareVector(2);
            i = i_start;
            j = j_start;
            currPath = retPath(1:end-1,:);
            currCost = retCost;
            
        end
        
        function [currCost,currPath,i,j,obj] = next(obj,currCost,currPath,i,j)
            j_start = j;
            i_start = i;
            retPath = currPath;
            retCost = currCost;
            retCompareVector = [obj.i_compare,obj.j_compare];
            %ensure we can execute next without going out of bounds on
            %nirsSeq and pySeq
            if(i<=obj.i_max&&j<=obj.j_max)
                
                
                %setting comparison objects if they havent been set yet or
                %adding the final values to be compared or setting its
                %initial value
                if((obj.j_compare == 0)&&j~=0)
                    obj.j_compare = obj.pyDiffSeq(j);
                else
                    obj.j_compare = obj.j_compare + obj.pyDiffSeq(j);
                end
                if((obj.i_compare == 0)&&i~=0)
                    obj.i_compare = obj.nirsDiffSeq(i);
                else
                    obj.i_compare = obj.i_compare +obj.nirsDiffSeq(i);
                end
                currPath = [currPath;i,j];
                
                
                
                
                
                %update our current path with the current i&j
                currCost = currCost + recurNW.calcScore(obj.j_compare,obj.i_compare);
                fprintf('matched %g with %g for new cost %g\n',obj.j_compare,obj.i_compare,currCost);
  
                %dont increment if were performing i_max or j_max position
                if(i~=obj.i_max&&j~=obj.j_max)
                    i=i+1;
                    j=j+1;
                    
                end
                
                %recursion step
                obj = recurNW.recur(obj,currCost,currPath,i,j);
            end
            if(i>=obj.i_max&&j>=obj.j_max)
                %end step of the recursion we should only get here if we
                %have calculated the full path
                
                %currCost = currCost + recurNW.calcScore(obj.nirsDiffSeq(i),obj.pyDiffSeq(j));
                if(isempty(obj.minTotalCost))
                    obj.minTotalCost = currCost;
                    obj.minFlag = 1;
                else
                    obj.minTotalCost = max(currCost,obj.minTotalCost);% we max because if all costs are negative the ones closer to 0 are greater than negatives further from 0
                    %given all costs are negative we want the "minimum" of
                    %those costs
                    if(currCost==obj.minTotalCost)
                        obj.minFlag = 1;%signal that we have set a minimum
                        obj.minUpdates = obj.minUpdates+1;
                    end
                    
                end
                %set the min cost path because minFlag is 1
                if(obj.minFlag == 1)
                    obj.minCostPath = currPath;
                    obj.minFlag = 0;
                    if mod(obj.minUpdates,3)==0 % only display every 3 update
                        fprintf('Update %g sets new min %g\n',obj.minUpdates,obj.minTotalCost);
                    end
                end
                %At this point we are done with the path so we need to exit
                %the functions and step back to last unique path
            end
            
            %reset the save states
            obj.i_compare = retCompareVector(1);
            obj.j_compare = retCompareVector(2);
            i = i_start;
            j = j_start;
            currPath = retPath(1:end-1,:);
            currCost = retCost;
        end
        
        
        
        
        %to be finished
        function [nirsGapped,logGapped,rebuiltTimes] = rebuiltTriggerTimes(nirs,pylog,matchPath)
            for i = 1:length(matchPath)
                
            end
        end
        
        
        
    end
    
    methods
        function obj = recurNW(m_nirsDiffSeq,m_pyDiffSeq)
            %setup the initial object
            obj.nirsDiffSeq = m_nirsDiffSeq;
            obj.pyDiffSeq = m_pyDiffSeq;
            obj = obj.start();
            
        end
        function obj = start(obj)
            %wrapper to execute all necessary startup procedures and begin
            %the recursion
            obj.j_max = length(obj.pyDiffSeq);
            obj.i_max = length(obj.nirsDiffSeq);
            
            %initiate all values and start the recursion at the first case
            
            currCost = 0;
            currPath = [];
            i = 1;
            j = 1;
            obj.i_compare = 0;
            obj.j_compare = 0;
            
            obj = recurNW.recur(obj,currCost,currPath,i,j);
            
            recurNW.plotPath(obj.minCostPath,obj.nirsDiffSeq,obj.pyDiffSeq);
            text(obj.minCostPath(end,2),obj.minCostPath(end,1)+.5,num2str(round(obj.minTotalCost,1)));
        end
        
    end
end