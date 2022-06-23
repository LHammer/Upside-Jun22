//
//  CallCorrectionSelectionVC.swift
//  Upside
//
//  Created by Luke Hammer on 5/28/22.
//

import UIKit

protocol PassSelectedCallCorrectionDelegate: AnyObject {
    func passCallCorrectionType(correctionType: CallCorrectionModel)
}

class CallCorrectionSelectionVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    weak var delegate: PassSelectedCallCorrectionDelegate?
    
    private var correctionTypes: [CallCorrectionModel]? {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupDefualtNavigationBar()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.correctionTypes = self.getTableViewData()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func getTableViewData() -> [CallCorrectionModel] {
        
        let a = CallCorrectionModel(id: nil,
                                    correctionDescription: "Correct a close won opportunity total value.",
                                    amount: nil,
                                    originalAmount: nil,
                                    type: CallCorrectionType.closedWonOpportunities.rawValue,
                                    opportunityID: nil,
                                    opportunityStage: nil,
                                    periodStartTimestamp: nil,
                                    periodEndTimestamp: nil,
                                    periodDescription: nil,
                                    periodType: nil,
                                    sfdcSyncTimestamp: nil,
                                    upsideLedgerUploadTimestamp: nil,
                                    callSummaryID: nil)
        
        
        /*
        let a = CallCorrectionModel(id: nil,
                                    correctionDescription: "Correct a close won opportunity total value.",
                                    amount: nil,
                                    originalAmount: nil,
                                    type: CallCorrectionType.closedWonOpportunities.rawValue,
                                    opportunityID: nil)*/
        
        let b = CallCorrectionModel(id: nil,
                                    correctionDescription: "Amend open opportunity total value.",
                                    amount: nil,
                                    originalAmount: nil,
                                    type: CallCorrectionType.openOpportunities.rawValue,
                                    opportunityID: nil,
                                    opportunityStage: nil,
                                    periodStartTimestamp: nil,
                                    periodEndTimestamp: nil,
                                    periodDescription: nil,
                                    periodType: nil,
                                    sfdcSyncTimestamp: nil,
                                    upsideLedgerUploadTimestamp: nil,
                                    callSummaryID: nil)
        
        /*
        let b = CallCorrectionModel(id: nil,
                                    correctionDescription: "Amend open opportunity total value.",
                                    amount: nil,
                                    originalAmount: nil,
                                    type: CallCorrectionType.openOpportunities.rawValue,
                                    opportunityID: nil)*/
        
        let c = CallCorrectionModel(id: nil,
                                    correctionDescription: "Set your call to a total amount.",
                                    amount: nil,
                                    originalAmount: nil,
                                    type: CallCorrectionType.overrideCall.rawValue,
                                    opportunityID: nil,
                                    opportunityStage: nil,
                                    periodStartTimestamp: nil,
                                    periodEndTimestamp: nil,
                                    periodDescription: nil,
                                    periodType: nil,
                                    sfdcSyncTimestamp: nil,
                                    upsideLedgerUploadTimestamp: nil,
                                    callSummaryID: nil)
        
    
        /*
        let c = CallCorrectionModel(id: nil,
                                    correctionDescription: "Set your call to a total amount.",
                                    amount: nil,
                                    originalAmount: nil,
                                    type: CallCorrectionType.overrideCall.rawValue,
                                    opportunityID: nil)*/
        
        
        return [a, b, c]
    }
}

// MARK: TableView Extension
extension CallCorrectionSelectionVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = Bundle.main.loadNibNamed("StandardCell", owner: self, options: nil)?.first as! StandardCell
        
        cell.heading = self.correctionTypes![indexPath.row].type ?? "---"
        cell.content = self.correctionTypes![indexPath.row].correctionDescription ?? "---"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        self.dismiss(animated: true) {
            self.delegate?.passCallCorrectionType(correctionType: self.correctionTypes![indexPath.row])
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.correctionTypes?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65.0
    }
    
}
