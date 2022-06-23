//
//  EditBookingsAmountVC.swift
//  Upside
//
//  Created by Luke Hammer on 5/22/22.
//

import UIKit

protocol PassAmendedOpportunityDelegate: AnyObject {
    func passOpportunity(_ opp: OpportunityLedgerModel, callCorrection: CallCorrectionModel?)
}

class EditBookingsAmountVC: UIViewController {
    
    @IBOutlet weak var changeInputTextFeild: CurrencyTextField!
    @IBOutlet weak var editMethodSegmentedControl: UISegmentedControl!
    @IBOutlet weak var primaryHolderView: UIView!
    
    @IBOutlet weak var oppNameLabel: UILabel!
    
    @IBOutlet weak var bookingsSaaSLabel: UILabel!
    @IBOutlet weak var bookingsCommerceLabel: UILabel!
    @IBOutlet weak var otherLabel: UILabel!
    @IBOutlet weak var totalSalesForceBookingsLabel: UILabel!
    
    @IBOutlet weak var userInputTotalBookingsLabel: UILabel!
    @IBOutlet weak var descriptionOfChangeLabel: UILabel!
    @IBOutlet weak var primaryProductLabel: UILabel!
    
    @IBOutlet weak var plusMinusImg: UIImageView!
    
    weak var delegate: PassAmendedOpportunityDelegate?
    
    var callPeriod: CallPeriod?
    
    var plusMinus = 1 { // 1 = positve, -1 = negative
        didSet {
            self.updateLabels()
            
            // plusMinusImg
            if plusMinus < 1 {
                
                self.plusMinusImg.image = UIImage(named: "minusVpos")
                
//                if opp?.userInputTotalBookings != nil {
//                    if opp!.userInputTotalBookings! > 0 {
//                        opp!.userInputTotalBookings! = opp!.userInputTotalBookings! * -1
//                    }
//                }
            } else {
                self.plusMinusImg.image = UIImage(named: "posVminus")
                
//                if opp?.userInputTotalBookings != nil {
//                    if opp!.userInputTotalBookings! < 0 {
//                        opp!.userInputTotalBookings! = opp!.userInputTotalBookings! * -1
//                    }
//                }
            }
        }
    }
    
