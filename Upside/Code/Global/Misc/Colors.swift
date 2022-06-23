//
//  Colors.swift
//  Upside
//
//  Created by Luke Hammer on 4/29/22.
//

import UIKit

extension UIColor {
    
    var coreImageColor: CIColor {
        return CIColor(color: self)
    }
    
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        let coreImageColor = self.coreImageColor
        return (coreImageColor.red, coreImageColor.green, coreImageColor.blue, coreImageColor.alpha)
    }
    
}


//rgb(0.0, 112.0, 217.0)
let ui_active_blue = UIColor(red: 0.0/255.0,
                             green: 112.0/255.0,
                             blue: 217.0/255.0,
                             alpha: 1.0)

//rgb(251,179,21)
let ui_active_light_yellow = UIColor(red: 251.0/255.0,
                                     green: 179.0/255.0,
                                     blue: 21.0/255.0,
                                     alpha: 1.0)

//rgb(243,133,31)
let ui_active_dark_yellow = UIColor(red: 243.0/255.0,
                                    green: 133.0/255.0,
                                    blue: 31.0/255.0,
                                    alpha: 1.0)

//rgb(77,82,90)
let ui_active_dark_gray = UIColor(red: 77.0/255.0,
                                  green: 82.0/255.0,
                                  blue: 90.0/255.0,
                                  alpha: 1.0)

//rgb(91,95,104)
let ui_active_light_gray = UIColor(red: 91.0/255.0,
                                   green: 95.0/255.0,
                                   blue: 104.0/255.0,
                                   alpha: 1.0)


//rgb(18,191,148)
let ui_active_aqua = UIColor(red: 18.0/255.0,
                             green: 191.0/255.0,
                             blue: 148.0/255.0,
                             alpha: 1.0)

let ui_active_light_aqua = UIColor(red: 165.0/255.0,
                                   green: 238.0/255.0,
                                   blue: 220.0/255.0,
                                   alpha: 1.0)

