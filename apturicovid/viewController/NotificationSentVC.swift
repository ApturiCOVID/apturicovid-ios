//
//  NotificationSentVC.swift
//  apturicovid
//
//  Created by Melānija Grunte on 18/05/2020.
//  Copyright © 2020 MAK IT. All rights reserved.
//

import Foundation
import UIKit

class NotificationSentVC: BaseViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var closeButton: RoundedButton!
    
    override func translate() {
        titleLabel.text = "notification_sent_title".translated
        descriptionLabel.text = "notification_sent_description".translated
        closeButton.setTitle("close".translated, for: .normal)
    }
    
    @IBAction func onCloseTapped(_ sender: UIButton) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
