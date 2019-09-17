classdef nirsFileData
    properties
    %holds file name data that will be matched across file types
    
        filePath%folder of files
        subjectTrials
        subjectID

    end
    properties(Constant)
        trialSpecifiers = ["ps","SP" "gng","rs"];
    end
    methods(Static)
        %Newest Version Works with wave1 and 2
        %Input is a unsorted subject folder
        
        %Input Subject path in format '/Volumes/data/Data/ben_IC/Wave1-Adzope'
        %Input DestinationFolder in format '/Volumes/data/Data/ben_IC/Wave1-Adzope/NIRS_sorted'
        function NirsFolderSort(SubjectsPath,destinationFolder)
            
            files = dir([SubjectsPath filesep '*' filesep '*txt']);
            for i =1:length(files)
                
                txt = fileread(files(i).name);
                
                indNum = regexp(txt,"Comment");
                relevantBlock = txt(indNum:indNum+100);
                blockinfo = split(relevantBlock,'[');
                blockinfo = blockinfo(1);
                
                [DelimitedInfo,del] = split(blockinfo);
                trialType = char(DelimitedInfo(2));
                
                fullFileName = fullfile(files(i).folder,files(i).name);
                [filepath,name,ext] = fileparts(fullFileName);
                parts = split(filepath,'/');
                subjectID = char(parts(end));
                b = length(parts)-1;
                while(length(subjectID)~=7)
                    subjectID = char(parts(b));
                    b=b-1;
                end
                sortedFolder = [destinationFolder filesep char(subjectID)];
                sortedTrialFolder = [destinationFolder filesep char(subjectID) filesep trialType];
                if(exist(sortedFolder)~=7) %#okEXIST
                    mkdir(sortedFolder);
                end
                if(exist(sortedTrialFolder)~=7) %#okEXIST
                    mkdir(sortedTrialFolder);
                end
                %cellfun(@(x) contains(trialType,x), trialSpecifiers);
                
                copyfile([filepath filesep name '.*'],sortedTrialFolder);
                
                
            end
        end 
        
        
        
        
        %% Deprecated
        %DONE
        %%%%%%%%% this assumes the first six characters are the subject ID %%%%%%%%%
        function subID = getSubID(FileName)
            civ=1;% this is the bool to identify what type of data were using
            if(civ==1)
                return;
            else
                subID = FileName(1:6);%Subject ID will be first 6 numbers of .OMM file
                if(contains(subID,'_')==1)%if subid has underscores
                    subID = FileName(1:8);
                end
            end
        end
        %DONE
        
        
        
        %DONE
        %with given folder it will identify all of the unique subject ids
        %and return a master list of all
        function subIDs = getAllSubID(filePath)
            civ= 1;
            if(civ==1)
                dirList = dir(char(strcat(filePath,'/*')));
                dirSize = size(dirList);
                subIDs = [];
                for n = 1:size(dirList)
                    subIDs = [subIDs;convertCharsToStrings(dirList(n).name)];
                end
                for i = 1:size(subIDs)
                    log = isstrprop(subIDs(i),'digit');
                    if(log(1)==1)
                        break;
                    end
                end
                subIDs = subIDs(i:end);
                
            else
                dirList = dir(char(strcat(filePath,'*.omm')));
                dirSize = size(dirList);
                subIDs = string.empty(dirSize(1),0);
                for n = 1:size(dirList)
                    subIDs(n) = nirsFileData.getSubID(dirList(n).name);
                end
                subIDs = unique(transpose(subIDs));
            end
            
            
            
        end
        %%DONE
        
        
        %DONE
        %Moves data specified in filepath to its subfolder created from its subjectID 
        function moveData(subjectID,FilePath) 
            civ=1;
            if(civ==1)
               FilePath = strcat(FilePath,'/',subjectID,'/');
            end
            dirList = dir(FilePath);
            dirNameList = {dirList(:).name};
            indList = find(contains(dirNameList,subjectID));
            if(not(exist(strcat(dirList(indList(1)).folder,'/',subjectID),'dir'))&&civ==0)%If folder is already made do not create another
                mkdir(FilePath,char(subjectID));
            end
            for i= 1:length(indList)
                if(civ==0)
                    file = strcat(dirList(indList(i)).folder,'/',dirList(indList(i)).name);
                else
                    file = strcat(dirList(indList(i)).folder,'/',dirList(indList(i)).name)
                end
                if(isfile(file))%Make sure the thing were trying to move is a file not a folder.%%%%%%%%%
                    if(civ==0)
                        newFolderPath = strcat(FilePath,subjectID,'/');
                    else
                        newFolderPath = FilePath;
                    end
                    movefile(file,char(newFolderPath)); % WE ARE MOVING NOT COPYING
                    
                end
            end 
        end 
        %DONE
        
        %done
        %read from .OMM file
        function [trialType,subjectFullName] = readOMMFile(inputFile)
            fid = fopen(inputFile);
            trialType = " No identifier Found";
            while(true)%Process line by line until we find ANYTHING that matches the strings in trialSpecifier string vector
                thisLine = fgetl(fid);
                
                if((~ischar(thisLine))&&trialType == " No identifier Found")%Contains does not require exact matching rather 
                    %if any string has consecutive chars that match the pattern it will return true
                    disp([string(inputFile),trialType]);%Help Us find what we missed
                    break;
                else
                    if(contains(thisLine,nirsFileData.trialSpecifiers))%we found a trial that matches pattern so which one did we find
                        for M = 1:length(nirsFileData.trialSpecifiers)
                           if(1==contains(thisLine,nirsFileData.trialSpecifiers(M)))
                               trialType = nirsFileData.trialSpecifiers(M);
                               [~,subjectFullName,~] = fileparts(string(inputFile));
                               fclose('all');
                               return;
                           end
                        end
                    end
                    
                end
            end
            [~,subjectFullName,~] = fileparts(string(inputFile));
            fclose('all');
        end
        
        
        function moveToTrialSpecificFolder(subFilePath)%input is the sub path once all omms have been grouped by subject
            dirList = dir(char(subFilePath));
            dirNameList = {dirList(:).name};
            indList = find(contains(dirNameList,".OMM"));
            for i = 1:length(indList)
               [trialType,id] = nirsFileData.readOMMFile(strcat(dirList(indList(i)).folder,"/",dirNameList(indList(i))));
               folderName = trialType;
               subtypeList = find(contains(dirNameList,char(id)));
               if(~isfolder(strcat(subFilePath,'/',folderName)))
                   mkdir(char(subFilePath),char(folderName));
               end
               folderPath = char(strcat(subFilePath,"/",folderName));
               for m = 1:length(subtypeList)
                   movefile(char(strcat(subFilePath,"/",dirNameList(subtypeList(m)))),folderPath); %MOVING NOT COPYING Be Cautious
               end
            end
        end
    
    
   
    
  end  
    
    
    
    
    methods%CIV DATA
        function obj = nirsFileData(filePath,ext)
            if(nargin>0)
                folder = dir(strcat(filePath,'/*',ext,''));%get the file specified by path
                subjectTrials = cell(length(folder),1);

                for i = 1:length(folder)
                    strTMP = strsplit(folder(i).name,'.');
                    subjectTrials(i) = (strTMP(1));%gets the name without extension
                end
                tmp = strsplit(folder(1).folder,'/');

                obj.subjectID = tmp(length(tmp)-1);
                obj.subjectTrials = subjectTrials;
                obj.filePath = filePath;
            end
            
%             function getTrialType(obj,~)
%                 if(exists(obj.filePath)>0)
%                     
%                 end
%                 
%                 
%             end
        end
    end
end