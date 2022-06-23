//
//  QuotaModel.swift
//  Upside
//
//  Created by Luke Hammer on 6/2/22.
//

import Foundation
import FirebaseFirestoreSwift
 
struct QuotaModel: Codable {
   
    @DocumentID var id: String?
    
    let amount: Double?
    let currencyCode: String?
    let endTimeStamp: Double?
    let startTimeStamp: Double?
    let fullName: String?
    let email: String?
    let periodDescription: String?
    let roleUp: String?
   
}

