//
//  WalkthroughWelcomeViewController.swift
//  Simple Login
//
//  Created by Thanh-Nhon Nguyen on 25/02/2020.
//  Copyright © 2020 SimpleLogin. All rights reserved.
//

import UIKit
import Gifu

final class WalkthroughWelcomeViewController: BaseWalkthroughStepViewController {
    @IBOutlet private weak var imageView: GIFImageView!
    
    override var index: Int {
        return 0
    }
    
    deinit {
        print("WalkthroughWelcomeViewController is deallocated")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.animate(withGIFNamed: "superman")
    }
}
