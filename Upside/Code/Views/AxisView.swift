//
//  AxisView.swift
//  Upside
//
//  Created by Luke Hammer on 6/10/22.
//
/*
enum CallCorrectionType : String {
    
     case closedWonOpportunities = "Closed Won",
          openOpportunities = "Open",
          overrideCall = "Set Call Total"*/

import UIKit

class AxisView: UIView {
    
    private enum Side : Int {
        case top=0,
        right,
        bottom,
        left
    }
    
    
    
    public func addLabels(strs: [String]?) {

        // remove all labels
        if strs != nil {
            for label in self.subviews { // currently only labels added.
                label.removeFromSuperview()
            }
        }

        if strs != nil {
            
            let side = self.getSideOfAxis()
            
            let labelCount = strs!.count
            var labelFrames = [CGRect]()
            for i in 0...labelCount - 1 {
                if let labelFrame = self.getLabelFrameFor(index: i,
                                                          count: labelCount - 1) {
                    labelFrames.append(labelFrame)
                }
                
            }
            
            for (i, aFrame) in labelFrames.enumerated() {
                let label = UILabel(frame: aFrame)
                
                
                if side == .left {
                    label.textAlignment = .right
                } else if side == .right {
                    label.textAlignment = .left
                } else {
                    label.textAlignment = .center
                }
                
                
//                label.layer.borderColor = UIColor.red.cgColor
//                label.layer.borderWidth = 1.0
                
                label.text = strs![i]
                label.textColor = .lightGray
                label.font = label.font.withSize(15)
                addSubview(label)
            }
        }
    }
    
    
    // this doesn't need to work for 'all' scenario's, just real world.
    // i.e we need to know what axis is on the bottom or right etc based on origin (x, y)
    // respective to size (maybe)
    // this is based o current xib setup - if i edit there, will need to change the hard coding.
    private func getSideOfAxis() -> Side {
        let x = frame.origin.x
        let y = frame.origin.y
        if y == 0.0 { // it must be top, right, or left
            if x == 0.0 { // it must be left or top
                if frame.size.width > frame.size.height { // assumtion is, this is top
                    return .top
                } else { // assumtion is, this is left
                    return .left
                }
            } else { // it must be right
                return .right
            }
        } else { // it must be bottom
            return .bottom
        }
    }
    
    // MARK: Just for bottom right now, will add others soon.
    private func getLabelFrameFor(index: Int, count: Int) -> CGRect? {
        
        if count < 1 {
            return nil
        }
        
        
        let side = self.getSideOfAxis()
        let standardWidthHeight = 50.0
        let edgeBuffer = 5.0
        
        switch side {
        case .right:
            
            let labelHeight = 20.0
            let centerRange = self.frame.size.height - (standardWidthHeight*2)
            let incrementHeightAmount = centerRange / Double( (count) )
            
            
            let x = edgeBuffer
            let y = ((incrementHeightAmount * Double(index))) + (labelHeight/2.0) + standardWidthHeight
            
            let correctedOrigin = self.normalizePoint(pt: CGPoint(x: x, y: y))
            
            
            
            let width = self.frame.size.width
            let height = 20.0 // self.frame.size.height
            
            return CGRect(x: correctedOrigin.x, y: correctedOrigin.y, width: width, height: height)
            
        case .bottom:
            
            let labelWidth = 200.0
            let centerRange = self.frame.size.width - (standardWidthHeight*2)
            let incrementWidthAmount = centerRange / Double( (count) )
            
            
            let x = ((incrementWidthAmount * Double(index))) - (labelWidth / 2.0) + standardWidthHeight  // this works only when labels are CENTERED.
            let y = edgeBuffer
            let width = labelWidth
            let height = 20.0 // self.frame.size.height
            
            return CGRect(x: x, y: y, width: width, height: height)
            
        case .left:

            let labelHeight = 20.0
            let centerRange = self.frame.size.height - (standardWidthHeight*2)
            let incrementHeightAmount = centerRange / Double( (count) )
            
            
            let x = -edgeBuffer
            let y = ((incrementHeightAmount * Double(index))) + (labelHeight/2.0) + standardWidthHeight
            
            let correctedOrigin = self.normalizePoint(pt: CGPoint(x: x, y: y))
            
            
            
            let width = self.frame.size.width
            let height = 20.0 // self.frame.size.height
            
            return CGRect(x: correctedOrigin.x, y: correctedOrigin.y, width: width, height: height)
            
        case .top:
            print("")
        }
        
        
        return CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0)
        
        
        
    }
    
    private func normalizePoint(pt: CGPoint) -> CGPoint {
        
        return CGPoint(x: pt.x,
                       y: self.bounds.size.height - pt.y)
        
    }

}

// the above doesn't have it's own xib but it is loaded from the parent view xib
// MARK: views with xib.
/*
required init() {
    super.init(frame: .zero)
    setupView()
}

required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
}

func setupView() {
    // Can do the setup of the view, including adding subviews

    setupConstraints()
}
 
 func setupConstraints() {
     // setup custom constraints as you wish
 }
 
 */
