//
//  UserCallSummaryVC.swift
//  Upside
//
//  Created by Luke Hammer on 6/1/22.
//

// MARK: TODO move to global.
// poor performance, only use for small arrays.
// https://stackoverflow.com/questions/25738817/removing-duplicate-elements-from-an-array-in-swift/48210756#48210756
extension Array where Element: Equatable {
    func removingDuplicates() -> Array {
        return reduce(into: []) { result, element in
            if !result.contains(element) {
                result.append(element)
            }
        }
    }
}

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestoreSwift
import SwiftUI

class UserCallSummaryVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var syncTimeLabel: UILabel!
    

    private var db = Firestore.firestore()
    
    // 1) user logs
    private var opportunityUploadLogs: [OpportunityUploadLogModel]? {
        didSet {
            
            if opportunityUploadLogs != nil && opportunityUploadLogs!.count > 0 {
                // have logs meta data, now pull past summeries followed by quotas.
                
                self.fetchCurrentUserData()
                
                // MARK: TODO move to own method.
                let log = opportunityUploadLogs![0]
                let date = Date(timeIntervalSince1970: log.uploadTimestamp!)
                let dateFormatter = DateFormatter()
                dateFormatter.timeZone = TimeZone.current // TimeZone(abbreviation: "GMT") //Set timezone that you want
                dateFormatter.locale = NSLocale.current
                // dateFormatter.dateFormat = "yyyy-MM-dd HH:mm" //Specify your format that you want
                dateFormatter.dateFormat = "MMM d, h:mm a" // "MMM-dd HH:mm" //Specify your format that you want
                let strDate = dateFormatter.string(from: date)
                
                self.syncTimeLabel.text = "sfdc sync:  " + strDate + ""
            }
        }
    }
    
    // two needs to be user data.
    //fullName
    private var currentUser: FirebaseUserModel? {
        didSet {
            if currentUser != nil {
                self.fetchAllUserSummeries()
            }
        }
    }
    
    
    
    // 2) summaries
    var userSummaries: [UserCallSummaryModel]? {
        didSet {
            if userSummaries != nil {
                self.groupedUserSummeries = self.groupCallsByCallPeriod(userCallSummaries: self.userSummaries!)
            }
        }
    }
    
    // 2)....
    var groupedUserSummeries: [[UserCallSummaryModel]]? {
        didSet {
            if groupedUserSummeries != nil {
                
                self.fetchRelevantClosedWonOpportunities()
                // self.callHistory = self.getGroupedSummaryHistory(groupedSummaries: groupedUserSummeries!)
            }
        }
    }
    
    // 2)....
    var callHistory: [UserCallSummaryHistoryModel]? {
        didSet {
            if callHistory != nil {
                // self.fetchRelevantClosedWonOpportunities()
            }
        }
    }
    
    
    // 3) closed won opps
    var closedWonOpps: [OpportunityModel]? {
        didSet {
            if closedWonOpps != nil {
                // print("closedWonOpps:")
                // print(closedWonOpps)
                self.fetchCurrentClosedWonCorrections()
                //self.tableView.reloadData()
            }
        }
    }
    
    // 4) close won corrections
    var closeWonCorrections: [CallCorrectionModel]? {
        didSet {
            if closeWonCorrections != nil {
                
                self.callHistory = self.getGroupedSummaryHistory(groupedSummaries: groupedUserSummeries!)
                
                self.tableView.reloadData()
                // print("closeWonCorrections:")
                // print(closeWonCorrections)
            }
        }
    }
    
    
    
    
    
    
    
 
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.setupDefualtNavigationBar()
        tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(title: " add ", style: .plain, target: self, action: #selector(addCallTapped))
        
    }
    
    public func removeData() {
        self.userSummaries = nil
        self.groupedUserSummeries = nil
        
        if self.tableView != nil {
            self.tableView.reloadData()
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        UINib(nibName: "UserCallSummaryVC", bundle: nil).instantiate(withOwner: self, options: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.authCheck()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.removeData()
    }
    
    
    @objc
    private func addCallTapped() {
        
        let rootViewController = UserCallVC()
        // rootViewController.delegate = self
        let navController = UINavigationController(rootViewController: rootViewController)
        self.present(navController, animated: true, completion: nil)
        
    }
    
    private func groupCallsByCallPeriod(userCallSummaries: [UserCallSummaryModel]) -> [[UserCallSummaryModel]]? {
        
        if let periodGroupStrings = self.getPeriodGroupingFrom(userCallSummaries: userCallSummaries) {
            
            var groupedPeriods = [[UserCallSummaryModel]]()
            
            for groupStr in periodGroupStrings {
                let groupArry = userCallSummaries.filter({
                    $0.periodDescription?.lowercased() == groupStr.lowercased()
                }).sorted(by: { $0.upsideSummaryUploadTimestamp! > $1.upsideSummaryUploadTimestamp! })
                groupedPeriods.append(groupArry)
            }
            return groupedPeriods
            
        } else {
            return nil
        }
    }
    
    private func getPeriodGroupingFrom(userCallSummaries: [UserCallSummaryModel]) -> [String]? {
        // MARK: TODO add sort here.
        
        if userCallSummaries.count == 0 {
            return nil
        } else {
            let periodGroups = userCallSummaries.map {$0.periodDescription!}
            return periodGroups.removingDuplicates()
        }
    }
    
    private func getCummulativeBookingsByDateFrom(closedWonOpps: [OpportunityModel],
                                                  closedWonCorrections: [CallCorrectionModel]?,
                                                  startPeriod: Double,
                                                  endPeriod: Double) -> [Double : Double] {
        
        // step one filter closed won opps by the time period.
        
        var withinPeriodWonOpps = closedWonOpps.filter({
            $0.closeDateTimeStamp! >= startPeriod &&
            $0.closeDateTimeStamp! <= endPeriod
        })
        
        
        // step two, correct any opportunties which have closed / won corrections.
        if closedWonCorrections != nil && closedWonCorrections!.count > 0 {
            
            for corc in closedWonCorrections! {
                
                if let oppID = corc.opportunityID {
                    
                    //let oppIndex = opps!.firstIndex(where: { $0.opportunityId == opp.id} )
                    
                    if let i = withinPeriodWonOpps.firstIndex(where: {
                        $0.opportunityId == oppID
                    }) {
                        // ok, we have the opp (we think), now need to swap it out
                        let oppToUpdate = withinPeriodWonOpps[i]
                        let newOpp = getOpportunityWithClosedWonCorrection(opp: oppToUpdate, change: corc.amount!)
                        
                        withinPeriodWonOpps[i] = newOpp
                    }
                }
            }
        }
        
        // step three, build the cummulative values...
        var cummulativeAmount = 0.0
        var cummulativeLogs = [Double : Double]()
        
        // we want to start at (0, 0)
        cummulativeLogs[startPeriod] = 0.0
        //startPeriod
        
        for aOpp in withinPeriodWonOpps {
            cummulativeAmount = cummulativeAmount + (aOpp.totalBookingsConverted! + aOpp.commerceBookings!)
            let aTimestamp = aOpp.closeDateTimeStamp!
            cummulativeLogs[aTimestamp] = cummulativeAmount
        }
        return cummulativeLogs
    }
    
    private func getOpportunityWithClosedWonCorrection(opp: OpportunityModel, change: Double) -> OpportunityModel {
        
        // new total bookings amount (not inlc commerce)
        let newTotalBookings = opp.totalBookingsConverted! + change
        return OpportunityModel(id: opp.id, accountName: opp.accountName, closeDate: opp.closeDate, commerceBookings: opp.commerceBookings, commerceBookingsCurrency: opp.commerceBookingsCurrency, createdDate: opp.createdDate, lastModifiedDate: opp.lastModifiedDate, lastStageChangeDate: opp.lastStageChangeDate, leadSource: opp.leadSource, opportunityCurrency: opp.opportunityCurrency, opportunityId: opp.opportunityId, opportunityName: opp.opportunityName, opportunityOwner: opp.opportunityOwner, opportunityOwnerEmail: opp.opportunityOwnerEmail, opportunityOwnerManager: opp.opportunityOwnerManager, primaryProductFamily: opp.primaryProductFamily, probability: opp.probability, stage: opp.stage, totalBookingsConverted: newTotalBookings, totalBookingsConvertedCurrency: opp.totalBookingsConvertedCurrency, type: opp.type, age: opp.age, closeDateTimeStamp: opp.closeDateTimeStamp, createdDateTimeStamp: opp.createdDateTimeStamp, lastModifiedDateTimeStamp: opp.lastModifiedDateTimeStamp, lastStageChangeDateTimeStamp: opp.lastStageChangeDateTimeStamp)
        
    }
    
    
    // MARK: TODO Should be a global function
    func showUserLoginVC(autoFillPassword: Bool) {
        let rootViewController = UserLoginVC()
        rootViewController.delegate = self
        
        rootViewController.autoBiometricCheckIsOn = autoFillPassword
        let navController = UINavigationController(rootViewController: rootViewController)
        rootViewController.isModalInPresentation = true // prevent drag down form option
        rootViewController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
}


// MARK: Firebase functions
extension UserCallSummaryVC {
    
    // MARK: Primary call to data base METHOD
    private func authCheck() {
        if Auth.auth().currentUser != nil { // do stuff
            // self.fetchAllUserSummeries() // will move to after Auth etc
            self.fetchMostRecentOpportunityUploadLog()
        } else { // show user login
            self.showUserLoginVC(autoFillPassword: true)
        }
    }
    
    
    // MARK: starting to build out more complex fetch logic
    // in order to build a reliable graph.
    
    // order to call.
    
    // 1) fetch most recent opportunities upload log
    // 2) fetch all relevant user summaries
    // 3) fetch relevant closed won opps
    // 4) fetch corrections
    
    
    
    // 1) fetch most recent opportunities upload log
    private func fetchMostRecentOpportunityUploadLog() {
        
        
        if Auth.auth().currentUser != nil {
            let query = db.collection("opp_upload_logs").order(by: "uploadTimestamp", descending: true).limit(to: 1)
            query.getDocuments { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    // MARK: TODO - add UI alert.
                    print("No documents, fetchOpportunities()")
                    return
                }
                self.opportunityUploadLogs = documents.compactMap { (queryDocumentSnapshot) -> OpportunityUploadLogModel? in
                    return try? queryDocumentSnapshot.data(as: OpportunityUploadLogModel.self)
                }
            }
        }
    }
    
    
    // 2) NEW TWO: fetch current user data first:
    func fetchCurrentUserData() {
        
        if let userID = Auth.auth().currentUser?.uid { // Has logged in user.
            let docRef = db.collection("users").document(userID)
            
            
            docRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    do {
                        self.currentUser = try document.data(as: FirebaseUserModel.self)
                    } catch {
    
                        // Create new Alert
                        let dialogMessage = UIAlertController(title: "Error",
                                                              message: error.localizedDescription,
                                                              preferredStyle: .alert)
                        
                        // Create OK button with action handler
                        let ok = UIAlertAction(title: "OK",
                                               style: .default,
                                               handler: { (action) -> Void in
                            print("Ok button tapped")
                         })
                        
                        //Add OK button to a dialog message
                        dialogMessage.addAction(ok)
                        // Present Alert to
                        self.present(dialogMessage, animated: true,
                                     completion: nil)
                    }
                } else {

                    // Create new Alert
                    let dialogMessage = UIAlertController(title: "Error",
                                                          message: "Document does not exist",
                                                          preferredStyle: .alert)
                    
                    // Create OK button with action handler
                    let ok = UIAlertAction(title: "OK",
                                           style: .default,
                                           handler: { (action) -> Void in
                        print("Ok button tapped")
                     })
                    
                    //Add OK button to a dialog message
                    dialogMessage.addAction(ok)
                    // Present Alert to
                    self.present(dialogMessage, animated: true,
                                 completion: nil)
                }
            }
        } else {  // Couldn't find user with uid.
    
            // Create new Alert
            let dialogMessage = UIAlertController(title: "Error",
                                                  message: "No user ID.",
                                                  preferredStyle: .alert)
            
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK",
                                   style: .default,
                                   handler: { (action) -> Void in
                print("Ok button tapped")
             })
            
            //Add OK button to a dialog message
            dialogMessage.addAction(ok)
            // Present Alert to
            self.present(dialogMessage, animated: true,
                         completion: nil)
        }
    }
    

    // 2) fetch all relevant user summaries
    func fetchAllUserSummeries() {
        
        // MARK: TODO: need to set a time limit / count limit on this.
        // will need to index a comnbined queary.
        
        let query = db.collection("call_summeries")
            .whereField("userID", isEqualTo: Auth.auth().currentUser!.uid)

        query.addSnapshotListener { (querySnapshot, error) in
        // query.getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("No documents, fetchOpportunities()")
                return
            }
            self.userSummaries = documents.compactMap { (queryDocumentSnapshot) -> UserCallSummaryModel? in
                return try? queryDocumentSnapshot.data(as: UserCallSummaryModel.self)
            }
        }
    }
    
    // 3) fetch relevant closed won opps
    func fetchRelevantClosedWonOpportunities() {
        
        // get all closed won opps in the past year.
  
        let now = Date()
        var dateComponents = DateComponents()
        dateComponents.year = -1
        
        let pastDate = Calendar(identifier: .gregorian).date(byAdding: dateComponents, to: now)!
        let pastTimestamp = pastDate.timeIntervalSince1970
        
        let email = Auth.auth().currentUser?.email ?? "n/a"
        
        
        let query = db.collection("opportunities")
            .whereField("opportunityOwnerEmail", isEqualTo: email)
            .whereField("stage", isEqualTo: "Closed Won")
            .whereField("closeDateTimeStamp", isGreaterThan: pastTimestamp)
            .order(by: "closeDateTimeStamp", descending: false)
        
        
        
        query.getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("No documents, fetchRelevantClosedWonOpportunities()")
                return
            }
            
            self.closedWonOpps = documents.compactMap { (queryDocumentSnapshot) -> OpportunityModel? in
                return try? queryDocumentSnapshot.data(as: OpportunityModel.self)
            }
        }
    }
    
    
    func fetchCurrentClosedWonCorrections() {
        
        if userSummaries != nil && userSummaries!.count > 0 {
            
            let mostRecentSummaryID = userSummaries!.sorted(by: {$0.upsideSummaryUploadTimestamp! > $1.upsideSummaryUploadTimestamp!}).first!.id!
            
            
            print("mostRecentSummaryID:", mostRecentSummaryID)
            
            let query = db.collection("call_corrections")
                .whereField("callSummaryID", isEqualTo: mostRecentSummaryID)
                .whereField("type", isEqualTo: "Closed Won")
            
            // var closeWonCorrections: [CallCorrectionModel]? {
            
            query.getDocuments { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("No documents, fetchCurrentClosedWonCorrections()")
                    return
                }
                
                self.closeWonCorrections = documents.compactMap { (queryDocumentSnapshot) -> CallCorrectionModel? in
                    return try? queryDocumentSnapshot.data(as: CallCorrectionModel.self)
                }
            }
            
            
        }
        
        
        
        
    }
    
    
    // 2) fetch past summeries
    /*
    private func fetchPastSummaries() {
        // go back 2 months, anything earlier is irrelevant.
        let now = Date()
        var dateComponents = DateComponents()
        dateComponents.month = -3
        
        let pastDate = Calendar(identifier: .gregorian).date(byAdding: dateComponents, to: now)!
        let pastTimestamp = pastDate.timeIntervalSince1970
        
//        let email = Auth.auth().currentUser?.email ?? "n/a"
//        print("email:", email)
        let id = Auth.auth().currentUser!.uid
        print("id:", id)
        
        let query = db.collection("call_summeries")
            .whereField("userID", isEqualTo: id)
            .whereField("upsideSummaryUploadTimestamp", isGreaterThan: pastTimestamp)
            .order(by: "upsideSummaryUploadTimestamp", descending: true)
            .limit(to: 75)

        query.getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("No documents, fetchPastSummaries()")
                
                self.pastSummeries = nil // set to nil to continue the chain of fetches.
                return
            }
            
            self.pastSummeries = documents.compactMap { (queryDocumentSnapshot) -> UserCallSummaryModel? in
                return try? queryDocumentSnapshot.data(as: UserCallSummaryModel.self)
            }
        }
    }*/
}


