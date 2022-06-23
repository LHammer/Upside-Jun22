//
//  UserCallVC.swift
//  Upside
//
//  Created by Luke Hammer on 5/19/22.
//


// MARK: TODO
// Need more logic as to what opps are assessed as 'ledger' opps. i.e if looking at next quarter,
// all closed deals should be excluded because it's in the future, but all open opps should always
// be included. may need to build logic that return open opps and closed opps seperatly and merge.

// MARK: TODO
// deal velocity not working when short periods of times.

// MARK: BUG
// when selecting time period for 'today' it shows more than 1 day is left.

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestoreSwift
import SwiftUI

// MARK: Complete review of class and required - to much drunk coding...

protocol PassUserCallVCStatus: AnyObject {
    func complete()
}

class UserCallVC: UIViewController {
    
    @IBOutlet weak var callByOppViewHolder: UIView!
    @IBOutlet weak var callByVelocityHolderView: UIView!
    @IBOutlet weak var manualCallCorrectionHolderView: UIView!
    @IBOutlet weak var summaryHolderView: UIView!
    
    @IBOutlet weak var correctionTableView: UITableView!
    @IBOutlet weak var callCorrectionHeaderHolderView: UIView!
    
    @IBOutlet weak var editCallByOppBtn: StandardButton!
    @IBOutlet weak var addCorrectionButton: StandardButton!
    @IBOutlet weak var submitCallButton: StandardButton!
    
    @IBOutlet weak var moreInfoCallByOpportunityBtn: UIButton!
    
    /* Call period labels */
    @IBOutlet weak var callPeriodTopLabel: UILabel!
    @IBOutlet weak var callPeriodBottomLabel: UILabel!
    
    /* SFDC label */
    @IBOutlet weak var syncTimeLabel: UILabel!
    
    /* CALL Labels */
    @IBOutlet weak var callTotalAmountLabel: UILabel!
    @IBOutlet weak var callTotalCountLabel: UILabel!
    @IBOutlet weak var callSaaSAmountLabel: UILabel!
    @IBOutlet weak var callSaaSCountLabel: UILabel!
    @IBOutlet weak var callComrcAmountLabel: UILabel!
    @IBOutlet weak var callComrcCountLabel: UILabel!
    @IBOutlet weak var callOtherAmountLabel: UILabel!
    @IBOutlet weak var callOtherCountLabel: UILabel!
    
    /* UPSIDE Labels */
    @IBOutlet weak var upsideTotalAmountLabel: UILabel!
    @IBOutlet weak var upsideTotalCountLabel: UILabel!
    @IBOutlet weak var upsideSaaSAmountLabel: UILabel!
    @IBOutlet weak var upsideSaaSCountLabel: UILabel!
    @IBOutlet weak var upsideComrcAmountLabel: UILabel!
    @IBOutlet weak var upsideComrcCountLabel: UILabel!
    @IBOutlet weak var upsideOtherAmountLabel: UILabel!
    @IBOutlet weak var upsideOtherCountLabel: UILabel!
 
    /* STRETCH Labels */
    @IBOutlet weak var stretchTotalAmountLabel: UILabel!
    @IBOutlet weak var stretchTotalCountLabel: UILabel!
    @IBOutlet weak var stretchSaaSAmountLabel: UILabel!
    @IBOutlet weak var stretchSaaSCountLabel: UILabel!
    @IBOutlet weak var stretchComrcAmountLabel: UILabel!
    @IBOutlet weak var stretchComrcCountLabel: UILabel!
    @IBOutlet weak var stretchOtherAmountLabel: UILabel!
    @IBOutlet weak var stretchOtherCountLabel: UILabel!
    
    /* OMIT Labels */
    @IBOutlet weak var omitTotalAmountLabel: UILabel!
    @IBOutlet weak var omitTotalCountLabel: UILabel!
    @IBOutlet weak var omitSaaSAmountLabel: UILabel!
    @IBOutlet weak var omitSaaSCountLabel: UILabel!
    @IBOutlet weak var omitComrcAmountLabel: UILabel!
    @IBOutlet weak var omitComrcCountLabel: UILabel!
    @IBOutlet weak var omitOtherAmountLabel: UILabel!
    @IBOutlet weak var omitOtherCountLabel: UILabel!
    
    /* Call by opportunity summary / total. */
    @IBOutlet weak var callTotalAmountSummaryLabel: UILabel!
    @IBOutlet weak var pipeBuildVelocityLabel: UILabel!
    @IBOutlet weak var dealCloseVelocityLabel: UILabel!
    @IBOutlet weak var closeWonRatioLabel: UILabel!
    @IBOutlet weak var upsideForecastLabel: UILabel!
    
    //
    @IBOutlet weak var userAmountByVelocityPercentageLabel: UILabel!
    @IBOutlet weak var userAmountByVelocityForecastLabel: UILabel!
    @IBOutlet weak var pipeBuildVelocitySlider: UISlider!
    
    /* ------------------------------------------------------- */
    // MARK: call by velocity outlets.
    @IBOutlet weak var daysRemainingLabel: UILabel!
    
    
    /* summary labels */
    @IBOutlet weak var summaryCallByOpportuntiesLabel: UILabel!
    @IBOutlet weak var summaryCallByVelocityLabel: UILabel!
    @IBOutlet weak var summaryCallByCorrectionsLabel: UILabel!
    @IBOutlet weak var summaryCallByClosedWonLabel: UILabel!
    @IBOutlet weak var summaryCallTotalLabel: UILabel!
    @IBOutlet weak var summaryCallRemainingLabel: UILabel!
    
    weak var delegate: PassUserCallVCStatus?
    
    private var db = Firestore.firestore()
    // order to call.
    
    // 1) fetch most recent opportunities upload log
    // 2) fetch past summeries
    // 3) fetch quotas
    // 4) fetch opportunties
    
    // var callPeriod = CallPeriod.thisQuarter {
    var callPeriod: CallPeriod? {
        didSet {
            
            print(">>> CallPeriod did set:", callPeriod)
            
            if callPeriod != nil {
                let timezone = TimeZone(identifier: "America/Chicago")!
                let periodInfo = self.getStartAndEndTimestampFor(callPeriod: self.callPeriod!,
                                                                 timeZone: timezone)
                self.callPeriodTopLabel.text = periodInfo.periodDescription
                self.callPeriodBottomLabel.text = periodInfo.periodDescription
            }
        }
    }
    
    private var pastSummeries: [UserCallSummaryModel]? {
        didSet {
            
            print(">>> pastSummeries did set:", pastSummeries)
            
            if pastSummeries == nil { // there no past summeries.
                self.fetchAllMyQuotas()
            } else { // there are past summeries, but maybe not for this time period.
                self.fetchAllMyQuotas()
                self.pastSummary = self.getPastSummaryFrom(period: self.callPeriod!,
                                                           summeries: self.pastSummeries!)
            }
            
        }
    }
    
    
    private var pastSummary: UserCallSummaryModel? {
        didSet {
            
            print(">>> pastSummary did set:", pastSummary)
            
            
            if pastSummary == nil { // there's no past call for this time period.
                print("been set to nil to setup for new period maybe.")
            } else { // there is a past call for this time period.
                print("past summary has been set: ")
                print(pastSummary!.periodDescription! + " from " + String(pastSummary!.upsideSummaryUploadTimestamp!))
                
            }
        }
    }
    
    
    
    var myQuotas: [QuotaModel]? {
        didSet {
            self.fetchOpportunities()
            
        }
    }
    
    
    
    // all opps for the user pulled from firestore. This includes (i think),
    // past three years of data (for historic data points), and three years forward
    // to include deals well out of range incase they can be pulled in, for the
    // call by opportunity section. Need to filter 'allUserOpportunities' for the
    // review of the current call period. it should only be open opps.
    
    
    private var allUserOpportunities: [OpportunityModel]? {
        
        
        didSet {
            
            print(">>> allUserOpportunities did set:", allUserOpportunities)
            
            if allUserOpportunities != nil {
                
                print("made it here.")
                
                self.setDataModels()
                
                self.updateSummaryLabels()
                self.updateDaysLeftLabel()
                self.updateCloseRatioLabels()
                self.updatePipeBuildVelocityLabels()
                
            }
        }
    }
    
    // MARK: TODO move method
    // MARK: TODO need to pass in time zone and time period and opps.
    private func setDataModels() {
        
        if self.allUserOpportunities != nil {
            
            if self.pastSummeries != nil {
                self.pastSummary = self.getPastSummaryFrom(period: self.callPeriod!,
                                                           summeries: self.pastSummeries!)
            }
            
            
            self.currentSummary = nil
            let periodInfo = self.getStartAndEndTimestampFor(callPeriod: callPeriod!,
                                                             timeZone: global_active_hq_time_zone)
            
            self.setupSummaryModelAndLedgerOppsWith(opportunities: self.allUserOpportunities!,
                                                    startOfPeriod: periodInfo.startTS,
                                                    endOfPeriod: periodInfo.endTS)
            
        } else {
            print("Error. self.allUserOpportunities has not been set.")
        }
    }
    
    
    
    private var currentSummary: UserCallSummaryModel? {
        didSet {
            if currentSummary != nil {
                self.updateCallByOpportunitiesLabelsWith(summary: self.currentSummary!)
                self.updateCallByVelocityLabels() // MARK: TODO should really pass a summary in for all these.
                self.updateSummaryLabels()
            }
        }
    }

    private var currentRelevantPeriodCallLedgerOpps: [OpportunityLedgerModel]? {
        didSet {
            // i'm drunk, this is wrong but i'm going to continue.
            // print("ready to open edit call by opportunity in sales force. Or will need to load in next view.")
        }
    }
    
    // MARK: TODO, need to add a firebase fetch for this
    // once we post the full summary / ledgers / corrections.... fucking love this flat structure.
    private var callCorrections: [CallCorrectionModel]? {
        didSet {
            self.updateSummaryLabels()
            self.correctionTableView.reloadData()
        }
    }
    
    
    
