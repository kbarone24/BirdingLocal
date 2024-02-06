//
//  SearchLocationController.swift
//  Birding Local
//
//  Created by Kenny Barone on 11/26/23.
//

import Foundation
import UIKit
import Combine
import MapKit

protocol SearchLocationDelegate: NSObject {
    func finishPassing(searchResult: SearchResult)
}

class SearchLocationController: UIViewController {
    typealias Input = SearchLocationViewModel.Input
    typealias DataSource = UITableViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    private let viewModel: SearchLocationViewModel
    private let searchText = PassthroughSubject<String, Never>()
    private var subscriptions = Set<AnyCancellable>()

    weak var delegate: SearchLocationDelegate?

    private lazy var dataSource: DataSource = {
        let dataSource = DataSource(tableView: tableView) { tableView, indexPath, item in
            switch item {
            case .item(let searchResult):
                let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultCell.reuseID, for: indexPath) as? SearchResultCell
                cell?.configure(searchResult: searchResult)
                return cell
            }
        }
        return dataSource
    }()

    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 300, right: 0)
        table.backgroundColor = .white
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.register(SearchResultCell.self, forCellReuseIdentifier: SearchResultCell.reuseID)
        table.rowHeight = 48
        table.delegate = self
        return table
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.color = .darkGray
        view.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        return view
    }()

    private var isWaitingForDatabaseFetch = false {
        didSet {
            DispatchQueue.main.async {
                if self.isWaitingForDatabaseFetch {
                    self.tableView.layoutIfNeeded()
                    let tableOffset = self.tableView.contentSize.height + 10
                    self.activityIndicator.snp.removeConstraints()
                    self.activityIndicator.snp.makeConstraints {
                        $0.centerX.equalToSuperview()
                        $0.width.height.equalTo(30)
                        $0.top.equalTo(tableOffset)
                    }
                    self.activityIndicator.startAnimating()
                } else {
                    self.activityIndicator.stopAnimating()
                }
            }
        }
    }

    enum Section: Hashable {
        case main
    }

    enum Item: Hashable {
        case item(searchResult: SearchResult)
    }

    private lazy var backArrow: UIButton = {
        let button = UIButton(withInsets: NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
        button.setImage(UIImage(asset: .BackArrow), for: .normal)
        button.addTarget(self, action: #selector(backTap), for: .touchUpInside)
        return button
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Search Location"
        label.textColor = UIColor(color: .PrimaryBlue)
        label.font = TextStyle.boldedHeader.uiFont
        return label
    }()

    private lazy var separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(color: .PrimaryGray)?.withAlphaComponent(0.25)
        return view
    }()

    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.barStyle = .default
        searchBar.tintColor = UIColor(color: .PrimaryGray)
        searchBar.barTintColor = .white
        searchBar.searchTextField.textColor = UIColor(color: .PrimaryBlue)
        searchBar.searchTextField.backgroundColor = .white
        searchBar.backgroundImage = UIImage()
        searchBar.layer.shadowOpacity = 0
        searchBar.layer.borderColor = UIColor(color: .PrimaryGray)?.withAlphaComponent(0.25).cgColor
        searchBar.layer.borderWidth = 1
        searchBar.layer.cornerRadius = 4
        searchBar.returnKeyType = .done
        searchBar.delegate = self
        searchBar.setMagnifyingGlassColorTo(color: UIColor(color: .PrimaryGray) ?? .gray)
        searchBar.setClearButtonColorTo(color: UIColor(color: .PrimaryGray) ?? .gray)
        return searchBar
    }()

    init(viewModel: SearchLocationViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()

        let input = Input(searchText: searchText)
        let output = viewModel.bind(to: input)

        output.snapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.dataSource.apply(snapshot, animatingDifferences: false)
                self?.isWaitingForDatabaseFetch = false
            }
            .store(in: &subscriptions)
    }

    private func setUpView() {
        view.backgroundColor = .white

        view.addSubview(backArrow)
        backArrow.snp.makeConstraints {
            $0.leading.equalTo(20)
            $0.top.equalTo(15)
        }

        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(20)
            $0.centerX.equalToSuperview()
        }

        view.addSubview(separatorLine)
        separatorLine.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(5)
            $0.height.equalTo(1)
            $0.top.equalTo(titleLabel.snp.bottom).offset(27)
        }

        view.addSubview(searchBar)
        searchBar.snp.makeConstraints {
            $0.top.equalTo(separatorLine.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(54)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(16)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        tableView.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(tableView).offset(100)
            $0.width.height.equalTo(30)
        }

        searchBar.becomeFirstResponder()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func backTap() {
        DispatchQueue.main.async {
            self.dismiss(animated: true)
        }
    }
}

extension SearchLocationController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = dataSource.snapshot().itemIdentifiers[indexPath.row]
        switch item {
        case .item(searchResult: let searchResult):
            let searchRequest = MKLocalSearch.Request(completion: searchResult.completerResult)
            // pause user interaction and show loading indicator
            tableView.isUserInteractionEnabled = false
            isWaitingForDatabaseFetch = true

            MKLocalSearch(request: searchRequest).start { [weak self] response, error in
                // TODO: Error handling
                if let response, let placemark = response.mapItems.first?.placemark {
                    searchResult.coordinate = placemark.coordinate
                }
                
                DispatchQueue.main.async {
                    self?.delegate?.finishPassing(searchResult: searchResult)
                    self?.dismiss(animated: true)
                }
            }
        }
    }
}

extension SearchLocationController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText.send(searchText)
        self.isWaitingForDatabaseFetch = true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
