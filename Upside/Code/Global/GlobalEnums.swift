//
//  GlobalEnums.swift
//  Upside
//
//  Created by Luke Hammer on 5/28/22.
//

import Foundation

enum CallCorrectionType : String {
    
     case closedWonOpportunities = "Closed Won",
          openOpportunities = "Open",
          overrideCall = "Set Call Total"
     
    static let allValues = [closedWonOpportunities,
                            openOpportunities,
                            overrideCall]
}

enum CallPeriod: String {
    case customPeriod="Custom",
    today="Today",
    tomorrow="Tomorrow",
    thisWeek="This Week",
    nextWeek="Next Week",
    thisMonth="This Month",
    nextMonth="Next Month",
    thisQuarter="This Quarter",
    nextQuarter="Next Quarter"
}

