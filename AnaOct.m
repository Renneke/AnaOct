pkg load symbolic;
clear -g; % clear all global variables


if(~exist('netlist', 'var'))
  [baseName, folder] = uigetfile({"*.net","LTSpice Netlist"});
  netlist = fullfile(folder, baseName);
end



%%%%%%%%%%%%%%%%%% Helper Functions %%%%%%%%%%%%%%%%%%%%%%%%%

global nets numNets;
global numAddIds;
global M b devices;

numNets = 1;
function netId = getNetID(netname)
  global nets numNets;
  
  if(netname(1)=='0')
    netId = 0;
    return
  end
  if(~isfield(nets, netname))
    eval(['nets.' netname ' = numNets;']);  
    netId = numNets;
    numNets = numNets + 1;
  else
    netId = eval(['nets.' netname]);
  end
end


%% Some devices need additional rows/columns in the matrix_type
%% This function keeps track of the number of additional entries.
%% In order to get the correct row (e.g.) one has to add to ids_offset the 
%% total number of rows without the additional ones. It is therefore an offset.
numAddIds = 1;
function [ids_offset] = getAddIds(num)
  global numAddIds;
  ids_offset = numAddIds:numAddIds+num-1;
  numAddIds = ids_offset(end)+1;
end



% Add some value to an entry in M
function M = addM(M, val, i, j)
  if(i~=0 && j ~= 0)
    M(i,j) = M(i,j) + val;
  end
end

function b = addB(b, val, i)
  if(i~=0)
    b(i) = b(i) + val;
  end
end
%%%%%%%%%%%%%%%%%% Helper Functions %%%%%%%%%%%%%%%%%%%%%%%%%







%%%%%%%%%%%%%%%%%% Devices Definitions %%%%%%%%%%%%%%%%%%%%%%%%%

%% -- V --
function [M, b] = device_V_applyM(device, M, b)
    global numNets;
    
    iadd = numNets-1+device.add_ids(1);
    
    M = addM(M, '-1', device.nets(1), iadd);
    M = addM(M, '+1', iadd, device.nets(1));
    M = addM(M, '-1', device.nets(2), iadd);
    M = addM(M, '+1', iadd, device.nets(2));

    if(device.AC == 1)
        b(numNets-1+device.add_ids(1)) = device.parameters{1};
    end    
end

function device = readInV(line)
  
  if(line(1) == 'V')
    data = textscan (line, '%s %s %s %s %s %s');
    device.nets = [getNetID(data{2}{1}), getNetID(data{3}{1})];
    device.add_ids = getAddIds(1);  % we want one additional row and column
    device.parameters = {data{1}{1}};
    device.type = 'V';
    device.match = 1;
    if(~isempty(strfind(line, 'AC')))  
        device.AC = 1; 
    else
        device.AC = 0;
    end
    
    device.applyM = @(M,b) device_V_applyM(device, M, b);
  else
    device.match = 0;
  end
end

%% -- R --

function [M, b] = device_R_applyM(device, M, b)
  global numNets;
    
    y = ['1/' device.parameters{1}];
    M = addM(M, ['+' y], device.nets(1),  device.nets(1));
    M = addM(M, ['-' y], device.nets(1),  device.nets(2));
    M = addM(M, ['-' y], device.nets(2),  device.nets(1));
    M = addM(M, ['+' y], device.nets(2),  device.nets(2));  

end

function device = readInR(line)
  
  if(line(1) == 'R')
    data = textscan (line, '%s %s %s %s %s %s');
    device.nets = [getNetID(data{2}{1}), getNetID(data{3}{1})];
    device.add_ids = []; 
    device.parameters = {data{1}{1}};
    device.type = 'R';
    device.applyM = @(M,b) device_R_applyM(device, M, b);
    device.match = 1;
  else
    device.match = 0;
  end
end

%% -- L --

function [M, b] = device_L_applyM(device, M, b)
  global numNets;
    
    y = ['1/(s*' device.parameters{1} ')'];
    M = addM(M, ['+' y], device.nets(1),  device.nets(1));
    M = addM(M, ['-' y], device.nets(1),  device.nets(2));
    M = addM(M, ['-' y], device.nets(2),  device.nets(1));
    M = addM(M, ['+' y], device.nets(2),  device.nets(2));  

end