    var opp: OpportunityLedgerModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupDefualtNavigationBar()
        self.primaryHolderView.layer.cornerRadius = 8.0
        self.editMethodSegmentedControl.backgroundColor = ui_active_aqua
        self.changeInputTextFeild.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.editMethodSegmentedControl.selectedSegmentIndex = 1
        self.editMethodSegmentedControl.addTarget(self, action: #selector(segmentAllEventTrigger(_:)), for: .allEvents)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "submit", style: .plain, target: self, action: #selector(submitTapped))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if opp != nil {
            self.changeInputTextFeild.currency = CurrencyModel(locale: "en_US", amount: 0.0)
            self.changeInputTextFeild.update()
            self.updateLabels()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func getProductRoleUp(oppLedger: OpportunityLedgerModel) -> String {
        
        if (oppLedger.primaryProductFamily == "ACTIVE Reserve" ||
            oppLedger.primaryProductFamily == "ACTIVEworks - Camps Plus" ||
            oppLedger.primaryProductFamily == "ACTIVEWorks Endurance" ||
            oppLedger.primaryProductFamily == "ACTIVEWorks Swim Manager" ||
            oppLedger.primaryProductFamily == "ACTIVEWorks Ticketing" ||
            oppLedger.primaryProductFamily == "JumpForward" ||
            oppLedger.primaryProductFamily == "LeagueOne" ||
            oppLedger.primaryProductFamily == "TeamPages" ||
            oppLedger.primaryProductFamily == "Virtual Event Bags (VEB)") {
            return "SaaS"
        } else if (oppLedger.primaryProductFamily == "Digital Media - Brands" ||
                   oppLedger.primaryProductFamily == "Digital Media - Orgs" ||
                   oppLedger.primaryProductFamily == "Digital Media - Pay for Performance" ||
                   oppLedger.primaryProductFamily == "Hy-Tek Endurance" ||
                   oppLedger.primaryProductFamily == "Marketing Services" ||
                   oppLedger.primaryProductFamily == "Technology Services") {
            return "Other"
        }
        return "Other"
    }
    
    private func getTotalBookingsFrom(oppLEdger: OpportunityLedgerModel) -> (SaaS: Double, commerce: Double, other: Double, total: Double) {
        
        let productRoleUp = self.getProductRoleUp(oppLedger: oppLEdger)
        
        var SaaS = 0.0
        var other = 0.0
    
        if productRoleUp.lowercased() == "saas" {
            SaaS = oppLEdger.totalBookingsConverted!
        } else {
            other = oppLEdger.totalBookingsConverted!
        }
        let commerce = oppLEdger.commerceBookings!
        let total = SaaS + other + commerce
        
        return (SaaS: SaaS,
                commerce: commerce,
                other: other,
                total: total)
    }
    
    private func updateLabels() {
        if opp != nil {
            
            self.oppNameLabel.text = self.opp!.opportunityName!
            self.primaryProductLabel.text = opp!.primaryProductFamily
            let totalBookings = self.getTotalBookingsFrom(oppLEdger: opp!)
            self.bookingsSaaSLabel.text = CurrencyModel(locale: "en_US", amount: totalBookings.SaaS).format + " SaaS"
            self.bookingsCommerceLabel.text = CurrencyModel(locale: "en_US", amount: totalBookings.commerce).format + " commerce"
            self.otherLabel.text = CurrencyModel(locale: "en_US", amount: totalBookings.other).format + " other"
            self.totalSalesForceBookingsLabel.text = CurrencyModel(locale: "en_US", amount: totalBookings.total).format
            
            let userInputBookingsAfterCorrection = self.getAmendedTotalOppValueFromUserInput()
            

            self.userInputTotalBookingsLabel.text = CurrencyModel(locale: "en_US",
                                                                  amount: userInputBookingsAfterCorrection).format
            
            // descripotion label.
            
            if userInputBookingsAfterCorrection > totalBookings.total { // user has increased bookings
                self.descriptionOfChangeLabel.text = "increase bookings by " + formatShortHandCurrency(num: userInputBookingsAfterCorrection - totalBookings.total) + " USD"
            } else if userInputBookingsAfterCorrection < totalBookings.total { // user has decreased bookings
                self.descriptionOfChangeLabel.text = "decreased bookings by " + formatShortHandCurrency(num: totalBookings.total - userInputBookingsAfterCorrection) + " USD"
            } else { // they're the same.
                self.descriptionOfChangeLabel.text = "---"
            }
        }
    }
    
    private func getAmendedTotalOppValueFromUserInput() -> Double {
        
        let totalBookings = self.getTotalBookingsFrom(oppLEdger: opp!)
        
        var userInputBookingsAfterCorrection = totalBookings.total
        
        
        if self.editMethodSegmentedControl.selectedSegmentIndex == 0 { // change TO the amount entered.
            
            if plusMinus < 0 {
                self.changeInputTextFeild.textColor = UIColor(displayP3Red: 1.0, green: 0.0, blue: 0.0, alpha: 0.6)
                userInputBookingsAfterCorrection = -changeInputTextFeild.currency!.amount
            } else {
                self.changeInputTextFeild.textColor = .black
                userInputBookingsAfterCorrection = changeInputTextFeild.currency!.amount
            }
        } else { // change BY the amount entered.
            if plusMinus < 0 {
                self.changeInputTextFeild.textColor = UIColor(displayP3Red: 1.0, green: 0.0, blue: 0.0, alpha: 0.6)
                userInputBookingsAfterCorrection = userInputBookingsAfterCorrection - changeInputTextFeild.currency!.amount
            } else {
                self.changeInputTextFeild.textColor = .black
                userInputBookingsAfterCorrection = userInputBookingsAfterCorrection + changeInputTextFeild.currency!.amount
            }
        }
        
        return userInputBookingsAfterCorrection
    }
    

    @objc
    func submitTapped() {
        
        
        //print("opp?.userInputTotalBookings =", opp?.userInputTotalBookings)
        
        
        
        
        
        if opp?.userInputTotalBookings == nil {
            self.dismiss(animated: true)
        } else {
            if opp!.userInputTotalBookings == 0.0 {
                self.dismiss(animated: true)
            } else {
                
                // MARK: TODO this is a poor bug fix that stop a positive number being
                // send back if it's in a minus status or vis versa. this is needed when
                // the plus minus button is pressed as the last action prior to submitting.
                // this is because the values change in text value changed.
//                if plusMinus < 0 && opp!.userInputTotalBookings! > 0.0 {
//                    opp!.userInputTotalBookings! = opp!.userInputTotalBookings! * -1
//                }
//                
//                if plusMinus > 0 && opp!.userInputTotalBookings! < 0.0 {
//                    opp!.userInputTotalBookings! = opp!.userInputTotalBookings! * -1
//                }
                
                print("")
                
                //getAmountFromInputTextFeild
                //self.opp!.userInputTotalBookings = self.getTotalAmountFromInputTextFeild()
                
                let originalAmount = self.getTotalBookingsFrom(oppLEdger: opp!).total
                
                // let changeAmount = (opp!.userInputTotalBookings! - opp!.commerceBookings! + opp!.totalBookingsConverted!)
                // print("changeAmount =", changeAmount)
                self.opp!.userInputTotalBookings = self.getTotalAmountFromInputTextFeild()
                // let changeAmount = self.getTotalAmountFromInputTextFeild() - originalAmount
                let changeAmount = self.opp!.userInputTotalBookings! - originalAmount
                
                var type = CallCorrectionType.openOpportunities
                if opp!.stage?.lowercased() == "closed won" {
                    type = CallCorrectionType.closedWonOpportunities
                }
                
                // MARK: TODO Need to make configurable.
                let timezone = TimeZone(identifier: "America/Chicago")!
                let callPeriod = self.getStartAndEndTimestampFor(callPeriod: self.callPeriod!,
                                                                 timeZone: timezone)
                
                let change = CallCorrectionModel(id: nil,
                                                 correctionDescription: opp!.opportunityName,
                                                 amount: changeAmount,
                                                 originalAmount: originalAmount,
                                                 type: type.rawValue,
                                                 opportunityID: opp!.opportunityId,
                                                 opportunityStage: opp!.stage,
                                                 periodStartTimestamp: callPeriod.startTS,
                                                 periodEndTimestamp: callPeriod.endTS,
                                                 periodDescription: callPeriod.periodDescription,
                                                 periodType: callPeriod.type,
                                                 sfdcSyncTimestamp: nil,
                                                 upsideLedgerUploadTimestamp: nil,
                                                 callSummaryID: nil)
                /*
                let change = CallCorrectionModel(id: nil,
                                                 correctionDescription: opp!.opportunityName,
                                                 amount: changeAmount,
                                                 originalAmount: originalAmount,
                                                 type: type.rawValue,
                                                 opportunityID: opp!.opportunityId)
                 */
                
                
                print("8888888888888888888888888888")
                print(change)
                // print("changeAmount =", changeAmount)
                
                
                self.dismiss(animated: true) {
                    self.delegate!.passOpportunity(self.opp!,
                                                   callCorrection: change)
                }
                // self.dismiss(animated: true)
            }
        }
    }
    
    private func getTotalAmountFromInputTextFeild() -> Double {
        
        if self.editMethodSegmentedControl.selectedSegmentIndex == 0 {
            return changeInputTextFeild.currency!.amount * Double(plusMinus)
        } else {
            
            let totalBookings = self.getTotalBookingsFrom(oppLEdger: opp!)
            
            return totalBookings.total + ((Double(plusMinus) * changeInputTextFeild.currency!.amount))
            
            
            //return changeInputTextFeild.currency!.amount * Double(plusMinus)
        }
        
    }
    
    
    @objc
    func segmentAllEventTrigger(_ segmentedControl: UISegmentedControl) {
        self.updateLabels()
    }

    @objc
    func textFieldDidChange(_ textField: CurrencyTextField) {
        
        // MARK: TODO easy stuff let's have a shower first.
        // change this to the logic above.
        
        /*
        if self.editMethodSegmentedControl.selectedSegmentIndex == 1 { // change by amount
            let totalBookings = self.getTotalBookingsFrom(oppLEdger: opp!)
            self.opp!.userInputTotalBookings = totalBookings.total + ((Double(plusMinus) * textField.currency!.amount))
        } else { // change to amount
            self.opp!.userInputTotalBookings = (Double(plusMinus) * textField.currency!.amount)
        }*/
        
        self.opp!.userInputTotalBookings = self.getTotalAmountFromInputTextFeild()
        
        
        
        self.updateLabels()
    }
    
    @IBAction func plusMinusButtonPressed(_ sender: Any) {
        plusMinus = plusMinus * -1
        self.changeInputTextFeild.becomeFirstResponder()
    }
}

// MARK: TODO repeat of code. Move to global area.
extension EditBookingsAmountVC {
    
    
    
