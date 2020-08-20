//
//  gosspTableViewCell.swift
//  Gossp
//
//  Created by Kaan Karay on 10.08.2020.
//  Copyright © 2020 Kaan Karay. All rights reserved.
//

import UIKit

class gosspTableViewCell: UITableViewCell {
  
  @IBOutlet var voteButtonsOutlet: [UIButton]!
  
  @IBOutlet var voteCountLabel: UILabel!
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var contextTextView: UITextView!
  @IBOutlet var cellImageView: UIImageView!
  @IBOutlet var commentImage: UIImageView!
  @IBOutlet var commentsCountLabel: UILabel!
  @IBOutlet var creatorCell: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
}
