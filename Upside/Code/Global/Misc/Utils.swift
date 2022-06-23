//
//  Utils.swift
//  Upside
//
//  Created by Luke Hammer on 5/1/22.
//

import Foundation


let global_active_hq_time_zone = TimeZone(identifier: "America/Chicago")!

// MARK: TODO Move to global / individual extension folder.
extension Double {
    /// Rounds the double to decimal places value
    func roundToPlaces(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor //round(self * divisor) / divisor
    }
}

// MARK: Rename or maybe put in CurrencyModel??
// MARK: TODO made some drunk adhoc changes
func formatShortHandCurrency(num: Double) -> String{
    
    var plusMinus = 1.0 as Double
    if num < 0.0 {
        plusMinus = -1
    }
    let absNum = abs(num)
    
    
    let thousandNum = absNum/1000
    let millionNum = absNum/1000000
    
    // print("number =", num)
    
    if absNum >= 999999.999999{ // technically not true, but fixed(ish) the double rounding error
        //if(floor(millionNum) == millionNum){
        //    return("\(Int(thousandNum))k")
        //}
        return ("\(millionNum.roundToPlaces(places: 1)*plusMinus)M")
    }
    
    if absNum >= 1000 && absNum < 1000000{
        if(floor(thousandNum) == thousandNum){
            return("\(Int(thousandNum*plusMinus))k")
        }
        return("\(thousandNum.roundToPlaces(places: 1)*plusMinus)k")
    }
    
    
    else{
        if(floor(absNum) == absNum){
            return ("\(Int(absNum*plusMinus))")
        }
        
        let formatted = String(format: "%.2f", absNum*plusMinus)
        return formatted
        //return ("\(num)")
    }

}



func isValidEmail(_ email: String) -> Bool {
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailPred.evaluate(with: email)
}