function device = readInL(line)
  
  if(line(1) == 'L')
    data = textscan (line, '%s %s %s %s %s %s');
    device.nets = [getNetID(data{2}{1}), getNetID(data{3}{1})];
    device.add_ids = []; 
    device.parameters = {data{1}{1}};
    device.type = 'L';
    device.applyM = @(M,b) device_L_applyM(device, M, b);
    device.match = 1;
  else
    device.match = 0;
  end
end

%% -- C --

function [M, b] = device_C_applyM(device, M, b)
  global numNets;
    
    y = ['(s*' device.parameters{1} ')'];
    M = addM(M, ['+' y], device.nets(1),  device.nets(1));
    M = addM(M, ['-' y], device.nets(1),  device.nets(2));
    M = addM(M, ['-' y], device.nets(2),  device.nets(1));
    M = addM(M, ['+' y], device.nets(2),  device.nets(2));  

end

function device = readInC(line)
  
  if(line(1) == 'C')
    data = textscan (line, '%s %s %s %s %s %s');
    device.nets = [getNetID(data{2}{1}), getNetID(data{3}{1})];
    device.add_ids = []; 
    device.parameters = {data{1}{1}};
    device.type = 'C';
    device.applyM = @(M,b) device_C_applyM(device, M, b);
    device.match = 1;
  else
    device.match = 0;
  end
end


%% -- I --

function [M, b] = device_I_applyM(device, M, b)
  global numNets;
    
    if(device.AC==1)
        y = device.parameters{1};
        
        b = addB(b, y, device.nets(2));
        b = addB(b, ['-' y], device.nets(1));
    end
    
end

function device = readInI(line)
  
  if(line(1) == 'I')
    data = textscan (line, '%s %s %s %s %s %s');
    device.nets = [getNetID(data{2}{1}), getNetID(data{3}{1})];
    device.add_ids = []; 
    device.parameters = {data{1}{1}};
    device.type = 'I';
    
    if(~isempty(strfind(line, 'AC')))  
        device.AC = 1; 
    else
        device.AC = 0;
    end
    
    device.applyM = @(M,b) device_I_applyM(device, M, b);
    device.match = 1;
  else
    device.match = 0;
  end
end



%% -- Mosfet --

function [M, b] = device_M_applyM(device, M, b)
  global numNets;
    
    % PMOS und NMOS sind hier identisch!!
    gm = device.parameters{1};
    M = addM(M, ['+' gm], device.nets(1),  device.nets(2));
    M = addM(M, ['-' gm], device.nets(1),  device.nets(3));
    M = addM(M, ['-' gm], device.nets(3),  device.nets(2));
    M = addM(M, ['+' gm], device.nets(3),  device.nets(3));  
        
    if(device.gds == 1)
        gds = device.parameters{2};
        M = addM(M, ['+' gds], device.nets(1),  device.nets(1));
        M = addM(M, ['-' gds], device.nets(3),  device.nets(1));
        M = addM(M, ['-' gds], device.nets(1),  device.nets(3));
        M = addM(M, ['+' gds], device.nets(3),  device.nets(3));    
    end
end

function device = readInM(line)
  
  if(line(1) == 'M')
    
    data = textscan (line, '%s %s %s %s %s %s');
    device.nets = [getNetID(data{2}{1}), getNetID(data{3}{1}), getNetID(data{4}{1})];
    device.add_ids = []; 
    device.parameters = {['gm_' data{1}{1}], ['gds_' data{1}{1}]};
    device.type = 'M';
        
    if(~isempty(strfind(line, 'NMOS')))  
        device.MOS = 'NMOS'; 
    else
        device.MOS = 'PMOS';
    end
    
    
    if(~isempty(strfind(line, 'gds')))  
        device.gds = 1; 
    else
        device.gds = 0;
    end
    
    device.applyM = @(M,b) device_M_applyM(device, M, b);
    device.match = 1;
  else
    device.match = 0;
  end
end




%% -- Opamp XU --

function [M, b] = device_XU_applyM(device, M, b)
  global numNets;
    
  % + - VDD GND out
  iadd = numNets-1+device.add_ids(1);
  M = addM(M, '-1', iadd,  device.nets(1));  
  M = addM(M, '+1', iadd,  device.nets(2));  
  M = addM(M, '+1', device.nets(5), iadd);  
  M = addM(M, '-1', device.nets(4), iadd);  
  
   
end

