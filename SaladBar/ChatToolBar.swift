//
//  ChatToolBar.swift
//  Chat
//
//  Created by 1amageek on 2017/01/31.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit

class ChatToolBar: UIView {
    
    private let textViewMinHeight: CGFloat = 20
    private let textViewMaxHeight: CGFloat = 150
    private let textViewInset: UIEdgeInsets = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)
    private let textViewContainerInset: UIEdgeInsets = UIEdgeInsets(top: 4, left: 3, bottom: 4, right: 3)
    
    var items: [UIBarButtonItem]? {
        return self.toolbar.items
    }
    
    convenience init() {
        let frame: CGRect = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 0)
        self.init(frame: frame)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(textView)
        self.addSubview(toolbar)
        self.backgroundColor = .white
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let constraintSize: CGSize = CGSize(width: self.bounds.width - textViewInset.left - textViewInset.right,
                                            height: CGFloat.greatestFiniteMagnitude)
        var textViewSize: CGSize = self.textView.sizeThatFits(constraintSize)
        if textViewMaxHeight < textViewSize.height {
            textViewSize.height = textViewMaxHeight
            textView.isScrollEnabled = true
        } else {
            textViewSize.height = max(textViewSize.height, textViewMinHeight)
            textView.isScrollEnabled = false
        }
        textView.frame = CGRect(x: textViewInset.left,
                                y: textViewInset.top,
                                width: constraintSize.width,
                                height: textViewSize.height)
        toolbar.sizeToFit()
        toolbar.frame = CGRect(x: 0,
                               y: textView.frame.maxY + textViewInset.bottom,
                               width: self.bounds.width,
                               height: toolbar.bounds.height)
        
        self.bounds = CGRect(x: 0,
                             y: 0,
                             width: self.bounds.width,
                             height: toolbar.frame.maxY)
    }
    
    func setItems(_ items: [UIBarButtonItem]?, animated: Bool) {
        self.toolbar.setItems(items, animated: animated)
    }
    
    override func sizeToFit() {
        super.sizeToFit()
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    private(set) lazy var textView: UITextView = {
        // TODO: placeholder text
        var textView = UITextView(frame: self.bounds)
        textView.isScrollEnabled = false
        textView.text = ""
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.textContainerInset = self.textViewContainerInset
        textView.backgroundColor = .white
        textView.sizeToFit()
        return textView
    }()
    
    private(set) lazy var toolbar: Toolbar = {
        var toolbar: Toolbar = Toolbar()
        toolbar.sizeToFit()
        return toolbar
    }()
    
    // MARK: -
    
    override func draw(_ rect: CGRect) {
        let line: UIBezierPath = UIBezierPath()
        line.move(to: rect.origin)
        line.addLine(to: CGPoint(x: rect.width, y: rect.origin.y))
        UIColor.lightGray.setStroke()
        line.lineWidth = 1
        line.stroke()
    }
    
}

extension ChatToolBar {
    
    /**
     translucent toolbar
     */
    class Toolbar: UIToolbar {
        
        convenience init() {
            let frame: CGRect = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40)
            self.init(frame: frame)
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.backgroundColor = .clear
            self.isOpaque = false
            self.isTranslucent = true
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func draw(_ rect: CGRect) {
            // translucent
        }
        
    }
}
