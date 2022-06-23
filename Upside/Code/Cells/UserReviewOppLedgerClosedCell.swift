//
//  UserReviewOppLedgerClosedCell.swift
//  Upside
//
//  Created by Luke Hammer on 5/29/22.
//

import UIKit

class UserReviewOppLedgerClosedCell: UITableViewCell {
    
    @IBOutlet weak var holderView: UIView!
    @IBOutlet weak var opportunityLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var changeLabel: UILabel!
    @IBOutlet weak var amendedLabel: UILabel!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.holderView.layer.cornerRadius = 10.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
