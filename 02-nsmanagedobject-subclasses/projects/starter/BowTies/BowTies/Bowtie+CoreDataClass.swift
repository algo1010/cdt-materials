//
//  Bowtie+CoreDataClass.swift
//  BowTies
//
//  Created by Dat on 20/03/2023.
//  Copyright © 2023 Razeware. All rights reserved.
//
//

import Foundation
import CoreData
import UIKit

@objc(Bowtie)
public class Bowtie: NSManagedObject {
  func fillWithDict(_ dict: [String : Any]) {
    id = UUID(uuidString: dict["id"] as! String)
    name = dict["name"] as? String
    searchKey = dict["searchKey"] as? String
    rating = dict["rating"] as! Double
    let colorDict = dict["tintColor"] as! [String: Any]
    tintColor = UIColor.color(dict: colorDict)
    let imageName = dict["imageName"] as? String
    let image = UIImage(named: imageName!)
    photoData = image!.pngData()!
    lastWorn = dict["lastWorn"] as? Date
    let timesNumber = dict["timesWorn"] as! NSNumber
    timesWorn = timesNumber.int32Value
    isFavorite = dict["isFavorite"] as! Bool
    url = URL(string: dict["url"] as! String)
  }
}

private extension UIColor {
  static func color(dict: [String : Any]) -> UIColor? {
    guard let red = dict["red"] as? NSNumber,
          let green = dict["green"] as? NSNumber,
          let blue = dict["blue"] as? NSNumber else {
      return nil
    }
    return UIColor(red: CGFloat(truncating: red) / 255.0, green: CGFloat(truncating: green) / 255.0, blue: CGFloat(truncating: blue) / 255.0, alpha: 1)
  }
}