    private var opportunityUploadLogs: [OpportunityUploadLogModel]? {
        didSet {
            
            if opportunityUploadLogs != nil && opportunityUploadLogs!.count > 0 {
                // have logs meta data, now pull past summeries followed by quotas.
                self.fetchPastSummaries()
                // MARK: TODO move to own method.
                let log = opportunityUploadLogs![0]
                let date = Date(timeIntervalSince1970: log.uploadTimestamp!)
                let dateFormatter = DateFormatter()
                dateFormatter.timeZone = TimeZone.current // TimeZone(abbreviation: "GMT") //Set timezone that you want
                dateFormatter.locale = NSLocale.current
                // dateFormatter.dateFormat = "yyyy-MM-dd HH:mm" //Specify your format that you want
                dateFormatter.dateFormat = "MMM-dd HH:mm" //Specify your format that you want
                let strDate = dateFormatter.string(from: date)
                
                self.syncTimeLabel.text = strDate
            }
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.correctionTableView.delegate = self
        self.correctionTableView.dataSource = self
        
        self.setupDefualtNavigationBar()
        
        self.callByOppViewHolder.layer.cornerRadius = 10.0
        self.callByVelocityHolderView.layer.cornerRadius = 10.0
        self.manualCallCorrectionHolderView.layer.cornerRadius = 10.0
        self.summaryHolderView.layer.cornerRadius = 10.0
        
        
        self.callCorrectionHeaderHolderView.layer.cornerRadius = 6.0
        self.correctionTableView.layer.cornerRadius = 6.0
        
        self.editCallByOppBtn.setColorSchemes(scheme: .aquaWhite)
        self.addCorrectionButton.setColorSchemes(scheme: .aquaWhite)
        self.submitCallButton.setColorSchemes(scheme: .blackWhite)
        
        // trialling this here...
        self.callPeriod = .thisQuarter // default value.
    }
    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        UINib(nibName: "UserCallVC", bundle: nil).instantiate(withOwner: self, options: nil)
//    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.setNeedsStatusBarAppearanceUpdate()
        // MARK: Primary call to data base.
        self.authCheck()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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
    
    @IBAction func cofidenceValueChanged(_ sender: UISlider) {
        
        self.currentSummary!.userForecastConfidenceInVelocity = Double(sender.value)
        self.currentSummary!.userVelocityForecast = Double(sender.value) * self.currentSummary!.upsideNewOppForecastAmount!

        self.userAmountByVelocityPercentageLabel.text = String(format: "%.1f", sender.value * 100.0) + "%"
        self.userAmountByVelocityForecastLabel.text = CurrencyModel(locale: "en_US",
                                                                    amount: self.currentSummary!.userVelocityForecast!).format
    }
    
    
    private func presentOppLedgerReviewVC() {
        
        let vc = UserOppLedgerReviewVC()
        
        let filteredListFunc = self.currentRelevantPeriodCallLedgerOpps?.filter({
            $0.stage?.lowercased() == "create" ||
            $0.stage?.lowercased() == "qualify" ||
            $0.stage?.lowercased() == "develop" ||
            $0.stage?.lowercased() == "prove" ||
            $0.stage?.lowercased() == "agreements"
        }).sorted(by: {
            ($0.totalBookingsConverted! + $0.commerceBookings!) > ($1.totalBookingsConverted! + $0.commerceBookings!)
        }).sorted(by: {
            $0.userCurrentCallStatusIndex! > $1.userCurrentCallStatusIndex!
        })
        
        
        vc.opps = filteredListFunc
        vc.delegate = self
        vc.callPeriod = self.callPeriod
        let navController = UINavigationController(rootViewController: vc)
        self.present(navController, animated: true, completion: nil)
        
    }
    
    private func presentOppLedgerClosedReviewVC() {
        
        let vc = UserOppLedgerClosedReviewVC()
        
        let filteredListFunc = self.currentRelevantPeriodCallLedgerOpps?.filter({
            $0.stage?.lowercased() == "closed won"
        }).sorted(by: {
            ($0.totalBookingsConverted! + $0.commerceBookings!) > ($1.totalBookingsConverted! + $0.commerceBookings!)
        })
        
        vc.opps = filteredListFunc
        vc.callPeriod = self.callPeriod
        vc.callCorrections = self.callCorrections
        vc.delegate = self
        let navController = UINavigationController(rootViewController: vc)
        self.present(navController, animated: true, completion: nil)
        
        
    }
    
    // MARK: Working here.
    private func timesOverlap(timeOneStart: Double,
                              timeOneEnd: Double,
                              timeTwoStart: Double,
                              timeTwoEnd: Double) -> Bool {
        
        if timeOneStart > timeTwoEnd {
            return false
        } else if timeOneEnd < timeTwoStart {
            return false
        }
        
        return true
    }
    
    /*
     // quota data:
     let quota: Double?
     let quotaToDate: Double?
     let quotaAttainment: Double?
     let quotaToDateAttainment: Double?
     */
    
    
    // MARK: NEW METHODS
    func getQuotaBetween(start: Double, end: Double, quota: QuotaModel) -> Double {
        
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
    
     
    func getQuotaBetween(start: Double, end: Double, quotas: [QuotaModel]) -> Double? {
        
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

    
    
    // MARK: Working here.
    private func getQuotaDataFrom(quotas: [QuotaModel], callPeriod: CallPeriod) -> (quota: Double, quotaToDate: Double) {

        let periodInfo = getStartAndEndTimestampFor(callPeriod: callPeriod,
                                                    timeZone: global_active_hq_time_zone)
        
        let quota = self.getQuotaBetween(start: periodInfo.startTS, end: periodInfo.endTS, quotas: quotas)
        // ok, now i need to get the percentage through the time.
        // MARK: TODO, should we use Date().timeIntervalSince1970, or the most recent sfdc time???
        let percThroughPeriod = (Date().timeIntervalSince1970 - periodInfo.startTS) / (periodInfo.endTS - periodInfo.startTS)
        
        
        // MARK: TODO should not use '!' some user may not have quotas. craches with Nic at the moment.
        return (quota: quota!,
                quotaToDate: percThroughPeriod * quota!)
    }
    
    // method used after making opp ledger and correction changes. typically from delegate.
    private func updateOpportunitiesWithCorrections(_ opps: [OpportunityLedgerModel],
                                                    corrections: [CallCorrectionModel]?) {
        
        // MARK: TODO dupliucate code. move to common method.
        
        for opp in opps {
            // find opp in relevant opps and replace with the passed back version.
            let oppIndex = self.currentRelevantPeriodCallLedgerOpps!.firstIndex(where: { $0.opportunityId == opp.id} )
            self.currentRelevantPeriodCallLedgerOpps![oppIndex!] = opp
        }
        
        // MARK: TODO BUG this will crash when there's no summary... such as me loggin in with no opps and trying to submit something.
        self.currentSummary = self.getUserCallSumaryFrom(oppLedgers: self.currentRelevantPeriodCallLedgerOpps!,
                                                         businessDaysLeft: self.currentSummary!.businessDaysLeft!,
                                                         nonBusinessDaysLeft: self.currentSummary!.nonBusinessDaysLeft!,
                                                         totalDaysLeft: self.currentSummary!.totalDaysLeft!,
                                                         pipeBuildPast60DayAmount: self.currentSummary!.pipeBuildPast60Days!,
                                                         pipeBuildPast60DayCount: self.currentSummary!.pipeBuildCountPast60Days!,
                                                         pipeBuildPast60DAyaverageSize: self.currentSummary!.pipeBuildAveDealSizePast60Days!,
                                                         pipeBuildPast60DayMedianSize: self.currentSummary!.pipeBuildMediumPast60Days!,
                                                         past30MeanDealVelocityBizDays: self.currentSummary!.past30MeanDealVelocityBizDays!,
                                                         past30MedianDealVelocityBizDays: self.currentSummary!.past30MedianDealVelocityBizDays!,
                                                         pipeBuildMediumPast60Days: self.currentSummary!.pipeBuildMediumPast60Days!,
                                                         averageCountPerBusinessDay60Days: self.currentSummary!.averageCountPerBusinessDay60Days!,
                                                         closeRateByamount: self.currentSummary!.closeRateByamount!,
                                                         closeRateByCount: self.currentSummary!.closeRateByCount!,
                                                         upsideNewOppForecastAmount: self.currentSummary!.upsideNewOppForecastAmount!)
        
        
        if corrections != nil {
            if self.callCorrections == nil {
                self.callCorrections = corrections
            } else {
                
                // remove any duplicates
                for corrc in corrections! {
                    self.callCorrections?.removeAll(where: {$0.opportunityID == corrc.opportunityID} )
                }
                
                // add the new corrections
                for corrc in corrections! {
                    self.callCorrections!.append(corrc)
                }
            }
            self.updateSummaryLabels()
        }
    }
    
    
    private func getCorrectedClosedWonWithCorrections() -> (amount: Double?, count: Int?) {
        
        if self.callCorrections == nil || self.callCorrections!.count == 0 {
            return (amount: nil, count: nil)
        }
        

        var totalAmount = 0.0
        var count = 0
        for corc in self.callCorrections! {
            if corc.type?.lowercased() == CallCorrectionType.closedWonOpportunities.rawValue.lowercased() {
                //closedWonCorrections.append(closedWonCorrections)
                totalAmount = totalAmount + corc.amount!
                count = count + 1
            }
        }
        return (amount: totalAmount, count: count)
    }
    
    
    @IBAction func selectCallPeriodTapped(_ sender: Any) {
    
        let rootViewController = SelectCallPeriodVC()
        rootViewController.delegate = self
        let navController = UINavigationController(rootViewController: rootViewController)
        self.present(navController, animated: true, completion: nil)
    }
    
    
    @IBAction func editCallByOpportunityTapped(_ sender: Any) {
        self.presentOppLedgerReviewVC()
    }
    
    @IBAction func submitCallButtonPressed(_ sender: Any) {
        self.uploadCall()
    }
    
    func getPastSummaryFrom(period: CallPeriod, summeries: [UserCallSummaryModel] ) -> UserCallSummaryModel? {
        
        let periodInfo = getStartAndEndTimestampFor(callPeriod: period,
                                                    timeZone: global_active_hq_time_zone)
        
        let relevantSummeries = summeries.filter( {$0.periodDescription == periodInfo.periodDescription} )
        if relevantSummeries.count == 0 {
            return nil
        }
        let mostRecentSummary = relevantSummeries.sorted(by: { $0.upsideSummaryUploadTimestamp! > $1.upsideSummaryUploadTimestamp! }).first
        return mostRecentSummary
    }
    
    
    // upsideSummaryUploadTimestamp
    // MARK: Helper method, move else where.
    private func getSummaryFrom(summary: UserCallSummaryModel,
                                upsideSummaryUploadTimestamp: Double,
                                callCorrectionIDs: [String]?,
                                total: Double,
                                totalRemaining: Double,
                                totalCorrections: Double,
                                totalWonCorrections: Double,
                                pastCloseWonTotal: Double?,
                                pastCloseWonCorrection: Double?,
                                pastUpsideUploadTime: Double?,
                                pastUserVelocityConfidence: Double?) -> UserCallSummaryModel {
        
        return UserCallSummaryModel(id: summary.id,
                                    userID: summary.userID,
                                    userEmail: summary.userEmail,
                                    sfdcSyncTimestamp: summary.sfdcSyncTimestamp,
                                    ledgerIDs: summary.ledgerIDs,
                                    closedWonTotalAmount: summary.closedWonTotalAmount,
                                    closedWonTotalCount: summary.closedWonTotalCount,
                                    closedWonSaaSAmount: summary.closedWonSaaSAmount,
                                    closedWonSaaSCount: summary.closedWonSaaSCount,
                                    closedWonComrcAmount: summary.closedWonComrcAmount,
                                    closedWonComrcCount: summary.closedWonComrcCount,
                                    closedWonOtherAmount: summary.closedWonOtherAmount,
                                    closedWonOtherCount: summary.closedWonOtherCount,
                                    callTotalAmount: summary.callTotalAmount,
                                    callTotalCount: summary.callTotalCount,
                                    callSaaSAmount: summary.callSaaSAmount,
                                    callSaaSCount: summary.callSaaSCount,
                                    callComrcAmount: summary.callComrcAmount,
                                    callComrcCount: summary.callComrcCount,
                                    callOtherAmount: summary.callOtherAmount,
                                    callOtherCount: summary.callOtherCount,
                                    upsideTotalAmount: summary.upsideTotalAmount,
                                    upsideTotalCount: summary.upsideTotalCount,
                                    upsideSaaSAmount: summary.upsideSaaSAmount,
                                    upsideSaaSCount: summary.upsideSaaSCount,
                                    upsideComrcAmount: summary.upsideComrcAmount,
                                    upsideComrcCount: summary.upsideComrcCount,
                                    upsideOtherAmount: summary.upsideOtherAmount,
                                    upsideOtherCount: summary.upsideOtherCount,
                                    stretchTotalAmount: summary.stretchTotalAmount,
                                    stretchTotalCount: summary.stretchTotalCount,
                                    stretchSaaSAmount: summary.stretchSaaSAmount,
                                    stretchSaaSCount: summary.stretchSaaSCount,
                                    stretchComrcAmount: summary.stretchComrcAmount,
                                    stretchComrcCount: summary.stretchComrcCount,
                                    stretchOtherAmount: summary.stretchOtherAmount,
                                    stretchOtherCount: summary.stretchOtherCount,
                                    omitTotalAmount: summary.omitTotalAmount,
                                    omitTotalCount: summary.omitTotalCount,
                                    omitSaaSAmount: summary.omitSaaSAmount,
                                    omitSaaSCount: summary.omitSaaSCount,
                                    omitComrcAmount: summary.omitComrcAmount,
                                    omitComrcCount: summary.omitComrcCount,
                                    omitOtherAmount: summary.omitOtherAmount,
                                    omitOtherCount: summary.omitOtherCount,
                                    closedLostTotalAmount: summary.closedLostTotalAmount,
                                    closedLostTotalCount: summary.closedLostTotalCount,
                                    closedLostSaaSAmount: summary.closedLostSaaSAmount,
                                    closedLostSaaSCount: summary.closedLostSaaSCount,
                                    closedLostComrcAmount: summary.closedLostComrcAmount,
                                    closedLostComrcCount: summary.closedLostComrcCount,
                                    closedLostOtherAmount: summary.closedLostOtherAmount,
                                    closedLostOtherCount: summary.closedLostOtherCount,
                                    businessDaysLeft: summary.businessDaysLeft,
                                    nonBusinessDaysLeft: summary.nonBusinessDaysLeft,
                                    totalDaysLeft: summary.totalDaysLeft,
                                    pipeBuildPast60Days: summary.pipeBuildPast60Days,
                                    pipeBuildCountPast60Days: summary.pipeBuildCountPast60Days,
                                    pipeBuildAveDealSizePast60Days: summary.pipeBuildAveDealSizePast60Days,
                                    pipeBuildMediumPast60Days: summary.pipeBuildMediumPast60Days,
                                    averageAmountPerBusinessDay60Days: summary.averageAmountPerBusinessDay60Days,
                                    averageCountPerBusinessDay60Days: summary.averageCountPerBusinessDay60Days,
                                    past30MeanDealVelocityBizDays: summary.past30MeanDealVelocityBizDays,
                                    past30MedianDealVelocityBizDays: summary.past30MedianDealVelocityBizDays,
                                    closeRateByamount: summary.closeRateByamount,
                                    closeRateByCount: summary.closeRateByCount,
                                    upsideNewOppForecastAmount: summary.upsideNewOppForecastAmount,
                                    userForecastConfidenceInVelocity: summary.userForecastConfidenceInVelocity,
                                    userVelocityForecast: summary.userVelocityForecast,
                                    periodStartTimestamp: summary.periodStartTimestamp,
                                    periodEndTimestamp: summary.periodEndTimestamp,
                                    periodDescription: summary.periodDescription,
                                    periodType: summary.periodType,
                                    upsideSummaryUploadTimestamp: upsideSummaryUploadTimestamp,
                                    callCorrectionIDs: callCorrectionIDs,
                                    quota: summary.quota,
                                    quotaToDate: summary.quotaToDate,
                                    quotaAttainment: summary.quotaAttainment,
                                    quotaToDateAttainment: summary.quotaToDateAttainment,
                                    total: total,
                                    totalRemaining: totalRemaining,
                                    totalCorrections: totalCorrections,
                                    totalWonCorrections: totalWonCorrections,
                                    pastSummaryID:summary.pastSummaryID,
                                    pastSummaryTotal: summary.pastSummaryTotal,
                                    pastSummaryTotalRemaining: summary.pastSummaryTotalRemaining,
                                    pastSummaryTotalCorrections: summary.pastSummaryTotalCorrections,
                                    pastSummaryCallCorrectionIDs: summary.pastSummaryCallCorrectionIDs,
                                    pastCloseWonTotal: pastCloseWonTotal,
                                    pastCloseWonCorrection: pastCloseWonCorrection,
                                    pastUpsideUploadTime: pastUpsideUploadTime,
                                    pastUserVelocityConfidence: pastUserVelocityConfidence)
        
    }
        

    // MARK: Helper method, move else where.
    private func getCallCorrectionFrom(correction: CallCorrectionModel,
                                       sfdcSyncTimestamp: Double,
                                       upsideLedgerUploadTimestamp: Double,
                                       callSummaryID: String) -> CallCorrectionModel {
        
        return CallCorrectionModel(id: correction.id,
                                   correctionDescription: correction.correctionDescription,
                                   amount: correction.amount,
                                   originalAmount: correction.originalAmount,
                                   type: correction.type,
                                   opportunityID: correction.opportunityID,
                                   opportunityStage: correction.opportunityStage,
                                   periodStartTimestamp: correction.periodStartTimestamp,
                                   periodEndTimestamp: correction.periodEndTimestamp,
                                   periodDescription: correction.periodDescription,
                                   periodType: correction.periodType,
                                   sfdcSyncTimestamp: sfdcSyncTimestamp,
                                   upsideLedgerUploadTimestamp: upsideLedgerUploadTimestamp,
                                   callSummaryID: callSummaryID)
    }
    
    // MARK: Helper method, move else where.
    private func getLedgerFrom(ledgerOpp: OpportunityLedgerModel, summaryDocID: String, uploadTimestamp: Double) -> OpportunityLedgerModel {
        
        return OpportunityLedgerModel(id: ledgerOpp.id, accountName: ledgerOpp.accountName, closeDate: ledgerOpp.closeDate, commerceBookings: ledgerOpp.commerceBookings, commerceBookingsCurrency: ledgerOpp.commerceBookingsCurrency, createdDate: ledgerOpp.createdDate, lastModifiedDate: ledgerOpp.lastModifiedDate, lastStageChangeDate: ledgerOpp.lastStageChangeDate, leadSource: ledgerOpp.leadSource, opportunityCurrency: ledgerOpp.opportunityCurrency, opportunityId: ledgerOpp.opportunityId, opportunityName: ledgerOpp.opportunityName, opportunityOwner: ledgerOpp.opportunityOwner, opportunityOwnerEmail: ledgerOpp.opportunityOwnerEmail, opportunityOwnerManager: ledgerOpp.opportunityOwnerManager, primaryProductFamily: ledgerOpp.primaryProductFamily, probability: ledgerOpp.probability, stage: ledgerOpp.stage, totalBookingsConverted: ledgerOpp.totalBookingsConverted, totalBookingsConvertedCurrency: ledgerOpp.totalBookingsConvertedCurrency, type: ledgerOpp.type, age: ledgerOpp.age, closeDateTimeStamp: ledgerOpp.closeDateTimeStamp, createdDateTimeStamp: ledgerOpp.createdDateTimeStamp, lastModifiedDateTimeStamp: ledgerOpp.lastModifiedDateTimeStamp, lastStageChangeDateTimeStamp: ledgerOpp.lastStageChangeDateTimeStamp, salesForcePreviousCallStatus: ledgerOpp.salesForcePreviousCallStatus, salesForceCurrentCallStatus: ledgerOpp.salesForceCurrentCallStatus, salesForcePreviousCallStatusIndex: ledgerOpp.salesForcePreviousCallStatusIndex, salesForceCurrentCallStatusIndex: ledgerOpp.salesForceCurrentCallStatusIndex, userPreviousCallStatus: ledgerOpp.userPreviousCallStatus, userCurrentCallStatus: ledgerOpp.userCurrentCallStatus, userPreviousCallStatusIndex: ledgerOpp.userPreviousCallStatusIndex, userCurrentCallStatusIndex: ledgerOpp.userCurrentCallStatusIndex, userInputTotalBookings: ledgerOpp.userInputTotalBookings, stageSortingIndex: ledgerOpp.stageSortingIndex, periodStartTimestamp: ledgerOpp.periodStartTimestamp, periodEndTimestamp: ledgerOpp.periodEndTimestamp, periodDescription: ledgerOpp.periodDescription, periodType: ledgerOpp.periodType, sfdcSyncTimestamp: ledgerOpp.sfdcSyncTimestamp, upsideLedgerUploadTimestamp: uploadTimestamp, callSummaryID: summaryDocID)
    }
    
    
    @IBAction func addCorrectionPressed(_ sender: Any) {

        let vc = CallCorrectionSelectionVC()
        vc.delegate = self
        let navController = UINavigationController(rootViewController: vc)
        self.present(navController, animated: true, completion: nil)

    }
    
    @IBAction func moreInfoCallByOpportunityBtnTapped(_ sender: Any) {
        print("get more info on call by opportunities.")
    }
    
}

// MARK: PassLoginSuccess Extension
extension UserCallVC: PassLoginSuccess {
    func passStatus(_ stat: Bool) {
        if stat == true {
            self.authCheck() // primary download method.
        } else {
            self.showUserLoginVC(autoFillPassword: true)
        }
    }
}

// MARK: Firebase reading and writing
extension UserCallVC {
    
    // MARK: Primary call to data base METHOD
    private func authCheck() {
        if Auth.auth().currentUser != nil { // do stuff
            // start downloading data
            self.fetchMostRecentOpportunityUploadLog()
        } else { // show user login
            self.showUserLoginVC(autoFillPassword: true)
        }
    }
    
    
    // order to call.
    
    // 1) fetch most recent opportunities upload log
    // 2) fetch past summeries
    // 3) fetch quotas
    // 4) fetch opportunties
    
    
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
    
    
    // 2) fetch past summeries
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
    }
    
    
    
    // 3) fetch quotas
    private func fetchAllMyQuotas() {
        
        let query = db.collection("quota_test")
            .whereField("email", isEqualTo: Auth.auth().currentUser!.email!)
        
        query.getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("No documents, fetchOpportunities()")
                return
            }
            self.myQuotas = documents.compactMap { (queryDocumentSnapshot) -> QuotaModel? in
                return try? queryDocumentSnapshot.data(as: QuotaModel.self)
            }
        }
    }

    
    // 4) fetch opportunties
    private func fetchOpportunities() {
        
        // stats we need. this is individual user, so
        // there shouldn't be to much data.
        // Go back 3 years, 3 years into the future.
        if Auth.auth().currentUser != nil { // has current user, fetch their data only.
            
            // Do this by;
            // 1) Getting the timestampes from
            // two years earlier and one year into the future:
            
            // three years ago date
            let startTimestamp = Double(Calendar.current.date(byAdding: .year, value: -3, to: Date())!.timeIntervalSince1970)
            // three years forward
            let endTimestamp = Double(Calendar.current.date(byAdding: .year, value: 3, to: Date())!.timeIntervalSince1970)
            
            // MARK: TODO - need to add cap / max download to this.
            // 2) Build query for opps for user within time period.
            let query = db.collection("opportunities")
                .whereField("opportunityOwnerEmail", isEqualTo: Auth.auth().currentUser!.email!) // only this users opps
                .whereField("closeDateTimeStamp", isGreaterThanOrEqualTo: startTimestamp) // opps after three years ago (close/date)
                .whereField("closeDateTimeStamp", isLessThanOrEqualTo: endTimestamp) // opps before one year from now (close/date)
                .order(by: "closeDateTimeStamp", descending: true) // order newest to oldest reps

            query.getDocuments { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("No documents, fetchOpportunities()")
                    return
                }
                
                // download succesfull, convert into swift objects...
                self.allUserOpportunities = documents.compactMap { (queryDocumentSnapshot) -> OpportunityModel? in
                    return try? queryDocumentSnapshot.data(as: OpportunityModel.self)
                }
            }
        }
    }
    
    
    
    private func uploadCall() {

        if self.currentSummary != nil && self.currentRelevantPeriodCallLedgerOpps != nil {
            let uploadTimestamp = Date().timeIntervalSince1970
            let batch = db.batch()
            let ledgerRef = db.collection("call_opportunity_ledgers")
            let summaryRef = db.collection("call_summeries").document()
            let correctionsRef = db.collection("call_corrections")//.document()
            
            // 2) Upload opp ledgers
            for opp in self.currentRelevantPeriodCallLedgerOpps! {
                let uploadOpp = self.getLedgerFrom(ledgerOpp: opp,
                                                   summaryDocID: summaryRef.documentID,
                                                   uploadTimestamp: uploadTimestamp)
                let oppRef = ledgerRef.document(uploadOpp.opportunityId!)
                do {
                    try batch.setData(from: uploadOpp, forDocument: oppRef)
                } catch {
                    // MARK: add ui alert
                    print("batch upload failed: try batch.setData(from: uploadOpp, forDocument: oppRef)")
                }
            }
            
            // 2) upload call corrections
            var correctionIDs: [String]?
            if self.callCorrections != nil && self.callCorrections!.count != 0 {
                correctionIDs = [String]()
                for correction in self.callCorrections! {
                    let ref = correctionsRef.document()
                    
                    let uploadCorrection = self.getCallCorrectionFrom(correction: correction,
                                                                      sfdcSyncTimestamp: self.opportunityUploadLogs![0].uploadTimestamp!,
                                                                      upsideLedgerUploadTimestamp: uploadTimestamp,
                                                                      callSummaryID: summaryRef.documentID)
                    
                    correctionIDs!.append(ref.documentID)
                    
                    do {
                        try batch.setData(from: uploadCorrection, forDocument: ref)
                    } catch {
                        // MARK: add ui alert
                        print("batch upload failed: try batch.setData(from: correction, forDocument: correctionsRef)")
                    }
                }
            }
            
            // 3) upload summary
            let totalCallAmount = self.currentSummary!.callTotalAmount! +
            self.currentSummary!.userVelocityForecast! +
            self.getTotalCorrectionAmount() +
            self.currentSummary!.closedWonTotalAmount!
            
            var pastCloseWonTotal: Double?
            var pastCloseWonCorrection: Double?
            var pastUpsideUploadTime: Double?
            var pastUserVelocityConfidence: Double?
            if self.pastSummary != nil {
                pastCloseWonTotal = self.pastSummary!.closedWonTotalAmount
                pastCloseWonCorrection = self.pastSummary!.closedWonTotalAmount // self.getTotalCorrectionWonAmount()
                pastUpsideUploadTime = self.pastSummary!.upsideSummaryUploadTimestamp!
                pastUserVelocityConfidence = self.pastSummary!.userForecastConfidenceInVelocity
            }
            
            
            
 
            let uploadSummary = getSummaryFrom(summary: self.currentSummary!,
                                               upsideSummaryUploadTimestamp: uploadTimestamp,
                                               callCorrectionIDs: correctionIDs,
                                               total: totalCallAmount,
                                               totalRemaining: totalCallAmount - self.currentSummary!.closedWonTotalAmount!,
                                               totalCorrections: self.getTotalCorrectionAmount(),
                                               totalWonCorrections: self.getTotalCorrectionWonAmount(),
                                               pastCloseWonTotal: pastCloseWonTotal,
                                               pastCloseWonCorrection: pastCloseWonCorrection,
                                               pastUpsideUploadTime: pastUpsideUploadTime,
                                               pastUserVelocityConfidence: pastUserVelocityConfidence)
            
            

            do {
                try batch.setData(from: uploadSummary, forDocument: summaryRef)
                // uploadSummary
                // try batch.setData(from: self.currentSummary!, forDocument: summaryRef)
            } catch {
                // MARK: add ui alert
                print("batch upload failed: try batch.setData(from: self.currentSummary!, forDocument: summaryRef)")
            }
            
            
            batch.commit() { err in
                if let err = err {
                    // MARK: add ui alert
                    print("Error:", err.localizedDescription)
                } else {
                    let dialogMessage = UIAlertController(title: "Success",
                                                          message: "You have made your call. Here is what you're calling etc.",
                                                          preferredStyle: .alert)
                    
              
                    let ok = UIAlertAction(title: "Ok",
                                           style: .default,
                                           handler: {(_: UIAlertAction!) in
                        
                        
                        self.dismissSelfAndData()
                        
                        // xyz abc
                        
                        
                        
                        
//                        self.pastSummeries?.removeAll()
//                        self.pastSummary = nil
//                        self.allUserOpportunities?.removeAll()
//                        self.callCorrections?.removeAll()
                        
                    })
                    dialogMessage.addAction(ok)
                    
                    self.present(dialogMessage, animated: true, completion: {
                        
                    })
                }
            }
        }
    }
    
    private func dismissSelfAndData() {
        self.dismiss(animated: true, completion: nil)
        self.delegate?.complete()
        // self.currentSummary = nil
        self.allUserOpportunities?.removeAll()// = nil
        // self.myQuotas = nil // DON't set to nil, that will trigger a data fetch.
        // self.pastSummary = nil
        // self.pastSummeries?.removeAll() // DON't set to nil, that will trigger a data fetch.
        //self.callPeriod = .thisQuarter
    }
    
}

