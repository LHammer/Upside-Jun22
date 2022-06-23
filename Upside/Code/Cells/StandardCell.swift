//
//  StandardCell.swift
//  Upside
//
//  Created by Luke Hammer on 4/30/22.
//


import UIKit

class StandardCell: UITableViewCell {
    
    @IBOutlet weak var holderView: UIView!
    
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    
    var heading = "---" {
        didSet {
            self.headingLabel.text = self.heading
        }
    }
    
    var content = "---" {
        didSet {
            self.contentLabel.text = self.content
        }
    }
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.holderView.layer.cornerRadius = 5.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
