//
//  MessageViewController.swift
//  Chat
//
//  Created by 1amageek on 2017/02/14.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit
import Firebase

class MessageViewController: ChatViewController {

    let room: Room = Room()

    let user: User = User()
    
    private(set) var dataSource: DataSource<Message>?
    
    override func loadView() {
        super.loadView()
        self.collectionView.register(ChatTextRightCell.self, forCellWithReuseIdentifier: "ChatTextRightCell")
        self.collectionView.register(ChatTextLeftCell.self, forCellWithReuseIdentifier: "ChatTextLeftCell")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        room.name = "Room"
        user.name = "User"

        //room.save()
        user.save()
        
        let fixedSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixedSpace.width = 16
        
        self.toolBar.setItems([
            //self.cameraBarButtonItem,
            //self.bookBarButtonItem,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            self.sendBarButtonItem,
            fixedSpace
            ], animated: false)

    }
    
    private(set) lazy var sendBarButtonItem: UIBarButtonItem = {
        let barButtonItem: UIBarButtonItem = UIBarButtonItem(title: "Send", style: .plain, target: self, action: #selector(send))
        barButtonItem.isEnabled = false
        return barButtonItem
    }()
    
    private(set) lazy var cameraBarButtonItem: UIBarButtonItem = {
        let barButtonItem: UIBarButtonItem = UIBarButtonItem(title: "Camera", style: .plain, target: self, action: #selector(camera))
        barButtonItem.isEnabled = true
        return barButtonItem
    }()
    
    private(set) lazy var bookBarButtonItem: UIBarButtonItem = {
        let barButtonItem: UIBarButtonItem = UIBarButtonItem(title: "Book", style: .plain, target: self, action: #selector(book))
        barButtonItem.isEnabled = true
        return barButtonItem
    }()
    
    @objc func send() {        
        guard let text: String = self.toolBar.textView.text else {
            return
        }
        let message: Message = Message()
        message.userID = user.id
        message.text = text
        room.messages.insert(message.id)
        room.save()
        self.toolBar.textView.text = ""
        self.layoutToolbar()
        self.sendBarButtonItem.isEnabled = false
    }

    @objc func camera() {
//        let storyboard: UIStoryboard = UIStoryboard(name: "Camera", bundle: nil)
//        let viewController: CameraViewController = storyboard.instantiateInitialViewController() as! CameraViewController
//        viewController.room = self.room
//        self.present(viewController, animated: true, completion: nil)
    }
    
    @objc func book() {
        
    }
    
    // MARK: - Datasorce
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSource?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ChatViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChatViewCell", for: indexPath) as! ChatViewCell
        return cell
//        self.dataSource.object
//        
//        switch Chat.ContentType(rawValue: transcript.contentType)! {
//        case .text:
//            if self.user!.uid == transcript.userID {
//                let cell: ChatTextRightCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChatTextRightCell", for: indexPath) as! ChatTextRightCell
//                cell.text = transcript.text
//                return cell
//            } else {
//                let cell: ChatTextLeftCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChatTextLeftCell", for: indexPath) as! ChatTextLeftCell
//                cell.text = transcript.text
//                return cell
//            }
//        default:
//            let cell: ChatViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChatViewCell", for: indexPath) as! ChatViewCell
//            return cell
//        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let transcript: Transcript = self.transcripts[indexPath.item]
//        
//        switch Chat.ContentType(rawValue: transcript.contentType)! {
//        case .text:
//            if self.user!.uid == transcript.userID {
//                let cell: ChatTextRightCell = ChatTextRightCell(frame: self.view.bounds)
//                cell.name = "name"
//                cell.text = transcript.text
//                return cell.calculateSize()
//            } else {
//                let cell: ChatTextLeftCell = ChatTextLeftCell(frame: self.view.bounds)
//                cell.name = "name"
//                cell.text = transcript.text
//                return cell.calculateSize()
//            }
//        default: return .zero
//        }
//        
//    }

    // MARK: - UITextViewDelegate
    
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        self.sendBarButtonItem.isEnabled = textView.text.characters.count > 0
    }

}