    func getStartOfDay(date: Date, timeZone: TimeZone) -> Double {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        return cal.startOfDay(for: date).timeIntervalSince1970
    }

    func getEndOfDay(date: Date, timeZone: TimeZone) -> Double {
        var cal = Calendar.current
        cal.timeZone = timeZone
        let endTime = cal.date(bySettingHour: 23, minute: 59, second: 59, of: date)!
        return endTime.timeIntervalSince1970
    }

    func getStartOfTomorrow(date: Date, timeZone: TimeZone) -> CGFloat {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let todayStart = Date(timeIntervalSince1970: getStartOfDay(date: date, timeZone: timeZone))
        var components = DateComponents()
        components.day = 1
        let endOfMonth = cal.date(byAdding: components,
                                  to: todayStart,
                                  wrappingComponents: false)
        return endOfMonth!.timeIntervalSince1970
    }

    func getEndOfTomorrow(date: Date, timeZone: TimeZone) -> CGFloat {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let todayEnd = Date(timeIntervalSince1970: getEndOfDay(date: date, timeZone: timeZone))
        var components = DateComponents()
        components.day = 1
        let endOfMonth = cal.date(byAdding: components,
                                  to: todayEnd,
                                  wrappingComponents: false)
        return endOfMonth!.timeIntervalSince1970
    }

