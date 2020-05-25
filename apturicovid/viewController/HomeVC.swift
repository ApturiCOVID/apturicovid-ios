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
import Anchorage

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
    @IBOutlet weak var exposureDescriptionLabel: UILabel!
    @IBOutlet weak var statsTitleLabel: UILabel!
    @IBOutlet weak var exposureViewButton: UIButton!
    
    private let statTested   = StatCell.create(item: "tested".translated)
    private let statNewCases = StatCell.create(item: "new_cases".translated)
    private let statDeceased = StatCell.create(item: "deceased".translated)
    
    var exposureNotificationTopConstraint: NSLayoutConstraint!
    
    var stats: Stats? {
        didSet {
            statTested.updateValue(stats?.yesterdaysTestsCount)
            statNewCases.updateValue(stats?.yesterdaysInfectedCount)
            statDeceased.updateValue(stats?.yesterdayDeathCount)
        }
    }
    
    var statCells: [StatCell] { [statTested,statNewCases,statDeceased] }
    
    private var exposureNotificationVisible = false {
        didSet {
            setExposureNotification(visible: exposureNotificationVisible, animated: true)
        }
    }
    
    @IBAction func onShareButtonTap(_ sender: Any) {
        presentShareController()
    }
    
    @IBAction func onSwitchTap(_ sender: UISwitch) {
        if !sender.isOn {
            showBasicPrompt(with: "exposure_off_prompt".translated, action: {
                self.toggleExposure(enabled: false)
            }, cancelAction: {
                self.exposureSwitch.isOn = true
            }, confirmTitle: "yes".translated, cancelTitle: "cancel".translated)
        } else {
            toggleExposure(enabled: sender.isOn)
        }
    }
    
    private func presentShareController() {
        let urlToShare = URL(string: "https://www.apturicovid.lv")!
        let sharedObjects = [urlToShare as AnyObject]
        let activityViewController = UIActivityViewController(activityItems : sharedObjects, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    private func setExposureStateVisual(animated: Bool = false) {
        
        func setImage(exposureEnabled: Bool){
            self.exposureIcon.image = exposureEnabled ? UIImage(named: "detection-on-home") : UIImage(named: "detection-off-home")
        }
        
        func setExposureImage(in duration: TimeInterval){
            exposureIcon.layer.removeAllAnimations()
            
            guard duration > 0 else {
                setImage(exposureEnabled: exposureEnabled)
                return
            }
            
            UIView.animate(withDuration: duration/2, animations: {
                self.exposureIcon.alpha = 0
            }) { completed in

                guard completed else { return }
                setImage(exposureEnabled: exposureEnabled)
                UIView.animate(withDuration: duration/2){
                    self.exposureIcon.alpha = 1
                }
            }
        }
        
        let exposureEnabled = ExposureManager.shared.enabled
        exposureSwitch.isOn = exposureEnabled
        tracingStateLabel.text = exposureEnabled ? "currently_active".translated : "currently_inactive".translated
        tracingStateLabel.textColor = exposureEnabled ? Colors.darkGreen : Colors.disabled
        setExposureImage(in: animated ? 0.3 : 0)
    }
    
    
    private func presentWelcomeIfNeeded() {
        guard !LocalStore.shared.hasSeenIntro else { return }
        
        let vc = UIStoryboard(name: "Welcome", bundle: nil).instantiateInitialViewController()
        vc?.isModalInPresentation = true
        self.present(vc!, animated: true, completion: nil)
    }
    
    private func presentExposureAlertVC() {
        guard let vc = self.storyboard?.instantiateViewController(identifier: "ExposureAlertVC") else { return }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showConnectivityWarningIfRequired()

        loadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        exposureNotificationTopConstraint = exposureNotificationView.topAnchor == bottomBackgroundView.topAnchor - bottomBackgroundView.curveOffset
        setExposureNotification(visible: false)

        exposureSwitch.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        exposureSwitch.setOffColor(UIColor(named: "offColor")!)
        exposureSwitch.isOn = ExposureManager.shared.enabled
        
        statCells.forEach{ statsStackView.addArrangedSubview($0) }
        
        presentWelcomeIfNeeded()
        
        exposureNotificationView
            .rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] (_) in
                self?.presentExposureAlertVC()
            })
            .disposed(by: disposeBag)
        
        exposureViewButton
            .rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] (_) in
                self?.presentExposureAlertVC()
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(UIApplication.didBecomeActiveNotification)
            .do(onNext: { _ in
                ExposureManager.shared.refreshState()
                self.setExposureStateVisual()
            })
            .flatMap({ _ -> Observable<Bool> in
                guard LocalStore.shared.hasSeenIntro else { return Observable.just(true) }
                return ExposureManager.shared.performExposureDetection()
            })
            .observeOn(MainScheduler.instance)
            .retry()
            .subscribe(onNext: { [weak self] (_) in
                self?.exposureNotificationVisible = LocalStore.shared.exposures.count > 0
                self?.loadData()
            }, onError: justPrintError)
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(.reachabilityChanged)
            .subscribe(onNext: { [weak self] notification in
                if let connection = notification.object as? Reachability.Connection {
                    if connection.available && self?.stats == nil { self?.loadData() }
                }
            })
            .disposed(by: disposeBag)
        
        testAnimation()
    }
    
    func testAnimation(){
        Timer.scheduledTimer(withTimeInterval: 4 , repeats: true){ [weak self] _ in
            self?.exposureNotificationVisible.toggle()
        }.fire()
    }
    
    func loadData(){
        stats = nil
        
        StatsClient.shared.getStats(ignoreOutdated: true)
        .subscribeOn(SerialDispatchQueueScheduler(qos: .default))
        .observeOn(MainScheduler.instance)
        .share()
        .subscribe(onNext: { [weak self] (stats) in
            self?.stats = stats
        }, onError: justPrintError)
        .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        exposureNotificationVisible = LocalStore.shared.exposures.count > 0
    }
    
    
    override func translate() {
        contactTracingTitle.text = "contact_tracing".translated
        tracingStateLabel.text = "currently_active".translated
        exposureDescriptionLabel.text = "exposure_detected_subtitle".translated
        statsTitleLabel.text = "stats_title".translated
        
        statTested.updateTitle("tested".translated)
        statNewCases.updateTitle("new_cases".translated)
        statDeceased.updateTitle("deceased".translated)
        
        shareButton.setTitle("share".translated, for: .normal)
        shareButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 10)
        shareButton.sizeToFit()
 
        setExposureStateVisual()
    }
    
    private func setExposureNotification(visible: Bool, animated: Bool = false) {

        let thisIsSmallScreen = UIDevice.smallScreenSizeModels.contains(UIDevice.current.type)
        
        let bestBackgroundHeight: CGFloat = thisIsSmallScreen ? UIDevice.current.type == .iPhoneSE ? 0 : 150 : 180

        if thisIsSmallScreen && visible {
            /// Adjust bottomBackgroundView height to fit content
            
            bottomBackgroundView.heightAnchor
                .constraint(equalToConstant: bestBackgroundHeight)
                .isActive = true

        } else {

            /// For large screens display both stats and exposure notification
            bottomBackgroundView.heightAnchor
                .constraint(equalToConstant: 180)
                .isActive = true
        }
        
        /// Mover exposure notification over bottomBackgroundView
        exposureNotificationTopConstraint.constant = visible ? -80 : bottomBackgroundView.curveOffset
        
        UIView.animate(withDuration: animated ? 0.3 : 0) { [weak self] in
            guard let `self` = self else { return }
            self.statsView.alpha = bestBackgroundHeight < self.statsView.bounds.height && visible ? 0 : 1
            self.view.layoutIfNeeded()
        }

    }
}

extension HomeVC: ContactDetectionToggleProvider {
    
    func contactDetectionProvider(exposureDidBecomeEnabled enabled: Bool) {
        exposureSwitch.isOn = enabled
        setExposureStateVisual(animated: true)
    }
    
    func contactDetectionProvider(didReceiveError error: Error) {
        justPrintError(error)
        self.setExposureStateVisual(animated: false)
    }
    
}

