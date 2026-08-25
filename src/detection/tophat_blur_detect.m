function out = tophat_blur_detect(img, disk_size)
    I = rgb2gray(img);
    subplot(2,2,1);
    imshow(I);
    title('Original Image');
    se=strel('disk',disk_size);
    er=imerode(I,se);
    dl=imdilate(er,se);
    subplot(2,2,2);
    imshow(dl);
    title('Image after opening');
    eg=I-dl;

    subplot(2,2,3);
    imshow(eg);
    title('Image after top hat transformation');
    ts=imadjust(eg);
    subplot(2,2,4);
    imshow(ts);
    title('Image after contranst enhancement');
end