/*
 }))
         alert.addAction(UIAlertAction(title: "Sign out",
                                       style: UIAlertActionStyle.default,
                                       handler: {(_: UIAlertAction!) in
                                         //Sign out action
         }))
 */

// MARK: TODO Move to correct location
// code currently working on to conver into all
// the needed formats to display / manage user input.
extension UserCallVC {

    
    // MARK: NEED to make a global function.
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
    
    private func getLedgerOppsWithAssignedCalls(startTimestamp: Double,
                                                endTimestamp: Double,
                                                newOpps: [OpportunityModel],
                                                previousLedgerOpps: [OpportunityLedgerModel]?) -> [OpportunityLedgerModel] {
        
        var returningCurrentOppLedgerArray = [OpportunityLedgerModel]()
        
        for opp in newOpps {
            
            var newLedgerOpp: OpportunityLedgerModel?
            let oppID = opp.opportunityId!
            
            if let pastOpp = previousLedgerOpps?.first(where: {$0.opportunityId == oppID}) { // we have a past opp
                
                newLedgerOpp = getNewLedgerOpportunityFrom(startTimestamp: startTimestamp,
                                                           endTimestamp: endTimestamp,
                                                           newOppData: opp,
                                                           pastLedgerOpp: pastOpp)
                
            } else { // there's no previous ledger entry
                
                newLedgerOpp = getNewLedgerOpportunityFrom(startTimestamp: startTimestamp,
                                                           endTimestamp: endTimestamp,
                                                           newOppData: opp,
                                                           pastLedgerOpp: nil)
            }
            
            returningCurrentOppLedgerArray.append(newLedgerOpp!)
        }
        
        return returningCurrentOppLedgerArray
    }
    
