//
//  HomeScreenTableViewHeader.swift
//  Birding Local
//
//  Created by Kenny Barone on 10/14/23.
//

import Foundation
import UIKit

class HomeScreenTableViewHeader: UITableViewHeaderFooterView {
    private var headerLabel: UILabel = {
        let label = UILabel()
        label.textColor = Colors.AccentWhite.color
        label.font = Fonts.SFProSemibold.font(with: 25)
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        contentView.addSubview(headerLabel)
        headerLabel.snp.makeConstraints {
            $0.leading.equalTo(20)
            $0.centerY.equalToSuperview()
        }
    }

    func configure(title: String) {
        headerLabel.text = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
