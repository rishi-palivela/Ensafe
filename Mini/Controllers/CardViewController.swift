//
//  CardViewController.swift
//  Mini
//
//  Created by Sai Hemanth Bheemreddy on 22/06/20.
//  Copyright © 2020 StarDust. All rights reserved.
//

import UIKit
import MapKit

protocol CardViewControllerDelegate {
    func expandCard()
    func collapseCard()
    func navigateTo(placemark: MKPlacemark)
}

class CardViewController: UIViewController {

    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var handleArea: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var canCollapse = true
    var delegate: CardViewControllerDelegate?
    
    private var localSearch: MKLocalSearch?
    private var searchResults = [MKMapItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let blurEffect: UIBlurEffect!
        if #available(iOS 13.0, *) {
            blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        } else {
            blurEffect = UIBlurEffect(style: .light)
        }
        visualEffectView.effect = blurEffect

        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func prepareToCollapse() {
        searchBarCancelButtonClicked(searchBar)
    }

}

extension CardViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        canCollapse = false
        delegate?.expandCard()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        canCollapse = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        localSearch?.cancel()
        searchResults.removeAll()
        tableView.reloadData()
        
        delegate?.collapseCard()
    }
    
    /// Called when user types into Search Bar
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        localSearch?.cancel()
        
        if(searchText.isEmpty ?? false) {
            searchResults.removeAll()
            tableView.reloadData()
        }
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchText
        
        localSearch = MKLocalSearch(request: searchRequest)
        localSearch!.start { response, error in
            guard let mapItems = response?.mapItems else {
                print(error?.localizedDescription ?? "Unknown Error")
//                TODO: show error message to user
                return
            }
            
            self.searchResults = mapItems
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
}

extension CardViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Search Result Cell")
        let placemark = searchResults[indexPath].placemark
        
        let addressComponents = [placemark.subLocality, placemark.locality, placemark.subAdministrativeArea,
                                 placemark.administrativeArea, placemark.postalCode]
        let addressComponentsUnwrapped  = addressComponents.filter { $0 != nil }.map { $0! }
        
        cell.textLabel?.text = placemark.name
        cell.detailTextLabel?.text = addressComponentsUnwrapped.joined(separator: ", ")
        
        cell.backgroundColor = nil
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.navigateTo(placemark: searchResults[indexPath].placemark)
    }
    
}