    private func getNewLedgerOpportunityFrom(startTimestamp: Double,
                                             endTimestamp: Double,
                                             newOppData: OpportunityModel,
                                             pastLedgerOpp: OpportunityLedgerModel?) -> OpportunityLedgerModel {
        
        let currentCall = getStandardCallFrom(startTimestamp: startTimestamp,
                                              endTimestamp: endTimestamp,
                                              opp: newOppData)
        
        let salesForceCurrentCallStatusFunc = currentCall.call
        let salesForceCurrentCallStatusIndexFunc = currentCall.callIndex
        
        // MARK: Previous logic
        // nil is default value for when there's no previous ledger
        
        // MARK: New logic
        // when there's no previous ledger, assume all values current and previous are as per sales force.
        var salesForcePreviousCallStatusFunc = salesForceCurrentCallStatusFunc
        var salesForcePreviousCallStatusIndexFunc = salesForceCurrentCallStatusIndexFunc
        var userPreviousCallStatusFunc = salesForceCurrentCallStatusFunc
        var userPreviousCallStatusIndexFunc = salesForceCurrentCallStatusIndexFunc
        
        if pastLedgerOpp != nil {
            salesForcePreviousCallStatusFunc = pastLedgerOpp!.salesForceCurrentCallStatus!
            salesForcePreviousCallStatusIndexFunc = pastLedgerOpp!.salesForceCurrentCallStatusIndex!
            userPreviousCallStatusFunc = pastLedgerOpp!.userCurrentCallStatus!
            userPreviousCallStatusIndexFunc = pastLedgerOpp!.userCurrentCallStatusIndex!
        }
        
        let timezone = TimeZone(identifier: "America/Chicago")!
        let periodInfo = self.getStartAndEndTimestampFor(callPeriod: self.callPeriod!, timeZone: timezone)
        
        // MARK: TODO - more of the user data points shuold be nil to start with.
        return OpportunityLedgerModel(id: newOppData.id,
                                      accountName: newOppData.accountName,
                                      closeDate: newOppData.closeDate,
                                      commerceBookings: newOppData.commerceBookings,
                                      commerceBookingsCurrency: newOppData.commerceBookingsCurrency,
                                      createdDate: newOppData.createdDate,
                                      lastModifiedDate: newOppData.lastModifiedDate,
                                      lastStageChangeDate: newOppData.lastStageChangeDate,
                                      leadSource: newOppData.leadSource,
                                      opportunityCurrency: newOppData.opportunityCurrency,
                                      opportunityId: newOppData.opportunityId,
                                      opportunityName: newOppData.opportunityName,
                                      opportunityOwner: newOppData.opportunityOwner,
                                      opportunityOwnerEmail: newOppData.opportunityOwnerEmail,
                                      opportunityOwnerManager: newOppData.opportunityOwnerManager,
                                      primaryProductFamily: newOppData.primaryProductFamily,
                                      probability: newOppData.probability,
                                      stage: newOppData.stage,
                                      totalBookingsConverted: newOppData.totalBookingsConverted,
                                      totalBookingsConvertedCurrency: newOppData.totalBookingsConvertedCurrency,
                                      type: newOppData.type,
                                      age: newOppData.age,
                                      closeDateTimeStamp: newOppData.closeDateTimeStamp,
                                      createdDateTimeStamp: newOppData.createdDateTimeStamp,
                                      lastModifiedDateTimeStamp: newOppData.lastModifiedDateTimeStamp,
                                      lastStageChangeDateTimeStamp: newOppData.lastStageChangeDateTimeStamp,
                                      salesForcePreviousCallStatus: salesForcePreviousCallStatusFunc,
                                      salesForceCurrentCallStatus: salesForceCurrentCallStatusFunc,
                                      salesForcePreviousCallStatusIndex: salesForcePreviousCallStatusIndexFunc,
                                      salesForceCurrentCallStatusIndex: salesForceCurrentCallStatusIndexFunc,
                                      userPreviousCallStatus: userPreviousCallStatusFunc,
                                      userCurrentCallStatus: userPreviousCallStatusFunc, // hasn't been changed yet.
                                      userPreviousCallStatusIndex: userPreviousCallStatusIndexFunc,
                                      userCurrentCallStatusIndex: userPreviousCallStatusIndexFunc,
                                      userInputTotalBookings: nil,
                                      stageSortingIndex: self.getSortingIndexFor(stage: newOppData.stage!),
                                      periodStartTimestamp: periodInfo.startTS,
                                      periodEndTimestamp: periodInfo.endTS,
                                      periodDescription: periodInfo.periodDescription,
                                      periodType: periodInfo.type,
                                      sfdcSyncTimestamp: self.opportunityUploadLogs![0].uploadTimestamp!,
                                      upsideLedgerUploadTimestamp: nil) // hasn't been changed yet.
        
    }
}

extension UserCallVC: PassOpportunityLedgersDelegate {
    
    // decided to pass in a subset and pass back a subset.
    // other option is to pass in the full data set and do the filtering
    // (i.e don't included won/lost) in the edit bookings.... this seems better.
    // func passOpportunities(_ opps: [OpportunityLedgerModel]) {
    func passOpportunities(_ opps: [OpportunityLedgerModel], corrections: [CallCorrectionModel]?) {
        // do something with the passed back opps.
        self.updateOpportunitiesWithCorrections(opps, corrections: corrections)
    }
}


// MARK: Extension for methods that need to be moved global
// or at least put somewhere else (maybe).
extension UserCallVC {
    
    // MARK: TODO Move else where
    private func getSortingIndexFor(stage: String) -> Int {
        
        if stage.lowercased() == "closed lost" {
            return 0
        } else if stage.lowercased() == "create" {
            return 1
        } else if stage.lowercased() == "qualify" {
            return 2
        } else if stage.lowercased() == "develop" {
            return 3
        } else if stage.lowercased() == "prove" {
            return 4
        } else if stage.lowercased() == "agreements" {
            return 5
        } else if stage.lowercased() == "closed won" {
            return 6
        }
        
        return -1
    }
    
    // assuming current quarter at the moment
    private func getStandardCallFrom(startTimestamp: Double,
                                     endTimestamp: Double,
                                     opp: OpportunityModel) -> (call: String, callIndex: Int) {

        if opp.closeDateTimeStamp! <= endTimestamp { // there should always be a close date time stamp - but this isn't safe.
            
            if opp.stage!.lowercased() == "closed won" {
                if opp.closeDateTimeStamp! < startTimestamp { // closed won prior to the start of the time preiod.
                    return (call: "Closed Won - Previous", callIndex: 7)
                }
                return (call: "Closed Won", callIndex: 6) // closed won within the time preiod.
            }
            
            if opp.stage!.lowercased() == "closed lost" {
                if opp.closeDateTimeStamp! < startTimestamp { // closed lost prior to the start of the time preiod.
                    return (call: "Closed Lost - Previous", callIndex: 0)
                }
                return (call: "Closed Lost", callIndex: 1)
            }
            
            if opp.stage!.lowercased() == "agreements" {
                return (call: "Call", callIndex: 5)
            }
            if opp.stage!.lowercased() == "prove" || opp.stage!.lowercased() == "develop" {
                return (call: "Upside", callIndex: 4)
            }
            if opp.stage!.lowercased() == "qualify" {
                return (call: "Stretch", callIndex: 3)
            } else { // it's in create, return omit
                return (call: "Omit", callIndex: 2)
            }
        } else { // close date is beyond period.
            return (call: "Omit", callIndex: 2)
        }
    }
}


// MARK: TEST METHODS
extension UserCallVC {
    
    
    // MARK: SEVERAL methods relying on this.
    // review this is doc to decide how to handle all scenarios / trickle down affect:
    // https://sarunw.com/posts/getting-number-of-days-between-two-dates/
    
    /*
     This is an inefficient method. Need to make
     alogorith rather than a loop. But this will suffice
     for now. Although once made more complex, taking in
     leave time and public holidays, a loop may be easier
     rather than subtracting those days as part of the algorithm.
      */
    func getWeekdayCount(startDate: Date, endDate: Date, timeZone: TimeZone) -> (businessDays: Double, nonBusinessDays: Double, totalDays: Double) {
        var cal = Calendar.init(identifier: .gregorian)
        cal.timeZone = timeZone // default passed in as as (CST / Dallas time)
        
        
//        print("TESTING HERE...")
//        print(startDate)
//        print(endDate)
        
        
        // portion left in day, based on past in timezone (CST / Dallas time throughout app at the moment)
        var portionLeft = 0.0 as Double
        let startOfDay = getStartOfDay(date: Date(), timeZone: timeZone)
        let endOfDay = getEndOfDay(date: Date(), timeZone: timeZone)
        let now = Date().timeIntervalSince1970
        let portionThroughDay = ((now - startOfDay) / (endOfDay - startOfDay))
        portionLeft = 1.0 - portionThroughDay
        var bussinessDays = 0.0
        var nonBussinessDays = 0.0

        // now add to either weekday or biz day based on blah blah
        if cal.isDateInWeekend(startDate) { // add to business day
            nonBussinessDays = portionLeft
        } else { // add to non business day
            bussinessDays = portionLeft
        }
        
        var dayComponent = DateComponents()
        dayComponent.day = 1
        var dayLoopComponent = DateComponents()
        dayLoopComponent.day = -1
        let endLoopDate = cal.date(byAdding: dayLoopComponent, to: endDate)!
        
        var testDate = startDate
        
        
        while testDate <= endLoopDate {
            testDate = cal.date(byAdding: dayComponent, to: testDate)!
            // print("testDate =", testDate)
            if cal.isDateInWeekend(testDate) { //
                nonBussinessDays = nonBussinessDays + 1.0
            } else {
                bussinessDays = bussinessDays + 1.0
            }
        }
        
        
        /*
        repeat {
            
            testDate = cal.date(byAdding: dayComponent, to: testDate)!
            // print("testDate =", testDate)
            if cal.isDateInWeekend(testDate) { //
                nonBussinessDays = nonBussinessDays + 1.0
            } else {
                bussinessDays = bussinessDays + 1.0
            }

        } while testDate <= endLoopDate
         */

        return (businessDays: bussinessDays,
                nonBusinessDays: nonBussinessDays,
                totalDays: bussinessDays + nonBussinessDays)
    }
    
    func opportunityWasCreatedWithin(startTimestamp: Double, endTimestamp: Double, opp: OpportunityModel) -> Bool {
        
        let createTimestamp = opp.createdDateTimeStamp!
        
        if createTimestamp <= endTimestamp && createTimestamp >= startTimestamp {
            return true
        } else {
            return false
        }
        
    }
    
