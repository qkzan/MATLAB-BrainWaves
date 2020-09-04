%memantinaScript2 - TFD
cd 'C:\Users\queru\Documents\GitHub\Projetos\Memantina'
Trechos; %load F;
srate = 1000; %Hz

datapath='C:\Users\queru\OneDrive - Universidade Federal do Rio Grande do Sul\MATLAB\Gabi\DADOS\';

for N = 2%[1:4 6:length(animal)]
  
    group = animal(N).grupo;
    
    if iscell(animal(N).arquivo)
        files = animal(N).arquivo;
        channels = animal(N).canais{1};
    else
        files = {animal(N).arquivo};
        channels = animal(N).canais;
    end
    CHs = cell(length(channels),1);

    disp(files)
    
    if length(files)>1
        for nfile = 1:length(files)
            filename = char(files{nfile});
            load([datapath filename])
            for CH = 1:length(channels)
                eval(['CHs{' num2str(CH) '} = [CHs{' num2str(CH) '}; AD' num2str(channels(CH)) ']'])
            end
        end
    else
        filename = char(files{nfile});
        load([datapath filename])
    end
    
    for CH = 1:length(channels)
        canais(count,1) = channels(CH);
        lfp{count,1} = eval(['AD' num2str(channels(CH)) '(starts(i):ends(i))']);
        grupotto(count,1) = group;
        Nrato(count,1) = str2double(filename(6:7));
        trecho = trecho + 1;
    end
end


Data = table(grupotto,Nrato,canais,period,lfp);
clearvars -except Data srate 
disp('Done')