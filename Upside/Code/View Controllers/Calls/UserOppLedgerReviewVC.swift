//
//  UserOppLedgerReviewVC.swift
//  Upside
//
//  Created by Luke Hammer on 5/20/22.
//

import UIKit

protocol PassOpportunityLedgersDelegate: AnyObject {
    func passOpportunities(_ opps: [OpportunityLedgerModel],
                           corrections: [CallCorrectionModel]?)
}


class UserOppLedgerReviewVC: UIViewController {

    @IBOutlet weak var sortByButton: UIButton!
    @IBOutlet weak var sortByImage: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var filterOptionSegmentedControl: UISegmentedControl!
    
    // MARK: TODO - is this needed?
    // if it is, let's actually use it. currently doesn't
    // prevent user input whilst the animation completes.
    var pauseInput = false // used to stop user input while animations (i.e segment control) complete.
    
    let searchController = UISearchController()
    
    weak var delegate: PassOpportunityLedgersDelegate?
    
    var callPeriod: CallPeriod?

    var opps: [OpportunityLedgerModel]? {
        didSet {
            
            // MARK: My edit to logic - should allow to keep
            // text filter whilst sort variable / down v up
            
            // filter the opps if there anything that's
            // been searched. This is a cool way of doing this.
            
            if let searchString = self.searchController.searchBar.text?.lowercased() {
                
                if searchString == "" {
                    self.filteredOpps = self.opps
                } else {
                    self.filteredOpps = self.opps?.filter({
                        $0.opportunityName!.lowercased().contains(searchString)
                    })
                }
            } else {
                self.filteredOpps = self.opps
            }
        }
    }
    
    var callCorrections: [CallCorrectionModel]? {
        didSet {
        }
    }
    