// MARK: TableView Extension
extension UserCallSummaryVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = Bundle.main.loadNibNamed("ExtendedUserCallSummaryCell", owner: self, options: nil)?.first as! ExtendedUserCallSummaryCell
        
        
        cell.callPeriodGroupDescription = self.callHistory![indexPath.row].heading
        cell.totalCallAmount = self.callHistory![indexPath.row].correctedCall
        cell.yetToCloseAmount = self.callHistory![indexPath.row].correctedYetToClose
        cell.forecastedAttainment = self.callHistory![indexPath.row].correctedForecast
        cell.quota = self.callHistory![indexPath.row].quota
        cell.closedWon = self.callHistory![indexPath.row].correctedClosedWonTotal
        cell.callTotalDelta = self.callHistory![indexPath.row].callTotalDelta
        cell.callPercentageDelta = self.callHistory![indexPath.row].callForecastDelta
        cell.closedWonDelta = self.callHistory![indexPath.row].closedWonDelta
        cell.maxCall = self.callHistory![indexPath.row].high
        cell.minCall = self.callHistory![indexPath.row].low
        cell.closedWonAmountCorrectionAmount = self.callHistory![indexPath.row].correctionOfCloseWonTotal
        cell.lastCallTimestamp = self.callHistory![indexPath.row].uploadTime
        
        //lastCallTimestamp
        
        let chartData = [
            self.callHistory![indexPath.row].upsideOverTime!,
            self.callHistory![indexPath.row].callOverTime!,
            self.callHistory![indexPath.row].quotaData!,
            self.callHistory![indexPath.row].cumulativeBoookings!,
            self.callHistory![indexPath.row].upsideProjection!,
            self.callHistory![indexPath.row].callProjection!
        ]
        
        let bottomLabels = self.callHistory![indexPath.row].chartBottomLabelsText
        let leftLabels = self.callHistory![indexPath.row].chartLeftLabelText
        let rightLabels = self.callHistory![indexPath.row].chartRightLabelText
        
        cell.chart.topHeading = self.callHistory![indexPath.row].chartHeading
        cell.chart.bottomLabels = bottomLabels
        cell.chart.leftLabels = leftLabels
        cell.chart.rightLabels = rightLabels
        
        // cell.chart.setChartModels(chartModels: chartData)
        cell.chart.chartModels = chartData
        cell.chart.renameUserCallSummaryHistoryModel = self.callHistory![indexPath.row]
        
        
        // cell.chart.setChartModels(chartModels: chartData)
        
        //cell.chart.chartModels = chartData
        //cell.chart.setChartModels(chartModels: chartData)
        
        
        // cell.chart.chartModel = self.callHistory![indexPath.row].cumulativeBoookings
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return self.groupedUserSummeries?.count ?? 0
        return self.callHistory?.count ?? 0

    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 575.0
    }
    
    
}

