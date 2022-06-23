//
//  TeamCallSummaryHistoryModel.swift
//  Upside
//
//  Created by Hammer, Luke on 6/20/22.
//


import Foundation
import FirebaseFirestoreSwift

struct TeamCallSummaryHistoryModel: Codable {
    
    @DocumentID var id: String?
    
    /* CORE DATA */
//    let heading: String
    
//    let correctedCall: Double
//    let correctedForecast: Double
//    let correctedClosedWonTotal: Double
//    let correctionOfCloseWonTotal: Double
    
    /* DATA DELTAs */
//    let callTotalDelta: Double?
//    let callForecastDelta: Double?
//    let closedWonDelta: Double?
    
    /* OTHER DATA */
//    let uploadTime: Double
//
//    let correctedYetToClose: Double
    let quota: Double
//    let high: Double
//    let low: Double
    
    let cumulativeBoookings: StandardChartModel?
    let quotaData: StandardChartModel?
//    let callOverTime: StandardChartModel?
//    let upsideOverTime: StandardChartModel?
//    let callProjection: StandardChartModel?
//    let upsideProjection: StandardChartModel?
    
    /* Label Data */
    let chartHeading: String?
    let chartBottomLabelsText: [String]?
    let chartLeftLabelText: [String]?
    let chartRightLabelText: [String]?
    
    
    let gridHorizontalCount: Int
    let gridVerticalCount: Int
}



