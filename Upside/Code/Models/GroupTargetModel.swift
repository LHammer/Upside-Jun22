//
//  GroupTargetModel.swift
//  Upside
//
//  Created by Hammer, Luke on 6/16/22.
//

import Foundation
import FirebaseFirestoreSwift

struct GroupTargetModel: Codable {
    
    @DocumentID var id: String?
    
    let amount: Double?
    let currencyCode: String?
    let endTimeStamp: Double?
    let periodDescription: String?
    let startTimeStamp: Double?
    let team: String?
    let teamUid: String?
    
}
