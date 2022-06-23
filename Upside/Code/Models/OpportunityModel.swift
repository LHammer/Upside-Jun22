//
//  OpportunityModel.swift
//  Upside
//
//  Created by Luke Hammer on 5/19/22.
//

import Foundation
import FirebaseFirestoreSwift

struct OpportunityModel: Codable {
    
    @DocumentID var id: String?
    
    // variables straight from sales force
    let accountName: String?
    let closeDate: String?
    let commerceBookings: Double?
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
    let primaryProductFamily: String?
    let probability: Double?
    let stage: String?
    let totalBookingsConverted: Double?
    let totalBookingsConvertedCurrency: String?
    let type: String?
    let age: Double?
    
    // custom variables, created during 'Upside Admin'
    let closeDateTimeStamp: Double?
    let createdDateTimeStamp: Double?
    let lastModifiedDateTimeStamp: Double?
    let lastStageChangeDateTimeStamp: Double?

    // MARK: Adding varibles post 'Upside Admin'
    // used for ledger entries.
//    var salesForcePreviousCallStatus: String?
//    var salesForceCurrentCallStatus: String?
//    var salesForcePreviousCallStatusIndex: Int?
//    var salesForceCurrentCallStatusIndex: Int?
//    var userPreviousCallStatus: String?
//    var userCurrentCallStatus: String?
//    var userPreviousCallStatusIndex: Int?
//    var userCurrentCallStatusIndex: Int?
}
