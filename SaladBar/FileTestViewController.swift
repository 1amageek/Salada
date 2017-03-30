//
//  FileTestViewController.swift
//  Salada
//
//  Created by 1amageek on 2017/03/01.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import UIKit
import Firebase

class FileTestViewController: UIViewController {
    
    var task: FIRStorageUploadTask? {
        didSet {
            self.pause = task?.observe(.pause, handler: { (snapshot) in
                print(snapshot)
            })
            
            self.progress = task?.observe(.progress, handler: { (snapshot) in
                print(snapshot)
            })
            
            self.resume = task?.observe(.resume, handler: { (snapshot) in
                print(snapshot)
            })
        }
    }
    
    var pause: String?
    
    var progress: String?
    
    var resume: String?
    
    @IBAction func stop(_ sender: Any) {
        self.task?.pause()
    }
    
    @IBAction func resume(_ sender: Any) {
        self.task?.resume()
    }
    
    @IBAction func start(_ sender: Any) {
        let image: UIImage = #imageLiteral(resourceName: "pexels-photo.jpg")
        let data: Data = UIImageJPEGRepresentation(image, 1)!

        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("sample")
            .appendingPathExtension("jpg")
        
        try! data.write(to: tmpURL)
        let ref: FIRStorageReference = FIRStorage.storage().reference().child("test")
        
        self.task = ref.putFile(tmpURL, metadata: nil) { (metadata, error) in

            if let error: Error = error as Error? {
                print(error)
                return
            }
            
            print("completed")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        
        
    }
    
}