    func getPipeBuildPassed(days: Int,
                            timeZone: TimeZone,
                            opportunities: [OpportunityModel]) -> (amount: Double,
                                                                   count: Int,
                                                                   averageSize: Double,
                                                                   medianSize: Double,
                                                                   businessDays: Double,
                                                                   averageAmountPerBusinessDay: Double,
                                                                   averageCountPerBusinessDay: Double) {
        
        let startOfDay = self.getStartOfDay(date: Date(),
                                            timeZone: timeZone) // i.e end date (don't include today) // use < rather than <=
        var cal = Calendar.current
        cal.timeZone = timeZone
        var dayComponent = DateComponents()
        dayComponent.day = -days
        let startDate = cal.date(byAdding: dayComponent, to: Date(timeIntervalSince1970: startOfDay))!.timeIntervalSince1970
        
        let daysCount = self.getWeekdayCount(startDate: Date(timeIntervalSince1970: startDate),
                                             endDate: Date(timeIntervalSince1970: startOfDay),
                                             timeZone: timeZone)
        
        let pipeBuiltBetween = getPipeBuiltBetween(startDate: startDate,
                                                   endDate: startOfDay,
                                                   timeZone: timeZone,
                                                   opportunities: opportunities)
        
        return (amount: pipeBuiltBetween.amount,
                count: pipeBuiltBetween.count,
                averageSize: pipeBuiltBetween.averageSize,
                medianSize: pipeBuiltBetween.medianSize,
                businessDays: daysCount.businessDays,
                averageAmountPerBusinessDay: pipeBuiltBetween.amount / daysCount.businessDays,
                averageCountPerBusinessDay: Double(pipeBuiltBetween.count) / daysCount.businessDays)
    }

    // returns a medium amount which is the medium commerce amount and medium bookings amount combined... i think this is better for calculations. but the medium of them combined prior to getting the medium m
    func getPipeBuiltBetween(startDate: Double,
                             endDate: Double,
                             timeZone: TimeZone,
                             opportunities: [OpportunityModel]) -> (amount: Double,
                                                                    count: Int,
                                                                    averageSize: Double,
                                                                    medianSize: Double) {

        var amount = 0.0
        var count = 0
        
        var oppsWithinRange = [OpportunityModel]()
        
        for opp in opportunities {
            
            if self.opportunityWasCreatedWithin(startTimestamp: startDate, endTimestamp: endDate, opp: opp) {
                oppsWithinRange.append(opp)
                let totalOppValue = opp.totalBookingsConverted! + opp.commerceBookings!
                amount = amount + totalOppValue
                count = count + 1
            }
        }
        
        let amountTotals = oppsWithinRange.map { $0.totalBookingsConverted! }
        let comrcAmountTotals = oppsWithinRange.map { $0.totalBookingsConverted! }
        let amountMedian = calculateMedian(array: amountTotals)
        let comrcAmountMedian = calculateMedian(array: comrcAmountTotals)

        return (amount: amount,
                count: count,
                averageSize: amount / Double(count),
                medianSize: amountMedian + comrcAmountMedian)
    }
    
    func calculateMedian(array: [Double]) -> Double {

        let sorted = array.sorted()
        if sorted.count % 2 == 0 {
            return Double((sorted[(sorted.count / 2)] + sorted[(sorted.count / 2) - 1])) / 2
        } else {
            return Double(sorted[(sorted.count - 1) / 2])
        }
    }
    
    
    func calculateMedian(array: [Int]) -> Float {
        let sorted = array.sorted()
        if sorted.count % 2 == 0 {
            return Float((sorted[(sorted.count / 2)] + sorted[(sorted.count / 2) - 1])) / 2
        } else {
            return Float(sorted[(sorted.count - 1) / 2])
        }
    }
    
    func calculateMean(array: [Int]) -> Double {
        
        // Calculate sum ot items with reduce function
        let sum = array.reduce(0, { a, b in
            return a + b
        })
        
        let mean = Double(sum) / Double(array.count)
        return Double(mean)
    }
    
    func calculateMean(array: [Double]) -> Double {
        
        // Calculate sum ot items with reduce function
        let sum = array.reduce(0, { a, b in
            return a + b
        })
        
        let mean = Double(sum) / Double(array.count)
        return Double(mean)
    }
}



// MARK: TODO
// methods to setup summary. may move to another class (like the summary struct)
extension UserCallVC {
    
