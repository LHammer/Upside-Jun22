//
//  OpportunityLedgerModel.swift
//  Upside
//
//  Created by Luke Hammer on 5/20/22.
//


import Foundation
import FirebaseFirestoreSwift

struct OpportunityLedgerModel: Codable {
    
    @DocumentID var id: String?
    
    // OpportunityModel variables
    let accountName: String?
    let closeDate: String?
    let commerceBookings: Double? // need
    let commerceBookingsCurrency: String?
    let createdDate: String?
    let lastModifiedDate: String?
    let lastStageChangeDate: String?
    let leadSource: String?
    let opportunityCurrency: String?
    let opportunityId : String?
    let opportunityName: String?
    let opportunityOwner: String?
    let opportunityOwnerEmail: String?
    let opportunityOwnerManager: String?
    let primaryProductFamily: String? // need
    let probability: Double?
    let stage: String?
    let totalBookingsConverted: Double? // need
    let totalBookingsConvertedCurrency: String?
    let type: String?
    let age: Double?
    let closeDateTimeStamp: Double?
    let createdDateTimeStamp: Double?
    let lastModifiedDateTimeStamp: Double?
    let lastStageChangeDateTimeStamp: Double?

    // New variables used for ledger entries.
    var salesForcePreviousCallStatus: String?
    var salesForceCurrentCallStatus: String? // need to auto load
    var salesForcePreviousCallStatusIndex: Int?
    var salesForceCurrentCallStatusIndex: Int? // need to auto load
    var userPreviousCallStatus: String?
    var userCurrentCallStatus: String?
    var userPreviousCallStatusIndex: Int?
    var userCurrentCallStatusIndex: Int?
    
    var userInputTotalBookings: Double?
    
    // New variables to assist with app.
    var stageSortingIndex: Int?
    
    //(startTS: Double, endTS: Double, description: String, type: String)
    // period information
    let periodStartTimestamp: Double?
    let periodEndTimestamp: Double?
    let periodDescription: String?
    let periodType: String?
    
    let sfdcSyncTimestamp: Double?
    var upsideLedgerUploadTimestamp: Double?
    
    var callSummaryID: String?
}

