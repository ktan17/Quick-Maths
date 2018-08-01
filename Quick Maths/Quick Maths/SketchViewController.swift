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
    private var strokeTimer: Timer!
    private var digitImages = [UIImage]()

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
        digitImages.removeAll()
    }

    @objc func sendDigits() {
        if let (image, digitRects) = findDigitsInImage() {
            var digitImages = [CGImage]()

            for rect in digitRects {
                if
                    let croppedDigit = image.cropping(to: rect),
                    let digitImage = drawDigit(digitImage: croppedDigit)
                {
                    digitImages.append(digitImage)
                }
            }

            present(TestViewController(images: digitImages), animated: true, completion: nil)
        }
    }

    // MARK: Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        isStroke = false
        strokeTimer?.invalidate()

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

        strokeTimer = Timer.scheduledTimer(timeInterval: 0.3,
                                           target: self,
                                           selector: #selector(sendDigits),
                                           userInfo: nil,
                                           repeats: false)
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

    private func findDigitsInImage() -> (image: CGImage, rects: [CGRect])? {
        guard
            let image = sketchImageView.image,
            let scaledImage = image.scaled(by: 0.2),
            let png = UIImagePNGRepresentation(scaledImage),
            let compressedImage = UIImage(data: png),
            let compressedCGImage = compressedImage.cgImage
        else { return nil }

        let nRows = compressedCGImage.height
        let nCols = compressedCGImage.width
        let row = [CGFloat](repeating: 0, count: nCols)
        var alphaArray = [[CGFloat]](repeating: row, count: nRows)

        // Extract alpha values into a 2D array
        for i in 0 ..< nRows {
            //print(String(format: "%02d", i), terminator: " ")
            for j in 0 ..< nCols {
                let point = CGPoint(x: j, y: i)
                alphaArray[i][j] = compressedImage.getPixelAlpha(at: point)
                //print("\(alphaArray[i][j] == 0 ? " " : "1")", terminator: "")
            }
            //print("")
        }

        func mergeSegments(_ firstSegment: Segment, _ secondSegment: Segment) -> Segment {
            let leftBound: Int?
            let rightBound: Int?
            if firstSegment.leftBound == nil {
                leftBound = secondSegment.leftBound
            } else if secondSegment.leftBound == nil {
                leftBound = firstSegment.leftBound
            } else {
                leftBound = firstSegment.leftBound! < secondSegment.leftBound! ? firstSegment.leftBound : secondSegment.leftBound
            }

            if firstSegment.rightBound == nil {
                rightBound = secondSegment.rightBound
            } else if secondSegment.rightBound == nil {
                rightBound = firstSegment.rightBound
            } else {
                rightBound = firstSegment.rightBound! > secondSegment.rightBound! ? firstSegment.rightBound : secondSegment.rightBound
            }

            return Segment(leftBound: leftBound, rightBound: rightBound)
        }

        func mergeDigits(_ firstDigit: inout DigitData, _ secondDigit: DigitData) {
            let count = min(firstDigit.segments.count, secondDigit.segments.count)
            for i in 0 ..< count {
                let firstSegment = firstDigit.segments[i]
                let secondSegment = secondDigit.segments[i]
                firstDigit.segments[i] = mergeSegments(firstSegment, secondSegment)
            }

            if firstDigit.segments.count < secondDigit.segments.count {
                firstDigit.segments += secondDigit.segments[firstDigit.segments.count ..< secondDigit.segments.count]
            }

            firstDigit.leftBound = min(firstDigit.leftBound, secondDigit.leftBound)
            firstDigit.topBound = min(firstDigit.topBound, secondDigit.topBound)
            firstDigit.rightBound = max(firstDigit.rightBound, secondDigit.rightBound)
            firstDigit.bottomBound = max(firstDigit.bottomBound, secondDigit.bottomBound)
        }

        struct DigitData {
            var segments: [Segment]
            var leftBound: Int
            var rightBound: Int
            var topBound: Int
            var bottomBound: Int
        }

        struct Segment {
            var leftBound: Int?
            var rightBound: Int?
        }

        // Find separate digits in image
        var digits = [DigitData]()

        // Iterate through each row starting at the very top of the image
        for rowIndex in 0 ..< nRows {
            let row = alphaArray[rowIndex]
            var segments = [Segment]()

            // Extract segments from this row
            var segmentStarted = false
            var currentLeftBound = 0
            for (index, value) in row.enumerated() {
                if value != 0 {
                    if !segmentStarted {
                        currentLeftBound = index
                        segmentStarted = true
                    }
                } else {
                    if segmentStarted {
                        segments.append(Segment(leftBound: currentLeftBound,
                                                rightBound: index - 1))
                        segmentStarted = false
                    }
                }
            }

            // Merge segments with previous ones
            for segment in segments {
                // Find all previous digits that are adjacent to this segment
                var adjacentIndices = [Int]()
                for (index, digit) in digits.enumerated() {
                    let previousRightBound: Int?
                    let previousLeftBound: Int?
                    if digit.segments.count == rowIndex + 1 {
                        previousRightBound = digit.segments[digit.segments.count - 2].rightBound
                        previousLeftBound = digit.segments[digit.segments.count - 2].leftBound

                        if previousRightBound == nil || previousLeftBound == nil {
                            continue
                        }
                    } else {
                        previousRightBound = digit.segments[digit.segments.count - 1].rightBound
                        previousLeftBound = digit.segments[digit.segments.count - 1].leftBound

                        if previousRightBound == nil || previousLeftBound == nil {
                            continue
                        }
                    }

                    if
                        previousRightBound! >= segment.leftBound! - 1 &&
                            previousLeftBound! <= segment.rightBound! + 1
                    {
                        adjacentIndices.append(index)
                    }
                }

                if let firstIndex = adjacentIndices.first {
                    // If there is more than one adjacent segment, merge them.
                    let otherIndices = adjacentIndices.dropFirst()
                    for otherIndex in otherIndices {
                        mergeDigits(&digits[firstIndex], digits[otherIndex])
                    }
                    for otherIndex in otherIndices.reversed() {
                        digits.remove(at: otherIndex)
                    }

                    // Append this segment
                    let digitSegmentCount = digits[firstIndex].segments.count
                    if digitSegmentCount == rowIndex + 1 {
                        digits[firstIndex].segments[digitSegmentCount - 1] = mergeSegments(digits[firstIndex].segments[digitSegmentCount - 1], segment)
                    } else {
                        digits[firstIndex].segments.append(segment)
                    }

                    // Update the digit's bounds
                    let currentLeftBound = digits[firstIndex].leftBound
                    let currentRightBound = digits[firstIndex].rightBound
                    digits[firstIndex].leftBound = min(currentLeftBound, segment.leftBound!)
                    digits[firstIndex].rightBound = max(currentRightBound, segment.rightBound!)
                    if digitSegmentCount != rowIndex + 1 {
                        digits[firstIndex].bottomBound += 1
                    }
                } else {
                    // Create a new DigitData object for this segment
                    let emptySegment = Segment()
                    var newSegments = [Segment](repeating: emptySegment, count: rowIndex)
                    newSegments.append(segment)

                    let digit = DigitData(segments: newSegments,
                                          leftBound: segment.leftBound!,
                                          rightBound: segment.rightBound!,
                                          topBound: rowIndex,
                                          bottomBound: rowIndex)
                    digits.append(digit)
                }
            }

            let emptySegment = Segment()
            for (index, digit) in digits.enumerated() {
                if digit.segments.count == rowIndex {
                    digits[index].segments.append(emptySegment)
                }
            }
        }

        var rects = [CGRect]()
        for digit in digits {
            rects.append(CGRect(x: digit.leftBound,
                                y: digit.topBound,
                                width: digit.rightBound - digit.leftBound,
                                height: digit.bottomBound - digit.topBound))
        }

        return (image: compressedCGImage, rects: rects)
    }

    /// Create an image of the digit scaled to 22x22 pixels; centered inside a 28x28 image.
    private func drawDigit(digitImage: CGImage) -> CGImage? {
        let scaleFactor = 22 / CGFloat(max(digitImage.width, digitImage.height))
        if let scaledImage = UIImage(cgImage: digitImage).scaled(by: scaleFactor) {
            UIGraphicsBeginImageContext(CGSize(width: 28, height: 28))
            defer { UIGraphicsEndImageContext() }

            let xOrigin = 14 - scaledImage.size.width / 2
            let yOrigin = 14 - scaledImage.size.height / 2
            scaledImage.draw(in: CGRect(x: xOrigin,
                                        y: yOrigin,
                                        width: scaledImage.size.width,
                                        height: scaledImage.size.height))

            let image = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
            return image
        } else {
            return nil
        }
    }

}