function device = readInXU(line)
  
  if(line(1) == 'X' && line(2) == 'U')
    
    data = textscan (line, '%s %s %s %s %s %s %s %s');
    device.nets = [getNetID(data{2}{1}), getNetID(data{3}{1}), ...
                    getNetID(data{4}{1}), getNetID(data{5}{1}), ...
                    getNetID(data{6}{1})]; % + - VDD GND out
    device.add_ids = getAddIds(1); 
    device.parameters = {};
    device.type = 'XU';
           
        
    device.applyM = @(M,b) device_XU_applyM(device, M, b);
    device.match = 1;
  else
    device.match = 0;
  end
end





% list of all read in functions of all devices
devices_list = {@(line) readInV(line),...
                @(line) readInI(line),...
                @(line) readInXU(line),...
                @(line) readInR(line),...
                @(line) readInL(line),...
                @(line) readInC(line),...
                @(line) readInM(line)};
                
%%%%%%%%%%%%%%%%%% Devices Definitions %%%%%%%%%%%%%%%%%%%%%%%%%





%%%%%%%%%%%%%%%%%% Read Netlist %%%%%%%%%%%%%%%%%%%%%%%%%
fid = fopen (netlist);

devices = {};

while 1
  line = fgetl (fid);
  if(line == -1)
    break;
  end
  
  %%%%%% read in all the different devices %%%%%%
  
  for i=1:length(devices_list)
    device = devices_list{i}(line);
    if(device.match == 1)
      devices{end+1} = device;
      break;
    end
  end
  %%%%%% read in all the different devices %%%%%%
  
  
end
  
%%%%%%%%%%%%%%%%%% Read Netlist %%%%%%%%%%%%%%%%%%%%%%%%%




%%%%%%%%%%%%%%%%%% Build the Equation system %%%%%%%%%%%%%%%%%%%%%%%%%
M = zeros(numNets-1 + numAddIds-1, numNets-1 + numAddIds-1);
b = zeros(numNets-1 + numAddIds-1, 1);
M = sym(M);
b = sym(b);
syms s;

for i=1:length(devices)
  
  [M,b] = devices{i}.applyM(M,b);  
  
  % Create all parameters here for the global context
  for(j=1:length(devices{i}.parameters))
    eval(['syms ' devices{i}.parameters{j} ';']);
  end
end
%%%%%%%%%%%%%%%%%% Build the Equation system %%%%%%%%%%%%%%%%%%%%%%%%%




%%%%%%%%%%%%%%%%%% Solve %%%%%%%%%%%%%%%%%%%%%%%%%

V = simplify(M\b);

%%%%%%%%%%%%%%%%%% Solve %%%%%%%%%%%%%%%%%%%%%%%%%





%%%%%%%%%%%%%%%%%% Advanced Analyzing Functions %%%%%%%%%%%%%%%%%%%%%%%%%


%% Calculate all the input/output resistances
%% of all nets which are named (in..., out...)
function R = calcRinout()
  
    global nets numNets;  
    global numAddIds;
    global M b devices;
    
    % Sweep through all nets with in and out in the name
    netNames = fieldnames(nets);
    netIDsToBeCalc = []; % collect the ids of the nets who have to be analyzed
    for(i=1:length(netNames))
        name = netNames{i};
        if(~isempty(strfind(name, 'in')) || ~isempty(strfind(name, 'out')))  
            netIDsToBeCalc = [netIDsToBeCalc, eval(['nets.' name])];
        end
    end

    % sweep through the ports and do the following:
    % 1) remove all connected voltages sources to all ports
    % 2) add GND voltage to all other ports
    % 3) add DC voltage source to the current port
    % 4) run the simulation
    % 5) save result in R vector
    
    
end

% Display any equation with online latex conversion
function Latex(equ)
  l = latex(equ);
  l = strrep(l, '\', '%5C');
  l = strrep(l, '[', '%5B');
  l = strrep(l, ']', '%5D');
  l = strrep(l, '^', '%5E');
  l = strrep(l, '{', '%7B');
  l = strrep(l, '}', '%7D');
  l = strrep(l, ' ', '%20');
  urlwrite(['https://latex.codecogs.com/gif.latex?' l], 'img.gif'); 
  imshow('img.gif');  
end
%%%%%%%%%%%%%%%%%% Advanced Analyzing Functions %%%%%%%%%%%%%%%%%%%%%%%%%