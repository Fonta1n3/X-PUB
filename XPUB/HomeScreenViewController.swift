//
//  HomeScreenViewController.swift
//  XPUB
//
//  Created by Peter on 17/02/19.
//  Copyright © 2019 Fontaine. All rights reserved.
//

import UIKit
import AES256CBC
import SwiftKeychainWrapper
import EFQRCode

class HomeScreenViewController: UIViewController, UITabBarControllerDelegate, UITextFieldDelegate {
    
    
    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var labelField: UITextField!
    @IBOutlet weak var invoiceAmountField: UITextField!
    var index = UInt32()
    var addressHD = String()
    @IBOutlet weak var copyAddressButtonLabel: UIButton!
    
    @IBAction func copyAddressButton(_ sender: Any) {
        
        share(textToShare: self.addressHD)
        
    }
    
    @IBOutlet weak var indexLabel: UILabel!
    
    @IBAction func addAction(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.index = self.index + 1
            UserDefaults.standard.set(self.index, forKey: "index")
            UIView.animate(withDuration: 0.75, animations: {
                self.indexLabel.text = "\(self.index)"
            })
            self.loadWatchOnlyWallet()
            
        }
        
    }
    
    @IBAction func subtractAction(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            if self.index > 0 {
                
                self.index = self.index - 1
                UserDefaults.standard.set(self.index, forKey: "index")
                UIView.animate(withDuration: 0.75, animations: {
                    self.indexLabel.text = "\(self.index)"
                })
                self.loadWatchOnlyWallet()
                
            }
            
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBarController!.delegate = self
        
        UITabBar.appearance().barTintColor = UIColor.black
        
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = [UIColor.white.cgColor, UIColor.orange.cgColor]
        gradient.locations = [0.0 , 1.0]
        gradient.startPoint = CGPoint(x: 1.0, y: 1.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        self.view.layer.insertSublayer(gradient, at: 0)
        
        if UserDefaults.standard.object(forKey: "encryptedXpub") == nil {
            
            DispatchQueue.main.async {
                
                self.tabBarController!.selectedIndex = 1
                
            }
            
        }
        
        invoiceAmountField.delegate = self
        labelField.delegate = self
        invoiceAmountField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        labelField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        qrImageView.isUserInteractionEnabled = true
        qrImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageTapped)))
        addDoneButtonOnKeyboard()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        
        
        if UserDefaults.standard.object(forKey: "encryptedXpub") == nil {
            
            DispatchQueue.main.async {
                
                self.tabBarController!.selectedIndex = 1
                
            }
            
        } else {
            
            index = UserDefaults.standard.object(forKey: "index") as! UInt32
            
            if index == 0 {
                
                //users first time here display zero as index
                UserDefaults.standard.set(index + 1, forKey: "index")
                self.index = 0
                
            } else {
                
                UserDefaults.standard.set(UInt32(index + 1), forKey: "index")
                self.index = UserDefaults.standard.object(forKey: "index") as! UInt32
                
            }
            
            self.indexLabel.text = "\(self.index)"
            
            loadWatchOnlyWallet()
            
        }
        
    }
    

    func loadWatchOnlyWallet() {
        
        if let password = KeychainWrapper.standard.string(forKey: "masterKey") {
            
            if let xpub = UserDefaults.standard.string(forKey: "encryptedXpub") {
                
                if let decryptedXpub = AES256CBC.decryptString(xpub, password: password) {
                    
                    if let watchOnlyKey = BTCKeychain.init(extendedKey: decryptedXpub) {
                        
                        self.addressHD = (watchOnlyKey.key(at: self.index).address.string)
                        
                        DispatchQueue.main.async {
                            
                            //self.copyAddressButtonLabel.setTitle(self.addressHD, for: .normal)
                            
                            UIView.transition(with: self.copyAddressButtonLabel,
                                              duration: 0.75,
                                              options: .transitionCrossDissolve,
                                              animations: { [weak self] in
                                                self?.copyAddressButtonLabel.setTitle(self?.addressHD, for: .normal)
                                }, completion: nil)
                            
                            self.updateQRImage()
                            
                        }
                        
                    } else {
                        
                        print("error creating keychain")
                        
                    }
                    
                } else {
                    
                    print("error decrypting")
                    
                }
                
            }
            
        }
        
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        print("textFieldDidChange")
        
        //update qr code in real time
        createBIP21Invoice()
        
    }
    
    func createBIP21Invoice() {
        print("createBIP21Invoice")
        
        updateQRImage()
        
    }
    
    func updateQRImage() {
        
        var newImage = UIImage()
        
        if self.invoiceAmountField.text == "" && self.labelField.text == "" {
            
            newImage = self.generateQrCode(key:"bitcoin:\(self.addressHD)")!
            
        } else if self.invoiceAmountField.text != "" && self.labelField.text != "" {
            
            newImage = self.generateQrCode(key:"bitcoin:\(self.addressHD)?amount=\(self.invoiceAmountField.text!)?label=\(self.labelField.text!)")!
            
        } else if self.invoiceAmountField.text != "" && self.labelField.text == "" {
            
            newImage = self.generateQrCode(key:"bitcoin:\(self.addressHD)?amount=\(self.invoiceAmountField.text!)")!
            
        } else if self.invoiceAmountField.text == "" && self.labelField.text != "" {
            
            newImage = self.generateQrCode(key:"bitcoin:\(self.addressHD)?label=\(self.labelField.text!)")!
            
        }
        
        DispatchQueue.main.async {
            
            UIView.transition(with: self.qrImageView,
                              duration: 0.75,
                              options: .transitionCrossDissolve,
                              animations: { self.qrImageView.image = newImage },
                              completion: nil)
            
            let impact = UIImpactFeedbackGenerator()
            impact.impactOccurred()
            
        }
        
    }
    
    func generateQrCode(key: String) -> UIImage? {
        print("generateQrCode")
        
        let pic = UIImage(named: "bWhite.png")!
        let filter = CIFilter(name: "CISepiaTone")!
        filter.setValue(CIImage(image: pic), forKey: kCIInputImageKey)
        filter.setValue(1.0, forKey: kCIInputIntensityKey)
        let ctx = CIContext(options:nil)
        let watermark = ctx.createCGImage(filter.outputImage!, from:filter.outputImage!.extent)
        let cgImage = EFQRCode.generate(content: key,
                          size: EFIntSize.init(width: 256, height: 256),
                          backgroundColor: UIColor.clear.cgColor,
                          foregroundColor: UIColor.darkGray.cgColor,
                          watermark: watermark,
                          watermarkMode: EFWatermarkMode.scaleAspectFit,
                          inputCorrectionLevel: EFInputCorrectionLevel.h,
                          icon: nil,
                          iconSize: nil,
                          allowTransparent: true,
                          pointShape: EFPointShape.circle,
                          mode: EFQRCodeMode.none,
                          binarizationThreshold: 0,
                          magnification: EFIntSize.init(width: 50, height: 50),
                          foregroundPointOffset: 0)
        let qrImage = UIImage(cgImage: cgImage!)
        
        return qrImage
        
    }
    
    @objc func dismissKeyboard() {
        
        view.endEditing(true)
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        view.endEditing(true)
        return false
        
    }
    
    func addDoneButtonOnKeyboard() {
        
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle = UIBarStyle.default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: #selector(doneButtonAction))
        
        let items = NSMutableArray()
        items.add(flexSpace)
        items.add(done)
        
        doneToolbar.items = (items as! [UIBarButtonItem])
        doneToolbar.sizeToFit()
        
        self.invoiceAmountField.inputAccessoryView = doneToolbar
        
    }
    
    @objc func doneButtonAction() {
        
        self.invoiceAmountField.resignFirstResponder()
        
    }
    
    func share(textToShare: String) {
        
        DispatchQueue.main.async {
            
            let textToShare = [textToShare]
            let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
            self.present(activityViewController, animated: true, completion: nil)
            
        }
        
    }
    
    @objc func shareQRCode() {
        
        DispatchQueue.main.async {
            
            /*//UIGraphicsBeginImageContextWithOptions(CGSize(self.qrframe.size.width*0.99,self.frame.size.height*0.70), false, 0)
            UIGraphicsBeginImageContext(CGSize(width: self.view.frame.width, height: self.qrImageView.frame.height))
            let image = UIGraphicsGetImageFromCurrentImageContext()
            let frame = CGRect(x: 0, y: self.copyAddressButtonLabel.frame.maxY, width: self.view.frame.width, height: self.qrImageView.frame.height)
            self.view.drawHierarchy(in: frame, afterScreenUpdates: true)
            //var screenShot  = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()*/
            
            var key = String()
            
            if self.invoiceAmountField.text == "" && self.labelField.text == "" {
                
                key = "bitcoin:\(self.addressHD)"
                
            } else if self.invoiceAmountField.text != "" && self.labelField.text != "" {
                
                key = "bitcoin:\(self.addressHD)?amount=\(self.invoiceAmountField.text!)?label=\(self.labelField.text!)"
                
            } else if self.invoiceAmountField.text != "" && self.labelField.text == "" {
                
                key = "bitcoin:\(self.addressHD)?amount=\(self.invoiceAmountField.text!)"
                
            } else if self.invoiceAmountField.text == "" && self.labelField.text != "" {
                
                key = "bitcoin:\(self.addressHD)?label=\(self.labelField.text!)"
                
            }
            
            let pic = UIImage(named: "bWhite.png")!
            let filter = CIFilter(name: "CISepiaTone")!
            filter.setValue(CIImage(image: pic), forKey: kCIInputImageKey)
            filter.setValue(1.0, forKey: kCIInputIntensityKey)
            let ctx = CIContext(options:nil)
            let watermark = ctx.createCGImage(filter.outputImage!, from:filter.outputImage!.extent)
            let cgImage = EFQRCode.generate(content: key,
                                            size: EFIntSize.init(width: 256, height: 256),
                                            backgroundColor: UIColor.orange.cgColor,
                                            foregroundColor: UIColor.darkGray.cgColor,
                                            watermark: watermark,
                                            watermarkMode: EFWatermarkMode.scaleAspectFit,
                                            inputCorrectionLevel: EFInputCorrectionLevel.h,
                                            icon: nil,
                                            iconSize: nil,
                                            allowTransparent: true,
                                            pointShape: EFPointShape.circle,
                                            mode: EFQRCodeMode.none,
                                            binarizationThreshold: 0,
                                            magnification: EFIntSize.init(width: 50, height: 50),
                                            foregroundPointOffset: 0)
            let qrImage = UIImage(cgImage: cgImage!)
            
            DispatchQueue.main.async {
                    
                let activityController = UIActivityViewController(activityItems: [qrImage as Any], applicationActivities: nil)
                self.present(activityController, animated: true, completion: nil)
                    
            }
                
            
        }
        
    }
    
    func getDocumentsDirectory() -> URL {
        print("getDocumentsDirectory")
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
        
    }
    
    @objc private func imageTapped(_ recognizer: UITapGestureRecognizer) {
        print("image tapped")
        
        shareQRCode()
        
        DispatchQueue.main.async {
            
            UIView.animate(withDuration: 0.2, animations: {
                
                self.qrImageView.alpha = 0
                
            }) { _ in
                
                UIView.animate(withDuration: 0.2) {
                    self.qrImageView.alpha = 1
                }
                
            }
            
        }
        
    }

}

