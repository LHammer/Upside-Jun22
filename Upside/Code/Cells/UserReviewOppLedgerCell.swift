//
//  UserReviewOppLedgerCell.swift
//  Upside
//
//  Created by Luke Hammer on 5/20/22.
//

import UIKit

class UserReviewOppLedgerCell: UITableViewCell {
    
    @IBOutlet weak var editBookingsBtn: UIButton!
    
    
    @IBOutlet weak var holderView: UIView!
    @IBOutlet weak var callSelectorSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var oppNameLabel: UILabel!
    @IBOutlet weak var bookingsTotalAmountLabel: UILabel!
    @IBOutlet weak var bookingsCommerceAmountLabel: UILabel!
    @IBOutlet weak var stageLabel: UILabel!
    @IBOutlet weak var productLabel: UILabel!
    @IBOutlet weak var closeDateLabel: UILabel!
    
    /* NEW LABELS */
    @IBOutlet weak var SaaSBookingsLabel: UILabel!
    @IBOutlet weak var otherBookingsLabel: UILabel!
    @IBOutlet weak var usersBookingsTotalLabel: UILabel!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.holderView.layer.cornerRadius = 8.0
        
        self.callSelectorSegmentedControl.backgroundColor = ui_active_aqua
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func editBookingsTapped(_ sender: Any) {
        print("edit bookings.")
    }
    
    
}
