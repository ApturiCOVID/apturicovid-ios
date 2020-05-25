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

protocol ContactDetectionToggleProvider : class {
    var disposeBag: DisposeBag {get}
    func setExposureTracking(enabled: Bool)
    func contactDetectionProvider(exposureDidBecomeEnabled enabled: Bool)
    func contactDetectionProvider(didReceiveError error: Error)
}

extension ContactDetectionToggleProvider {
    
    func setExposureTracking(enabled: Bool) {
        ExposureManager.shared.toggleExposureNotifications(enabled: enabled)
            .subscribe(onCompleted: { [weak self] in
                self?.contactDetectionProvider(exposureDidBecomeEnabled: ExposureManager.shared.enabled )
            }, onError: { [weak self] (error) in
                if let enError = error as? ENError, enError.code == ENError.Code.notAuthorized {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                } else {
                    self?.contactDetectionProvider(didReceiveError: error)
                }
            })
            .disposed(by: disposeBag)
    }
    
}
