//
//  TableViewCell.swift
//  Salada
//
//  Created by 1amageek on 2017/05/31.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var judgmentLabel: UILabel!
    @IBOutlet weak var expectLabel: UILabel!

    @IBAction func decrementAction(_ sender: Any) {
        self.decrement?()
    }

    @IBAction func incrementAction(_ sender: Any) {
        self.increment?()
    }

    var increment: (() -> Void)?

    var decrement: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {

    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {

    }

}
