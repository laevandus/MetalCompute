//
//  ViewController.swift
//  MetalCompute
//
//  Created by Toomas Vahter on 01/11/2017.
//  Copyright © 2017 Augmented Code. All rights reserved.
//

import UIKit

final class ViewController: UIViewController
{
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let paragraphStyle = NSParagraphStyle.default.mutableCopy(with: nil) as! NSMutableParagraphStyle
        paragraphStyle.alignment = .center
        
        let attributes = [NSAttributedStringKey.paragraphStyle: paragraphStyle]
        textView.textStorage.setAttributedString(NSAttributedString(string: "Tap on the compute.", attributes: attributes))
    }
    
    
    @IBAction func compute(_ sender: Any)
    {
        // Create float array with 1000 random elements.
        var input = ContiguousArray<Float>(repeating: 0.0, count: 1000)
        (0..<1000).forEach({ input[$0] = Float(arc4random()) / Float(UInt32.max) * 10.0 })
        
        // Pass data to DataConverter what uses Metal.
        let converter = DataConverter()
        let output = converter.process(data: input)
        
        // For printing create strings from input and output float arrays by using zip function and then convering input and output pairs into strings.
        let lines = zip(input, output).map { (input, output) -> String in
            return String(describing: "\(input) -> \(output)")
        }
        
        // Center align the final string what is set to text view.
        let paragraphStyle = NSParagraphStyle.default.mutableCopy(with: nil) as! NSMutableParagraphStyle
        paragraphStyle.alignment = .center
        let attributes = [NSAttributedStringKey.paragraphStyle: paragraphStyle]
        
        // Join lines and update text view.
        let outputDescription = NSAttributedString(string: lines.joined(separator: "\n"), attributes: attributes)
        textView.textStorage.setAttributedString(outputDescription)
    }
}

