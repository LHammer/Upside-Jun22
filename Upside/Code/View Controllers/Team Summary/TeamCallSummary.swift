//
//  TeamCallSummary.swift
//  Upside
//
//  Created by Hammer, Luke on 6/14/22.
//

// 1) confirm user is logged in
// 2) get current user data
// 3) 

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestoreSwift
import SwiftUI


class TeamCallSummary: UIViewController {

    @IBOutlet weak var syncTimeLabel: UILabel!
    private var db = Firestore.firestore()
    @IBOutlet weak var periodStatHolderView: UIView!
    @IBOutlet weak var periodSnapHolderView: UIView!
    
    @IBOutlet weak var primaryChart: ChartStandardView!
    

    // 1) logs
    private var opportunityUploadLogs: [OpportunityUploadLogModel]? {
        didSet {
            if opportunityUploadLogs != nil && opportunityUploadLogs!.count > 0 {
                if let log = opportunityUploadLogs?[0] {
                    self.setSFDCLabel(log: log)
                    self.fetchCurrentUserData()
                }
            }
        }
    }
    
    // 2) user
    private var currentUser: FirebaseUserModel? {
        didSet {
            if currentUser != nil {
                print("we now have user:")
                print(currentUser!)
                
                self.fetchUserTeams()
            }
        }
    }
    
    
    // MARK: TODO: need more logic like this in other classes.
    // 3) affilated teams
    private var teamAffiliations: [TeamModel]? {
        didSet {
            if teamAffiliations != nil && teamAffiliations!.count > 0 {
                print("teamAffiliations:")
                print(teamAffiliations!)
                
                if let aTeam = self.getPrimaryTeamFrom(teams: teamAffiliations!) {
                    self.myTeam = aTeam
                }
            }
        }
    }
    
    // 3) a) get the primary team
    private var myTeam: TeamModel? {
        didSet {
            if myTeam == nil { // no team, move to the individual view.
                print("Move to the individual view.")
            } else { // they are a team leader
                print("team leader, primary team:")
                print(myTeam!)
                
                let myTeamUids = self.teamAffiliations!.map( {
                    $0.id!
                } )
                
                print("myTeamUids:")
                print(myTeamUids)
                
                self.fetchRelevantGroupedTargets(teamUids: myTeamUids)
                
            }
        }
    }
    
    
    // 4) get all relevant quotas
    private var myGroupedQuotas: [GroupTargetModel]? {
        didSet {
            if myGroupedQuotas != nil {
                
                let now = Date()
                var dateComponents = DateComponents()
                dateComponents.year = -2
                
                let pastDate = Calendar(identifier: .gregorian).date(byAdding: dateComponents, to: now)!
                let pastTimestamp = pastDate.timeIntervalSince1970
                
                
                
                self.fetchTeamMembers(teamUid: myTeam!.id!,
                                      employedSince: pastTimestamp) // team members working in the last 2 years.
            }
        }
    }
    
    
    
    
    
    
    
    // 5) get all team members so we can then get all users.
    private var teamMembers: [GroupMemberModel]? {
        didSet {
            if teamMembers != nil && teamMembers!.count > 0 {
                let uids = self.teamMembers!.map({
                    $0.firebaseUid!
                })
                
                
                // MARK: TODO need to figure out if getting the unique members should be done here or in the fetch
                let uniqueTeamMemberIDs = Array(Set(uids))
                
                // let set: Set<Int> = [1, 1, 1, 2, 2, 2, 3, 3, 3]
                // let unique = Array(Set(array)) - order doesn't matter
                
                
                
                // self.fetchUsers(uids: uids)
                self.fetchUsers(uids: uniqueTeamMemberIDs)
            }
        }
    }
    
    // 6) get all team users
    private var teamUsers: [FirebaseUserModel]? {
        didSet {
            print("---have users---")
            print("now need to get the relevant opps. currently  only to 10 users and filter products after.")
            //  now get all relevant closed won opps. only by person, not product.
            
            
            if teamUsers != nil {
                
                let emails = teamUsers!.map({
                    $0.email!
                })
                
                let now = Date()
                var dateComponents = DateComponents()
                dateComponents.year = -2
                
                let pastDate = Calendar(identifier: .gregorian).date(byAdding: dateComponents, to: now)!
                let pastTimestamp = pastDate.timeIntervalSince1970
                
                self.fetchClosedWonOpps(userEmails: emails,
                                        sinceTimestamp: pastTimestamp)
                
            }
        }
    }
    