    // MARK: TODO first test method to build
    // MARK: TODO fix variable names passed in.
    // (amount: Double, count: Int, averageSize: Double, medianSize: Double)
    private func getUserCallSumaryFrom(oppLedgers: [OpportunityLedgerModel],
                                       businessDaysLeft: Double,
                                       nonBusinessDaysLeft: Double,
                                       totalDaysLeft: Double,
                                       pipeBuildPast60DayAmount: Double,
                                       pipeBuildPast60DayCount: Int,
                                       pipeBuildPast60DAyaverageSize: Double,
                                       pipeBuildPast60DayMedianSize: Double,
                                       past30MeanDealVelocityBizDays: Double,
                                       past30MedianDealVelocityBizDays: Double,
                                       pipeBuildMediumPast60Days: Double,
                                       averageCountPerBusinessDay60Days: Double,
                                       closeRateByamount: Double,
                                       closeRateByCount: Double,
                                       upsideNewOppForecastAmount: Double) -> UserCallSummaryModel {

        var closedWonTotalAmount = 0.0
        var closedWonTotalCount:Int = 0
        var closedWonSaaSAmount = 0.0
        var closedWonSaaSCount:Int = 0
        var closedWonComrcAmount = 0.0
        var closedWonComrcCount:Int = 0
        var closedWonOtherAmount = 0.0
        var closedWonOtherCount:Int = 0
        
        var callTotalAmount = 0.0
        var callTotalCount:Int = 0
        var callSaaSAmount = 0.0
        var callSaaSCount:Int = 0
        var callComrcAmount = 0.0
        var callComrcCount:Int = 0
        var callOtherAmount = 0.0
        var callOtherCount:Int = 0
        
        var upsideTotalAmount = 0.0
        var upsideTotalCount:Int = 0
        var upsideSaaSAmount = 0.0
        var upsideSaaSCount:Int = 0
        var upsideComrcAmount = 0.0
        var upsideComrcCount:Int = 0
        var upsideOtherAmount = 0.0
        var upsideOtherCount:Int = 0

        var stretchTotalAmount = 0.0
        var stretchTotalCount:Int = 0
        var stretchSaaSAmount = 0.0
        var stretchSaaSCount:Int = 0
        var stretchComrcAmount = 0.0
        var stretchComrcCount:Int = 0
        var stretchOtherAmount = 0.0
        var stretchOtherCount:Int = 0
        
        var omitTotalAmount = 0.0
        var omitTotalCount:Int = 0
        var omitSaaSAmount = 0.0
        var omitSaaSCount:Int = 0
        var omitComrcAmount = 0.0
        var omitComrcCount:Int = 0
        var omitOtherAmount = 0.0
        var omitOtherCount:Int = 0
        
        var closedLostTotalAmount = 0.0
        var closedLostTotalCount:Int = 0
        var closedLostSaaSAmount = 0.0
        var closedLostSaaSCount:Int = 0
        var closedLostComrcAmount = 0.0
        var closedLostComrcCount:Int = 0
        var closedLostOtherAmount = 0.0
        var closedLostOtherCount:Int = 0

        for ledger in oppLedgers {
            
            let productRollUp = self.getProductRoleUp(oppLedger: ledger)
            if ledger.userCurrentCallStatus!.lowercased() == "closed won" {
                // total
                closedWonTotalAmount = closedWonTotalAmount + (ledger.totalBookingsConverted! + ledger.commerceBookings!) // not safe
                closedWonTotalCount = closedWonTotalCount + 1
                // SaaS
                if productRollUp.lowercased() == "saas" {
                    closedWonSaaSAmount = closedWonSaaSAmount + (ledger.totalBookingsConverted!) // not safe
                    closedWonSaaSCount = closedWonSaaSCount + 1
                }
                // commerce
                closedWonComrcAmount = closedWonComrcAmount + ledger.commerceBookings! // not safe
                if ledger.commerceBookings! > 0.0 {
                    closedWonComrcCount = closedWonComrcCount + 1
                }
                // other
                if productRollUp.lowercased() == "other" {
                    closedWonOtherAmount = closedWonOtherAmount + (ledger.totalBookingsConverted!) // not safe
                    closedWonOtherCount = closedWonOtherCount + 1
                }
                
            } else if ledger.userCurrentCallStatus!.lowercased() == "call" {
                // total
                callTotalAmount = callTotalAmount + (ledger.totalBookingsConverted! + ledger.commerceBookings!) // not safe
                callTotalCount = callTotalCount + 1
                // SaaS
                if productRollUp.lowercased() == "saas" {
                    callSaaSAmount = callSaaSAmount + (ledger.totalBookingsConverted!) // not safe
                    callSaaSCount = callSaaSCount + 1
                }
                // commerce
                callComrcAmount = callComrcAmount + ledger.commerceBookings! // not safe
                if ledger.commerceBookings! > 0.0 {
                    callComrcCount = callComrcCount + 1
                }
                // other
                if productRollUp.lowercased() == "other" {
                    callOtherAmount = callOtherAmount + (ledger.totalBookingsConverted!) // not safe
                    callOtherCount = callOtherCount + 1
                }
            } else if ledger.userCurrentCallStatus!.lowercased() == "upside" {
                // total
                upsideTotalAmount = upsideTotalAmount + (ledger.totalBookingsConverted! + ledger.commerceBookings!) // not safe
                upsideTotalCount = upsideTotalCount + 1
                // SaaS
                if productRollUp.lowercased() == "saas" {
                    upsideSaaSAmount = upsideSaaSAmount + (ledger.totalBookingsConverted!) // not safe
                    upsideSaaSCount = upsideSaaSCount + 1
                }
                // commerce
                upsideComrcAmount = upsideComrcAmount + ledger.commerceBookings! // not safe
                if ledger.commerceBookings! > 0.0 {
                    upsideComrcCount = upsideComrcCount + 1
                }
                // other
                if productRollUp.lowercased() == "other" {
                    upsideOtherAmount = upsideOtherAmount + (ledger.totalBookingsConverted!) // not safe
                    upsideOtherCount = upsideOtherCount + 1
                }
            } else if ledger.userCurrentCallStatus!.lowercased() == "stretch" {
                // total
                stretchTotalAmount = stretchTotalAmount + (ledger.totalBookingsConverted! + ledger.commerceBookings!) // not safe
                stretchTotalCount = stretchTotalCount + 1
                // SaaS
                if productRollUp.lowercased() == "saas" {
                    stretchSaaSAmount = stretchSaaSAmount + (ledger.totalBookingsConverted!) // not safe
                    stretchSaaSCount = stretchSaaSCount + 1
                }
                // commerce
                stretchComrcAmount = stretchComrcAmount + ledger.commerceBookings! // not safe
                if ledger.commerceBookings! > 0.0 {
                    stretchComrcCount = stretchComrcCount + 1
                }
                // other
                if productRollUp.lowercased() == "other" {
                    stretchOtherAmount = stretchOtherAmount + (ledger.totalBookingsConverted!) // not safe
                    stretchOtherCount = stretchOtherCount + 1
                }
            } else if ledger.userCurrentCallStatus!.lowercased() == "omit" {
                // total
                omitTotalAmount = omitTotalAmount + (ledger.totalBookingsConverted! + ledger.commerceBookings!) // not safe
                omitTotalCount = omitTotalCount + 1
                // SaaS
                if productRollUp.lowercased() == "saas" {
                    omitSaaSAmount = omitSaaSAmount + (ledger.totalBookingsConverted!) // not safe
                    omitSaaSCount = omitSaaSCount + 1
                }
                // commerce
                omitComrcAmount = omitComrcAmount + ledger.commerceBookings! // not safe
                if ledger.commerceBookings! > 0.0 {
                    omitComrcCount = omitComrcCount + 1
                }
                // other
                if productRollUp.lowercased() == "other" {
                    omitOtherAmount = omitOtherAmount + (ledger.totalBookingsConverted!) // not safe
                    omitOtherCount = omitOtherCount + 1
                }
            } else if ledger.userCurrentCallStatus!.lowercased() == "closed lost" {
                // total
                closedLostTotalAmount = closedLostTotalAmount + (ledger.totalBookingsConverted! + ledger.commerceBookings!) // not safe
                closedLostTotalCount = closedLostTotalCount + 1
                // SaaS
                if productRollUp.lowercased() == "saas" {
                    closedLostSaaSAmount = closedLostSaaSAmount + (ledger.totalBookingsConverted!) // not safe
                    closedLostSaaSCount = closedLostSaaSCount + 1
                }
                // commerce
                closedLostComrcAmount = closedLostComrcAmount + ledger.commerceBookings! // not safe
                if ledger.commerceBookings! > 0.0 {
                    closedLostComrcCount = closedLostComrcCount + 1
                }
                // other
                if productRollUp.lowercased() == "other" {
                    closedLostOtherAmount = closedLostOtherAmount + (ledger.totalBookingsConverted!) // not safe
                    closedLostOtherCount = closedLostOtherCount + 1
                }
            }
        }
        
        let confidence = Double(pipeBuildVelocitySlider.value)
        
        // MARK: TODO need to make the time configurable.
        let timezone = TimeZone(identifier: "America/Chicago")!
        let periodInfo = getStartAndEndTimestampFor(callPeriod: self.callPeriod!, timeZone: timezone)
        let ledgerIDs = self.currentRelevantPeriodCallLedgerOpps!.map { $0.opportunityId! }
        
        // MARK: Working here to solve for
        /*
         let quota: Double?
         let quotaToDate: Double?
         let quotaAttainment: Double?
         let quotaToDateAttainment: Double?
         */
        
        let quotaData = getQuotaDataFrom(quotas: self.myQuotas!,
                                         callPeriod: self.callPeriod!)
        
        let quotaAttainment = closedWonTotalAmount / quotaData.quota
        let quotaToDateAttainment = closedWonTotalAmount / quotaData.quotaToDate
        
    
        /* Need to figure our where to add this. */
        /*
        let totalCallAmount = self.currentSummary!.callTotalAmount! +
        self.currentSummary!.userVelocityForecast! +
        self.getTotalCorrectionAmount() +
        self.currentSummary!.closedWonTotalAmount!
         */
        
        // abc here
        // this is verbose and can be cleaned, but adding if statement for if there's a past summary or not.
        
        /*
         let pastSummaryID: String?
         let pastSummaryTotal: Double?

         let pastSummaryTotalRemaining: Double?
         let pastSummaryTotalCorrections: Double?
         
         let pastSummaryCallCorrectionIDs: [String]?
         */
        
        
        if pastSummary == nil {
            
            print("&&&&&&&&&&&&&&&&&&&")
            print("WE DON't have a past summary A PAST SUMMARY")
            
            let summary = UserCallSummaryModel(id: nil, userID: Auth.auth().currentUser!.uid, userEmail: Auth.auth().currentUser!.email, sfdcSyncTimestamp: opportunityUploadLogs![0].uploadTimestamp!, ledgerIDs: ledgerIDs, closedWonTotalAmount: closedWonTotalAmount, closedWonTotalCount: closedWonTotalCount, closedWonSaaSAmount: closedWonSaaSAmount, closedWonSaaSCount: closedWonSaaSCount, closedWonComrcAmount: closedWonComrcAmount, closedWonComrcCount: closedWonComrcCount, closedWonOtherAmount: closedWonOtherAmount, closedWonOtherCount: closedWonOtherCount, callTotalAmount: callTotalAmount, callTotalCount: callTotalCount, callSaaSAmount: callSaaSAmount, callSaaSCount: callSaaSCount, callComrcAmount: callComrcAmount, callComrcCount: callComrcCount, callOtherAmount: callOtherAmount, callOtherCount: callOtherCount, upsideTotalAmount: upsideTotalAmount, upsideTotalCount: upsideTotalCount, upsideSaaSAmount: upsideSaaSAmount, upsideSaaSCount: upsideSaaSCount, upsideComrcAmount: upsideComrcAmount, upsideComrcCount: upsideComrcCount, upsideOtherAmount: upsideOtherAmount, upsideOtherCount: upsideOtherCount, stretchTotalAmount: stretchTotalAmount, stretchTotalCount: stretchTotalCount, stretchSaaSAmount: stretchSaaSAmount, stretchSaaSCount: stretchSaaSCount, stretchComrcAmount: stretchComrcAmount, stretchComrcCount: stretchComrcCount, stretchOtherAmount: stretchOtherAmount, stretchOtherCount: stretchOtherCount, omitTotalAmount: omitTotalAmount, omitTotalCount: omitTotalCount, omitSaaSAmount: omitSaaSAmount, omitSaaSCount: omitSaaSCount, omitComrcAmount: omitComrcAmount, omitComrcCount: omitComrcCount, omitOtherAmount: omitOtherAmount, omitOtherCount: omitOtherCount, closedLostTotalAmount: closedLostTotalAmount, closedLostTotalCount: closedLostTotalCount, closedLostSaaSAmount: closedLostSaaSAmount, closedLostSaaSCount: closedLostSaaSCount, closedLostComrcAmount: closedLostComrcAmount, closedLostComrcCount: closedLostComrcCount, closedLostOtherAmount: closedLostOtherAmount, closedLostOtherCount: closedLostOtherCount, businessDaysLeft: businessDaysLeft, nonBusinessDaysLeft: nonBusinessDaysLeft, totalDaysLeft: totalDaysLeft, pipeBuildPast60Days: pipeBuildPast60DayAmount, pipeBuildCountPast60Days: pipeBuildPast60DayCount, pipeBuildAveDealSizePast60Days: pipeBuildPast60DAyaverageSize, pipeBuildMediumPast60Days: pipeBuildPast60DayMedianSize, averageAmountPerBusinessDay60Days: pipeBuildMediumPast60Days, averageCountPerBusinessDay60Days: averageCountPerBusinessDay60Days, past30MeanDealVelocityBizDays: past30MeanDealVelocityBizDays, past30MedianDealVelocityBizDays: past30MedianDealVelocityBizDays, closeRateByamount: closeRateByamount, closeRateByCount: closeRateByCount, upsideNewOppForecastAmount: upsideNewOppForecastAmount, userForecastConfidenceInVelocity: confidence, userVelocityForecast: (confidence * upsideNewOppForecastAmount), periodStartTimestamp: periodInfo.startTS, periodEndTimestamp: periodInfo.endTS, periodDescription: periodInfo.periodDescription, periodType: periodInfo.type, upsideSummaryUploadTimestamp: nil, quota: quotaData.quota, quotaToDate: quotaData.quotaToDate, quotaAttainment: quotaAttainment, quotaToDateAttainment: quotaToDateAttainment, total: nil, totalRemaining: nil, totalCorrections: nil, totalWonCorrections: nil, pastSummaryID: nil, pastSummaryTotal: nil, pastSummaryTotalRemaining: nil, pastSummaryTotalCorrections: nil, pastSummaryCallCorrectionIDs: nil, pastCloseWonTotal: nil, pastCloseWonCorrection: nil, pastUpsideUploadTime: nil, pastUserVelocityConfidence: nil)
            
            
            
            
            /*
             let pastCloseWonTotal: Double?
             let pastCloseWonCorrection: Double?
             let pastUpsideUploadTime: Double?
             let pastUserVelocityConfidence: Double?
             */

            
            
            return summary
            
        } else {
            
            print("&&&&&&&&&&&&&&&&&&&")
            print("THERE's NO PAST SUMMARY")
            
            let pastID = pastSummary!.id
            let pastTotal = pastSummary!.total
            let pastTotalRemaining = pastSummary!.totalRemaining
            let pastTotalCorrections = pastSummary!.totalCorrections
            let pastCallCorrectionIDs = pastSummary!.callCorrectionIDs
            
//            print("pastID:", pastID)
//            print("pastTotal:", pastTotal)
//            print("pastTotalRemaining:", pastTotalRemaining)
//            print("pastTotalCorrections:", pastTotalCorrections)
//            print("pastCallCorrectionIDs:", pastCallCorrectionIDs)
            
            let summary = UserCallSummaryModel(id: nil, userID: Auth.auth().currentUser!.uid, userEmail: Auth.auth().currentUser!.email, sfdcSyncTimestamp: opportunityUploadLogs![0].uploadTimestamp!, ledgerIDs: ledgerIDs, closedWonTotalAmount: closedWonTotalAmount, closedWonTotalCount: closedWonTotalCount, closedWonSaaSAmount: closedWonSaaSAmount, closedWonSaaSCount: closedWonSaaSCount, closedWonComrcAmount: closedWonComrcAmount, closedWonComrcCount: closedWonComrcCount, closedWonOtherAmount: closedWonOtherAmount, closedWonOtherCount: closedWonOtherCount, callTotalAmount: callTotalAmount, callTotalCount: callTotalCount, callSaaSAmount: callSaaSAmount, callSaaSCount: callSaaSCount, callComrcAmount: callComrcAmount, callComrcCount: callComrcCount, callOtherAmount: callOtherAmount, callOtherCount: callOtherCount, upsideTotalAmount: upsideTotalAmount, upsideTotalCount: upsideTotalCount, upsideSaaSAmount: upsideSaaSAmount, upsideSaaSCount: upsideSaaSCount, upsideComrcAmount: upsideComrcAmount, upsideComrcCount: upsideComrcCount, upsideOtherAmount: upsideOtherAmount, upsideOtherCount: upsideOtherCount, stretchTotalAmount: stretchTotalAmount, stretchTotalCount: stretchTotalCount, stretchSaaSAmount: stretchSaaSAmount, stretchSaaSCount: stretchSaaSCount, stretchComrcAmount: stretchComrcAmount, stretchComrcCount: stretchComrcCount, stretchOtherAmount: stretchOtherAmount, stretchOtherCount: stretchOtherCount, omitTotalAmount: omitTotalAmount, omitTotalCount: omitTotalCount, omitSaaSAmount: omitSaaSAmount, omitSaaSCount: omitSaaSCount, omitComrcAmount: omitComrcAmount, omitComrcCount: omitComrcCount, omitOtherAmount: omitOtherAmount, omitOtherCount: omitOtherCount, closedLostTotalAmount: closedLostTotalAmount, closedLostTotalCount: closedLostTotalCount, closedLostSaaSAmount: closedLostSaaSAmount, closedLostSaaSCount: closedLostSaaSCount, closedLostComrcAmount: closedLostComrcAmount, closedLostComrcCount: closedLostComrcCount, closedLostOtherAmount: closedLostOtherAmount, closedLostOtherCount: closedLostOtherCount, businessDaysLeft: businessDaysLeft, nonBusinessDaysLeft: nonBusinessDaysLeft, totalDaysLeft: totalDaysLeft, pipeBuildPast60Days: pipeBuildPast60DayAmount, pipeBuildCountPast60Days: pipeBuildPast60DayCount, pipeBuildAveDealSizePast60Days: pipeBuildPast60DAyaverageSize, pipeBuildMediumPast60Days: pipeBuildPast60DayMedianSize, averageAmountPerBusinessDay60Days: pipeBuildMediumPast60Days, averageCountPerBusinessDay60Days: averageCountPerBusinessDay60Days, past30MeanDealVelocityBizDays: past30MeanDealVelocityBizDays, past30MedianDealVelocityBizDays: past30MedianDealVelocityBizDays, closeRateByamount: closeRateByamount, closeRateByCount: closeRateByCount, upsideNewOppForecastAmount: upsideNewOppForecastAmount, userForecastConfidenceInVelocity: confidence, userVelocityForecast: (confidence * upsideNewOppForecastAmount), periodStartTimestamp: periodInfo.startTS, periodEndTimestamp: periodInfo.endTS, periodDescription: periodInfo.periodDescription, periodType: periodInfo.type, upsideSummaryUploadTimestamp: nil, quota: quotaData.quota, quotaToDate: quotaData.quotaToDate, quotaAttainment: quotaAttainment, quotaToDateAttainment: quotaToDateAttainment, total: nil, totalRemaining: nil, totalCorrections: nil, totalWonCorrections: nil, pastSummaryID: pastID, pastSummaryTotal: pastTotal, pastSummaryTotalRemaining: pastTotalRemaining, pastSummaryTotalCorrections: pastTotalCorrections, pastSummaryCallCorrectionIDs: pastCallCorrectionIDs, pastCloseWonTotal: nil, pastCloseWonCorrection: nil, pastUpsideUploadTime: nil, pastUserVelocityConfidence: nil)
            
            
            return summary
            
        }
    }
    
    
    // Return all open opps, and all closed opps within the time period.
    private func getRelevantOpportuntiesForSFDCCall(opportunities: [OpportunityModel], startOfPeriod: Double, endOfPeriod: Double) -> [OpportunityModel] {
        
        let filteredClosedOpps = opportunities.filter({$0.closeDateTimeStamp! >= startOfPeriod && $0.closeDateTimeStamp! <= endOfPeriod}).filter({$0.stage!.lowercased() == "closed won"  || $0.stage!.lowercased() == "closed lost"})
        
        let openOpps = opportunities.filter({
            $0.stage!.lowercased() == "agreements" ||
            $0.stage!.lowercased() == "prove" ||
            $0.stage!.lowercased() == "develop" ||
            $0.stage!.lowercased() == "qualify" ||
            $0.stage!.lowercased() == "create"
        })
        
        return filteredClosedOpps + openOpps
    }
    
