//
//  ShindigCell.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-17.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit

class ShindigCell: UITableViewCell {

	@IBOutlet weak var title: UILabel!
	@IBOutlet weak var detail: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
