//
//  SelectCallPeriodVC.swift
//  Upside
//
//  Created by Luke Hammer on 6/2/22.
//

import UIKit

protocol PassSelectedCallPeriod: AnyObject {
    func passCallPeriod(aCallPeriod: CallPeriod)
}


class SelectCallPeriodVC: UIViewController {
    
    private struct SelectCallPeriodCellDataModel {
        
        let callPeriod: CallPeriod?
        let heading: String?
        let body: String?
        
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    weak var delegate: PassSelectedCallPeriod?
    
    private var data: [SelectCallPeriodCellDataModel]? {
        didSet {
            if self.data != nil && self.tableView != nil {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupDefualtNavigationBar()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.setupDataModel()
    }
    
    private func setupDataModel() {
        
        let timezone = TimeZone(identifier: "America/Chicago")!
        
        /* ---------------------- */
        
        var periodInfo = self.getStartAndEndTimestampFor(callPeriod: .today,
                                                         timeZone: timezone)
        
        let a = SelectCallPeriodCellDataModel(callPeriod: .today,
                                              heading: periodInfo.type,
                                              body: periodInfo.periodDescription)
        
        
        /* ---------------------- */
        
        /*
        periodInfo = self.getStartAndEndTimestampFor(callPeriod: .tomorrow,
                                                         timeZone: timezone)
        
        let b = SelectCallPeriodCellDataModel(callPeriod: .tomorrow,
                                              heading: periodInfo.type,
                                              body: periodInfo.periodDescription)*/
        
        /* ---------------------- */
        
        
        periodInfo = self.getStartAndEndTimestampFor(callPeriod: .thisWeek,
                                                         timeZone: timezone)
        
        let c = SelectCallPeriodCellDataModel(callPeriod: .thisWeek,
                                              heading: periodInfo.type,
                                              body: periodInfo.periodDescription)
        
        /* ---------------------- */
        
        /*
        periodInfo = self.getStartAndEndTimestampFor(callPeriod: .nextWeek,
                                                         timeZone: timezone)
        
        let d = SelectCallPeriodCellDataModel(callPeriod: .nextWeek,
                                              heading: periodInfo.type,
                                              body: periodInfo.periodDescription)
         */
        
        /* ---------------------- */
        
        periodInfo = self.getStartAndEndTimestampFor(callPeriod: .thisMonth,
                                                         timeZone: timezone)
        
        let e = SelectCallPeriodCellDataModel(callPeriod: .thisMonth,
                                              heading: periodInfo.type,
                                              body: periodInfo.periodDescription)
        
        /* ---------------------- */
        
        /*
        periodInfo = self.getStartAndEndTimestampFor(callPeriod: .nextMonth,
                                                         timeZone: timezone)
        
        let f = SelectCallPeriodCellDataModel(callPeriod: .nextMonth,
                                              heading: periodInfo.type,
                                              body: periodInfo.periodDescription)
         */
        
        /* ---------------------- */
        
        periodInfo = self.getStartAndEndTimestampFor(callPeriod: .thisQuarter,
                                                         timeZone: timezone)
        
        let g = SelectCallPeriodCellDataModel(callPeriod: .thisQuarter,
                                              heading: periodInfo.type,
                                              body: periodInfo.periodDescription)
        
        /* ---------------------- */
        
        /*
        periodInfo = self.getStartAndEndTimestampFor(callPeriod: .nextQuarter,
                                                         timeZone: timezone)
        
        let h = SelectCallPeriodCellDataModel(callPeriod: .nextQuarter,
                                              heading: periodInfo.type,
                                              body: periodInfo.periodDescription)
         */
        
        /* ---------------------- */
        
        //data = [a, b, c, d, e, f, g, h]
        data = [a, c, e, g]
    }
}

// MARK: TableView Extension
extension SelectCallPeriodVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = Bundle.main.loadNibNamed("StandardCell", owner: self, options: nil)?.first as! StandardCell
        
        cell.heading = data![indexPath.row].heading!
        cell.content = data![indexPath.row].body!
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        self.delegate?.passCallPeriod(aCallPeriod: data![indexPath.row].callPeriod!)
        self.dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
}










// MARK: TODO could be moved to a helper method/.
// MARK: TODO move to global class / method - it's in multiple.
// time / period managment / descriptions.
extension SelectCallPeriodVC {
    
    
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



    func getStartAndEndTimestampFor(callPeriod: CallPeriod, timeZone: TimeZone) -> (startTS: Double,
                                                                                    endTS: Double,
                                                                                    periodDescription: String,
                                                                                    type: String) {
        
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
