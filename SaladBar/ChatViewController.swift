//
//  ChatViewController.swift
//  Chat
//
//  Created by 1amageek on 2017/01/30.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController, UICollectionViewDelegate {
    
    override func loadView() {
        super.loadView()
        self.view.backgroundColor = .white
        self.view.addSubview(collectionView)
        self.view.addSubview(toolBar)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        layoutToolbar()
        layoutChatView()
        self.collectionView.scrollToBottom(false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func layoutToolbar() {
        toolBar.sizeToFit()
        let toolBarOriginY = self.view.bounds.height - self.toolBar.bounds.height - self.keyboardHeight
        toolBar.frame = CGRect(x: 0, y: toolBarOriginY, width: self.toolBar.bounds.width, height: self.toolBar.bounds.height)
    }
    
    func layoutChatView() {
        var contentInset: UIEdgeInsets = collectionView.contentInset
        contentInset.top = navigationBarHeight
        contentInset.bottom = toolBarHeight
        collectionView.scrollIndicatorInsets = contentInset
        contentInset.top = navigationBarHeight + 8
        contentInset.bottom = toolBarHeight + 8
        collectionView.contentInset = contentInset
    }
    
    // Keyboard
    
    private var navigationBarHeight: CGFloat {
        return (self.navigationController?.navigationBar.frame.height ?? 0) + UIApplication.shared.statusBarFrame.height
    }
    
    private var toolBarHeight: CGFloat {
        return self.keyboardHeight + self.toolBar.bounds.height
    }
    
    private var keyboardHeight: CGFloat = 0
    
    final func keyboardWillShow(notification: Notification) {
        moveToolbar(up: true, notification: notification)
    }
    
    final func keyboardWillHide(notification: Notification) {
        moveToolbar(up: false, notification: notification)
    }
    
    final func moveToolbar(up: Bool, notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        let animationDuration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let animationCurve: UIViewAnimationCurve = UIViewAnimationCurve(rawValue: (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).intValue)!
        self.keyboardHeight = up ? (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height : 0
        
        // Animation
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(animationDuration)
        UIView.setAnimationCurve(animationCurve)
        layoutToolbar()
        layoutChatView()
        UIView.commitAnimations()
        if up {
            self.collectionView.scrollToBottom(true)
        }
    }

    // MARK: -
    
    private(set) lazy var collectionView: ChatView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 4
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .vertical
        let view: ChatView = ChatView(frame: self.view.bounds, collectionViewLayout: layout)
        view.dataSource = self
        view.delegate = self
        view.alwaysBounceVertical = true
        view.alwaysBounceHorizontal = false
        view.register(ChatViewCell.self, forCellWithReuseIdentifier: "ChatViewCell")
        view.backgroundColor = .white
        view.keyboardDismissMode = .onDrag
        return view
    }()
    
    private(set) lazy var toolBar: ChatToolBar = {
        let toolbar: ChatToolBar = ChatToolBar()
        toolbar.textView.delegate = self
        toolbar.sizeToFit()
        return toolbar
    }()
    
}

extension ChatViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}

extension ChatViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        layoutToolbar()
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        textView.scrollRangeToVisible(textView.selectedRange)
    }
    
}
