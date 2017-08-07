//
//  ChatViewCell.swift
//  Chat
//
//  Created by 1amageek on 2017/01/30.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit

class ChatViewCell: UICollectionViewCell {

    override func layoutSubviews() {
        super.layoutSubviews()
        _ = calculateSize()
    }
    
    func calculateSize() -> CGSize {
        return CGSize(width: self.bounds.width, height: self.bounds.height)
    }
    
}
