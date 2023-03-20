//
//  ViewController.swift
//  HitList
//
//  Created by Dat on 20/03/2023.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    private var names = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "The List"
        tableView.registerClass(UITableViewCell.self)
    }

    @IBAction func addName(_ sender: Any) {
        let alert = UIAlertController(title: "New Name", message: "Add a new name", preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default) {[unowned self] action in
            guard let name = alert.textFields?.first?.text else { return }
            self.names.append(name)
            self.tableView.reloadData()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addTextField()
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return names.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(UITableViewCell.self)
        cell.textLabel?.text = names[indexPath.row]
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

