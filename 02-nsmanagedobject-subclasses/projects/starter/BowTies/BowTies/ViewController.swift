/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import CoreData

class ViewController: UIViewController {
  // MARK: - IBOutlets
  @IBOutlet weak var segmentedControl: UISegmentedControl!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var ratingLabel: UILabel!
  @IBOutlet weak var timesWornLabel: UILabel!
  @IBOutlet weak var lastWornLabel: UILabel!
  @IBOutlet weak var favoriteLabel: UILabel!
  @IBOutlet weak var wearButton: UIButton!
  @IBOutlet weak var rateButton: UIButton!
  
  var managedContext: NSManagedObjectContext!
  
  var currentBowtie: Bowtie!
  
  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    insertSampleData()
    loadDefaultBowtie()
  }
  
  // MARK: - IBActions
  
  @IBAction func segmentedControl(_ sender: UISegmentedControl) {
    guard let title = sender.titleForSegment(at: sender.selectedSegmentIndex) else { return }
    let fetchRequest = Bowtie.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "%K = %@", argumentArray: [#keyPath(Bowtie.searchKey), title])
    
    do {
      let bowties = try managedContext.fetch(fetchRequest)
      currentBowtie = bowties.first
      populate(bowtie: currentBowtie)
    } catch {
      print("Change bow tie with error: \(error.localizedDescription)")
    }
  }
  
  @IBAction func wear(_ sender: UIButton) {
    let times = currentBowtie.timesWorn
    currentBowtie.timesWorn = times + 1
    currentBowtie.lastWorn = Date()
    
    do {
      try managedContext.save()
      populate(bowtie: currentBowtie)
    } catch {
      print("Save wear info with error: \(error.localizedDescription)")
    }
  }
  
  @IBAction func rate(_ sender: UIButton) {
    let alert = UIAlertController(title: "New Rating", message: "Rate this bow tie", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
      guard let rate = alert.textFields?.first?.text, let number = Double(rate) else { return }
      self.updateRating(number)
    })
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    alert.addTextField { textField in textField.keyboardType = .decimalPad }
    present(alert, animated: true)
  }
}

extension ViewController {
  private var sampleDataPath: URL? {
    return Bundle.main.url(forResource: "SampleData", withExtension: "plist")
  }
  
  private func insertSampleData() {
    let fetchRequest = Bowtie.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "searchKey != nil")
    
    let count = try! managedContext.count(for: fetchRequest)
    guard count == 0 else { return }
    
    guard let sampleDataPath = sampleDataPath else { return }
    let items = try! NSArray(contentsOf: sampleDataPath, error: ())
    
    for item in items {
      guard let entity = NSEntityDescription.entity(forEntityName: "Bowtie", in: managedContext) else { continue }
      let bowtie = Bowtie(entity: entity, insertInto: managedContext)
      let dict = item as! [String : Any]
      bowtie.fillWithDict(dict)
    }
    
    do {
      try managedContext.save()
    } catch {
      print("Inset sample data with error: \(error.localizedDescription)")
    }
  }
  
  private func loadDefaultBowtie() {
    let firstTitle = segmentedControl.titleForSegment(at: 0)!
    let fetchRequest = Bowtie.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "%K = %@", argumentArray: [#keyPath(Bowtie.searchKey), firstTitle])
    
    do {
      let bowties = try managedContext.fetch(fetchRequest)
      currentBowtie = bowties.first
      populate(bowtie: bowties.first!)
    } catch {
      print("Load default bowtie with error: \(error.localizedDescription)")
    }
  }
  
  private func populate(bowtie: Bowtie) {
    guard let imageData = bowtie.photoData as Data?,
          let lastWorn = bowtie.lastWorn as Date?,
          let tintColor = bowtie.tintColor as? UIColor else {
      return
    }
    imageView.image = UIImage(data: imageData)
    nameLabel.text = bowtie.name
    ratingLabel.text = "Rating: \(bowtie.rating)/5"
    timesWornLabel.text = "# times worn: \(bowtie.timesWorn)"
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .short
    dateFormatter.timeStyle = .none
    lastWornLabel.text =
    "Last worn: " + dateFormatter.string(from: lastWorn)
    favoriteLabel.isHidden = !bowtie.isFavorite
    view.tintColor = tintColor
  }
  
  private func updateRating(_ rate: Double) {
    currentBowtie.rating = rate
    do {
      try managedContext.save()
      populate(bowtie: currentBowtie)
    } catch {
      print("Update rating with error: \(error.localizedDescription)")
    }
  }
}
