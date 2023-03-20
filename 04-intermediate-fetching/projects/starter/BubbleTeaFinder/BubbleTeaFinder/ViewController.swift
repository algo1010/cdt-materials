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
  // MARK: - Properties
  private let filterViewControllerSegueIdentifier = "toFilterViewController"
  private let venueCellIdentifier = "VenueCell"

  lazy var coreDataStack = CoreDataStack(modelName: "BubbleTeaFinder")

  // MARK: - IBOutlets
  @IBOutlet weak var tableView: UITableView!
  
  var venueFetchRequest: NSFetchRequest<Venue>?
  var venues: [Venue] = []
  
  var asyncFetchRequest: NSAsynchronousFetchRequest<Venue>?

  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()

    importJSONSeedDataIfNeeded()
    initVenueFetchRequest()
    fetchAndReload()
    favoriteAllVenues()
  }

  // MARK: - Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    guard segue.identifier == filterViewControllerSegueIdentifier,
          let navController = segue.destination as? UINavigationController,
          let filterVC = navController.topViewController as? FilterViewController
    else { return }
    filterVC.coreDataStack = coreDataStack
    filterVC.delegate = self
  }
  
  private func initVenueFetchRequest() {
    // Because fetch request load from data model is immutable
    // So I will create fetch request in code
//    guard let model = coreDataStack.managedContext.persistentStoreCoordinator?.managedObjectModel,
//          let venueFetchRequestTemplate = model.fetchRequestTemplate(forName: "FetchAllVenueTemplate") as? NSFetchRequest<Venue>
//    else { return }
    self.venueFetchRequest = Venue.fetchRequest()
  }
  
  private func fetchAndReload() {
//    guard let venueFetchRequest = venueFetchRequest else { return }
//    do {
//      venues = try coreDataStack.managedContext.fetch(venueFetchRequest)
//      tableView.reloadData()
//    } catch {
//      print("Fetch venues with error: \(error.localizedDescription)")
//    }
    
    guard let venueFetchRequest = venueFetchRequest else { return }
    asyncFetchRequest = NSAsynchronousFetchRequest<Venue>(fetchRequest: venueFetchRequest, completionBlock: { [unowned self] result in
      guard let venues = result.finalResult else { return }
      
      self.venues = venues
      self.tableView.reloadData()
    })
    
    guard let asyncFetchRequest = asyncFetchRequest else { return }
    
    do {
      try coreDataStack.managedContext.execute(asyncFetchRequest)
    } catch {
      print("Fetch venues with error: \(error.localizedDescription)")
    }
  }
  
  private func favoriteAllVenues() {
    let batchUpdateRequest = NSBatchUpdateRequest(entityName: "Venue")
    batchUpdateRequest.propertiesToUpdate = [#keyPath(Venue.favorite) : true]
    batchUpdateRequest.affectedStores = coreDataStack.managedContext.persistentStoreCoordinator?.persistentStores
    batchUpdateRequest.resultType = .updatedObjectsCountResultType
    
    do {
      let result = try coreDataStack.managedContext.execute(batchUpdateRequest) as! NSBatchUpdateResult
      print("Records updated \(result.result!)")
    } catch {
      print("Favorite all venues with error: \(error.localizedDescription)")
    }
  }
}

// MARK: - IBActions
extension ViewController {
  @IBAction func unwindToVenueListViewController(_ segue: UIStoryboardSegue) {
  }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return venues.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: venueCellIdentifier, for: indexPath)
    let venue = venues[indexPath.row]
    cell.textLabel?.text = venue.name
    cell.detailTextLabel?.text = venue.priceInfo?.priceCategory
    return cell
  }
}

// MARK: - Data loading
extension ViewController {
  func importJSONSeedDataIfNeeded() {
    let fetchRequest = NSFetchRequest<Venue>(entityName: "Venue")

    do {
      let venueCount = try coreDataStack.managedContext.count(for: fetchRequest)
      guard venueCount == 0 else { return }
      try importJSONSeedData()
    } catch let error as NSError {
      print("Error fetching: \(error), \(error.userInfo)")
    }
  }

  func importJSONSeedData() throws {
    // swiftlint:disable:next force_unwrapping
    let jsonURL = Bundle.main.url(forResource: "seed", withExtension: "json")!
    let jsonData = try Data(contentsOf: jsonURL)

    guard
      let jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: [.fragmentsAllowed]) as? [String: Any],
      let responseDict = jsonDict["response"] as? [String: Any],
      let jsonArray = responseDict["venues"] as? [[String: Any]]
    else {
      return
    }

    for jsonDictionary in jsonArray {
      guard
        let contactDict = jsonDictionary["contact"] as? [String: String],
        let specialsDict = jsonDictionary["specials"] as? [String: Any],
        let locationDict = jsonDictionary["location"] as? [String: Any],
        let priceDict = jsonDictionary["price"] as? [String: Any],
        let statsDict = jsonDictionary["stats"] as? [String: Any]
      else {
        continue
      }

      let venueName = jsonDictionary["name"] as? String
      let venuePhone = contactDict["phone"]
      let specialCount = specialsDict["count"] as? Int32 ?? 0

      let location = Location(context: coreDataStack.managedContext)
      location.address = locationDict["address"] as? String
      location.city = locationDict["city"] as? String
      location.state = locationDict["state"] as? String
      location.zipcode = locationDict["postalCode"] as? String
      location.distance = locationDict["distance"] as? Float ?? 0

      let category = Category(context: coreDataStack.managedContext)

      let priceInfo = PriceInfo(context: coreDataStack.managedContext)
      priceInfo.priceCategory = priceDict["currency"] as? String

      let stats = Stats(context: coreDataStack.managedContext)
      stats.checkinsCount = statsDict["checkinsCount"] as? Int32 ?? 0
      stats.tipCount = statsDict["tipCount"] as? Int32 ?? 0

      let venue = Venue(context: coreDataStack.managedContext)
      venue.name = venueName
      venue.phone = venuePhone
      venue.specialCount = specialCount
      venue.location = location
      venue.category = category
      venue.priceInfo = priceInfo
      venue.stats = stats
    }

    coreDataStack.saveContext()
  }
}

extension ViewController: FilterViewControllerDelegate {
  func filterViewController(filter: FilterViewController, didSelectPredicate predicate: NSPredicate?, sortDescriptor: NSSortDescriptor?) {
    guard let venueFetchRequest = venueFetchRequest else { return }
    venueFetchRequest.predicate = nil
    venueFetchRequest.sortDescriptors = nil
    
    venueFetchRequest.predicate = predicate
    if let sortDescriptor = sortDescriptor {
      venueFetchRequest.sortDescriptors = [sortDescriptor]
    }
    
    fetchAndReload()
  }
}
