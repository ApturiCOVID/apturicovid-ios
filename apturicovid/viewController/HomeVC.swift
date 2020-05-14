//
//  HomeVC.swift
//  apturicovid
//
//  Created by Mazens Zibara on 08/05/2020.
//  Copyright © 2020 MAK IT. All rights reserved.
//

import UIKit

class HomeVC: BaseViewController {
    @IBOutlet weak var bottomBackgroundView: UIView!
    @IBOutlet weak var exposureSwitch: UISwitch!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var statsStackView: UIStackView!
    @IBOutlet weak var exposureIcon: UIImageView!
    @IBOutlet weak var exposureNotificationView: UIView!
    
    @IBOutlet weak var contactTracingTitle: UILabel!
    @IBOutlet weak var tracingStateLabel: UILabel!
    @IBOutlet weak var exposureTitleLabel: UILabel!
    @IBOutlet weak var exposureDescriptionLabel: UILabel!
    @IBOutlet weak var statsTitleLabel: UILabel!
    
    @IBOutlet var smallSizeBottomBackground: NSLayoutConstraint!
    @IBOutlet var fullHeightBottomBorder: NSLayoutConstraint!
    
    private var exposureNotificationVisible = false {
        didSet {
            setExposureNotification(visible: exposureNotificationVisible)
        }
    }
    
    @IBAction func onShareButtonTap(_ sender: Any) {
        exposureNotificationVisible = !exposureNotificationVisible
//        presentShareController()
    }
    
    @IBAction func onSwitchTap(_ sender: UISwitch) {
        ExposureManager.shared.toggleExposureNotifications(enabled: sender.isOn)
            .subscribe(onError: { error in
                justPrintError(error)
                sender.isOn = ExposureManager.shared.enabled
                self.setExposureStateVisual()
            })
            .disposed(by: disposeBag)
    }
    
    private func presentShareController() {
        let someText = "Dalies ar lietotni"
        let objectsToShare = URL(string: "http://www.apturicovid.lv")!
        let sharedObjects:[AnyObject] = [objectsToShare as AnyObject, someText as AnyObject]
        let activityViewController = UIActivityViewController(activityItems : sharedObjects, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view

        self.present(activityViewController, animated: true, completion: nil)
    }
    
    private func setExposureStateVisual() {
        let exposureEnabled = ExposureManager.shared.enabled
        tracingStateLabel.text = exposureEnabled ? "currently_active".translated : "currently_inactive".translated
        tracingStateLabel.textColor = exposureEnabled ? Colors.darkGreen : Colors.darkOrange
        exposureIcon.image = exposureEnabled ? UIImage(named: "exposure-icon") : UIImage(named: "exposure-disabled")
    }
    
    private func setExposureNotification(visible: Bool) {
        exposureNotificationView.isHidden = !visible
        smallSizeBottomBackground.isActive = visible
        fullHeightBottomBorder.isActive = !visible
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        exposureSwitch.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        shareButton.layer.cornerRadius = 5
        
        let backgroundView = HomeBottomView()
        bottomBackgroundView.addSubviewWithInsets(backgroundView)
        
        exposureSwitch.isOn = ExposureManager.shared.enabled
        
        [("600", "Testēti"), ("600", "Testēti"), ("600", "Testēti")].forEach { (arg0) in
            let (value, title) = arg0
            
            let stat = StatCell().fromNib() as! StatCell
            stat.fill(item: title, value: value)
            statsStackView.addArrangedSubview(stat)
        }
        
        setExposureNotification(visible: false)
    }
    
    override func translate() {
        contactTracingTitle.text = "contact_tracing".translated
        tracingStateLabel.text = "currently_active".translated
        exposureDescriptionLabel.text = "exposure_detected_subtitle".translated
        statsTitleLabel.text = "stats_title".translated
        shareButton.setTitle("share".translated, for: .normal)
        setExposureStateVisual()
    }
}
