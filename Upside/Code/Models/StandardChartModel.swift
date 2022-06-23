//
//  StandardChartModel.swift
//  Upside
//
//  Created by Luke Hammer on 6/7/22.
//

import Foundation
import UIKit


struct DoubleRange: Codable {
    let max: Double
    let min: Double
}

struct StandardChartModel: Codable {
    
    let verticalRange: DoubleRange
    let horizontalRange: DoubleRange
    
    // prob need to remove these two.
    let verticalLabels: [String]
    let horizontalLabels: [String]
    
    
    let chartData: [String: [Double : Double]]
    
    let lineWidth: Double
    let lineRed: Double
    let lineGreen: Double
    let lineBlue: Double
    let lineAlpha: Double
}


