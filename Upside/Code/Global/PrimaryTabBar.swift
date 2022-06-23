//
//  PrimaryTabBar.swift
//  Upside
//
//  Created by Luke Hammer on 4/29/22.
//

import UIKit

class PrimaryTabBar: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupDefualtNavigationBar()
        self.tabBar.barTintColor = UIColor.black
        self.tabBar.backgroundColor = UIColor.black
        self.tabBar.tintColor = ui_active_light_yellow
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    
    
}
