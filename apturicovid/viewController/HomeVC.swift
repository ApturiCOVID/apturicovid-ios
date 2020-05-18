//
//  HomeVC.swift
//  apturicovid
//
//  Created by Mazens Zibara on 08/05/2020.
//  Copyright © 2020 MAK IT. All rights reserved.
//

import UIKit
import RxSwift
import ExposureNotification

class HomeVC: BaseViewController {
    
    @IBOutlet weak var bottomBackgroundView: HomeBottomView!
    @IBOutlet weak var exposureSwitch: UISwitch!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var statsStackView: UIStackView!
    @IBOutlet weak var exposureIcon: UIImageView!
    @IBOutlet weak var exposureNotificationView: UIView!
    @IBOutlet weak var statsView: UIView!
    @IBOutlet weak var contactTracingTitle: UILabel!
    @IBOutlet weak var tracingStateLabel: UILabel!
    @IBOutlet weak var exposureTitleLabel: UILabel!
    @IBOutlet weak var exposureDescriptionLabel: UILabel!
    @IBOutlet weak var statsTitleLabel: UILabel!
    @IBOutlet weak var exposureViewButton: UIButton!
    
    private var exposureNotificationVisible = false {
        didSet {
            setExposureNotification(visible: exposureNotificationVisible)
        }
    }
    
    @IBAction func onShareButtonTap(_ sender: Any) {
        presentShareController()
    }
    
    @IBAction func onSwitchTap(_ sender: UISwitch) {
        ExposureManager.shared.toggleExposureNotifications(enabled: sender.isOn)
            .subscribe(onCompleted: {
                self.setExposureStateVisual()
            }, onError: { (error) in
                justPrintError(error)
                if let enError = error as? ENError, enError.code == ENError.Code.notAuthorized {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                }
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
        exposureSwitch.isOn = exposureEnabled
        tracingStateLabel.text = exposureEnabled ? "currently_active".translated : "currently_inactive".translated
        tracingStateLabel.textColor = exposureEnabled ? Colors.darkGreen : Colors.darkOrange
        exposureIcon.image = exposureEnabled ? UIImage(named: "exposure-icon") : UIImage(named: "exposure-disabled")
    }
    
    private func setExposureNotification(visible: Bool) {
        exposureNotificationView.isHidden = !visible
        layoutRequiresSetup(for: UIDevice.smallScreenSizeModels, backgroudVisible: !visible)
    }
    
    private func presentWelcomeIfNeeded() {
        guard !LocalStore.shared.hasSeenIntro else { return }
        
        let vc = UIStoryboard(name: "Welcome", bundle: nil).instantiateInitialViewController()
        vc?.isModalInPresentation = true
        self.present(vc!, animated: true, completion: nil)
    }
    
    private func presentExposureAlertVC() {
        guard let vc = self.storyboard?.instantiateViewController(identifier: "ExposureAlertVC") else { return }
        present(vc, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        exposureSwitch.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        
        exposureSwitch.isOn = ExposureManager.shared.enabled
        
        [("600", "Testēti"), ("600", "Testēti"), ("600", "Testēti")].forEach { (arg0) in
            let (value, title) = arg0
            
            let stat = StatCell().fromNib() as! StatCell
            stat.fill(item: title, value: value)
            statsStackView.addArrangedSubview(stat)
        }
        
        setExposureNotification(visible: false)
        presentWelcomeIfNeeded()
        
        exposureNotificationView
            .rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { (_) in
                self.presentExposureAlertVC()
            })
            .disposed(by: disposeBag)
        
        exposureViewButton
            .rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { (_) in
                self.presentExposureAlertVC()
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(UIApplication.didBecomeActiveNotification)
            .subscribe(onNext: { (_) in
                self.setExposureStateVisual()
                self.exposureNotificationVisible = LocalStore.shared.exposures.count > 0
            })
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        exposureNotificationVisible = LocalStore.shared.exposures.count > 0
    }
    
    override func translate() {
        contactTracingTitle.text = "contact_tracing".translated
        tracingStateLabel.text = "currently_active".translated
        exposureTitleLabel.text  = "exposure_detected_title".translated
        exposureDescriptionLabel.text = "exposure_detected_subtitle".translated
        statsTitleLabel.text = "stats_title".translated
        shareButton.setTitle("share".translated, for: .normal)
        setExposureStateVisual()
    }
    
    private func layoutRequiresSetup(for models: [Model], backgroudVisible: Bool) {
        guard models.contains(UIDevice.current.type) else { return }

        let bestBackgroundHeight: CGFloat = UIDevice.current.type == .iPhoneSE ? 30 : 50
        
        bottomBackgroundView.heightAnchor
            .constraint(equalToConstant: bestBackgroundHeight)
            .isActive = !backgroudVisible
     
        statsView.isHidden = !backgroudVisible
    }
}
