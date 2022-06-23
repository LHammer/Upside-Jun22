//
//  StandardButton.swift
//  Upside
//
//  Created by Luke Hammer on 4/30/22.
//

import UIKit

enum ButtonColorSchemes: Int {
    case blackWhite=0,
         whiteBlack,
         blueWhite,
         whiteBlue,
         clearBlue,
         aquaWhite,
         redWhite
}

class StandardButton: UIButton {
    
    var buttonColor = UIColor.black
    var textColor = UIColor.white

    override func layoutSubviews() { // update drawing after rotation
        self.configureButton()
    }
    
    
    // rename
    public func configureButton() {
        
        // MARK: TODO currently not working. likely due to font download from GitHub
        self.titleLabel?.font = UIFont(name: "ProximaNova-Bold", size: 17.0)
        self.backgroundColor = buttonColor
        self.layer.cornerRadius = self.frame.height/2
        self.layer.borderColor = buttonColor.cgColor
        self.titleLabel?.frame = self.bounds
        self.titleLabel?.numberOfLines = 1
        self.titleLabel?.adjustsFontSizeToFitWidth = true
        self.titleLabel?.lineBreakMode = .byClipping
        self.titleLabel?.textAlignment = .center
        
        self.tintColor = textColor
        
        self.setTitleColor(textColor, for: .normal)
        self.setTitleColor(textColor, for: .disabled)
        self.setTitleColor(textColor, for: .application)
        self.setTitleColor(textColor, for: .focused)
        
        self.setTitleColor(textColor, for: .reserved)
        
        self.setTitleColor(.darkGray, for: .highlighted)
        self.setTitleColor(.darkGray, for: .selected)
        
        self.setNeedsDisplay()
    }
    
    
    
    public func setColorSchemes(scheme: ButtonColorSchemes) {
        switch scheme {
        case .clearBlue:
            
            self.buttonColor = UIColor.clear
            self.textColor = ui_active_blue
            
        case .whiteBlack:
            
            self.buttonColor = UIColor.white
            self.textColor = UIColor.black
            
        case .blueWhite:
            self.buttonColor = ui_active_blue
            self.textColor = UIColor.white
        case .aquaWhite:
            self.buttonColor = ui_active_aqua
            self.textColor = UIColor.white
        case .redWhite:
            self.buttonColor = .red
            self.textColor = UIColor.white
        default:
            self.buttonColor = UIColor.black
            self.textColor = UIColor.white
        }
        
        self.configureButton()
    }
}
