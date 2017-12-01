//
//  ViewController.swift
//  MyAliyunOSSDemoSwift
//
//  Created by Crack on 2017/11/30.
//  Copyright © 2017年 Crack. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate,UINavigationControllerDelegate {

    var service: MyOssService!
    var imageService: MyOssService!
    var imageOperation: ImageService!
    var uploadFilePath: String!
    var originConstraintValue: Int!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var fileNameTextField: UITextField!
    @IBOutlet weak var textWaterMarkTextField: UITextField!
    @IBOutlet weak var textSizeTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        print(path ?? "")
        
        service = MyOssService.init(view: self, endpoint: endPoint)
        imageService = MyOssService.init(view: self, endpoint: imageEndPoint)
        imageOperation = ImageService.init(service: imageService)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        
        
    }

    @IBAction func selectFileBtn(_ sender: UIButton) {
        let title = "选择"
        let cancelButtonTitle = "取消"
        let picButtonTitle = "拍照"
        let photoButtonTitle = "从相册选择"
        
        let alert = UIAlertController.init(title: title, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction.init(title: cancelButtonTitle, style: .cancel, handler: nil)
        let picAction = UIAlertAction.init(title: picButtonTitle, style: .destructive) { (action) in
            let imagePickerController = UIImagePickerController.init()
            imagePickerController.delegate = self
            imagePickerController.allowsEditing = true
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true, completion: nil)
        }
        let photoAction = UIAlertAction.init(title: photoButtonTitle, style: .destructive) { (action) in
            let imagePickerController = UIImagePickerController.init()
            imagePickerController.delegate = self
            imagePickerController.allowsEditing = true
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
        }
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(cancelAction)
            alert.addAction(picAction)
            alert.addAction(photoAction)
        } else {
            alert.addAction(cancelAction)
            alert.addAction(photoAction)
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    func verifyFileName() -> Bool {
        if (fileNameTextField.text?.isEmpty)! || fileNameTextField.text == "" {
            self.showMessage(putType: "填写错误", message: "文件名不能为空！")
            return false
        }
        return true
    }
    
    @IBAction func uploadFileBtn(_ sender: UIButton) {
        if !self.verifyFileName() {
            return
        }
        let objectKey = fileNameTextField.text
        service.asyncPutImage(objectKey: objectKey!, filePath: uploadFilePath)
    }
    
    @IBAction func downloadFileBtn(_ sender: UIButton) {
        if !self.verifyFileName() {
            return
        }
        let objectKey = fileNameTextField.text
        service.asyncGetImage(objectKey: objectKey!)
    }
    
    @IBAction func resumableUploadBtn(_ sender: UIButton) {
        if !self.verifyFileName() {
            return
        }
        service.resumableUpload(objectKey: fileNameTextField.text!, localFilePath: uploadFilePath)
    }
    
    @IBAction func textWaterMarkBtn(_ sender: UIButton) {
        if !self.verifyFileName() {
            return
        }
        if (fileNameTextField.text?.isEmpty)! {
            self.showMessage(putType: "填写错误", message: "水印文字不能为空！")
            return
        }
        if (textSizeTextField.text?.isEmpty)! {
            self.showMessage(putType: "填写错误", message: "字体大小不能为空！必须是数字！")
            return
        }
//        if (textSizeTextField.text?.isEmpty)! {
//            self.showMessage(putType: "填写错误", message: "字体必须是数字！")
//            return
//        }
        let objectKey: String = fileNameTextField.text!
        let waterMark: String = textWaterMarkTextField.text!
        let size: Int = Int(textSizeTextField.text!)!
        imageOperation.textWaterMark(object: objectKey, text: waterMark, size: size)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true) {
            
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        let image: UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        self.saveImage(currentImage: image, imageName: "currentImage")
        imageView.image = image
        imageView.tag = 100
    }
    
    
    
    // 载后存储并显示图片
    func saveAndDisplayImage(objectData: Data, objectKey: String) {
        let fullPath = NSHomeDirectory().appending("/Documents/").appending(objectKey)
        do {
            try objectData.write(to: URL.init(fileURLWithPath: fullPath), options: .atomic)
        } catch {
            print(error)
        }
        let image = UIImage.init(data: objectData)
        uploadFilePath = fullPath
        DispatchQueue.main.async {
            self.imageView.image = image
        }
    }
    
    // 保存图片
    func saveImage(currentImage: UIImage, imageName: String) {
        let imageData = UIImageJPEGRepresentation(currentImage, 0.5)
        let fullPath = NSHomeDirectory().appending("/Documents/").appending(imageName)
        do {
            try imageData?.write(to: URL.init(fileURLWithPath: fullPath), options: .atomic)
        } catch {
            print(error)
        }
        uploadFilePath = fullPath
    }
    
    func showMessage(putType: String, message: String) {
        let defaultAction = UIAlertAction.init(title: "确定", style: .default, handler: nil)
        let alert = UIAlertController.init(title: putType, message: message, preferredStyle: .alert)
        alert.addAction(defaultAction)
        self.present(alert, animated: true, completion: nil)
    }

}