    // week
    func getStartOfCurrentWeek(date: Date, timeZone: TimeZone) -> CGFloat {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let weekDay = cal.dateComponents([.weekday], from: date).weekday!
        var components = DateComponents()
        components.day = -(weekDay-2)
        let startOfToday = Date(timeIntervalSince1970: getStartOfDay(date: date, timeZone: timeZone))
        let startOfWeek = cal.date(byAdding: components,
                                        to: startOfToday,
                                        wrappingComponents: false)
        return startOfWeek!.timeIntervalSince1970
    }

    func getEndOfCurrentWeek(date: Date, timeZone: TimeZone) -> CGFloat {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let startOfWeek = Date(timeIntervalSince1970: getStartOfCurrentWeek(date: date, timeZone: timeZone))
        var components = DateComponents()
        components.day = 7
        components.second = -1
        let endOfWeek = cal.date(byAdding: components,
                                        to: startOfWeek,
                                        wrappingComponents: false)
        
        return endOfWeek!.timeIntervalSince1970
    }

    func getStartOfNextWeek(date: Date, timeZone: TimeZone) -> CGFloat {
        let startOfCurrentWeek = Date(timeIntervalSince1970: getStartOfCurrentWeek(date: date, timeZone: timeZone))
        var components = DateComponents()
        components.day = 7
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let startOfNextWeek = cal.date(byAdding: components,
                                                to: startOfCurrentWeek,
                                            wrappingComponents: false)
        
        return startOfNextWeek!.timeIntervalSince1970
    }

