//
//  ImageService.swift
//  MyAliyunOSSDemoSwift
//
//  Created by Crack on 2017/11/30.
//  Copyright © 2017年 Crack. All rights reserved.
//

import UIKit

class ImageService: NSObject {

    // 字体，默认文泉驿正黑
    let font = "d3F5LXplbmhlaQ=="
    var imageService: MyOssService! = nil
    
    init(service: MyOssService) {
        imageService = service
    }
    
    // 图片打水印
    func textWaterMark(object: String, text: String, size: Int) {
        let base64Text: String = Base64Safe.base64EncodedString(with: text)
        let queryString = "@watermark=2&type=\(font)&text=\(base64Text)&size=\(size)"
        imageService.asyncGetImage(objectKey: "\(object)\(queryString)")
    }
    
}