    // 7) get all closed won opps
    private var closedWonOpps: [OpportunityModel]? {
        didSet {
            
            if closedWonOpps != nil &&  myTeam != nil {
                
                self.fetchTeamQuotas(team: self.myTeam!)
            }
        }
    }
    
    
    // 8) get all team quotas
    private var teamQuota: [TeamQuotaModel]? {
        didSet {
            if teamQuota != nil && teamQuota!.count > 0 {
                
                
                
                
                print("Ok, we now have team quotas let's organise.")
                print(teamQuota!)
                
                let quotaData = self.getQuotaDataFrom(aQuotas: teamQuota!,
                                                      callPeriod: .thisQuarter)
                
                print("quotaData:")
                print(quotaData)
                
                
                self.setDataModelsFrom(closedWonOpps: closedWonOpps!,
                                       quota: quotaData.quota,
                                       quotaToDate: quotaData.quotaToDate)
            }
        }
    }
    
    
    
    
    private var dataModel: TeamCallSummaryHistoryModel? {
        didSet {
            if dataModel != nil {
                self.updateDisplay(aDataModel: self.dataModel!)
            }
        }
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //    periodStatHolderView
        //    periodSnapHolderView
        
        self.periodSnapHolderView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.periodSnapHolderView.layer.cornerRadius = 10.0
        self.periodStatHolderView.layer.cornerRadius = 10.0
        

        
        
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        UINib(nibName: "TeamCallSummary", bundle: nil).instantiate(withOwner: self, options: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.authCheck()
    }
    
    
    // MARK: Working here.
    private func getQuotaDataFrom(aQuotas: [TeamQuotaModel], callPeriod: CallPeriod) -> (quota: Double, quotaToDate: Double) {

        let periodInfo = getStartAndEndTimestampFor(callPeriod: callPeriod,
                                                    timeZone: global_active_hq_time_zone)
        
        let quota = self.getQuotaBetween(start: periodInfo.startTS, end: periodInfo.endTS, quotas: aQuotas)
        // ok, now i need to get the percentage through the time.
        // MARK: TODO, should we use Date().timeIntervalSince1970, or the most recent sfdc time???
        let percThroughPeriod = (Date().timeIntervalSince1970 - periodInfo.startTS) / (periodInfo.endTS - periodInfo.startTS)
        
        
        // MARK: TODO should not use '!' some user may not have quotas. craches with Nic at the moment.
        return (quota: quota!,
                quotaToDate: percThroughPeriod * quota!)
    }
    
    // MARK: NEW METHODS
    func getQuotaBetween(start: Double, end: Double, quota: TeamQuotaModel) -> Double {
        
        if start > quota.endTimeStamp! { // period is after quota timeline.
            return 0.0
        }
        
        if end < quota.startTimeStamp! { // period is before quota timeline
            return 0.0
        }
        
        var portionStart = quota.startTimeStamp!
        if start > quota.startTimeStamp! {
            portionStart = start
        }
        
        var portionEnd = quota.endTimeStamp!
        if end < quota.endTimeStamp! {
            portionEnd = end
        }
        
        return ((portionEnd - portionStart) / (quota.endTimeStamp! - quota.startTimeStamp!)) * quota.amount!
    }
    
     
    func getQuotaBetween(start: Double, end: Double, quotas: [TeamQuotaModel]) -> Double? {
        
        var amount = 0.0
        for quota in quotas {
            let relevantQuotaAmount = getQuotaBetween(start: start, end: end, quota: quota)
            amount = amount + relevantQuotaAmount
        }
        
        if amount == 0.0 {
            return nil
        }
        return amount
    }
    
    
    
    
    
    // MARK: Current working point
    private func updateDisplay(aDataModel: TeamCallSummaryHistoryModel) {
        
        self.primaryChart!.topHeading = myTeam!.team
        self.primaryChart!.renameTeamCallSummaryHistoryModel = aDataModel
        self.primaryChart!.bottomLabels = aDataModel.chartBottomLabelsText
        self.primaryChart!.leftLabels = aDataModel.chartLeftLabelText
        self.primaryChart!.rightLabels = aDataModel.chartRightLabelText
        let chartData = [
            aDataModel.cumulativeBoookings!,
            aDataModel.quotaData!
        ]
        self.primaryChart!.chartModels = chartData
        self.primaryChart!.updateDisplay()
        
    }
    
    
    // MARK: TODO copy over to calls vc's...
    // make this method, clear. it purpose is to setup all data models ONCE all data is collected .
    // so pass in the data.
    // MARK: TODO currenty just working for current quarter.
    private func setDataModelsFrom(closedWonOpps: [OpportunityModel],
                                   quota: Double,
                                   quotaToDate: Double) {
        
        
        
        
        let start = self.getStartOfQuarter(date: Date(),
                                           timeZone: global_active_hq_time_zone)
        
        let end = self.getEndOfQuarter(date: Date(),
                                       timeZone: global_active_hq_time_zone)
        
        
        let cumulativeClosedWonBookings = self.getCummulativeBookingsByDateFrom(closedWonOpps: closedWonOpps,
                                                                                closedWonCorrections: nil,
                                                                                startPeriod: start,
                                                                                endPeriod: end)
        
        
        
        // MARK: Move to
        let vertMaxOptions = [cumulativeClosedWonBookings.values.max()!, quota, 0.0, 0.0]
        
        let vertMax = vertMaxOptions.max()!
        

        let vertRange = DoubleRange(max: vertMax,
                                    min: 0.0)
        
        
        // MARK: Will move to another method.
        // create bottom labels. assume 5 for now.
        let chartBottomLabelsText = self.getTimeLabelTextFrom(start: start,
                                                              end: end,
                                                              count: 4)
        
        let chartLeftLabelText = self.getShortHandCurrencyLabelTextFrom(min: 0.0,
                                                                        max: vertRange.max,
                                                                        count: 5)
        
        let tempHorizontalRange = DoubleRange(max: end, min: start)
        
        let cumulativeClosedWonBookingsChartData = StandardChartModel(verticalRange: vertRange,
                                                                      horizontalRange: tempHorizontalRange,
                                                                      verticalLabels: ["blah", "blah", "blah"],
                                                                      horizontalLabels: ["blah", "blah", "blah"],
                                                                      chartData: ["Cumulative Bookings" : cumulativeClosedWonBookings],
                                                                      lineWidth: 3.0,
                                                                      lineRed: ui_active_blue.components.red,
                                                                      lineGreen: ui_active_blue.components.green,
                                                                      lineBlue: ui_active_blue.components.blue,
                                                                      lineAlpha: 1.0)
        
        /*
        let dataModel = TeamCallSummaryHistoryModel(cumulativeBoookings: cumulativeClosedWonBookingsChartData,
                                                    chartHeading: "my test heading.",
                                                    chartBottomLabelsText: chartBottomLabelsText,
                                                    chartLeftLabelText: chartLeftLabelText,
                                                    chartRightLabelText: chartLeftLabelText,
                                                    gridHorizontalCount: chartBottomLabelsText!.count + 1,
                                                    gridVerticalCount: chartLeftLabelText!.count + 1)*/
        
        
        var quotaChartData = [Double : Double]()
        quotaChartData[start] = quota
        quotaChartData[end] = quota
        
        print("888888888888888888")
        print(quotaChartData)
        
        let quotaData = StandardChartModel(verticalRange: vertRange,
                                           horizontalRange: tempHorizontalRange,
                                           verticalLabels: ["blah", "blah", "blah"],
                                           horizontalLabels: ["blah", "blah", "blah"],
                                           chartData: ["Quota" : quotaChartData],
                                           lineWidth: 2.0,
                                           lineRed: UIColor.red.components.red,
                                           lineGreen: UIColor.red.components.green,
                                           lineBlue: UIColor.red.components.blue,
                                           lineAlpha: 1.0)
        
        
        let dataModel = TeamCallSummaryHistoryModel(quota: quota,
                                                    cumulativeBoookings: cumulativeClosedWonBookingsChartData,
                                                    quotaData: quotaData,
                                                    chartHeading: "my test heading.",
                                                    chartBottomLabelsText: chartBottomLabelsText,
                                                    chartLeftLabelText: chartLeftLabelText,
                                                    chartRightLabelText: chartLeftLabelText,
                                                    gridHorizontalCount: chartBottomLabelsText!.count + 1,
                                                    gridVerticalCount: chartLeftLabelText!.count + 1)
        
        
        
        

        self.dataModel = dataModel
        
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
    
    
    
//    private func getCummulativeBookingsFrom(closedWonOpps: [OpportunityModel]) -> [Double : Double] {
//        return [0.0 : 0.0]
//    }
    
    
    private func getOpportunityWithClosedWonCorrection(opp: OpportunityModel, change: Double) -> OpportunityModel {
        
        // new total bookings amount (not inlc commerce)
        let newTotalBookings = opp.totalBookingsConverted! + change
        return OpportunityModel(id: opp.id, accountName: opp.accountName, closeDate: opp.closeDate, commerceBookings: opp.commerceBookings, commerceBookingsCurrency: opp.commerceBookingsCurrency, createdDate: opp.createdDate, lastModifiedDate: opp.lastModifiedDate, lastStageChangeDate: opp.lastStageChangeDate, leadSource: opp.leadSource, opportunityCurrency: opp.opportunityCurrency, opportunityId: opp.opportunityId, opportunityName: opp.opportunityName, opportunityOwner: opp.opportunityOwner, opportunityOwnerEmail: opp.opportunityOwnerEmail, opportunityOwnerManager: opp.opportunityOwnerManager, primaryProductFamily: opp.primaryProductFamily, probability: opp.probability, stage: opp.stage, totalBookingsConverted: newTotalBookings, totalBookingsConvertedCurrency: opp.totalBookingsConvertedCurrency, type: opp.type, age: opp.age, closeDateTimeStamp: opp.closeDateTimeStamp, createdDateTimeStamp: opp.createdDateTimeStamp, lastModifiedDateTimeStamp: opp.lastModifiedDateTimeStamp, lastStageChangeDateTimeStamp: opp.lastStageChangeDateTimeStamp)
        
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
    
    
    
    // this should only be called once user is downloaded AND
    // teams are downlaoded - it's not intended to error handle.
    // the user only has one assigned team.
    private func getPrimaryTeamFrom(teams: [TeamModel]?) -> TeamModel? {
        if teams == nil || teams!.count == 0 {
            return nil
        }
        let userPrimaryTeamUID = currentUser!.teamOwnedUid!
        return teams!.filter( {
            $0.id == userPrimaryTeamUID
        } ).first!
    }
    
    
    private func setSFDCLabel(log: OpportunityUploadLogModel) {
        
        // let log = opportunityUploadLogs![0]
        let date = Date(timeIntervalSince1970: log.uploadTimestamp!)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "MMM d, h:mm a"
        let strDate = dateFormatter.string(from: date)
        
        self.syncTimeLabel.text = "sfdc sync:  " + strDate + ""
        
    }
    
    
    
}

// MARK: Firebase fetch and write functions
extension TeamCallSummary: PassLoginSuccess {
    
    private func showUserLoginVC(autoFillPassword: Bool) {
        let rootViewController = UserLoginVC()
        rootViewController.delegate = self
        rootViewController.autoBiometricCheckIsOn = autoFillPassword
        let navController = UINavigationController(rootViewController: rootViewController)
        rootViewController.isModalInPresentation = true // prevent drag down form option
        rootViewController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    private func authCheck() {
        if Auth.auth().currentUser != nil {
            self.fetchMostRecentOpportunityUploadLog()
        } else { // show user login
            self.showUserLoginVC(autoFillPassword: true)
        }
    }
    
    func passStatus(_ stat: Bool) {
        if stat == true {
            self.authCheck() // primary download method.
        } else {
            self.showUserLoginVC(autoFillPassword: true)
        }
    }
    
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
    
    
    // No user has that many teams, so just fetch all and sort out logic later.
    private func fetchUserTeams() {
        
        if let userID = Auth.auth().currentUser?.uid {
            
            let query = db.collection("teams")
                .whereField("ownerUid", isEqualTo: userID)
            
            
            query.getDocuments { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    // MARK: TODO add user ui error
                    print("No documents, fetchUserTeams()")
                    return
                }
                self.teamAffiliations = documents.compactMap { (queryDocumentSnapshot) -> TeamModel? in
                    return try? queryDocumentSnapshot.data(as: TeamModel.self)
                }
            }
        }
    }
    
    
    // MARK: TODO - need to build out logic uf there's more than 10 teams.
    // or cap it to ten groups per person
    private func fetchRelevantGroupedTargets(teamUids: [String]) {
        
        
        print("COUNT teamUids:")
        print(teamUids.count)
        
        
        let query = db.collection("grouped_targets")
            .whereField("teamUid", in: teamUids)

        query.getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                // MARK: TODO add user ui error
                print("No documents, fetchRelevantGroupedTargets(teamUids:)")
                return
            }
            self.myGroupedQuotas = documents.compactMap { (queryDocumentSnapshot) -> GroupTargetModel? in
                return try? queryDocumentSnapshot.data(as: GroupTargetModel.self)
            }
        }
    }
    
    
    // method to get team member identities, and their duration.
    // can then getch team member USER info later.
    private func fetchTeamMembers(teamUid: String, employedSince: Double) {
        
        let query = db.collection("team_members")
            .whereField("teamUid", isEqualTo: teamUid)
            .whereField("endTimeStamp", isGreaterThanOrEqualTo: employedSince)
        
        query.getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                // MARK: TODO add user ui error
                print("fetchTeamMembers(teamUid:, employedSince:)")
                return
            }
            
            self.teamMembers = documents.compactMap { (queryDocumentSnapshot) -> GroupMemberModel? in
                return try? queryDocumentSnapshot.data(as: GroupMemberModel.self)
            }
        }
    }
    
    // MARK: TODO this only caters to less than 10 users atm.
    // method to get all user data (public) for team members.
    private func fetchUsers(uids: [String]) {
        
        
        print("COUNT uids:")
        print(uids.count)
        
        let query = db.collection("users")
            .whereField("firebaseUid", in: uids)
        
        query.getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                // MARK: TODO add user ui error
                print("Error: fetchUsers(uids: [String])")
                return
            }
            
            self.teamUsers = documents.compactMap { (queryDocumentSnapshot) -> FirebaseUserModel? in
                return try? queryDocumentSnapshot.data(as: FirebaseUserModel.self)
            }
        }
    }
    
    
    
    // MARK: TODO: currently only works for 10 or less users. enough for testing for inside sales.
    // currently, query will just run off email rather than uid.... this may
    // need to be improved in the future. but for now it's indesign to run
    // off email address as even at scale, it should be true that there's only
    // one email address within one company.
    
    private func fetchClosedWonOpps(userEmails: [String], sinceTimestamp: Double) {
        
        
        print("COUNT userEmails:")
        print(userEmails.count)
        
        
        
        //let query = db.collection("opportunties")
        let query = db.collection("opportunities")
            .whereField("opportunityOwnerEmail", in: userEmails)
            .whereField("stage", isEqualTo: "Closed Won")
            .whereField("closeDateTimeStamp", isGreaterThanOrEqualTo: sinceTimestamp)
        
       
        query.getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                // MARK: TODO add user ui error
                print("Error: fetchClosedWonOpps(userEmails:, sinceTimestamp:)")
                return
            }
            
            self.closedWonOpps = documents.compactMap { (queryDocumentSnapshot) -> OpportunityModel? in
                return try? queryDocumentSnapshot.data(as: OpportunityModel.self)
            }
        }
    }
    
    
    
    private func fetchTeamQuotas(team: TeamModel) {
        
        let query = db.collection("team_quota")
            .whereField("teamUid", isEqualTo: team.id!)
        
        
        query.getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                // MARK: TODO add user ui error
                print("Error: fetchClosedWonOpps(userEmails:, sinceTimestamp:)")
                return
            }
            
            self.teamQuota = documents.compactMap { (queryDocumentSnapshot) -> TeamQuotaModel? in
                return try? queryDocumentSnapshot.data(as: TeamQuotaModel.self)
            }
        }
        
        
        
    }
    
    
}






// MARK: TODO could be moved to a helper method/.
// MARK: TODO move to global class / method - it's in multiple.
// time / period managment / descriptions.
extension TeamCallSummary {
    
    
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