    private func setupSummaryModelAndLedgerOppsWith(opportunities: [OpportunityModel], startOfPeriod: Double, endOfPeriod: Double) {
        
        let timezone = TimeZone(identifier: "America/Chicago")!
        let filteredArrayForSalesForceCall = self.getRelevantOpportuntiesForSFDCCall(opportunities: opportunities,
                                                                                     startOfPeriod: startOfPeriod,
                                                                                     endOfPeriod: endOfPeriod)
        
        let newLedgerOpps = self.getLedgerOppsWithAssignedCalls(startTimestamp: startOfPeriod,
                                                                endTimestamp: endOfPeriod,
                                                                newOpps: filteredArrayForSalesForceCall,
                                                                previousLedgerOpps: nil) // first entry ever.
        
        self.currentRelevantPeriodCallLedgerOpps = newLedgerOpps
        
        if self.currentRelevantPeriodCallLedgerOpps!.count > 0 { // avoid crashing if user has no opps.
            
            let pipeBuildData = self.getPipeBuildPassed(days: 60,
                                                        timeZone: timezone,
                                                        opportunities: opportunities)
            
            let averageDealVelocity = self.getAverageCloseVelocityInDays(opps: opportunities,
                                                                         dealsBack: 30)
            // now focused on the past rolling 20
            let closeRatios = self.getCloseWonRatioFrom(opps: opportunities,
                                                        dealsBack: 20)
            
            let daysLeftWithinPeriod = self.getDaysLeftInPeriodFromNow(endTimestamp: endOfPeriod)
            
            
            let upsideNewOppForecastAmount = self.getUpsideFuturePipeCloseWonForecastAmountFrom(businessDaysLeft: daysLeftWithinPeriod.businessDays,
                                                                                                past30MedianDealVelocityBizDays: averageDealVelocity.medianFunc,
                                                                                                averageAmountPerBusinessDay60Days: pipeBuildData.averageAmountPerBusinessDay,
                                                                                                closeRateByamount: closeRatios.closeRateByamount)
            
            self.currentSummary = self.getUserCallSumaryFrom(oppLedgers: self.currentRelevantPeriodCallLedgerOpps!,
                                                             businessDaysLeft: daysLeftWithinPeriod.businessDays,
                                                             nonBusinessDaysLeft: daysLeftWithinPeriod.nonBusinessDays,
                                                             totalDaysLeft: daysLeftWithinPeriod.totalDays,
                                                             pipeBuildPast60DayAmount: pipeBuildData.amount,
                                                             pipeBuildPast60DayCount: pipeBuildData.count,
                                                             pipeBuildPast60DAyaverageSize: pipeBuildData.averageSize,
                                                             pipeBuildPast60DayMedianSize: pipeBuildData.medianSize,
                                                             past30MeanDealVelocityBizDays: averageDealVelocity.average,
                                                             past30MedianDealVelocityBizDays: averageDealVelocity.medianFunc,
                                                             pipeBuildMediumPast60Days: pipeBuildData.averageAmountPerBusinessDay,
                                                             averageCountPerBusinessDay60Days: pipeBuildData.averageCountPerBusinessDay,
                                                             closeRateByamount: closeRatios.closeRateByamount,
                                                             closeRateByCount: closeRatios.closeRateByCount,
                                                             upsideNewOppForecastAmount: upsideNewOppForecastAmount)
        }
    }
    
    
    private func getUpsideFuturePipeCloseWonForecastAmountFrom(businessDaysLeft: Double,
                                                               past30MedianDealVelocityBizDays: Double,
                                                               averageAmountPerBusinessDay60Days: Double,
                                                               closeRateByamount: Double) -> Double {

        var fullImpactPipeBuildDays = businessDaysLeft - past30MedianDealVelocityBizDays // for all the days other than the ones near the end, where we need a portion.
        if businessDaysLeft < past30MedianDealVelocityBizDays {
            fullImpactPipeBuildDays = 0
        }
        
        var partialImpactDaysPipeBuildDays = past30MedianDealVelocityBizDays * 0.5 // the portion days. we're going to just start with
        
        if businessDaysLeft < past30MedianDealVelocityBizDays {
            partialImpactDaysPipeBuildDays = past30MedianDealVelocityBizDays * (businessDaysLeft /  past30MedianDealVelocityBizDays)
        }
        
        let daysOfInPeriodPipeBuild = fullImpactPipeBuildDays + partialImpactDaysPipeBuildDays
        let impactAmountTotal = daysOfInPeriodPipeBuild * averageAmountPerBusinessDay60Days
        let upsideAnticipatedBookings = impactAmountTotal * closeRateByamount
        
        return upsideAnticipatedBookings
    }
    
    private func getCloseWonRatioFrom(opps: [OpportunityModel],
                                      dealsBack: Int) -> (closeRateByamount: Double,
                                                          closeRateByCount: Double) {
        
        let closedDeals = opps.filter({
            $0.stage?.lowercased() == "closed won" ||
            $0.stage?.lowercased() == "closed lost"
        }).sorted(by: {
            $0.closeDateTimeStamp! > $1.closeDateTimeStamp!
        })
        
        let dealsToAssess = closedDeals.prefix(dealsBack)
        
        var closedBookingsAmountTotal = 0.0
        var closedBookingsCountTotal = 0 as Int
        
        var closedWonBookingsAmountTotal = 0.0
        var closedWonBookingsCountTotal = 0 as Int
        
        for deal in dealsToAssess {
            let amount = deal.commerceBookings! + deal.totalBookingsConverted!
            closedBookingsAmountTotal = closedBookingsAmountTotal + amount
            closedBookingsCountTotal = closedBookingsCountTotal + 1
            
            if deal.stage!.lowercased() == "closed won" {
                closedWonBookingsAmountTotal = closedWonBookingsAmountTotal + amount
                closedWonBookingsCountTotal = closedWonBookingsCountTotal + 1
            }
        }
        
        return (closeRateByamount: closedWonBookingsAmountTotal / closedBookingsAmountTotal,
                closeRateByCount: Double(closedWonBookingsCountTotal) / Double(closedBookingsCountTotal))
        
        
    }
    
    private func getDaysLeftInPeriodFromNow(endTimestamp: Double) -> (businessDays: Double, nonBusinessDays: Double, totalDays: Double) {
        
        let timezone = TimeZone(identifier: "America/Chicago")!
        //let endQuarter = Date(timeIntervalSince1970: self.getEndOfQuarter(date: Date(), timeZone: timezone))
        
        let dayCount = self.getWeekdayCount(startDate: Date(),
                                            endDate: Date(timeIntervalSince1970: endTimestamp),
                                            timeZone: timezone)
        
        return dayCount
        
    }
    
    // MARK: TODO - inital testing - need to run through the math (sober)
    // method to provide the average deal velocity by day, determined by X number of deals back,
    // meaning sorting from most recent deals, close won or lost, then picking the most recent
    // X amount.
    private func getAverageCloseVelocityInDays(opps: [OpportunityModel], dealsBack: Int) -> (average: Double, medianFunc: Double) {
        
        let closedDeals = opps.filter({
            $0.stage?.lowercased() == "closed won" ||
            $0.stage?.lowercased() == "closed lost"
        }).sorted(by: {
            $0.closeDateTimeStamp! > $1.closeDateTimeStamp!
        })
        
        
        let dealsToAssess = closedDeals.prefix(dealsBack)
        var bizDaysToClose = [Double]()
        for deal in dealsToAssess {
            // print(deal.opportunityName! + " close date: " + deal.closeDate! + " & status: " + deal.stage!)
            
            let timezone = TimeZone(identifier: "America/Chicago")!
            let daysBetween = self.getWeekdayCount(startDate: Date(timeIntervalSince1970: deal.createdDateTimeStamp!),
                                                   endDate: Date(timeIntervalSince1970: deal.closeDateTimeStamp!),
                                                   timeZone: timezone)
            
            //print(daysBetween)
            bizDaysToClose.append(daysBetween.businessDays)
        }
        
        let average = calculateMean(array: bizDaysToClose)
        let median = calculateMedian(array: bizDaysToClose)
        
        return (average: average,
                medianFunc: median)

    }
    
}

// MARK: TODO
// update labels.
extension UserCallVC {
    
    // MARK: TODO need to move to main body - test
    private func getTotalCorrectionAmount() -> Double {
        
        if self.callCorrections == nil || self.callCorrections!.count == 0 {
            return 0.0
        }
        
        var totalCorrection = 0.0
        
        for corc in self.callCorrections! {
            totalCorrection = totalCorrection + corc.amount!
        }
        
        return totalCorrection
        
    }
    
    private func getTotalCorrectionWonAmount() -> Double {
        
        if self.callCorrections == nil || self.callCorrections!.count == 0 {
            return 0.0
        }
        
        var totalCorrection = 0.0
        
        for corc in self.callCorrections! {
            if corc.opportunityStage?.lowercased() == "closed won" {
                totalCorrection = totalCorrection + corc.amount!
            }
        }
        
        return totalCorrection
        
    }
    
    private func updateSummaryLabels() {
        
        if currentSummary != nil {
            self.summaryCallByOpportuntiesLabel.text = CurrencyModel(locale: "en_US",
                                                                     amount: self.currentSummary!.callTotalAmount!).format
            
            self.summaryCallByVelocityLabel.text = CurrencyModel(locale: "en_US",
                                                                 amount: self.currentSummary!.userVelocityForecast!).format

            self.summaryCallByCorrectionsLabel.text = CurrencyModel(locale: "en_US",
                                                                  amount: self.getTotalCorrectionAmount()).format
            
            
            // MARK: TODO make own method.
            let totalCallAmount = self.currentSummary!.callTotalAmount! +
            self.currentSummary!.userVelocityForecast! +
            self.getTotalCorrectionAmount() +
            self.currentSummary!.closedWonTotalAmount!
            
            
            let changedCloseWonAmount = self.getCorrectedClosedWonWithCorrections().amount
            if changedCloseWonAmount == nil || self.getCorrectedClosedWonWithCorrections().count == 0 {
                self.summaryCallByClosedWonLabel.text = CurrencyModel(locale: "en_US",
                                                                      amount: self.currentSummary!.closedWonTotalAmount!).format
                
                
                let amountLeftInCall = totalCallAmount - self.currentSummary!.closedWonTotalAmount!
                self.summaryCallRemainingLabel.text = formatShortHandCurrency(num: amountLeftInCall) + " remaining"
                
            } else {
                
                let correctedCloseWonAmount = self.currentSummary!.closedWonTotalAmount! + changedCloseWonAmount!
                let correctedString = formatShortHandCurrency(num: changedCloseWonAmount!)
                
                
                let closeWonString = CurrencyModel(locale: "en_US",
                                                   amount: correctedCloseWonAmount).format
                
                self.summaryCallByClosedWonLabel.text = closeWonString + " (NOT incl " + correctedString + " of corrections)"
                
                
                
                var amountLeftInCall = totalCallAmount - self.currentSummary!.closedWonTotalAmount!
                amountLeftInCall = amountLeftInCall - changedCloseWonAmount!
                self.summaryCallRemainingLabel.text = formatShortHandCurrency(num: amountLeftInCall) + " remaining (before " + correctedString + " correction)"
                
            }
            
            
            
            
            
            
            self.summaryCallTotalLabel.text =  CurrencyModel(locale: "en_US",
                                                            amount: totalCallAmount).format
            
            
            /*
            self.summaryCallRemainingLabel.text = CurrencyModel(locale: "en_US",
                                                                amount: amountLeftInCall).format
             */
            
        }
    }
    
    
    
    
    
