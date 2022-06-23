//
//  CallCorrectionCell.swift
//  Upside
//
//  Created by Luke Hammer on 5/26/22.
//

import UIKit

class CallCorrectionCell: UITableViewCell {
    
    @IBOutlet weak var holderView: UIView!
    
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.holderView.layer.cornerRadius = 8.0
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
