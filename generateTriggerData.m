classdef generateTriggerData
    %GENERATETRIGGERDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods(Static)
        function returnedTable = generateTriggerData(subjectFile)
            %GENERATETRIGGERDATA Construct an instance of this class
            %   Returns trigger info or -1 on failure
            matrixInput = readtable(filename,'HeaderLines',34);
            names = matrixInput.Properties.VariableNames;
            matrixInput = NMLstartup.extractBlockData(matrixInput);
            if(isempty(matrixInput))
                returnedTable = -1;
                return;
            end
            
        end
        
        
    end
end