extension HomeScreenViewController  {
    func tabBarController(_ tabBarController: UITabBarController, animationControllerForTransitionFrom fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return MyTransition(viewControllers: tabBarController.viewControllers)
    }
}

class MyTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    let viewControllers: [UIViewController]?
    let transitionDuration: Double = 0.5
    
    init(viewControllers: [UIViewController]?) {
        self.viewControllers = viewControllers
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return TimeInterval(transitionDuration)
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard
            let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let fromView = fromVC.view,
            let fromIndex = getIndex(forViewController: fromVC),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
            let toView = toVC.view,
            let toIndex = getIndex(forViewController: toVC)
            else {
                transitionContext.completeTransition(false)
                return
        }
        
        let frame = transitionContext.initialFrame(for: fromVC)
        var fromFrameEnd = frame
        var toFrameStart = frame
        fromFrameEnd.origin.x = toIndex > fromIndex ? frame.origin.x - frame.width : frame.origin.x + frame.width
        toFrameStart.origin.x = toIndex > fromIndex ? frame.origin.x + frame.width : frame.origin.x - frame.width
        toView.frame = toFrameStart
        
        DispatchQueue.main.async {
            transitionContext.containerView.addSubview(toView)
            UIView.animate(withDuration: self.transitionDuration, animations: {
                fromView.frame = fromFrameEnd
                toView.frame = frame
            }, completion: {success in
                fromView.removeFromSuperview()
                transitionContext.completeTransition(success)
            })
        }
    }
    
    func getIndex(forViewController vc: UIViewController) -> Int? {
        guard let vcs = self.viewControllers else { return nil }
        for (index, thisVC) in vcs.enumerated() {
            if thisVC == vc { return index }
        }
        return nil
    }
}

extension UIView {
    
    func screenshot() -> UIImage {
        return UIGraphicsImageRenderer(size: bounds.size).image { _ in
            drawHierarchy(in: CGRect(origin: .zero, size: bounds.size), afterScreenUpdates: true)
        }
    }
    
}


