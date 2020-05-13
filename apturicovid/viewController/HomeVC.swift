//
//  HomeVC.swift
//  apturicovid
//
//  Created by Mazens Zibara on 08/05/2020.
//  Copyright © 2020 MAK IT. All rights reserved.
//

import UIKit

class HomeVC: UIViewController {
    @IBOutlet weak var topHolder: UIView!
    @IBOutlet weak var shareHolder: UIView!
    
    @IBAction func onToggle(_ sender: UISwitch) {
        ExposureManager.shared.enabled = sender.isOn
    }
    
    @IBAction func onSettingsTap(_ sender: Any) {
        let vc = UIStoryboard(name: "ExposureSettings", bundle: nil).instantiateViewController(identifier: "ExposureSettings")
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func presentShareController() {
        let someText = "Dalies ar lietotni"
        let objectsToShare = URL(string: "http://www.apturicovid.lv")!
        let sharedObjects:[AnyObject] = [objectsToShare as AnyObject, someText as AnyObject]
        let activityViewController = UIActivityViewController(activityItems : sharedObjects, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view

        self.present(activityViewController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topHolder.layer.shadowColor = UIColor.black.cgColor
        topHolder.layer.shadowOpacity = 0.2
        topHolder.layer.shadowOffset = .zero
        topHolder.layer.shadowRadius = 10
        
        topHolder.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 50)
        shareHolder.roundCorners(corners: .allCorners, radius: 20)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(presentShareController))
        shareHolder.addGestureRecognizer(tapGesture)
        
//        if let onboarding = UIStoryboard(name: "Welcome", bundle: nil).instantiateInitialViewController() {
//            onboarding.modalPresentationStyle = .overFullScreen
//            self.present(onboarding, animated: true, completion: nil)
//        }
        
        RestClient.shared.getDiagnosisKeyFileURLs(startingAt: 1, completion: { (result) in
            switch result {
            case .success(let urls):
                print(urls)
            default: break
            }
        })
    }
}
