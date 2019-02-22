//
//  InfoViewController.swift
//  XPUB
//
//  Created by Peter on 22/02/19.
//  Copyright © 2019 Fontaine. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = [UIColor.white.cgColor, UIColor.orange.cgColor]
        gradient.locations = [0.0 , 1.0]
        gradient.startPoint = CGPoint(x: 1.0, y: 1.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        self.view.layer.insertSublayer(gradient, at: 0)
        
        textView.text = "X-PUB is an open sourced app and the code can be found here: https://github.com/FontaineDenton/X-PUB\n\nX-PUB is compatible with extended public keys that have been derived from BIP39 seeds (recovery phrases) that utilize the industry standard BIP44 derivation path m/44'/0'/0'/0.  Unfortunately not all wallets are compatible such as electrum, so always make sure to check that the addresses produced by X-PUB are the same as whatever wallet you are using before sending real funds to the addresses.  For now X-PUB is only compatible with legacy addresses.\n\nIn the worst case scenario we would be able to assist you in recovering any lost funds as long as you have your original seed phrase, just email us at bitsenseapp@gmail.com.\n\nOur other app DiceKeys is guranteed to give you the same addresses and we recommend this app for your offline secure key creation needs. DiceKeys will give you an xpub that is fully BIP39/BIP44 compatible and will work on this app flawlessly.\n\nYou can always go to https://iancoleman.io/bip39/ and select BIP44 derivation path to verify the resulting address are being created correctly and even get the corresponding private keys, of course this should only be done offline."
    }
    

    override func viewDidAppear(_ animated: Bool) {
        
        textView.setContentOffset(.zero, animated: true)
        
    }

}
