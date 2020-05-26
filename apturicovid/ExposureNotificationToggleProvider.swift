//
//  ExposureNotificationToggleProvider.swift
//  apturicovid
//
//  Created by Artjoms Spole on 22/05/2020.
//  Copyright © 2020 MAK IT. All rights reserved.
//

import Foundation
import RxSwift
import ExposureNotification

protocol Switch where Self:UIControl  {
    var isOn: Bool { get set }
    func setOn(_ on: Bool, animated: Bool)
}

extension UISwitch: Switch {}
extension DesignableSwitch: Switch {}

protocol ContactDetectionToggleProvider : class {
    var disposeBag: DisposeBag {get}
    func setExposureTracking(enabled: Bool, referenceSwitch: Switch?, animated: Bool)
    func contactDetectionProvider(exposureDidBecomeEnabled enabled: Bool)
    func contactDetectionProvider(didReceiveError error: Error)
}

extension ContactDetectionToggleProvider {
    
    func setExposureTracking(enabled: Bool, referenceSwitch: Switch?, animated: Bool = true) {

        func authorize(enabled: Bool, goToSettingsIfUnauthorized: Bool){
            
            ExposureManager.shared.toggleExposureNotifications(enabled: enabled)
            .subscribe(onCompleted: { [weak self] in
                self?.contactDetectionProvider(exposureDidBecomeEnabled: ExposureManager.shared.enabled )
            }, onError: { [weak self] (error) in
                if let enError = error as? ENError {
                    switch enError.code {
                    case .notAuthorized:
                        referenceSwitch?.setOn(false, animated: true)
                        self?.contactDetectionProvider(exposureDidBecomeEnabled: false)
                        if goToSettingsIfUnauthorized {  UIApplication.openSettings() }
                    
                    default:
                        print(enError.code)
                         self?.contactDetectionProvider(didReceiveError: error)
                    }
                }
            })
            .disposed(by: disposeBag)
        }
        
        authorize(enabled: enabled, goToSettingsIfUnauthorized: enabled && ExposureManager.authorizationStatus != .unknown)
        
    }
    
}
