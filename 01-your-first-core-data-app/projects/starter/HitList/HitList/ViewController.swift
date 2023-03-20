//
//  ViewController.swift
//  HitList
//
//  Created by Dat on 20/03/2023.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    private var people = [NSManagedObject]()
    
    private var persistentContainer: NSPersistentContainer {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer
    }
    
    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "The List"
        tableView.registerClass(UITableViewCell.self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadPeople() { self.tableView.reloadData() }
    }

    @IBAction func addName(_ sender: Any) {
        let alert = UIAlertController(title: "New Name", message: "Add a new name", preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default) {[unowned self] action in
            guard let name = alert.textFields?.first?.text else { return }
            self.save(name) { self.tableView.reloadData() }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addTextField()
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func save(_ name: String, completion: () -> Void) {
        guard let entity = NSEntityDescription.entity(forEntityName: "Person", in: context) else { return }
        let person = NSManagedObject(entity: entity, insertInto: context)
        person.setValue(name, forKey: "name")
        do {
            try context.save()
            people.append(person)
            completion()
        } catch {
            print("Save with error: \(error.localizedDescription)")
        }
    }
    
    private func loadPeople(completion: () -> Void) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Person")
        do {
            people = try context.fetch(fetchRequest)
            completion()
        } catch {
            print("Load people with error: \(error.localizedDescription)")
        }
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return people.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(UITableViewCell.self)
        let person = people[indexPath.row]
        cell.textLabel?.text = person.valueForKey("name")
        return cell
    }
}

extension UITableView {
    func registerNib<T>(_ type: T.Type) {
        let className = String(describing: type)
        register(UINib(nibName: className, bundle: nil), forCellReuseIdentifier: className)
    }
    
    func registerClass<T: UITableViewCell>(_ type: T.Type) {
        let className = String(describing: type)
        register(type, forCellReuseIdentifier: className)
    }
    
    func dequeueReusableCell<T: UITableViewCell>(_ type: T.Type) -> T {
        let className = String(describing: type)
        return dequeueReusableCell(withIdentifier: className) as! T
    }
}

extension NSManagedObject {
    func valueForKey<T>(_ key: String) -> T? {
        return value(forKey: key) as? T
    }
}

