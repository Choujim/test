% ������һ����ɷ�ͼ��ķ���

function angle = detect_angle(image, scale_total, orientation_total, method)
    % bilinear���ͼ
    im = de_background(image, 2);
    
    if (method == 0)
        %% ��ø�������ķ�������������
        temp_angles = [];
        temp_energy = [];
        for i = 1:orientation_total
            temp_angles = [temp_angles, 180*(i-1)/orientation_total]; % �˴��Ƕ�Ϊdegree������f_energy��Ҫ�仡��rad
            temp = 0;
            for k = 1:scale_total
                temp = temp + f_energy(im, scale_total, orientation_total, [k, i], 0);
            end
            temp_energy = [temp_energy, temp];
        end
        
        %% ���ַ��������ƥ��Ƕ�
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
        %% ���ȼ�Ȩ���/ֱ��ƽ�� �Ƕ�
        dims = size(im);
        ctr = ceil((dims+0.5)/2);
        
        f_im = abs(fftshift(fft2(im))).^2;
        threshold_amp = mean(f_im(:));
        threshold_idx = f_im <= threshold_amp; % �߼�ֵ����
        f_im(threshold_idx) = 0; 
        f_im(ctr(1), ctr(2)) = 0;
        threshold_amp = mean(f_im(:));
        threshold_idx = f_im > threshold_amp;
%         f_im(threshold_idx) = 0; 
        
        mean_amp = sum(f_im(:));
        % ��Ȩ��ͽǶ�
        [xramp,yramp] = meshgrid( ([1:dims(2)]-ctr(2))./(dims(2)/2), ...
                                  ([1:dims(1)]-ctr(1))./(dims(1)/2) );
        angle_map = atan2(yramp,xramp);
        inv_idx = angle_map <= 0;
        angle_map(inv_idx) = angle_map(inv_idx) + pi;
        % ���ȼ�Ȩ���
        mean_angle = (angle_map .* f_im);
        angle = sum(mean_angle(:))/mean_amp;

        % ֱ��ƽ��
%         mean_angle = sum(angle_map(threshold_idx)) / sum(double(threshold_idx(:)));
%         angle = mean_angle;
    elseif (method == 2)
        %% ����������ǿ�Ļ���
        angle = 0;
        % ����任��Ƶ�׽Ƕ�
        f_im = abs(fftshift(fft2(im))).^2;
        % ����任ֱ����ͼ��Ƕ�
%         f_im = im;                    % ʹ��bilinear���
%         f_im = edge(image, 'canny');  % ʹ��canny����Ե
%         angle = -90;
        
        threshold_amp = mean(f_im(:));
        threshold_idx = f_im <= threshold_amp; % �߼�ֵ����
        % ��ֵ��
        f_im(threshold_idx) = 0;
        f_im(~threshold_idx) = 1;
        
        
        % Hough�任
        [H,T,R] = hough(f_im);
        H_peaks = houghpeaks(H);
        
        %% ���ӻ�
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
        f_im(ctr(1),ctr(2)) = 0; % ȥ��ֱ������
        [max_value, max_index] = max(f_im(:));
        [max_row, max_col] = ind2sub(dims, max_index);
        angle = atan2(max_row - ctr(1), max_col - ctr(2));
        if (angle < 0)
            angle = angle + pi;
        angle = angle/pi*180;
    end
    
end
