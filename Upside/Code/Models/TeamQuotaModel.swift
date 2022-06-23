//
//  TeamQuotaModel.swift
//  Upside
//
//  Created by Hammer, Luke on 6/22/22.
//

import Foundation
import FirebaseFirestoreSwift

struct TeamQuotaModel: Codable {
    
    @DocumentID var id: String?

    let amount: Double?
    let currencyCode: String?
    let endTimeStamp: Double?
    let periodDescription: String?
    let startTimeStamp: Double?
    let teamName: String?
    let teamOwnerEmail: String?
    let teamOwnerUid: String?
    let teamRoleUpName: String?
    let teamRoleUpUid: String?
    let teamUid: String?

}