    private func updateCallByOpportunitiesLabelsWith(summary: UserCallSummaryModel) {
        
        /* CALL Labels */
        self.callTotalAmountLabel.text = CurrencyModel(locale: "en_US", amount: summary.callTotalAmount!).format
        self.callTotalCountLabel.text = String(summary.callTotalCount!)
        self.callSaaSAmountLabel.text = formatShortHandCurrency(num: summary.callSaaSAmount!)
        self.callSaaSCountLabel.text = String(summary.callSaaSCount!)
        self.callComrcAmountLabel.text = formatShortHandCurrency(num: summary.callComrcAmount!)
        self.callComrcCountLabel.text = String(summary.callComrcCount!)
        self.callOtherAmountLabel.text = formatShortHandCurrency(num: summary.callOtherAmount!)
        self.callOtherCountLabel.text = String(summary.callOtherCount!)
        
        
        /* UPSIDE Labels */
        self.upsideTotalAmountLabel.text = CurrencyModel(locale: "en_US", amount: summary.upsideTotalAmount!).format
        self.upsideTotalCountLabel.text = String(summary.upsideTotalCount!)
        self.upsideSaaSAmountLabel.text = formatShortHandCurrency(num: summary.upsideSaaSAmount!)
        self.upsideSaaSCountLabel.text = String(summary.upsideSaaSCount!)
        self.upsideComrcAmountLabel.text = formatShortHandCurrency(num: summary.upsideComrcAmount!)
        self.upsideComrcCountLabel.text = String(summary.upsideComrcCount!)
        self.upsideOtherAmountLabel.text = formatShortHandCurrency(num: summary.upsideOtherAmount!)
        self.upsideOtherCountLabel.text = String(summary.upsideOtherCount!)
     
        /* STRETCH Labels */
        self.stretchTotalAmountLabel.text = CurrencyModel(locale: "en_US", amount: summary.stretchTotalAmount!).format
        self.stretchTotalCountLabel.text = String(summary.stretchTotalCount!)
        self.stretchSaaSAmountLabel.text = formatShortHandCurrency(num: summary.stretchSaaSAmount!)
        self.stretchSaaSCountLabel.text = String(summary.stretchSaaSCount!)
        self.stretchComrcAmountLabel.text = formatShortHandCurrency(num: summary.stretchComrcAmount!)
        self.stretchComrcCountLabel.text = String(summary.stretchComrcCount!)
        self.stretchOtherAmountLabel.text = formatShortHandCurrency(num: summary.stretchOtherAmount!)
        self.stretchOtherCountLabel.text = String(summary.stretchOtherCount!)
        
        /* OMIT Labels */
        self.omitTotalAmountLabel.text = CurrencyModel(locale: "en_US", amount: summary.omitTotalAmount!).format
        self.omitTotalCountLabel.text = String(summary.omitTotalCount!)
        self.omitSaaSAmountLabel.text = formatShortHandCurrency(num: summary.omitSaaSAmount!)
        self.omitSaaSCountLabel.text = String(summary.omitSaaSCount!)
        self.omitComrcAmountLabel.text = formatShortHandCurrency(num: summary.omitComrcAmount!)
        self.omitComrcCountLabel.text = String(summary.omitComrcCount!)
        self.omitOtherAmountLabel.text = formatShortHandCurrency(num: summary.omitOtherAmount!)
        self.omitOtherCountLabel.text = String(summary.omitOtherCount!)
        
        /* SUMARRY Labels */
        self.callTotalAmountSummaryLabel.text = CurrencyModel(locale: "en_US", amount: summary.callTotalAmount!).format
    }
    
    private func updateDealVelocityLabels() {
        let meanStr = String(format: "%.1f", self.currentSummary!.past30MeanDealVelocityBizDays!)
        let medianStr = String(format: "%.1f", self.currentSummary!.past30MedianDealVelocityBizDays!)
        self.dealCloseVelocityLabel.text = meanStr + " biz days (mean), " + medianStr + " (median)"
    }
    
    private func updateCallByVelocityLabels() {
        if currentSummary != nil {
            self.updateDaysLeftLabel()
            self.updatePipeBuildVelocityLabels()
            self.updateDealVelocityLabels()
            self.updateCloseRatioLabels()
            self.upsideForecastLabel.text = CurrencyModel(locale: "en_US",
                                                          amount: self.currentSummary!.upsideNewOppForecastAmount!).format
            
            // now update the inital perc and amount labels.
            
            let confidencePercString = String(format: "%.1f", self.currentSummary!.userForecastConfidenceInVelocity! * 100.0) + "%"
            let userVelocityForecastString = CurrencyModel(locale: "en_US",
                                                           amount: self.currentSummary!.userVelocityForecast!).format
            
            self.userAmountByVelocityPercentageLabel.text = confidencePercString
            self.userAmountByVelocityForecastLabel.text = userVelocityForecastString
            
            
            /*
             @IBOutlet weak var userAmountByVelocityPercentageLabel: UILabel!
             @IBOutlet weak var userAmountByVelocityForecastLabel: UILabel!
             @IBOutlet weak var pipeBuildVelocitySlider: UISlider!
             */
            
            
        }
    }
    
    private func updateCloseRatioLabels() {
        
        if self.currentSummary != nil {
            
            let byAmountRateStr = String(format: "%.1f", (self.currentSummary!.closeRateByamount! * 100.0))
            let byCountRateStr = String(format: "%.1f", (self.currentSummary!.closeRateByCount! * 100.0))
            self.closeWonRatioLabel.text = byAmountRateStr + "% by amount, " + byCountRateStr + "% by count."
            
        }
        
        
    }
    
    private func updateDaysLeftLabel() {
        
        if self.currentSummary != nil {
            
            let daysLeftString = String(format: "%.1f", self.currentSummary!.totalDaysLeft!)
            let businessDaysLeftString = String(format: "%.1f", self.currentSummary!.businessDaysLeft!)
            let nonBusinessDaysLeftString = String(format: "%.1f", self.currentSummary!.nonBusinessDaysLeft!)
            self.daysRemainingLabel.text = daysLeftString + " day's left (" + businessDaysLeftString + " biz & " + nonBusinessDaysLeftString + " non-biz)."
            
        }

        
    }
    
    // current 60 days focus.
    private func updatePipeBuildVelocityLabels() {
        
        if self.currentSummary != nil {
            
            let pipeBuildAmountStr = CurrencyModel(locale: "en_US", amount: self.currentSummary!.pipeBuildPast60Days!).format
            let pipeBuildCountStr = String(self.currentSummary!.pipeBuildCountPast60Days!)
            
            
            let avePerBizDayStr = CurrencyModel(locale: "en_US",
                                                amount: self.currentSummary!.averageAmountPerBusinessDay60Days!).format
             
        
            
            self.pipeBuildVelocityLabel.text = pipeBuildAmountStr + " USD (" + pipeBuildCountStr + ")" + ", " + avePerBizDayStr + " per biz day."
            
        }
        
        
    }
}




// MARK: TableView Extension
extension UserCallVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = Bundle.main.loadNibNamed("CallCorrectionCell", owner: self, options: nil)?.first as! CallCorrectionCell
        
        cell.descriptionLabel.text = self.callCorrections![indexPath.row].correctionDescription ?? "n/a"
        cell.amountLabel.text = formatShortHandCurrency(num: self.callCorrections![indexPath.row].amount!)
        var color = ui_active_blue
        if self.callCorrections![indexPath.row].amount! < 0.0 {
            color = .red
        }
        cell.amountLabel.textColor = color
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.correctionTableView.deselectRow(at: indexPath, animated: true)
        
        
        // get index path, pass in opp ledger from filtered list straight to change opp....
        // MARK: 12345
        
//        print("callCorrections![indexPath.row].id = ", callCorrections![indexPath.row].opportunityID)
        if let oppID = callCorrections![indexPath.row].opportunityID {
            
//            print("have an ID let's continue.")
            let vc = EditBookingsAmountVC()
            // vc.delegate = self
            vc.callPeriod = self.callPeriod
            let opp = currentRelevantPeriodCallLedgerOpps?.first(where: {
                $0.opportunityId == oppID
            })
            
            
//            print("the opp is:")
//            print(opp)
            vc.delegate = self
            vc.opp = opp
            let navController = UINavigationController(rootViewController: vc)
            self.present(navController, animated: true, completion: nil)
        }
        
        
        
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return callCorrections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }
    
    /* Delete cell / data.*/
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            tableView.beginUpdates()
            
            
            if let oppID = callCorrections?[indexPath.row].opportunityID {
                if let replacmentOpp = currentRelevantPeriodCallLedgerOpps?.first(where: {
                    $0.opportunityId == oppID
                }) {
                    let oppIndex = self.currentRelevantPeriodCallLedgerOpps!.firstIndex(where: { $0.opportunityId == oppID} )
                    
                    // MARK: TODO turn this into a method within the ledger model.
                    let ledger = OpportunityLedgerModel(id: replacmentOpp.id, accountName: replacmentOpp.accountName, closeDate: replacmentOpp.closeDate, commerceBookings: replacmentOpp.commerceBookings, commerceBookingsCurrency: replacmentOpp.commerceBookingsCurrency, createdDate: replacmentOpp.createdDate, lastModifiedDate: replacmentOpp.lastModifiedDate, lastStageChangeDate: replacmentOpp.lastStageChangeDate, leadSource: replacmentOpp.leadSource, opportunityCurrency: replacmentOpp.opportunityCurrency, opportunityId: replacmentOpp.opportunityId, opportunityName: replacmentOpp.opportunityName, opportunityOwner: replacmentOpp.opportunityOwner, opportunityOwnerEmail: replacmentOpp.opportunityOwnerEmail, opportunityOwnerManager: replacmentOpp.opportunityOwnerManager, primaryProductFamily: replacmentOpp.primaryProductFamily, probability: replacmentOpp.probability, stage: replacmentOpp.stage, totalBookingsConverted: replacmentOpp.totalBookingsConverted, totalBookingsConvertedCurrency: replacmentOpp.totalBookingsConvertedCurrency, type: replacmentOpp.type, age: replacmentOpp.age, closeDateTimeStamp: replacmentOpp.closeDateTimeStamp, createdDateTimeStamp: replacmentOpp.createdDateTimeStamp, lastModifiedDateTimeStamp: replacmentOpp.lastModifiedDateTimeStamp, lastStageChangeDateTimeStamp: replacmentOpp.lastStageChangeDateTimeStamp, salesForcePreviousCallStatus: replacmentOpp.salesForcePreviousCallStatus, salesForceCurrentCallStatus: replacmentOpp.salesForceCurrentCallStatus, salesForcePreviousCallStatusIndex: replacmentOpp.salesForcePreviousCallStatusIndex, salesForceCurrentCallStatusIndex: replacmentOpp.salesForceCurrentCallStatusIndex, userPreviousCallStatus: replacmentOpp.userPreviousCallStatus, userCurrentCallStatus: replacmentOpp.userCurrentCallStatus, userPreviousCallStatusIndex: replacmentOpp.userPreviousCallStatusIndex, userCurrentCallStatusIndex: replacmentOpp.userCurrentCallStatusIndex, userInputTotalBookings: nil, stageSortingIndex: replacmentOpp.stageSortingIndex, periodStartTimestamp: replacmentOpp.periodStartTimestamp, periodEndTimestamp: replacmentOpp.periodEndTimestamp, periodDescription: replacmentOpp.periodDescription, periodType: replacmentOpp.periodType, sfdcSyncTimestamp: self.opportunityUploadLogs![0].uploadTimestamp!, upsideLedgerUploadTimestamp: nil) // all this to get the 'nil' in there
                    
                    self.currentRelevantPeriodCallLedgerOpps![oppIndex!] = ledger
                }
            }
                
                
            tableView.deleteRows(at: [indexPath], with: .fade)
            callCorrections?.remove(at: indexPath.row)
//            /userInputTotalBookings
            
            
            tableView.endUpdates()
        }
        
    }
    
        
}

/*
protocol PassSelectedCallPeriod: AnyObject {
    func passCallPeriod(callPeriod: CallPeriod)
}
*/
extension UserCallVC: PassSelectedCallPeriod {
    
    func passCallPeriod(aCallPeriod: CallPeriod) {
        
        
        print("Passing back call period: ")
        print(aCallPeriod)
        
        self.callPeriod = aCallPeriod
        
        
        // MARK: TODO TESTING NEED TO UPDATE MODELS BASED on new time
        // could move to a didSet method.
        
        
        
        self.setDataModels()
        
        self.updateSummaryLabels()
        self.updateDaysLeftLabel()
        self.updateCloseRatioLabels()
        self.updatePipeBuildVelocityLabels()
    }
    
}

// PassSelectedCallCorrectionDelegate
extension UserCallVC: PassSelectedCallCorrectionDelegate {
    
    func passCallCorrectionType(correctionType: CallCorrectionModel) {
        // print(correctionType)
        
        
        switch correctionType.type?.lowercased() {
        case CallCorrectionType.closedWonOpportunities.rawValue.lowercased():
            self.presentOppLedgerClosedReviewVC()
        case CallCorrectionType.openOpportunities.rawValue.lowercased():
            self.presentOppLedgerReviewVC()
        case CallCorrectionType.overrideCall.rawValue.lowercased():
            print("override correction vc")
        default:
            // MARK: TODO add error message in UI.
            print("erroer in: extension UserCallVC: PassSelectedCallCorrectionDelegate")
        }
        
    }
    
}

extension UserCallVC: PassAmendedOpportunityDelegate {
    
    
    func passOpportunity(_ opp: OpportunityLedgerModel, callCorrection: CallCorrectionModel?) {
        
        if callCorrection != nil {
            self.updateOpportunitiesWithCorrections([opp], corrections: [callCorrection!])
        } else {
            self.updateOpportunitiesWithCorrections([opp], corrections: nil)
        }
        
        
        
    }
    
    //self.updateOpportunitiesWithCorrections(opps, corrections: corrections)
}
/*
 protocol PassAmendedOpportunityDelegate: AnyObject {
     func passOpportunity(_ opp: OpportunityLedgerModel, callCorrection: CallCorrectionModel?)
 }
 */

extension UserCallVC: PassClosedLedgerOppsDelegate {
    
    func passClosedOpportunitiesWithCorrections(_ opps: [OpportunityLedgerModel],
                                                corrections: [CallCorrectionModel]?) {
        self.updateOpportunitiesWithCorrections(opps, corrections: corrections)
    }
}





// MARK: TODO could be moved to a helper method/.
// MARK: TODO move to global class / method - it's in multiple.
// time / period managment / descriptions.
extension UserCallVC {
    
    
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
