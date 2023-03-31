clear all
close all
clc

%% Data resaving 

fd_nativ = 'D:\Projects\Brain\SmartBrained\';
fd_phases = 'D:\Projects\Brain\CTAs\';
fd_resaved = 'D:\Projects\Brain\';


patients = []; % patients series numbers
%%
for patient = patients
    
    collection_nativ = dicomCollection([fd_nativ,num2str(patient)]);

    collection = dicomCollection([fd_phases,num2str(patient), '\Export\DICOM\']);

    nativ = squeeze(dicomreadVolume(collection_nativ,"s1"));

    info1 = str2num(dicominfo(collection.Filenames{1}(1)).AcquisitionTime); 
    info2 = str2num(dicominfo(collection.Filenames{2}(1)).AcquisitionTime); 
    info3 = str2num(dicominfo(collection.Filenames{3}(1)).AcquisitionTime); 
    infos = [info1, info2, info3];
    sorted = sort(infos);
   
    phase1 = squeeze(dicomreadVolume(collection.Filenames{infos==sorted(1)}));

    phase2 = squeeze(dicomreadVolume(collection.Filenames{infos==sorted(2)}));

    phase3 = squeeze(dicomreadVolume(collection.Filenames{infos==sorted(3)}));
     
    niftiwrite(phase1(:,:,320:end), [fd_resaved, num2str(patient),'\cropped_phase1'])

    niftiwrite(nativ, [fd_resaved, num2str(patient),'\nativ'])
    niftiwrite(phase1, [fd_resaved, num2str(patient),'\phase1'])
    niftiwrite(phase2, [fd_resaved, num2str(patient),'\phase2'])
    niftiwrite(phase3, [fd_resaved, num2str(patient),'\phase3'])

end
% 
%% phase 1 croping

fd = 'D:\Projects\Brain\';
patients = []; % patients series numbers

for patient = patients
    
    info1 = str2num(dicominfo(collection_phase.Filenames{1}(1)).AcquisitionTime);
    info2 = str2num(dicominfo(collection_phase.Filenames{2}(1)).AcquisitionTime);
    info3 = str2num(dicominfo(collection_phase.Filenames{3}(1)).AcquisitionTime);
    info4 = str2num(dicominfo(collection_phase.Filenames{4}(1)).AcquisitionTime);
    infos = [info1, info2, info3, info4];
    sorted = sort(infos);
   

    collection = dicomCollection([fd,'\',num2str(patient),'\1']);
    
    phase1 = squeeze(dicomreadVolume(collection,"s1"));

    niftiwrite(phase1(:,:,320:end), [num2str(patient),'_cropped_phase1'])
  
end

%% registration 

patients = []; % patients series numbers
phases = [1,2,3];
PF_name = 'D:\Projects\Brain\Rigid_parameter-file_nii.txt'; % direction to parametric file
OldPath = 'D:\Projects\Brain\';
NewPath = 'D:\Projects\New';

for patient=patients
    for phase = phases
        if phase == 1
            CMD = ['elastix\elastix -f ' [OldPath, num2str(patient), '\','nativ.nii']...  
                    ' -m ' [OldPath,num2str(patient), '\','cropped_','phase',num2str(phase),'.nii'] ' -out ' ...
                    [NewPath, num2str(patient),'\', num2str(phase),'\' ] ' -p ' PF_name];
            system(CMD)
        else 
            CMD = ['elastix\elastix -f ' [OldPath, num2str(patient), '\','nativ.nii']...  
                    ' -m ' [OldPath, '\',num2str(patient), '\','phase',num2str(phase),'.nii'] ' -out ' ...
                    [NewPath, num2str(patient),'\', num2str(phase),'\' ] ' -p ' PF_name];
            system(CMD)
        end
    end
end

%% HU reparation

patients = []; % patients series numbers
phases = [1,2,3];
OldPath = 'D:\Projects\Brain\';
NewPath = 'D:\Projects\New\';

for patient=patients
    info = niftiinfo([OldPath, num2str(patient), '\', num2str(patient), 'nativ.nii']);
    nativ = int16(niftiread(info))-1024;
    for phase = phases
        if phase == 1
            info = niftiinfo([OldPath, num2str(patient), '\', num2str(patient), '_cropped_phase1.nii']);
            actual_phase = int16(niftiread(info))-1024;
        else
            info = niftiinfo([OldPath, num2str(patient), '\', num2str(patient), 'phase', num2str(phase), '.nii']);
            actual_phase = int16(niftiread(info))-1024;
        end
        niftiwrite(actual_phase, [NewPath, num2str(patient), '\phase', num2str(phase), '.nii']);
    end
    niftiwrite(nativ, [NewPath, num2str(patient), '\nativ.nii']);
end

%% tMIP

patients = [];% patients series numbers
phases = [1,2,3];
OldPath = 'D:\Projects\Brain\';
New_Path = 'D:\Projects\New';

for patient=patients

    phase1 = int16(niftiread(niftiinfo([OldPath, num2str(patient), '\', num2str(1), '\result.0.nii']))) - 1024;
    phase2 = int16(niftiread(niftiinfo([OldPath, num2str(patient), '\', num2str(2), '\result.0.nii']))) - 1024;
    phase3 = int16(niftiread(niftiinfo([OldPath, num2str(patient), '\',num2str(3), '\result.0.nii']))) - 1024;

    all_in_one = findmaxes3(phase1, phase2, phase3);
    niftiwrite(all_in_one, [NewPath, num2str(patient), 'fused.nii']);
end

