//
//  CallCorrectionModel.swift
//  Upside
//
//  Created by Luke Hammer on 5/26/22.
//

import Foundation
import FirebaseFirestoreSwift

struct CallCorrectionModel: Codable {
    
    @DocumentID var id: String?
 
    let correctionDescription: String?
    let amount: Double?
    let originalAmount: Double?
    let type: String?
    let opportunityID: String?
    let opportunityStage: String?
    
    
    let periodStartTimestamp: Double?
    let periodEndTimestamp: Double?
    let periodDescription: String?
    let periodType: String?
    
    let sfdcSyncTimestamp: Double?
    var upsideLedgerUploadTimestamp: Double?
    var callSummaryID: String?
}