    func getEndOfNextWeek(date: Date, timeZone: TimeZone) -> CGFloat {
        let startOfNextWeek = Date(timeIntervalSince1970: getStartOfNextWeek(date: date, timeZone: timeZone))
        var components = DateComponents()
        components.day = 7
        components.second = -1
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let endOfNextWeek = cal.date(byAdding: components,
                                            to: startOfNextWeek,
                                            wrappingComponents: false)
        
        return endOfNextWeek!.timeIntervalSince1970
    }

    func getStartOfMonth(date: Date, timeZone: TimeZone) -> CGFloat {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let month = cal.component(.month, from: date)
        let year = cal.component(.year, from: date)
        var components = DateComponents()
        components.second = 0
        components.hour = 0
        components.day = 1
        components.month = month
        components.year = year
        let startDate = cal.date(from: components)
        return startDate!.timeIntervalSince1970
    }

    func getEndOfMonth(date: Date, timeZone: TimeZone) -> CGFloat {
        let startDate = Date(timeIntervalSince1970: getStartOfMonth(date: date, timeZone: timeZone))
        var components = DateComponents()
        components.month = 1
        components.second = -1
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let endOfMonth = cal.date(byAdding: components,
                                  to: startDate,
                                  wrappingComponents: false)
        
        return endOfMonth!.timeIntervalSince1970
    }




    func getStartOfNextMonth(date: Date, timeZone: TimeZone) -> CGFloat {
        let startOfMonth = Date(timeIntervalSince1970: getStartOfMonth(date: date, timeZone: timeZone))
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        var components = DateComponents()
        components.month = 1
        
        let startOfNextMonth = cal.date(byAdding: components,
                                        to: startOfMonth,
                                        wrappingComponents: false)
        return startOfNextMonth!.timeIntervalSince1970
    }


    func getEndOfNextMonth(date: Date, timeZone: TimeZone) -> CGFloat {
        let startOfNextMonth = Date(timeIntervalSince1970: getStartOfNextMonth(date: date, timeZone: timeZone))
        let endOfNextMonth = getEndOfMonth(date: startOfNextMonth, timeZone: timeZone)
        return endOfNextMonth
    }

    func  getStartOfNextQuarter(date: Date,
                                timeZone: TimeZone) -> CGFloat {
        let startOfQuarter = Date(timeIntervalSince1970: getStartOfQuarter(date: date,
                                                                           timeZone: timeZone))
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        
        var components = DateComponents()
        components.month = 3
        let startOfNextQuarter = cal.date(byAdding: components, to: startOfQuarter)
        return startOfNextQuarter!.timeIntervalSince1970
    }

    func  getEndOfNextQuarter(date: Date,
                                timeZone: TimeZone) -> CGFloat {
        let startOfNextQuarter = Date(timeIntervalSince1970: getStartOfNextQuarter(date: date, timeZone: timeZone))
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        var components = DateComponents()
        components.month = 3
        components.second = -1
        let endOfNextQuarter = cal.date(byAdding: components, to: startOfNextQuarter)
        return endOfNextQuarter!.timeIntervalSince1970
    }



    func getStartOfQuarter(date: Date,
                           timeZone: TimeZone) -> CGFloat {
        
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let month = cal.component(.month, from: date)
        let quarter = getQuarterFrom(month: month)
        let year = cal.component(.year, from: date)
        var components = DateComponents()
        components.second = 0
        components.hour = 0
        components.day = 1
        components.month = getStartMonthFrom(quarter: quarter!)
        components.year = year
        let startDate = cal.date(from: components)
        return startDate!.timeIntervalSince1970
    }

    func getEndOfQuarter(date: Date, timeZone: TimeZone) -> CGFloat {
        let startDate = Date(timeIntervalSince1970: getStartOfQuarter(date: date, timeZone: timeZone))
        
        var components = DateComponents()
        components.month = 3
        components.second = -1
        
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let endOfQuarter = cal.date(byAdding: components,
                                  to: startDate,
                                  wrappingComponents: false)
        
        return endOfQuarter!.timeIntervalSince1970
    }

