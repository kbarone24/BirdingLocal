//
//  SearchResultCell.swift
//  Birding Local
//
//  Created by Kenny Barone on 10/25/23.
//

import Foundation
import UIKit

class SearchResultCell: UITableViewCell {
    private lazy var titleContainer = UIView()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Colors.PrimaryBlue.color
        label.font = Fonts.SFProMedium.font(with: 14)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Colors.AccentBlue.color
        label.font = Fonts.SFProMedium.font(with: 12.5)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var bottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.849, green: 0.849, blue: 0.849, alpha: 1)
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .white

        contentView.addSubview(titleContainer)
        titleContainer.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.centerY.equalToSuperview()
        }

        titleContainer.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview()
            $0.top.equalToSuperview()
        }

        titleContainer.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview()
            $0.top.equalTo(titleLabel.snp.bottom).offset(2)
            $0.bottom.equalToSuperview()
        }

        contentView.addSubview(bottomLine)
        bottomLine.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
    }

    func configure(searchResult: SearchResult) {
        titleLabel.text = searchResult.titleString
        subtitleLabel.text = searchResult.subtitleString
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