// MARK: PassLoginSuccess Extension
extension UserCallSummaryVC: PassLoginSuccess {
    func passStatus(_ stat: Bool) {
        if stat == true {
            self.authCheck() // primary download method.
        } else {
            self.showUserLoginVC(autoFillPassword: true)
        }
    }
}



// MARK: Helper method(s) to create the data models

extension UserCallSummaryVC {
    
    private func getGroupedSummaryHistory(groupedSummaries: [[UserCallSummaryModel]]) -> [UserCallSummaryHistoryModel] {
        
        // MARK: TODO Testing to create graph ready data.
        // MARK: TODO need to make corrections to call, upside & stretch (this covered for total call). - not needed for MVP
        
        var callHistories = [UserCallSummaryHistoryModel]()
        
        for userSummeries in groupedSummaries {
            
            let heading = userSummeries.map({$0.periodDescription!}).first!
            
            let dateMarkers = userSummeries.map({$0.upsideSummaryUploadTimestamp!})
            let closedWonMarkers = userSummeries.map({$0.closedWonTotalAmount!})
            let closedWonCorrectionMarkers = userSummeries.map({$0.totalWonCorrections!})
            var correctedClosedWonMarkers = [Double]()
            
            for (i, nonCorrectedClosedWon) in closedWonMarkers.enumerated() {
                let correctedAmount = nonCorrectedClosedWon + closedWonCorrectionMarkers[i]
                correctedClosedWonMarkers.append(correctedAmount)
            }
            
            let callMarkers = userSummeries.map({$0.total!})
            
            
            
            // MARK: This doesn't work dummy.
            // let upsideMarkers = userSummeries.map({$0.upsideTotalAmount!}) + userSummeries.map({$0.callTotalAmount!})
            
            
            let minCall = callMarkers.min()!
            let maxCall = callMarkers.max()!
            // let currentCallCorrection = userSummeries.map({$0.totalCorrections!}).first!
            
            let currentCallWithCorrections = callMarkers.first! // total alraedy takes corrections into consideration from the user submit vc
            
            let quota = userSummeries.map({$0.quota!}).first!
            let currentForcast = currentCallWithCorrections / quota
            let currentClosedWonWithCorrections = correctedClosedWonMarkers.first!
            let currentCorrectionForCloseWon = userSummeries.map({$0.totalWonCorrections!}).first!
            
            
            var callTotalDelta: Double?
            var callForecastDelta: Double?
            var closedWonDelta: Double?
            if userSummeries.count > 1 {
                callTotalDelta = callMarkers[0] - callMarkers[1]
                callForecastDelta = currentForcast - (callMarkers[1]  / quota)
                closedWonDelta = currentClosedWonWithCorrections - correctedClosedWonMarkers[1]
            }
            
            // let tempVertRange = DoubleRange(max: maxCall, min: 0.0)
            
            let end = userSummeries.map({$0.periodEndTimestamp!}).first!
            let start = userSummeries.map({$0.periodStartTimestamp!}).first!
            
            // use this start and end to get
            // private func getCummulativeBookingsByDateFrom(closedWonOpps: [], closedWonCorrections: []?, startPeriod: Double, endPeriod: Double) -> [Double : Double]
            
            
       
            let tempHorizontalRange = DoubleRange(max: end, min: start)
            
            let cummulativeBookingChartData = self.getCummulativeBookingsByDateFrom(closedWonOpps: self.closedWonOpps!,
                                                                                    closedWonCorrections: self.closeWonCorrections!,
                                                                  startPeriod: start,
                                                                  endPeriod: dateMarkers.first!)
            
            let upsideMarkers = userSummeries.map({$0.upsideTotalAmount!})
            var upsideChartData = [Double : Double]()
            var callPlusUpside = [Double]()
            for (i, upside) in upsideMarkers.enumerated() {
                let timestamp = dateMarkers[i]
                let call = callMarkers[i]
                callPlusUpside.append(upside + call)
                upsideChartData[timestamp] = upside + call
            }
            
            
            var quotaChartData = [Double : Double]()
            quotaChartData[start] = quota
            quotaChartData[end] = quota
            //  callMarkers
            //  dateMarkers
            var callChartData = [Double : Double]()
            for (i, call) in callMarkers.enumerated() {
                let timestamp = dateMarkers[i]
                callChartData[timestamp] = call
            }
            
            
            
            
            
            let vertMaxOptions = [maxCall, quota, callMarkers.max()!, callPlusUpside.max()!]
            
            let vertMax = vertMaxOptions.max()!
            
    
            let vertRange = DoubleRange(max: vertMax,
                                        min: 0.0)
            
            let cumulativeBoookingsPassIn = StandardChartModel(verticalRange: vertRange,
                                                               horizontalRange: tempHorizontalRange,
                                                               verticalLabels: ["1", "2", "3"],
                                                               horizontalLabels: ["1", "2", "3"],
                                                               chartData: ["Cumulative Boookings" : cummulativeBookingChartData],
                                                               lineWidth: 4.0,
                                                               lineRed: ui_active_blue.components.red,
                                                               lineGreen: ui_active_blue.components.green,
                                                               lineBlue: ui_active_blue.components.blue,
                                                               lineAlpha: ui_active_blue.components.alpha)

            let quotaPassIn = StandardChartModel(verticalRange: vertRange,
                                                 horizontalRange: tempHorizontalRange,
                                                 verticalLabels: ["1", "2", "3"],
                                                 horizontalLabels: ["1", "2", "3"],
                                                 chartData: ["Quota" : quotaChartData],
                                                 lineWidth: 3.0,
                                                 lineRed: UIColor.red.components.red,
                                                 lineGreen: UIColor.red.components.green,
                                                 lineBlue: UIColor.red.components.blue,
                                                 lineAlpha: UIColor.red.components.alpha)

            let callOverTime = StandardChartModel(verticalRange: vertRange,
                                                 horizontalRange: tempHorizontalRange,
                                                 verticalLabels: ["1", "2", "3"],
                                                 horizontalLabels: ["1", "2", "3"],
                                                 chartData: ["Call" : callChartData],
                                                  lineWidth: 3.0,
                                                 lineRed: ui_active_aqua.components.red,
                                                 lineGreen: ui_active_aqua.components.green,
                                                 lineBlue: ui_active_aqua.components.blue,
                                                 lineAlpha: ui_active_aqua.components.alpha)

            /*
            let lightAqua = UIColor(red: ui_active_aqua.components.red,
                                    green: ui_active_aqua.components.green,
                                    blue: ui_active_aqua.components.blue,
                                    alpha: 0.5)
             */

            let upsideOverTime = StandardChartModel(verticalRange: vertRange,
                                                    horizontalRange: tempHorizontalRange,
                                                    verticalLabels: ["1", "2", "3"],
                                                    horizontalLabels: ["1", "2", "3"],
                                                    chartData: ["Upside" : upsideChartData],
                                                    lineWidth: 3.0,
                                                    lineRed: ui_active_light_aqua.components.red,
                                                    lineGreen: ui_active_light_aqua.components.green,
                                                    lineBlue: ui_active_light_aqua.components.blue,
                                                    lineAlpha: ui_active_light_aqua.components.alpha)
            
            
            /*
            var quotaChartData = [Double : Double]()
            quotaChartData[start] = quota
            quotaChartData[end] = quota
            */
            
            var callProjectionChartData = [Double : Double]()
            
            var startProjectionTime = self.closedWonOpps!.last!.closeDateTimeStamp!
            if startProjectionTime < start {
                startProjectionTime = start
            }
            
            callProjectionChartData[startProjectionTime] = cummulativeBookingChartData.values.max()
            callProjectionChartData[end] = currentCallWithCorrections
            
            
            let callProjection = StandardChartModel(verticalRange: vertRange,
                                                    horizontalRange: tempHorizontalRange,
                                                    verticalLabels: ["1", "2", "3"],
                                                    horizontalLabels: ["1", "2", "3"],
                                                    chartData: ["Call Projection" : callProjectionChartData],
                                                    lineWidth: 3.0,
                                                    lineRed: ui_active_aqua.components.red,
                                                    lineGreen: ui_active_aqua.components.green,
                                                    lineBlue: ui_active_aqua.components.blue,
                                                    lineAlpha: ui_active_aqua.components.alpha)
            
            var upsideProjectionChartData = [Double : Double]()
            
            
            
            upsideProjectionChartData[startProjectionTime] = cummulativeBookingChartData.values.max()
            upsideProjectionChartData[end] = upsideChartData[upsideChartData.keys.max()!]
            
            
            let upsideProjection = StandardChartModel(verticalRange: vertRange,
                                                    horizontalRange: tempHorizontalRange,
                                                    verticalLabels: ["1", "2", "3"],
                                                    horizontalLabels: ["1", "2", "3"],
                                                    chartData: ["Call Projection" : upsideProjectionChartData],
                                                      lineWidth: 3.0,
                                                    lineRed: ui_active_light_aqua.components.red,
                                                    lineGreen: ui_active_light_aqua.components.green,
                                                    lineBlue: ui_active_light_aqua.components.blue,
                                                    lineAlpha: ui_active_light_aqua.components.alpha)
            
            
            // MARK: Will move to another method.
            // create bottom labels. assume 5 for now.
            let chartBottomLabelsText = self.getTimeLabelTextFrom(start: start,
                                                                  end: end,
                                                                  count: 4)
            
            let chartLeftLabelText = self.getShortHandCurrencyLabelTextFrom(min: 0.0,
                                                                            max: vertRange.max,
                                                                            count: 5)
            
            var chartHeading = heading // which is the grouping.
            if currentUser != nil {
                
                if let userName = currentUser!.fullName {
                    
                    chartHeading = userName + "'s " + heading + " call"
                    
                }
                
            }
            
            /*
             let gridHorizontalCount: Int
             let gridVerticalCount: Int
             */
            

            let callHistory = UserCallSummaryHistoryModel(id: nil,
                                                          heading: heading,
                                                          correctedCall: currentCallWithCorrections,
                                                          correctedForecast: currentForcast,
                                                          correctedClosedWonTotal: currentClosedWonWithCorrections,
                                                          correctionOfCloseWonTotal: currentCorrectionForCloseWon,
                                                          callTotalDelta: callTotalDelta,
                                                          callForecastDelta: callForecastDelta,
                                                          closedWonDelta: closedWonDelta,
                                                          uploadTime: dateMarkers.first!,
                                                          correctedYetToClose: currentCallWithCorrections - currentClosedWonWithCorrections,
                                                          quota: quota,
                                                          high: maxCall,
                                                          low: minCall,
                                                          cumulativeBoookings: cumulativeBoookingsPassIn,
                                                          quotaData: quotaPassIn,
                                                          callOverTime: callOverTime,
                                                          upsideOverTime: upsideOverTime,
                                                          callProjection: callProjection,
                                                          upsideProjection: upsideProjection,
                                                          chartHeading: chartHeading,
                                                          chartBottomLabelsText: chartBottomLabelsText,
                                                          chartLeftLabelText: chartLeftLabelText,
                                                          chartRightLabelText: chartLeftLabelText,
                                                          gridHorizontalCount: chartLeftLabelText!.count,
                                                          gridVerticalCount: 0)
            

            callHistories.append(callHistory)
        }
        
        return callHistories
    }
    
    
    // MARK: TODO dup - move to global class
    private func getShortHandCurrencyLabelTextFrom(min: Double, max: Double, count: Int) -> [String]? {
        if count < 1 {
            return nil
        }
        let amountDelta = max - min
        let amountIncrement = amountDelta / Double(count - 1)
        var labelTexts = [String]()
        for i in 0...count-1  {
            let str = formatShortHandCurrency(num: min + (Double(i) * amountIncrement))
            labelTexts.append(str)
        }
        return labelTexts
    }
    
    // MARK: TODO dup - move to global class
    private func getTimeLabelTextFrom(start: Double, end: Double, count: Int) -> [String]? {
        if count < 1 {
            return nil
        }
        let timeDelta = end - start
        let timeIncrement = timeDelta / Double(count - 1)
        var labelTexts = [String]()
        for i in 0...count-1  {
            let timestamp = start + (Double(i) * timeIncrement)
            let date = Date(timeIntervalSince1970: timestamp)
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = TimeZone.current // TimeZone(abbreviation: "GMT") //Set timezone that you want
            dateFormatter.locale = NSLocale.current
            dateFormatter.dateFormat = "MMM d" //Specify your format that you want
            let strDate = dateFormatter.string(from: date)
            labelTexts.append(strDate.lowercased())
            
        }
        return labelTexts
    }
    
    
}