    func getStartOfYear(date: Date, timeZone: TimeZone) -> CGFloat {
        
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone

        let year = cal.component(.year, from: date)
        
        var components = DateComponents()
        components.second = 0
        components.hour = 0
        components.day = 1
        components.month = 1
        components.year = year
        
        let startDate = cal.date(from: components)
        return startDate!.timeIntervalSince1970
    }

    func getEndOfYear(date: Date, timeZone: TimeZone) -> CGFloat {
        
        let startDate = Date(timeIntervalSince1970: getStartOfYear(date: date, timeZone: timeZone))
        

        var components = DateComponents()
        components.second = -1
        components.year = 1
        
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let endOfYear = cal.date(byAdding: components,
                                  to: startDate,
                                  wrappingComponents: false)
        
        return endOfYear!.timeIntervalSince1970
    }

    func getQuarterFrom(timeZone: TimeZone, date: Date) -> Int {
        let month = getMonth(timeZone: timeZone, date: date)
        return getQuarterFrom(month: month)!
    }

    func getStartMonthFrom(quarter: Int) -> Int? {
        if quarter == 1 {
            return 1
        } else if quarter == 2 {
            return 4
        } else if quarter == 3 {
            return 7
        } else if quarter == 4 {
            return 10
        } else {
            return nil
        }
    }

    func getQuarterFrom(month: Int) -> Int? {
        if month <= 3 {
            return 1
        } else if month <= 6 {
            return 2
        } else if month <= 9 {
            return 3
        } else if month <= 12 {
            return 4
        } else {
            return nil
        }
    }


