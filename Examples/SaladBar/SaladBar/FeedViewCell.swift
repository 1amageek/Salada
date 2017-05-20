//
//  FeedViewCell.swift
//  SaladBar
//
//  Created by 1amageek on 2017/05/20.
//  Copyright © 2017年 Stamp Inc. All rights reserved.
//

import UIKit

class FeedViewCell: UITableViewCell {
    
    var id: String?

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.id = nil
    }
    
}
