//
//  QRCodeScannerViewController.swift
//  XPUB
//
//  Created by Peter on 17/02/19.
//  Copyright © 2019 Fontaine. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftKeychainWrapper
import AES256CBC

class QRCodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITabBarControllerDelegate {

    let imagePicker = UIImagePickerController()
    let uploadButton = UIButton()
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBarController!.delegate = self
        
        UITabBar.appearance().barTintColor = UIColor.black
        
        if let _ = KeychainWrapper.standard.string(forKey: "masterKey") {
                
            //encryption key already saved do nothing
                
        } else {
                
            let masterkey = randomString(length: 32)
            let success = KeychainWrapper.standard.set(masterkey, forKey: "masterKey")
            if success {
                print("success saving master key \(masterkey)")
            }
                
        }
            
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        imagePicker.delegate = self
            
        let videoInput: AVCaptureDeviceInput
            
        do {
                
            guard let videoCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
                    
                print("no camera")
                failed()
                throw error.noCameraAvailable
                    
            }
                
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
                
        } catch {
                
            failed()
            return
                
        }
            
        if (captureSession.canAddInput(videoInput)) {
            
            captureSession.addInput(videoInput)
                
        } else {
                
            failed()
            return
                
        }
            
        let metadataOutput = AVCaptureMetadataOutput()
            
        if (captureSession.canAddOutput(metadataOutput)) {
                
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
                
        } else {
                
            failed()
            return
                
        }
            
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        view.layer.addSublayer(previewLayer)
            
        captureSession.startRunning()
            
        addButtons()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        
        
    }
    
    func displayAlert(viewController: UIViewController, title: String, message: String) {
        print("displayAlert")
        
        DispatchQueue.main.async {
            
            let alertcontroller = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertcontroller.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            viewController.present(alertcontroller, animated: true, completion: nil)
            
        }
        
    }
    
    enum error: Error {
        
        case noCameraAvailable
        case videoInputInitFail
        
    }
    
    func addButtons() {
        
        DispatchQueue.main.async {
            
            self.uploadButton.removeFromSuperview()
            self.uploadButton.showsTouchWhenHighlighted = true
            self.uploadButton.setTitleColor(UIColor.white, for: .normal)
            self.uploadButton.backgroundColor = UIColor.clear
            self.uploadButton.titleLabel?.font = UIFont.init(name: "HelveticaNeue-Bold", size: 20)
            self.uploadButton.frame = CGRect(x: 0, y: self.view.frame.maxY - 100, width: self.view.frame.width, height: 30)
            self.uploadButton.showsTouchWhenHighlighted = true
            self.uploadButton.titleLabel?.textAlignment = .center
            self.uploadButton.setTitle("Upload from photos", for: .normal)
            self.uploadButton.addTarget(self, action: #selector(self.chooseQRCodeFromLibrary), for: .touchUpInside)
            self.view.addSubview(self.uploadButton)
            
            let label = UILabel()
            label.removeFromSuperview()
            label.frame = CGRect(x: 0, y: 30, width: self.view.frame.width, height: 25)
            label.text = "Scan an XPUB"
            label.font = UIFont.init(name: "HelveticaNeue-Light", size: 20)
            label.textAlignment = .center
            label.backgroundColor = UIColor.clear
            label.textColor = UIColor.white
            self.view.addSubview(label)
            
        }
        
    }
    
    func failed() {
        print("failed")
        addButtons()
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    /*func captureOutput(_ output: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        
        
    }*/
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
        
    }
    
    func found(code: String) {
        print(code)
        DispatchQueue.main.async {
            self.importXpub(xpub: code)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    @objc func chooseQRCodeFromLibrary() {
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            
            let detector:CIDetector=CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])!
            let ciImage:CIImage = CIImage(image:pickedImage)!
            var qrCodeLink = ""
            let features = detector.features(in: ciImage)
            
            for feature in features as! [CIQRCodeFeature] {
                qrCodeLink += feature.messageString!
            }
            
            print(qrCodeLink)
            
            if qrCodeLink != "" {
                
                DispatchQueue.main.async {
                    
                    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                    self.importXpub(xpub: qrCodeLink)
                }
                
            }
            
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    
    func importXpub(xpub: String) {
        print("importXpub = \(importXpub)")
        
        if xpub.hasPrefix("xpub") {
            
            if let _ = BTCKeychain.init(extendedKey: xpub) {
                
                //encrypt xpub and store it in core data
                //segue to displaying invoice creator
                //automatically increment index, but allow manual incrementing
                //allow user to use bip21
                //change qr code live
                //allow fiat
                
                if let password = KeychainWrapper.standard.string(forKey: "masterKey") {
                    
                    let encryptedXpub = AES256CBC.encryptString(xpub, password: password)!
                    
                    if UserDefaults.standard.string(forKey: "encryptedXpub") != nil {
                        
                        DispatchQueue.main.async {
                            
                            let alert = UIAlertController(title: "Warning!", message: "You already have an exisiting xpub saved to the device, scanning a new one will overwrite your existing xpub!", preferredStyle: UIAlertController.Style.actionSheet)
                            
                            alert.addAction(UIAlertAction(title: NSLocalizedString("Overwrite", comment: ""), style: .destructive, handler: { (action) in
                                
                                DispatchQueue.main.async {
                                    
                                    UserDefaults.standard.set(encryptedXpub, forKey: "encryptedXpub")
                                    UserDefaults.standard.set(0, forKey: "index")
                                    self.tabBarController!.selectedIndex = 0
                                    
                                }
                                
                            }))
                            
                            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action) in
                                
                                DispatchQueue.main.async {
                                    
                                    self.tabBarController!.selectedIndex = 0
                                    
                                }
                                
                            }))
                            
                            alert.popoverPresentationController?.sourceView = self.view
                            self.present(alert, animated: true) {
                                print("option menu presented")
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0...length-1).map{ _ in letters.randomElement()! })
    }
    

}

extension QRCodeScannerViewController  {
    func tabBarController(_ tabBarController: UITabBarController, animationControllerForTransitionFrom fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return MyTransition(viewControllers: tabBarController.viewControllers)
    }
}
