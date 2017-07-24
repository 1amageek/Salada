//
//  ChatTextCell.swift
//  Chat
//
//  Created by 1amageek on 2017/02/16.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit

class ChatTextCell: ChatViewCell {
    
    var image: UIImage? {
        didSet {
            self.imageView.image = image
        }
    }
    
    var name: String? {
        didSet {
            self.nameLabel.text = text
            self.setNeedsLayout()
        }
    }
    
    var text: String? {
        didSet {
            self.textLabel.text = text
            self.setNeedsLayout()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(balloonView)
        self.contentView.addSubview(imageView)
        self.contentView.addSubview(nameLabel)
        self.contentView.addSubview(textLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
        self.nameLabel.text = nil
        self.textLabel.text = nil
    }
    
    // MARK: -

    private(set) lazy var balloonView: UIView = {
        let view: UIView = UIView(frame: .zero)
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()
    
    private(set) lazy var imageView: UIImageView = {
        let view: UIImageView = UIImageView(frame: .zero)
        view.clipsToBounds = true
        view.backgroundColor = UIColor(white: 0.9, alpha: 1)
        return view
    }()
    
    private(set) lazy var nameLabel: UILabel = {
        let label: UILabel = UILabel(frame: .zero)
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    
    private(set) lazy var textLabel: UILabel = {
        let label: UILabel = UILabel(frame: .zero)
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

}

class ChatTextLeftCell: ChatTextCell {
    
    let imageViewRadius: CGFloat = 16
    let contentInset: UIEdgeInsets = UIEdgeInsets(top: 16, left: 8, bottom: 16, right: 8)
    let textInset: UIEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    var textLabelMaximumWidth: CGFloat {
        return self.bounds.width * 0.55
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.imageView.layer.cornerRadius = imageViewRadius
        self.balloonView.backgroundColor = UIColor(red: 30/255.0, green: 155/255.0, blue: 255/255.0, alpha: 1)
        self.textLabel.textColor = .white
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func calculateSize() -> CGSize {
        
        let imageViewDiameter: CGFloat = imageViewRadius * 2
        let constraintSize: CGSize = CGSize(width: textLabelMaximumWidth, height: CGFloat.greatestFiniteMagnitude)
        let textLabelSize: CGSize = textLabel.sizeThatFits(constraintSize)
        let balloonOriginX: CGFloat = contentInset.left + imageViewDiameter + 8
        let balloonSize: CGSize = CGSize(width: textInset.left + textLabelSize.width + textInset.right, height: textInset.top + textLabelSize.height + textInset.bottom)
        nameLabel.sizeToFit()
        nameLabel.frame = CGRect(x: balloonOriginX, y: contentInset.top, width: nameLabel.bounds.width, height: nameLabel.bounds.height)
        balloonView.frame = CGRect(x: balloonOriginX , y: nameLabel.frame.maxY, width: balloonSize.width, height: balloonSize.height)
        textLabel.frame = CGRect(x: balloonView.frame.minX + textInset.left, y: balloonView.frame.minY + textInset.top, width: textLabelSize.width, height: textLabelSize.height)
        imageView.frame = CGRect(x: contentInset.left, y: balloonView.frame.maxY - imageViewDiameter, width: imageViewDiameter, height: imageViewDiameter)
        return CGSize(width: self.bounds.width, height: balloonView.frame.maxY)
    }
    
}

class ChatTextRightCell: ChatTextCell {
    
    let imageViewRadius: CGFloat = 16
    let contentInset: UIEdgeInsets = UIEdgeInsets(top: 16, left: 8, bottom: 16, right: 8)
    let textInset: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    var textLabelMaximumWidth: CGFloat {
        return self.bounds.width * 0.55
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.imageView.layer.cornerRadius = imageViewRadius
        self.balloonView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        self.textLabel.textColor = .black
        self.nameLabel.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func calculateSize() -> CGSize {
        let imageViewDiameter: CGFloat = imageViewRadius * 2
        let constraintSize: CGSize = CGSize(width: textLabelMaximumWidth, height: CGFloat.greatestFiniteMagnitude)
        let textLabelSize: CGSize = textLabel.sizeThatFits(constraintSize)
        let balloonSize: CGSize = CGSize(width: textInset.left + textLabelSize.width + textInset.right, height: textInset.top + textLabelSize.height + textInset.bottom)
        let balloonOriginX: CGFloat = self.bounds.width - (contentInset.right + imageViewDiameter + 8) - balloonSize.width
        nameLabel.sizeToFit()
        nameLabel.frame = CGRect(x: balloonOriginX, y: contentInset.top, width: nameLabel.bounds.width, height: nameLabel.bounds.height)
        balloonView.frame = CGRect(x: balloonOriginX , y: contentInset.top, width: balloonSize.width, height: balloonSize.height)
        textLabel.frame = CGRect(x: balloonView.frame.minX + textInset.left, y: balloonView.frame.minY + textInset.top, width: textLabelSize.width, height: textLabelSize.height)
        imageView.frame = CGRect(x: self.bounds.width - contentInset.right - imageViewDiameter, y: balloonView.frame.maxY - imageViewDiameter, width: imageViewDiameter, height: imageViewDiameter)
        return CGSize(width: self.bounds.width, height: balloonView.frame.maxY)
    }
    
}
