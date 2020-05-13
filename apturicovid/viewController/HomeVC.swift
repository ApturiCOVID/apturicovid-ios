//
//  HomeVC.swift
//  apturicovid
//
//  Created by Mazens Zibara on 08/05/2020.
//  Copyright © 2020 MAK IT. All rights reserved.
//

import UIKit

class HomeVC: UIViewController {
    @IBOutlet weak var bottomBackgroundView: UIView!
    @IBOutlet weak var exposureSwitch: UISwitch!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var statsStackView: UIStackView!
    
    @IBAction func onShareButtonTap(_ sender: Any) {
        presentShareController()
    }
    
    private func presentShareController() {
        let someText = "Dalies ar lietotni"
        let objectsToShare = URL(string: "http://www.apturicovid.lv")!
        let sharedObjects:[AnyObject] = [objectsToShare as AnyObject, someText as AnyObject]
        let activityViewController = UIActivityViewController(activityItems : sharedObjects, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view

        self.present(activityViewController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        exposureSwitch.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        shareButton.layer.cornerRadius = 5
        
        let backgroundView = HomeBottomView()
        bottomBackgroundView.addSubviewWithInsets(backgroundView)
        
        [("600", "Testēti"), ("600", "Testēti"), ("600", "Testēti")].forEach { (arg0) in
            let (value, title) = arg0
            
            let stat = StatCell().fromNib() as! StatCell
            stat.fill(item: title, value: value)
            statsStackView.addArrangedSubview(stat)
        }
    }
}
