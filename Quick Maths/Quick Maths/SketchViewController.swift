//
//  ViewController.swift
//  Quick Maths
//
//  Created by Kevin Tan on 7/31/18.
//  Copyright © 2018 KxTGames. All rights reserved.
//

import UIKit

class SketchViewController: UIViewController {
    private let strokeWidth: CGFloat = 10
    private let strokeColor = UIColor.black

    @IBOutlet var sketchImageView: UIImageView!
    @IBOutlet var tempImageView: UIImageView!
    private var lastPoint = CGPoint.zero
    private var isStroke = false

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func clearTapped() {
        sketchImageView.image = nil
    }

    // MARK: Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        isStroke = false

        if let touch = touches.first {
            lastPoint = touch.location(in: tempImageView)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        isStroke = true

        if let touch = touches.first {
            let currentPoint = touch.location(in: tempImageView)
            drawLine(from: lastPoint, to: currentPoint)

            lastPoint = currentPoint
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        if !isStroke {
            drawLine(from: lastPoint, to: lastPoint)
        }

        UIGraphicsBeginImageContext(sketchImageView.frame.size)
        defer { UIGraphicsEndImageContext() }

        sketchImageView.image?.draw(in: sketchImageView.bounds)
        tempImageView.image?.draw(in: sketchImageView.bounds)

        sketchImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        tempImageView.image = nil
    }

    // MARK: - Helper Functions

    private func drawLine(from fromPoint: CGPoint, to toPoint: CGPoint) {
        UIGraphicsBeginImageContext(sketchImageView.frame.size)
        defer { UIGraphicsEndImageContext() }

        if let context = UIGraphicsGetCurrentContext() {
            tempImageView.image?.draw(in: tempImageView.bounds)

            context.move(to: fromPoint)
            context.addLine(to: toPoint)
            context.setLineCap(.round)
            context.setLineWidth(strokeWidth)
            context.setStrokeColor(strokeColor.cgColor)
            context.setBlendMode(.normal)

            context.strokePath()

            tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        }
    }

}

