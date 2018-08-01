//
//  TestViewController.swift
//  Quick Maths
//
//  Created by Kevin Tan on 7/31/18.
//  Copyright © 2018 KxTGames. All rights reserved.
//

import UIKit

class TestViewController: UIViewController {

    var images: [CGImage]

    init(images: [CGImage]) {
        self.images = images
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        var originY: CGFloat = 0
        for image in images {
            let uiImage = UIImage(cgImage: image)
            let imageView = UIImageView(image: uiImage)
            imageView.center.x = view.center.x
            imageView.frame.origin.y = originY
            
            originY += imageView.frame.height
            view.addSubview(imageView)
        }

        let backButton = UIButton(frame: CGRect(x: 20, y: 20, width: 100, height: 100))
        backButton.setTitle("bacK", for: .normal)
        backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        view.addSubview(backButton)
    }

    @objc func back() {
        self.dismiss(animated: true, completion: nil)
    }

}
