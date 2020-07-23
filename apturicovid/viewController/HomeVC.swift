import UIKit
import RxSwift
import ExposureNotification
import Anchorage

class HomeVC: BaseViewController {
    
    @IBOutlet weak var bottomBackgroundView: HomeBottomView!
    @IBOutlet weak var exposureSwitch: DesignableSwitch!
    @IBOutlet weak var shareButton: RoundedButton!
    @IBOutlet weak var statsStackView: UIStackView!
    @IBOutlet weak var exposureIcon: UIImageView!
    @IBOutlet weak var exposureNotificationView: UIView!
    @IBOutlet weak var statsView: UIView!
    @IBOutlet weak var contactTracingTitle: UILabel!
    @IBOutlet weak var tracingStateLabel: UILabel!
    @IBOutlet weak var exposureDescriptionLabel: UILabel!
    @IBOutlet weak var statsTitleLabel: UILabel!
    @IBOutlet weak var exposureViewButton: UIButton!
    
    fileprivate let layoutConfig = HomeLayoutConfig.defaultConfig
    var bottomViewHeightAnchor: NSLayoutConstraint!
    var exposureNotificationTopAnchor: NSLayoutConstraint!
    
    private let statTested   = StatCell.create(item: "tested".translated)
    private let statNewCases = StatCell.create(item: "new_cases".translated)
    private let statDeceased = StatCell.create(item: "deaths".translated)
    
    var stats: Stats? {
        didSet {
            statTested.updateValue(stats?.yesterdaysTestsCount)
            statNewCases.updateValue(stats?.yesterdaysInfectedCount)
            statDeceased.updateValue(stats?.yesterdayDeathCount)
        }
    }
    
    var statCells: [StatCell] { [statNewCases,statDeceased,statTested] }
    
    private var exposureNotificationVisible = false {
        didSet {
            setExposureNotification(visible: exposureNotificationVisible, animated: true)
        }
    }
    
    @IBAction func onShareButtonTap(_ sender: Any) {
        presentShareController()
    }
    
    @IBAction func onSwitchTap(_ sender: DesignableSwitch) {
        
        if sender.isOn {
            setExposureTracking(enabled: true, referenceSwitch: sender, animated: true)
        } else {
            showBasicPrompt(with: "exposure_off_prompt".translated,
                            action: self.setExposureTracking(enabled: false, referenceSwitch: sender, animated: true),
                            cancelAction: sender.setOn(ExposureManager.shared.trackingIsWorking, animated: true),
                            confirmTitle: "yes".translated,
                            cancelTitle: "no".translated)
        }
    }
    