    var filteredOpps: [OpportunityLedgerModel]? {
        didSet {
            if filteredOpps != nil {
                if tableView != nil {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    var sortAcsending = false {
        didSet {
            if sortAcsending == true {
                sortByImage.image = UIImage(named: "sort_blue_up")
            } else {
                sortByImage.image = UIImage(named: "sort_blue_down")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.filterOptionSegmentedControl.backgroundColor = ui_active_light_yellow
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.setupDefualtNavigationBar()
        self.searchController.searchResultsUpdater = self
        self.definesPresentationContext = true
        self.navigationItem.searchController = self.searchController
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "submit", style: .plain, target: self, action: #selector(submitTapped))
    }

    override func viewDidAppear(_ animated: Bool) {
        self.tableView.reloadData()
        self.searchController.searchBar.searchTextField.textColor = .white
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    //getFilterFromSortSegmentIndex
    
    private func sortOppsByOption(filter: String, funcOpps: [OpportunityLedgerModel]) -> [OpportunityLedgerModel] {
        
        let option = filter.lowercased()
        
        switch option {
            
        case "value":
            // MARK: TODO - Sort byt total (i.e commerce + saas/other bookings)
            if sortAcsending == false {
                let sortedOpps = funcOpps.sorted(by: { $0.totalBookingsConverted! > $1.totalBookingsConverted! }) // large to small (top down)
                return sortedOpps
            } else {
                let sortedOpps = funcOpps.sorted(by: { $0.totalBookingsConverted! < $1.totalBookingsConverted! }) // small to large
                return sortedOpps
            }
            
        case "stage":
            
            if sortAcsending == false {
                let sortedOpps = funcOpps.sorted(by: { $0.stageSortingIndex! > $1.stageSortingIndex! }) // large to small (top down)
                return sortedOpps
            } else {
                let sortedOpps = funcOpps.sorted(by: { $0.stageSortingIndex! < $1.stageSortingIndex! }) // small to large
                return sortedOpps
            }
        case "call":
            
            if sortAcsending == false {
                let sortedOpps = funcOpps.sorted(by: { $0.userCurrentCallStatusIndex! > $1.userCurrentCallStatusIndex! }) // large to small (top down)
                return sortedOpps
            } else {
                let sortedOpps = funcOpps.sorted(by: { $0.userCurrentCallStatusIndex! < $1.userCurrentCallStatusIndex! }) // small to large
                return sortedOpps
            }
            
        case "date":
            
            if sortAcsending == false {
                let sortedOpps = funcOpps.sorted(by: { $0.closeDateTimeStamp! > $1.closeDateTimeStamp! }) // large to small (top down)
                return sortedOpps
            } else {
                let sortedOpps = funcOpps.sorted(by: { $0.closeDateTimeStamp! < $1.closeDateTimeStamp! }) // small to large
                return sortedOpps
            }
            
        default: // defualt and default the same ;)
            
            if sortAcsending == false {
                
                
                let sortedOpps = funcOpps.sorted(by: {
                    $0.totalBookingsConverted! > $1.totalBookingsConverted!
                }).sorted(by: {
                    $0.userCurrentCallStatusIndex! > $1.userCurrentCallStatusIndex!
                })
                
                
                return sortedOpps
            } else {
                
                let sortedOpps = funcOpps.sorted(by: {
                    $0.totalBookingsConverted! < $1.totalBookingsConverted!
                }).sorted(by: {
                    $0.userCurrentCallStatusIndex! < $1.userCurrentCallStatusIndex!
                })
                return sortedOpps
            }
        }
    }
    
    private func getFilterFromSortSegmentIndex() -> String {
        let i = filterOptionSegmentedControl.selectedSegmentIndex
        
        switch i {
        case 0:
            return "defualt"
        case 1:
            return "value"
        case 2:
            return "stage"
        case 3:
            return "call"
        case 4:
            return "date"
        default:
            return "defualt"
        }
    }
    
    // MARK: NEED to move to a global func
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
    
    private func getCallStatusStringFromSegmentInput(index: Int) -> String {
        
        switch index {
        case 0:
            return "Call"
        case 1:
            return "upside"
        case 2:
            return "Stretch"
        case 3:
            return "Omit"
        default:
            return "Omit"
        }
        
    }
    
    private func getSegmentControlIndexFor(callSataus: String) -> Int {
        
        if callSataus.lowercased() == "call" {
            return 0
        } else if callSataus.lowercased() == "upside" {
            return 1
        } else if callSataus.lowercased() == "stretch" {
            return 2
        } else if  callSataus.lowercased() == "omit" {
            return 3
        } else {
            return 3
        }
        
    }
    
    @objc
    func submitTapped() {
        // self.delegate?.passOpportunities(opps!)
        self.delegate?.passOpportunities(opps!,
                                         corrections: self.callCorrections ?? nil)
        
        self.dismiss(animated: true)
    }
    
    @objc
    func segmentAllEventTrigger(sender: UISegmentedControl) {
        self.pauseInput = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [self] in
            let callStatus = getCallStatusStringFromSegmentInput(index: sender.selectedSegmentIndex)
            self.filteredOpps![sender.tag].userCurrentCallStatus = callStatus
            let oppIndex = opps!.firstIndex(where: { $0.opportunityId == filteredOpps![sender.tag].id} )
            opps?[oppIndex!].userCurrentCallStatus = callStatus
            self.pauseInput = false
        }
    }
    
    // MARK: TODO now add the logic to bring a new VC up and pull in new bookings amount.
    @objc
    private func editBookingAmountPressed(sender: UIButton) {
        let rootViewController = EditBookingsAmountVC()
        rootViewController.opp = filteredOpps![sender.tag]
        rootViewController.delegate = self
        rootViewController.callPeriod = self.callPeriod
        let navController = UINavigationController(rootViewController: rootViewController)
        rootViewController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
        
    @IBAction func filterOptionChanged(_ sender: UISegmentedControl) {
        
        // MARK: TODO hard coded for now.
        switch sender.selectedSegmentIndex {
        case 0:
            self.opps = self.sortOppsByOption(filter: "default",
                                              funcOpps: self.opps!)
        case 1:
            self.opps = self.sortOppsByOption(filter: "value",
                                              funcOpps: self.opps!)
        case 2:
            self.opps = self.sortOppsByOption(filter: "stage",
                                              funcOpps: self.opps!)
        case 3:
            
            self.opps = self.sortOppsByOption(filter: "call",
                                              funcOpps: self.opps!)
        case 4:
            self.opps = self.sortOppsByOption(filter: "date",
                                              funcOpps: self.opps!)
        default:
            print("error: incorrect value in filterOptionChanged.")
            self.opps = self.sortOppsByOption(filter: "default",
                                              funcOpps: self.opps!)
        }
    }
    
    @IBAction func sortButtonTapped(_ sender: Any) {
        if self.sortAcsending == true {
            self.sortAcsending = false
        } else {
            self.sortAcsending = true
        }
        if self.opps != nil {
            self.opps = self.sortOppsByOption(filter: self.getFilterFromSortSegmentIndex(),
                                  funcOpps: self.opps!)
        }
    }
}


// MARK: TableView Extension
extension UserOppLedgerReviewVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = Bundle.main.loadNibNamed("UserReviewOppLedgerCell", owner: self, options: nil)?.first as! UserReviewOppLedgerCell
        let opp = self.filteredOpps![indexPath.row]
        let totalBookings = self.getTotalBookingsFrom(oppLEdger: opp)
        cell.callSelectorSegmentedControl.selectedSegmentIndex = self.getSegmentControlIndexFor(callSataus: opp.userCurrentCallStatus!)// 2
        cell.callSelectorSegmentedControl.tag = indexPath.row
        cell.callSelectorSegmentedControl.addTarget(self, action: #selector(segmentAllEventTrigger(sender:)), for: .valueChanged)
        cell.oppNameLabel.text = opp.opportunityName ?? "---"
        cell.bookingsTotalAmountLabel.text = CurrencyModel(locale: "en_US",
                                                           amount: totalBookings.total).format
        
        cell.bookingsCommerceAmountLabel.text = CurrencyModel(locale: "en_US",
                                                              amount: totalBookings.commerce).format + " commerce"
        
        cell.SaaSBookingsLabel.text = CurrencyModel(locale: "en_US",
                                                    amount: totalBookings.SaaS).format + " SaaS"
        
        cell.otherBookingsLabel.text = CurrencyModel(locale: "en_US",
                                                     amount: totalBookings.other).format + " other"
        cell.closeDateLabel.text = opp.closeDate
        cell.stageLabel.text = opp.stage
        cell.productLabel.text = opp.primaryProductFamily
        cell.editBookingsBtn.tag = indexPath.row
        cell.editBookingsBtn.addTarget(self, action: #selector(self.editBookingAmountPressed(sender:)), for: .touchUpInside)
        if opp.userInputTotalBookings != nil {
            cell.usersBookingsTotalLabel.text = CurrencyModel(locale: "en_US",
                                                              amount: opp.userInputTotalBookings!).format
        } else {
            cell.usersBookingsTotalLabel.text = "---"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.self.filteredOpps?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 240.0
    }
    
}


extension UserOppLedgerReviewVC: UISearchResultsUpdating {
    
    // MARK: TODO Move to extension.
    // search bar method
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let text = searchController.searchBar.text?.lowercased() else {
            self.filteredOpps = opps
            return
        }
        if text == "" { // no text, filtered list is the entire list.
            self.filteredOpps = opps
        } else {
            self.filteredOpps = opps?.filter({
                $0.opportunityName!.lowercased().contains(text)
            })
        }
    }
}


extension UserOppLedgerReviewVC: PassAmendedOpportunityDelegate {
    
    func passOpportunity(_ opp: OpportunityLedgerModel, callCorrection: CallCorrectionModel?) {
        
        let oppIndex = opps!.firstIndex(where: { $0.opportunityId == opp.id} )
        opps?[oppIndex!] = opp
        
        let filteredOppIndex = filteredOpps!.firstIndex(where: { $0.opportunityId == opp.id} )
        filteredOpps?[filteredOppIndex!] = opp
        
        if callCorrection != nil {
            if self.callCorrections != nil {
                // remove any correction associated
                self.callCorrections?.removeAll(where: {
                    $0.opportunityID?.lowercased() == opp.opportunityId?.lowercased()
                })
                self.callCorrections?.append(callCorrection!)
            } else {
                self.callCorrections = [CallCorrectionModel]()
                self.callCorrections?.append(callCorrection!)
            }
        }
    }
}

