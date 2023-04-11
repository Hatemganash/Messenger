
import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    private let spinner = JGProgressHUD()

    private let searchBar : UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search For Users . . . "
        return searchBar
    }()
    
    private let tableview : UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
        
    }()
    
    private let noResultLabel: UILabel = {
       let label = UILabel()
        label.isHidden = true
        label.text = "No Result"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem (title: "Cancel", style: .done , target: self, action: #selector(dismissSelf))

        searchBar.becomeFirstResponder()
    }
    @objc private func dismissSelf () {
        dismiss(animated: true)
        
    }
}

extension NewConversationViewController : UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
    }
}