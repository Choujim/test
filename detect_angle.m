% 测量单一方向成分图像的方向

function angle = detect_angle(image, scale_total, orientation_total, method)
    % bilinear差分图
    im = de_background(image, 2);
    
    if (method == 0)
        %% 获得各个方向的方向能量等数据
        temp_angles = [];
        temp_energy = [];
        for i = 1:orientation_total
            temp_angles = [temp_angles, 180*(i-1)/orientation_total]; % 此处角度为degree，下面f_energy需要输弧度rad
            temp = 0;
            for k = 1:scale_total
                temp = temp + f_energy(im, scale_total, orientation_total, [k, i], 0);
            end
            temp_energy = [temp_energy, temp];
        end
        
        %% 二分法查找最佳匹配角度
        [energy_1, idx_1] = max(temp_energy);
        angle_1 = temp_angles(idx_1);
        temp_energy(idx_1) = [];
        temp_angles(idx_1) = [];
        [energy_2, idx_2] = max(temp_energy);
        angle_2 = temp_angles(idx_2);
        
        while (abs(angle_1-angle_2) > 1)
            if (energy_1 >= energy_2)
                angle_2 = (angle_1 + angle_2)/2;
                energy_2 = 0;
                for k = 1:scale_total
                    energy_2 = energy_2 + f_energy(im, scale_total, orientation_total, [k, angle_2/180*pi], 1);
                end
            else
                angle_1 = (angle_1 + angle_2)/2;
                energy_1 = 0;
                for k = 1:scale_total
                    energy_1 = energy_1 + f_energy(im, scale_total, orientation_total, [k, angle_1/180*pi], 1);
                end
            end
        end
        angle = round((angle_1 + angle_2)/2);

    elseif (method == 1)
        %% 幅度加权求和/直接平均 角度
        dims = size(im);
        ctr = ceil((dims+0.5)/2);
        
        f_im = abs(fftshift(fft2(im))).^2;
        threshold_amp = mean(f_im(:));
        threshold_idx = f_im <= threshold_amp; % 逻辑值矩阵
        f_im(threshold_idx) = 0; 
        f_im(ctr(1), ctr(2)) = 0;
        threshold_amp = mean(f_im(:));
        threshold_idx = f_im > threshold_amp;
%         f_im(threshold_idx) = 0; 
        
        mean_amp = sum(f_im(:));
        % 加权求和角度
        [xramp,yramp] = meshgrid( ([1:dims(2)]-ctr(2))./(dims(2)/2), ...
                                  ([1:dims(1)]-ctr(1))./(dims(1)/2) );
        angle_map = atan2(yramp,xramp);
        inv_idx = angle_map <= 0;
        angle_map(inv_idx) = angle_map(inv_idx) + pi;
        % 幅度加权求和
        mean_angle = (angle_map .* f_im);
        angle = sum(mean_angle(:))/mean_amp;

        % 直接平均
%         mean_angle = sum(angle_map(threshold_idx)) / sum(double(threshold_idx(:)));
%         angle = mean_angle;
    elseif (method == 2)
        %% 方向能量增强的霍夫法
        angle = 0;
        % 霍夫变换求频谱角度
        f_im = abs(fftshift(fft2(im))).^2;
        % 霍夫变换直接求图像角度
%         f_im = im;                    % 使用bilinear差分
%         f_im = edge(image, 'canny');  % 使用canny检测边缘
%         angle = -90;
        
        threshold_amp = mean(f_im(:));
        threshold_idx = f_im <= threshold_amp; % 逻辑值矩阵
        % 二值化
        f_im(threshold_idx) = 0;
        f_im(~threshold_idx) = 1;
        
        
        % Hough变换
        [H,T,R] = hough(f_im);
        H_peaks = houghpeaks(H);
        
        %% 可视化
        lines = houghlines(f_im,T,R,H_peaks,'MinLength',1);
%         figure; imshow(f_im), hold on
        for k = 1:length(lines)
            xy = [lines(k).point1; lines(k).point2];
            plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');
        end
        %%
        angle = angle + mod(H_peaks(2), 180);
       
    elseif (method == 3)
        dims = size(im);
        ctr = ceil((dims+0.5)/2);
        f_im = fftshift(fft2(image));
        f_im(ctr(1),ctr(2)) = 0; % 去除直流分量
        [max_value, max_index] = max(f_im(:));
        [max_row, max_col] = ind2sub(dims, max_index);
        angle = atan2(max_row - ctr(1), max_col - ctr(2));
        if (angle < 0)
            angle = angle + pi;
        angle = angle/pi*180;
    end
    
end
