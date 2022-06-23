//
//  UserCallSummaryCell.swift
//  Upside
//
//  Created by Luke Hammer on 6/1/22.
//

import UIKit

class UserCallSummaryCell: UITableViewCell {
    
    @IBOutlet weak var holderView: UIView!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        self.holderView.layer.cornerRadius = 10.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
