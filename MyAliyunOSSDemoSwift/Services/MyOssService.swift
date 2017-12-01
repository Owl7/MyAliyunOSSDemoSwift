//
//  MyOssService.swift
//  MyAliyunOSSDemoSwift
//
//  Created by Crack on 2017/11/30.
//  Copyright © 2017年 Crack. All rights reserved.
//

import UIKit

class MyOssService: NSObject {

    var client: OSSClient!
    var endPoint: String!
    var callbackAddress: String!
    var uploadStatusRecorder:Dictionary<String, Any>!
    var currentUploadRecordKey: String!
    var putRequest: OSSPutObjectRequest!
    var getRequest: OSSGetObjectRequest!
    
    // 全局断点
    var resumableUpload: OSSResumableUploadRequest!
    var viewController: ViewController!
    
    var isCancelled: Bool!
    var isResumeUpload: Bool!
    
    init(view: ViewController, endpoint: String) {
        super.init()
        
        viewController = view
        endPoint = endpoint
        isResumeUpload = false
        isCancelled = false
        currentUploadRecordKey = ""
        uploadStatusRecorder = Dictionary.init()
        
        // 初始化
        self.ossInit()
    }
    
    func ossInit() {
        
        let credential: OSSCredentialProvider = OSSCustomSignerCredentialProvider.init { (contentToSign, error) -> String? in
            let signature: String = OSSUtil.calBase64Sha1(withData: contentToSign, withSecret: accessKeySecret)
            if signature != "" {
                
            } else {
                return nil
            }
            return "OSS \(accessKeyID):\(signature)"
        }
        
        client = OSSClient.init(endpoint: endPoint, credentialProvider: credential)
        
    }
    
    // 设置server callback地址
    func setCallbackAddress(address: String) {
        callbackAddress = address
    }
    
    // 上传图片
    func asyncPutImage(objectKey: String, filePath: String) {
        if objectKey.isEmpty {
            return
        }
        putRequest = OSSPutObjectRequest.init()
        putRequest.bucketName = BUCKET_NAME
        putRequest.objectKey = objectKey;
        putRequest.uploadingFileURL = URL.init(fileURLWithPath: filePath)
        putRequest.uploadProgress = { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
            print("Bytes sent: \(bytesWritten), Total bytes sent:\(totalBytesWritten), Expected total bytes sent: \(totalBytesExpectedToWrite)")
        }
        if (callbackAddress != nil) {
            putRequest.callbackParam = [
                "callbackUrl": callbackAddress,
                // callbackBody可自定义传入的信息
                "callbackBody": "filename=${object}"
            ]
        }
        
        let putTask = client.putObject(putRequest)
        putTask.continue ({ (task) -> AnyObject? in
            if task.result == nil {
                DispatchQueue.main.async {
                    self.viewController.showMessage(putType: "普通上传", message: "Failed!")
                }
                return nil
            }
            let result = task.result as! OSSPutObjectResult
            if (task.error == nil) {
                print("上传成功")
                DispatchQueue.main.async {
                    self.viewController.showMessage(putType: "普通上传", message: "Success!")
                }
            } else {
                print("上传失败:\(errno)")
                
                DispatchQueue.main.async {
                    self.viewController.showMessage(putType: "普通上传", message: "Failed!")
                }
                
            }
            self.putRequest = nil;
            return nil
        })
    }
    
    // 下载图片
    func asyncGetImage(objectKey: String) {
        if objectKey.isEmpty {
            return
        }
        
        getRequest = OSSGetObjectRequest.init()
        getRequest.bucketName = BUCKET_NAME
        if !objectKey.contains("@") {
            getRequest.objectKey = objectKey
        } else {
            getRequest.objectKey = objectKey.components(separatedBy: "@").first
            let str = objectKey.components(separatedBy: "@").last
            let arr = str?.components(separatedBy: "&")
            var dic = Dictionary<String, String>.init()

            for s: String in arr! {
                let a = s.components(separatedBy: "=")
                dic.updateValue(a[1], forKey: a[0])
            }

            let safeBase64: String = Base64Safe.base64EncodedString(with: "ts.jpg?x-oss-process=image/resize,P_20")
            let type: String = dic["type"] ?? ""
            let size: String = dic["size"] ?? ""
            let text: String = dic["text"] ?? ""
            getRequest.xOssProcess = "image/resize,w_300,h_300/watermark,type_\(type),size_\(size),text_\(text),color_FFFFFF,image_\(safeBase64),interval_10"
        }
        getRequest.downloadProgress = { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
            print("Bytes sent: \(bytesWritten), Total bytes sent:\(totalBytesWritten), Expected total bytes sent: \(totalBytesExpectedToWrite)")
        }
        let getTask = client.getObject(getRequest)
        getTask.continue ({ (task) -> AnyObject? in
            if task.result == nil {
                DispatchQueue.main.async {
                    self.viewController.showMessage(putType: "普通下载", message: "Failed!")
                }
                return nil
            }
            let result = task.result as! OSSGetObjectResult
            if (task.error == nil) {
                self.viewController.saveAndDisplayImage(objectData: result.downloadedData, objectKey: objectKey.components(separatedBy: "@").first!)
                print("下载成功")
                DispatchQueue.main.async {
                    self.viewController.showMessage(putType: "普通下载", message: "Success!")
                }
            } else {
                print("下载失败:\(errno)")
                
                DispatchQueue.main.async {
                    self.viewController.showMessage(putType: "普通下载", message: "Failed!")
                }
                
            }
            self.getRequest = nil;
            return nil
        })
        
    }
    
    // 断点续传
    func resumableUpload(objectKey: String, localFilePath: String) {
        
        var uploadId = ""
        
        let uploadRequest = OSSInitMultipartUploadRequest.init()
        uploadRequest.bucketName = BUCKET_NAME
        uploadRequest.objectKey = objectKey
        
        let task = client.multipartUploadInit(uploadRequest)
        
        task.continue ({ (task) -> Any? in
            if task.error != nil {
                let result = task.result
                uploadId = (result?.uploadId)!
            } else {
//                print(task.error!)
            }
            return nil
        }).waitUntilFinished()
        
        let resumableUpload = OSSResumableUploadRequest.init()
        resumableUpload.bucketName = BUCKET_NAME
        resumableUpload.objectKey = objectKey
        resumableUpload.uploadId = uploadId
        resumableUpload.partSize = 1024 * 1024
        resumableUpload.uploadProgress = { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
            print("Bytes sent: \(bytesWritten), Total bytes sent:\(totalBytesWritten), Expected total bytes sent: \(totalBytesExpectedToWrite)")
        }
        resumableUpload.uploadingFileURL = URL.init(fileURLWithPath: localFilePath)
        let resumeTask = client.resumableUpload(resumableUpload)
        
        resumeTask.continue ({ (task) -> Any? in
            if task.error != nil {
                DispatchQueue.main.async {
                    self.viewController .showMessage(putType: "断点续传", message: "Failed!")
                }
            } else {
                DispatchQueue.main.async {
                    self.viewController .showMessage(putType: "断点续传", message: "Success!")
                }
            }
            return nil
        })
        
    }
    
}










