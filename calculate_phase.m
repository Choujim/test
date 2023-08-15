% 根据给定最优角度返回对应CSP子带滤波器map
% 需要输入的角度为弧度制
% 默认method为1使用任意角度
function [ret_phase, ret_index] = calculate_phase(image, scale_total, orientation_total, optimal_angle)
    ret_phase = [];
    ret_index = [];
    method = 1;
    temp_fft = fftshift(fft2(image));
    for i = 1:scale_total
        dims = size(temp_fft);
        mask = mask_creator(size(image), scale_total, orientation_total, [i, optimal_angle], method);
        temp_phase = ifft2(ifftshift(mask .* temp_fft));
        temp_phase = angle(temp_phase);
        ret_phase = [ret_phase; temp_phase(:)];
        ret_index = [ret_index; dims];
        
        % 下采样诸多事宜
        ctr = ceil((dims+0.5)/2);
        lodims = ceil((dims-0.5)/2);
        loctr = ceil((lodims+0.5)/2);
        lostart = ctr-loctr+1;
        loend = lostart+lodims-1;
        
        temp_fft = temp_fft(lostart(1):loend(1),lostart(2):loend(2));
        
    end
        

end