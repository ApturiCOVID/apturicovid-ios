import Foundation
import RxSwift
import ExposureNotification

protocol Switch where Self:UIControl  {
    var isOn: Bool { get set }
    func setOn(_ on: Bool, animated: Bool)
}

extension UISwitch: Switch {}
extension DesignableSwitch: Switch {}

protocol ContactDetectionToggleProvider : UIViewController {
    var disposeBag: DisposeBag {get}
    func setExposureTracking(enabled: Bool, referenceSwitch: Switch?, animated: Bool)
    func contactDetectionProvider(didReceiveError error: Error)
}

extension ContactDetectionToggleProvider {
    
    func setExposureTracking(enabled: Bool, referenceSwitch: Switch?, animated: Bool = true) {

        func authorize(enabled: Bool, goToSettingsIfUnauthorized: Bool){
            
            ExposureManager.shared
                .setExposureNotificationsEnabled(enabled)
                .subscribe(onError: { [weak self] (error) in
                    
                    switch error as? ExposureManager.StateError {
                        
                        //MARK: Unauthorized:
                    case .unauthorized:
                        
                        if goToSettingsIfUnauthorized {

                            let alert = UIAlertController(title: "exposure_notifications_off_error".translated,
                                                          message: "exposure_notifications_usage_description".translated,
                                                          preferredStyle: .alert)
                            alert.overrideUserInterfaceStyle = .light
                            
                            alert.addAction( UIAlertAction(title: "app_settings".translated,
                                                           style: .default) { _ in
                                                            referenceSwitch?.setOn(ExposureManager.shared.trackingIsWorking, animated: true)
                                                            UIApplication.openSettings()
                            })
                            
                            alert.addAction( UIAlertAction(title: "close".translated,
                                                           style: .cancel){ _ in
                                                            
                                                            referenceSwitch?.setOn(ExposureManager.shared.trackingIsWorking, animated: true)
                                                            
                            })
                            
                            self?.present(alert, animated: true)
                            
                        } else {
                            referenceSwitch?.setOn(false, animated: true)
                        }
                        
                        //MARK: BLE disabled:
                    case .bluetoothDisabled:
                        
                        
                        let alert = UIAlertController(title: "ble_off_error".translated,
                                                      message: "ble_usage_description".translated,
                                                      preferredStyle: .alert)
                        alert.overrideUserInterfaceStyle = .light
                        
                        //Private API url. Always check if can be opened
                        let bleSettingsUrl = URL(string: "App-prefs:Bluetooth")!
                        if UIApplication.shared.canOpenURL(bleSettingsUrl) {
                            
                            alert.addAction( UIAlertAction(title: "app_settings".translated,
                                                           style: .default) { _ in
                                                            referenceSwitch?.setOn(ExposureManager.shared.trackingIsWorking, animated: true)
                                                            UIApplication.shared.open(bleSettingsUrl)
                            })
                        }
                        
                        alert.addAction( UIAlertAction(title: "close".translated,
                                                       style: .cancel){ _ in
                                                        referenceSwitch?.setOn(ExposureManager.shared.trackingIsWorking, animated: true)
                                                        
                        })
                        
                        self?.present(alert, animated: true)
                        
                        //MARK: Other errors:
                    default:
                        referenceSwitch?.setOn(ExposureManager.shared.trackingIsWorking, animated: true)
                        self?.contactDetectionProvider(didReceiveError: error)
                    }
            })
            .disposed(by: disposeBag)
        }
        
        let redirectToSettings = enabled && ExposureManager.authorizationStatus != .unknown
        authorize(enabled: enabled, goToSettingsIfUnauthorized: redirectToSettings)
        
    }
    
}
