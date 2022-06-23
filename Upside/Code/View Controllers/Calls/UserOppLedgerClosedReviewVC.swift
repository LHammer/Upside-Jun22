//
//  UserOppLedgerClosedReviewVC.swift
//  Upside
//
//  Created by Luke Hammer on 5/29/22.
//

import UIKit

/*
 protocol PassOpportunityLedgersDelegate: AnyObject {
     func passOpportunities(_ opps: [OpportunityLedgerModel],
                            corrections: [CallCorrectionModel]?)
 }

 */

protocol PassClosedLedgerOppsDelegate: AnyObject {
    func passClosedOpportunitiesWithCorrections(_ opps: [OpportunityLedgerModel],
                                                corrections: [CallCorrectionModel]?)
}

class UserOppLedgerClosedReviewVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    weak var delegate: PassClosedLedgerOppsDelegate?
    
    var callPeriod: CallPeriod?
    
    var opps: [OpportunityLedgerModel]? {
        didSet {
            if opps != nil && self.tableView != nil {
                self.tableView.reloadData()
            }
        }
    }
    
    var callCorrections: [CallCorrectionModel]? {
        didSet {
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupDefualtNavigationBar()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "submit", style: .plain, target: self, action: #selector(submitTapped))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    private func displayEditBookingsAmountVC(index: Int) {
        
        let rootViewController = EditBookingsAmountVC()
        rootViewController.opp = opps![index]
        rootViewController.callPeriod = self.callPeriod
        rootViewController.delegate = self
        let navController = UINavigationController(rootViewController: rootViewController)
        rootViewController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
        
    }
    
    @objc
    func submitTapped() {
        
        self.delegate?.passClosedOpportunitiesWithCorrections(opps!,
                                                              corrections: callCorrections)
        
        
        self.dismiss(animated: true)
    }
}

// MARK: TableView Extension
extension UserOppLedgerClosedReviewVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = Bundle.main.loadNibNamed("UserReviewOppLedgerClosedCell", owner: self, options: nil)?.first as! UserReviewOppLedgerClosedCell
        
        cell.opportunityLabel.text = opps![indexPath.row].opportunityName!
        
        let amount = opps![indexPath.row].totalBookingsConverted! + opps![indexPath.row].commerceBookings!
        cell.amountLabel.text = formatShortHandCurrency(num: amount)
        
        if opps![indexPath.row].userInputTotalBookings != nil {
            cell.amendedLabel.text = formatShortHandCurrency(num: opps![indexPath.row].userInputTotalBookings!)
            
            let changeAmount = opps![indexPath.row].userInputTotalBookings! - amount
            cell.changeLabel.text = formatShortHandCurrency(num: changeAmount)
            
            if changeAmount < 0.0 {
                cell.changeLabel.textColor = .red
            }
        }
        
        
        
        

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        self.displayEditBookingsAmountVC(index: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return opps?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 130.0
    }
    
}


extension UserOppLedgerClosedReviewVC: PassAmendedOpportunityDelegate {
    
    func passOpportunity(_ opp: OpportunityLedgerModel, callCorrection: CallCorrectionModel?) {
        
        let oppIndex = opps!.firstIndex(where: { $0.opportunityId == opp.id} )
        opps?[oppIndex!] = opp
        
//        let filteredOppIndex = filteredOpps!.firstIndex(where: { $0.opportunityId == opp.id} )
//        filteredOpps?[filteredOppIndex!] = opp
        
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
        
        self.tableView.reloadData()
    }
}
