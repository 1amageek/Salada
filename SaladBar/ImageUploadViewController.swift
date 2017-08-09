//
//  ImageUploadViewController.swift
//  SaladBar
//
//  Created by 1amageek on 2017/08/09.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import UIKit

class ImageUploadViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBAction func uploadAction(_ sender: Any) {

        let item: Item = Item()
        let image: UIImage = #imageLiteral(resourceName: "salada")
        let data: Data = UIImageJPEGRepresentation(image, 0.4)!
        item.file = File(data: data, mimeType: .jpeg)
        item.save { [weak self] (ref, error) in
            if let error = error {
                print(error)
                return
            }
            Item.observeSingle(ref!.key, eventType: .value, block: { (item) in
                self?.imageView.image = image
                self?.imageView.setNeedsDisplay()
            })
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