    private func presentShareController() {
        let urlToShare = URL(string: "https://www.apturicovid.lv#\(Language.primary.localization)")!
        let sharedObjects = [urlToShare as AnyObject]
        let activityViewController = UIActivityViewController(activityItems : sharedObjects, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    private func setExposureStateVisual(forState exposureEnabled: Bool, animated: Bool = false) {
        
        func setImage(exposureEnabled: Bool){
            self.exposureIcon.image = exposureEnabled ? UIImage(named: "detection-on-home") : UIImage(named: "detection-off-home")
        }
        
        func setExposureImage(in duration: TimeInterval){
            exposureIcon.layer.removeAllAnimations()
            
            guard duration > 0 else {
                exposureIcon.alpha = 1
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
        
        exposureSwitch.setOn(exposureEnabled, animated: false)
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
    
    private func updateTrackingIconVisibility(){
        exposureIcon.alpha = exposureIcon.bounds.height < 100 ? 0 : 1
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        translate()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTrackingIconVisibility()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadData()
        checkExposureStatus()
        showConnectivityWarningIfRequired()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setExposureNotification(visible: false)
        
        statCells.enumerated().forEach{ item in
            item.element.spacer.isHidden = item.offset == statCells.count-1
            statsStackView.addArrangedSubview(item.element)
        }
        
        //MARK: Exposure tracking enabled
        
        ExposureManager.shared.trackingIsWorkingObserver
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] enabled in
                self?.setExposureStateVisual(forState: enabled, animated: true)
                })
            .disposed(by: disposeBag)

        presentWelcomeIfNeeded()
        
        //MARK: Tap on exposure view
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
        
        //MARK: Track app state
        NotificationCenter.default.rx
            .notification(UIApplication.didBecomeActiveNotification)
            .flatMap({ _ -> Observable<Bool> in
                guard LocalStore.shared.hasSeenIntro else { return Observable.just(true) }
                return ExposureManager.shared.performExposureDetection()
            })
            .observeOn(MainScheduler.instance)
            .retry()
            .subscribe(onNext: { [weak self] (_) in
                self?.loadData()
                self?.checkExposureStatus()
                self?.setExposureStateVisual(forState: ExposureManager.shared.trackingIsWorking, animated: false)
            }, onError: justPrintError)
            .disposed(by: disposeBag)
        
        //MARK: Track reachability
        NotificationCenter.default.rx
            .notification(.reachabilityChanged)
            .subscribe(onNext: { [weak self] notification in
                if let connection = notification.object as? Reachability.Connection {
                    if connection.available && self?.stats == nil { self?.loadData() }
                }
            })
            .disposed(by: disposeBag)
        
    }
    
    func checkExposureStatus(){
        exposureNotificationVisible = LocalStore.shared.exposures.count > 0
    }
    
    func setupAnchorConstraints(dynamicHeight dynamic: Bool){

        bottomViewHeightAnchor?.isActive = false
        exposureNotificationTopAnchor?.isActive = false

        if dynamic {
            bottomViewHeightAnchor = bottomBackgroundView.heightAnchor >= layoutConfig.minimizedBottomBackgroundHeight
        } else {
            bottomViewHeightAnchor = bottomBackgroundView.heightAnchor == layoutConfig.minimizedBottomBackgroundHeight
        }
       
        exposureNotificationTopAnchor = exposureNotificationView.topAnchor == bottomBackgroundView.topAnchor
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
    
    override func translate() {
        contactTracingTitle.text = "contact_tracing".translated
        tracingStateLabel.text = "currently_active".translated
        exposureDescriptionLabel.text = "exposure_detected_subtitle".translated
        statsTitleLabel.text = "stats_title".translated
        
        statTested.updateTitle("tested".translated)
        statNewCases.updateTitle("new_cases".translated)
        statDeceased.updateTitle("deaths".translated)
        shareButton.setText("share".translated)
 
        setExposureStateVisual(forState: ExposureManager.shared.trackingIsWorking, animated: false)
        
    }
    
    private func setExposureNotification(visible: Bool, animated: Bool = false) {
        let isSE = UIDevice.current.type == .iPhoneSE
        setupAnchorConstraints(dynamicHeight: isSE ? !visible : true)
        
        /// Mover exposure notification over bottomBackgroundView
        let offset = layoutConfig.exporureNotificationYOffset
        exposureNotificationTopAnchor.constant = visible ? -offset : offset
        
        /// Adjust bottomBackgroundView height to fit content
        let minH = layoutConfig.minimizedBottomBackgroundHeight
        let maxH = layoutConfig.maximizedBottomBackgroundHeight
        bottomViewHeightAnchor.constant = visible ? minH : maxH
        
        let animationBlock: () -> Void = { [weak self] in
            self?.statsView.alpha = isSE && visible ? 0 : 1
            self?.view.layoutIfNeeded()
            self?.updateTrackingIconVisibility()
        }
        
        if animated {
            view.layer.removeAllAnimations()
            UIView.animate(withDuration: 0.3, animations: animationBlock)
        } else {
            animationBlock()
        }

    }
}

extension HomeVC: ContactDetectionToggleProvider {
    
    func contactDetectionProvider(didReceiveError error: Error) {
        justPrintError(error)
    }
    
}

fileprivate extension HomeVC {
    
    struct HomeLayoutConfig{
        var maximizedBottomBackgroundHeight: CGFloat
        var minimizedBottomBackgroundHeight: CGFloat
        var exporureNotificationYOffset: CGFloat
        
        static let defaultConfig: HomeLayoutConfig = {
            
            let maxH: CGFloat = 180
            let minH: CGFloat = {
                guard UIDevice.smallScreenSizeModels.contains(UIDevice.current.type) else { return maxH }
                return UIDevice.current.type == .iPhoneSE ? 0 : 150
            }()
            
            return HomeLayoutConfig(
                maximizedBottomBackgroundHeight: maxH,
                minimizedBottomBackgroundHeight: minH,
                exporureNotificationYOffset: 80)
            
        }()
    }
    
}

