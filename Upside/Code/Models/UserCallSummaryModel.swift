//
//  UserCallSummaryModel.swift
//  Upside
//
//  Created by Luke Hammer on 5/19/22.
//

import Foundation
import FirebaseFirestoreSwift

struct UserCallSummaryModel: Codable {
    
    @DocumentID var id: String?
    
    let userID: String!
    let userEmail: String!
    
    let sfdcSyncTimestamp: Double!
    let ledgerIDs: [String]!
    
    let closedWonTotalAmount: Double?
    let closedWonTotalCount: Int?
    let closedWonSaaSAmount: Double?
    let closedWonSaaSCount: Int?
    let closedWonComrcAmount: Double?
    let closedWonComrcCount: Int?
    let closedWonOtherAmount: Double?
    let closedWonOtherCount: Int?
    
    let callTotalAmount: Double?
    let callTotalCount: Int?
    let callSaaSAmount: Double?
    let callSaaSCount: Int?
    let callComrcAmount: Double?
    let callComrcCount: Int?
    let callOtherAmount: Double?
    let callOtherCount: Int?
    
    let upsideTotalAmount: Double?
    let upsideTotalCount: Int?
    let upsideSaaSAmount: Double?
    let upsideSaaSCount: Int?
    let upsideComrcAmount: Double?
    let upsideComrcCount: Int?
    let upsideOtherAmount: Double?
    let upsideOtherCount: Int?

    let stretchTotalAmount: Double?
    let stretchTotalCount: Int?
    let stretchSaaSAmount: Double?
    let stretchSaaSCount: Int?
    let stretchComrcAmount: Double?
    let stretchComrcCount: Int?
    let stretchOtherAmount: Double?
    let stretchOtherCount: Int?
    
    let omitTotalAmount: Double?
    let omitTotalCount: Int?
    let omitSaaSAmount: Double?
    let omitSaaSCount: Int?
    let omitComrcAmount: Double?
    let omitComrcCount: Int?
    let omitOtherAmount: Double?
    let omitOtherCount: Int?
    
    let closedLostTotalAmount: Double?
    let closedLostTotalCount: Int?
    let closedLostSaaSAmount: Double?
    let closedLostSaaSCount: Int?
    let closedLostComrcAmount: Double?
    let closedLostComrcCount: Int?
    let closedLostOtherAmount: Double?
    let closedLostOtherCount: Int?
    
    // time left.
    let businessDaysLeft: Double?
    let nonBusinessDaysLeft: Double?
    let totalDaysLeft: Double?

    
    // pipe build metrics (current focus past 60 days)
    let pipeBuildPast60Days: Double?
    let pipeBuildCountPast60Days: Int?
    let pipeBuildAveDealSizePast60Days: Double?
    let pipeBuildMediumPast60Days: Double?
    
    // MARK: change variable names to show that it's DAILY
    let averageAmountPerBusinessDay60Days: Double?
    let averageCountPerBusinessDay60Days: Double?
    
    // deal velovity metrics (currently focused on max last closed deals - incl won & lost)
    let past30MeanDealVelocityBizDays: Double?
    let past30MedianDealVelocityBizDays: Double?
    
    // deal close / won ration
    let closeRateByamount: Double?
    let closeRateByCount: Double?
    
    // deals by velocity calcs
    // rename - upside just means which opps have been pipeed yet.
    var upsideNewOppForecastAmount: Double?
    var userForecastConfidenceInVelocity: Double?
    var userVelocityForecast: Double?
    
    // time period data.
    let periodStartTimestamp: Double?
    let periodEndTimestamp: Double?
    let periodDescription: String?
    let periodType: String?

    var upsideSummaryUploadTimestamp: Double?
    var callCorrectionIDs: [String]?
    
    // quota data:
    let quota: Double?
    let quotaToDate: Double?
    let quotaAttainment: Double?
    let quotaToDateAttainment: Double?
    
    // MARK: TODO need to make totals more clear. do i store 'totalWithoutCorrections' and with corrections??
    // Totals
    let total: Double?
    let totalRemaining: Double?
    let totalCorrections: Double?
    let totalWonCorrections: Double?
    

    // let's add some previous summary data
    let pastSummaryID: String?
    let pastSummaryTotal: Double?
    let pastSummaryTotalRemaining: Double?
    let pastSummaryTotalCorrections: Double?
    let pastSummaryCallCorrectionIDs: [String]?
    
    let pastCloseWonTotal: Double?
    let pastCloseWonCorrection: Double?
    let pastUpsideUploadTime: Double?
    let pastUserVelocityConfidence: Double?
}