    func getYear(timeZone: TimeZone, date: Date) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year], from: date)
        return components.year!
    }

    func getMonth(timeZone: TimeZone, date: Date) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let calendar = Calendar(identifier: .gregorian)
        
        let components = calendar.dateComponents([.month], from: date)
        return components.month!
    }

    func getQuarterDescription(timeZone: TimeZone, date: Date) -> String {
        let quarter = getQuarterFrom(timeZone: timeZone, date: date)
        let year = getYear(timeZone: timeZone, date: date)
        return String(year) + " Q" + String(quarter)
    }

    func getNextQuarterDescription(timeZone: TimeZone, date: Date) -> String {
        
        // MARK: Neeed to confirm this doesn't F up the logic.
        var components = DateComponents()
        components.month = 3
        
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let threeMonthsForNow = cal.date(byAdding: components,
                                         to: date,
                                         wrappingComponents: false)
        
        let quarter = getQuarterFrom(timeZone: timeZone, date: threeMonthsForNow!)
        let year = getYear(timeZone: timeZone, date: threeMonthsForNow!)
        return String(year) + " Q" + String(quarter)
        
    }

    func getMonthDescriptionFrom(timeZone: TimeZone, date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timeZone
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "YYYY MMM"
        return dateFormatter.string(from: date)
    }

    func getNextMonthDescriptionFrom(timeZone: TimeZone, date: Date) -> String {
        
        var components = DateComponents()
        components.month = 1
        
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let nextMonth = cal.date(byAdding: components,
                                 to: date,
                                 wrappingComponents: false)
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timeZone
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "YYYY MMM"
        return dateFormatter.string(from: nextMonth!)
    }

    func getWeekDescriptionFrom(timeZone: TimeZone, date: Date) -> String {
        
        let startOfWeek = getStartOfCurrentWeek(date: date, timeZone: timeZone)
        let startDate = Date(timeIntervalSince1970: startOfWeek)
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timeZone
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "d MMM yyyy"
        return "Week " + dateFormatter.string(from: startDate)
        
        
    }

    func getNextWeekDescriptionFrom(timeZone: TimeZone, date: Date) -> String {
        
        let startOfWeek = getStartOfNextWeek(date: date, timeZone: timeZone)
        let startDate = Date(timeIntervalSince1970: startOfWeek)
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timeZone
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "d MMM yyyy"
        return "Week " + dateFormatter.string(from: startDate)
    }


    func getDayDescriptionFrom(timeZone: TimeZone, date: Date) -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timeZone
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "d MMM yyyy"
        return dateFormatter.string(from: date)
    }

    func getTomorrowDayDescriptionFrom(timeZone: TimeZone, date: Date) -> String {
        
       
        var components = DateComponents()
        components.day = 1
        
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let tomorrow = cal.date(byAdding: components,
                                 to: date,
                                 wrappingComponents: false)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timeZone
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "d MMM yyyy"
        return dateFormatter.string(from: tomorrow)
    }



    func getStartAndEndTimestampFor(callPeriod: CallPeriod, timeZone: TimeZone) -> (startTS: Double, endTS: Double, periodDescription: String, type: String) {
        
        switch callPeriod {
        case .customPeriod:
            print("Error: cannot get end and start time stamps from: ", callPeriod)
        case .today:
            let start = getStartOfDay(date: Date(), timeZone: timeZone)
            let end = getEndOfDay(date: Date(), timeZone: timeZone)
            let descr = getDayDescriptionFrom(timeZone: timeZone, date: Date())
            return (startTS: start, endTS: end, periodDescription: descr, type: callPeriod.rawValue)
            
        case .tomorrow:
            let start = getStartOfTomorrow(date: Date(), timeZone: timeZone)
            let end = getEndOfTomorrow(date: Date(), timeZone: timeZone)
            let descr = getTomorrowDayDescriptionFrom(timeZone: timeZone, date: Date())
            return (startTS: start, endTS: end, periodDescription: descr, type: callPeriod.rawValue)
        case .thisWeek:
            let start = getStartOfCurrentWeek(date: Date(), timeZone: timeZone)
            let end = getEndOfCurrentWeek(date: Date(), timeZone: timeZone)
            let descr = getWeekDescriptionFrom(timeZone: timeZone, date: Date())
            return (startTS: start, endTS: end, periodDescription: descr, type: callPeriod.rawValue)
        case .nextWeek:
            let start = getStartOfNextWeek(date: Date(), timeZone: timeZone)
            let end = getEndOfNextWeek(date: Date(), timeZone: timeZone)
            let descr = getNextWeekDescriptionFrom(timeZone: timeZone, date: Date())
            return (startTS: start, endTS: end, periodDescription: descr, type: callPeriod.rawValue)
        case .thisMonth:
            let start = getStartOfMonth(date: Date(), timeZone: timeZone)
            let end = getEndOfMonth(date: Date(), timeZone: timeZone)
            let descr = getMonthDescriptionFrom(timeZone: timeZone, date: Date())
            return (startTS: start, endTS: end, periodDescription: descr, type: callPeriod.rawValue)
        case .nextMonth:
            let start = getStartOfNextMonth(date: Date(), timeZone: timeZone)
            let end = getEndOfNextMonth(date: Date(), timeZone: timeZone)
            let descr = getNextMonthDescriptionFrom(timeZone: timeZone, date: Date())
            return (startTS: start, endTS: end, periodDescription: descr, type: callPeriod.rawValue)
        case .thisQuarter:
            let start = getStartOfQuarter(date: Date(), timeZone: timeZone)
            let end = getEndOfQuarter(date: Date(), timeZone: timeZone)
            let descr = getQuarterDescription(timeZone: timeZone, date: Date())
            return (startTS: start, endTS: end, periodDescription: descr, type: callPeriod.rawValue)
        case .nextQuarter:
            let start = getStartOfNextQuarter(date: Date(), timeZone: timeZone)
            let end = getEndOfNextQuarter(date: Date(), timeZone: timeZone)
            let descr = getNextQuarterDescription(timeZone: timeZone, date: Date())
            return (startTS: start, endTS: end, periodDescription: descr, type: callPeriod.rawValue)
        }
        
        return (startTS: 0.0, endTS: 0.0, periodDescription: "n/a", type: "n/a")
    }
    
    
}
