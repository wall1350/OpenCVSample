//
//  OpenCVSample.m
//  OpenCVSample
//
//  Created by Pin-Chou Liu on 6/26/17.
//  Copyright © 2017 Pin-Chou Liu.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
// 參考：https://blog.csdn.net/qq_18343569/article/details/47999751

#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#include <iostream>
#import "OpenCVSample-Bridging-Header.h"
using namespace std;
using namespace cv;
/*
 * add a method convertToMat to UIImage class
 */
@interface UIImage (OpenCVWrapper)
- (void)convertToMat: (cv::Mat *)pMat;
@end

@implementation UIImage (OpenCVWrapper)
- (void)convertToMat: (cv::Mat *)pMat {
    if (self.imageOrientation == UIImageOrientationRight) {
        /*
         * When taking picture in portrait orientation,
         * convert UIImage to OpenCV Matrix in landscape right-side-up orientation,
         * and then rotate OpenCV Matrix to portrait orientation
         */
        UIImageToMat([UIImage imageWithCGImage:self.CGImage scale:1.0 orientation:UIImageOrientationUp], *pMat);
        cv::rotate(*pMat, *pMat, cv::ROTATE_90_CLOCKWISE);
    } else if (self.imageOrientation == UIImageOrientationLeft) {
        /*
         * When taking picture in portrait upside-down orientation,
         * convert UIImage to OpenCV Matrix in landscape right-side-up orientation,
         * and then rotate OpenCV Matrix to portrait upside-down orientation
         */
        UIImageToMat([UIImage imageWithCGImage:self.CGImage scale:1.0 orientation:UIImageOrientationUp], *pMat);
        cv::rotate(*pMat, *pMat, cv::ROTATE_90_COUNTERCLOCKWISE);
    } else {
        /*
         * When taking picture in landscape orientation,
         * convert UIImage to OpenCV Matrix directly,
         * and then ONLY rotate OpenCV Matrix for landscape left-side-up orientation
         */
        UIImageToMat(self, *pMat);
        if (self.imageOrientation == UIImageOrientationDown) {
            cv::rotate(*pMat, *pMat, cv::ROTATE_180);
        }
    }
}
@end


/*
 *  class methods to execute OpenCV operations
 */
@implementation OpenCVWrapper : NSObject

+ (UIImage *)grayscaleImage:(UIImage *)image {
    cv::Mat mat;
    [image convertToMat: &mat];

    cv::Mat gray;
    if (mat.channels() > 1) {
        cv::cvtColor(mat, gray, CV_RGB2GRAY);
    } else {
        mat.copyTo(gray);
    }

    UIImage *grayImg = MatToUIImage(gray);
    return grayImg;
}

+ (UIImage *)gaussianBlurImage:(UIImage *)image {
    cv::Mat mat;
    [image convertToMat: &mat];

    cv::Mat gray, blur;
    if (mat.channels() > 1) {
        cv::cvtColor(mat, gray, CV_RGB2GRAY);
    } else {
        mat.copyTo(gray);
    }

    cv::GaussianBlur(gray, blur, cv::Size(5, 5), 3, 3);

    UIImage *blurImg = MatToUIImage(blur);
    return blurImg;
}

+ (UIImage *)cannyEdgeImage:(UIImage *)image {
    cv::Mat mat;
    [image convertToMat: &mat];

    cv::Mat gray, blur, edge;
    if (mat.channels() > 1) {
        cv::cvtColor(mat, gray, CV_RGB2GRAY);
    } else {
        mat.copyTo(gray);
    }

    cv::GaussianBlur(gray, blur, cv::Size(5, 5), 3, 3);

    cv::Canny(blur, edge, 20, 40 * 3, 3);

    UIImage *edgeImg = MatToUIImage(edge);
    return edgeImg;
}

+ (UIImage *) findTheCenterPoint:(UIImage *)image{
    cv::Mat mat;
    [image convertToMat: &mat];

    cv::Mat gray, blur, edge;
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    if (mat.channels() > 1) {
        cv::cvtColor(mat, gray, CV_RGB2GRAY);
    } else {
        mat.copyTo(gray);
    }

    cv::GaussianBlur(gray, blur, cv::Size(5, 5), 3, 3);
    /// 使用Canndy邊緣檢測
    cv::Canny(blur, edge, 20, 40 * 3, 3);
    /// 找到輪廓
    cv::findContours(edge,contours,cv::RETR_EXTERNAL,cv::CHAIN_APPROX_SIMPLE,cv::Point());
    

    
    /// 計算矩 （矩是用來表示物體形狀的物理量）
    vector<Moments> mu(contours.size());
    for (int i = 0; i < contours.size(); i++)
    {
        mu[i] = moments(contours[i], false);
    }
    ///  計算中心矩  （中心點）:
    vector<Point2f> mc(contours.size());
    for (int i = 0; i < contours.size(); i++)
    {
        mc[i] = Point2f(mu[i].m10 / mu[i].m00, mu[i].m01 / mu[i].m00);
        cout<<"中心點 x:" <<(mu[i].m10 / mu[i].m00) <<" y："<< mu[i].m01 / mu[i].m00 <<endl;
    }
    

    RNG rng(12345);
    /// 畫出輪廓（debug用，應該會變成粉紅色）
    Mat drawing = Mat::zeros(edge.size(), CV_8UC3);
    for (int i = 0; i< contours.size(); i++)
    {
        Scalar color = Scalar(rng.uniform(0, 255), rng.uniform(0, 255), rng.uniform(0, 255));
        drawContours(drawing, contours, i, color, 2, 8, hierarchy, 0, cv::Point());
        circle(drawing, mc[i], 4, color, -1, 8, 0);
        
    }
   


    UIImage *drawingImg = MatToUIImage(drawing);
       
    return drawingImg;
   
}

@end
