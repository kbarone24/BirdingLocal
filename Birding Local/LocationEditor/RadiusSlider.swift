//
//  RadiusSlider.swift
//  Birding Local
//
//  Created by Kenny Barone on 12/28/23.
//

import UIKit
import SnapKit

protocol PrivacySliderDelegate: AnyObject {
    func finishPassing(radius: Double)
}

class RadiusSlider: UIView {
    weak var delegate: PrivacySliderDelegate?
    private lazy var selectedSliderPositon: SliderPosition = .left

    private lazy var sliderContainer = UIView()
    private lazy var sliderBall = SliderBall()

    private var sliderBallXConstraint: Constraint?
    private let sliderBallWidth: CGFloat = 72
    private let sideInset: CGFloat = 48
    private let tickWidth: CGFloat = 8
    private let tickCount = 5

    private var panGestureStartingX: CGFloat = 0

    private var lineWidth: CGFloat {
        let containerWidth = UIScreen.main.bounds.width - sideInset * 2
        let combinedTickWidth = CGFloat(tickCount) * tickWidth
        return (containerWidth - combinedTickWidth) / CGFloat(tickCount - 1)
    }

    init(radius: Double) {
        super.init(frame: .zero)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap(_:))))

        addSubview(sliderContainer)
        sliderContainer.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(sideInset)
            $0.top.bottom.equalToSuperview()
        }

        var leadingConstraint = sliderContainer.snp.leading

        for i in 0...tickCount - 1 {
            let tick = SliderTick(viewPosition: SliderPosition(position: i))
            sliderContainer.addSubview(tick)
            tick.snp.makeConstraints {
                $0.leading.equalTo(leadingConstraint)
                $0.centerY.equalToSuperview()
                $0.height.width.equalTo(tickWidth)
            }

            // No line after final tick
            guard i < tickCount - 1 else {
                continue
            }

            let line = SliderView(viewPosition: SliderPosition(position: i))
            sliderContainer.addSubview(line)
            line.snp.makeConstraints {
                $0.leading.equalTo(tick.snp.trailing)
                $0.centerY.equalToSuperview()
                $0.height.equalTo(3)
                $0.width.equalTo(lineWidth)
            }

            leadingConstraint = line.snp.trailing
        }

        addSubview(sliderBall)
        sliderBall.snp.makeConstraints {
            // updated in setSelected
            sliderBallXConstraint = $0.leading.equalToSuperview().constraint
            $0.centerY.equalToSuperview()
            $0.height.equalTo(36)
            $0.width.equalTo(sliderBallWidth)
        }

        sliderBall.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(pan(_:))))

        let startingPosition = SliderPosition(radius: radius)
        setSelected(position: startingPosition)
    }

    private func determineSelectedPosition(offset: CGFloat) {
        let fullSpace = tickWidth + lineWidth
        if offset > 0 && offset < sideInset + fullSpace / 2 {
            setSelected(position: .left)
        } else if offset < sideInset + fullSpace + fullSpace / 2  {
            setSelected(position: .leftCenter)
        } else if offset < sideInset + fullSpace * 2 + fullSpace / 2 {
            setSelected(position: .center)
        } else if offset < sideInset + fullSpace * 3 + fullSpace / 2 {
            setSelected(position: .rightCenter)
        } else if offset < UIScreen.main.bounds.width {
            setSelected(position: .right)
        }

    }

    @objc private func tap(_ gesture: UITapGestureRecognizer) {
        determineSelectedPosition(offset: gesture.location(in: self).x)
    }

    @objc private func pan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        let velocity = gesture.velocity(in: self)

        switch gesture.state {
        case.began:
            panGestureStartingX = gesture.view?.frame.minX ?? 0
        case .changed:
            sliderBallXConstraint?.update(offset: panGestureStartingX + translation.x)
        case .ended, .cancelled, .failed:
            let adjustedVelocity = min(80, velocity.x / 20)
            let composite = panGestureStartingX + sliderBallWidth / 2 + translation.x + adjustedVelocity
            determineSelectedPosition(offset: composite)
        default:
            return
        }
    }

    func setSelected(position: SliderPosition) {
        HapticGenerator.shared.play(.light)
        selectedSliderPositon = position

        sliderBall.setPosition(sliderPosition: position)

        for view in sliderContainer.subviews {
            if let tick = view as? SliderTick {
                tick.setPosition(sliderPosition: position)
                continue
            }

            if let line = view as? SliderView {
                line.setPosition(sliderPosition: position)
            }
        }

        let offset = (sideInset + (tickWidth - sliderBallWidth) / 2) + (CGFloat(position.position) * (lineWidth + tickWidth))
        sliderBallXConstraint?.update(offset: offset)

        delegate?.finishPassing(radius: selectedSliderPositon.radius)
    }

    private func resetSelected() {
       // sliderBallXConstraint?.update(offset: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SliderTick: SliderView {
    override init(viewPosition: SliderPosition) {
        super.init(viewPosition: viewPosition)
        layer.cornerRadius = 4
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setPosition(sliderPosition: SliderPosition) {
        if sliderPosition.position > viewPosition.position - 1 {
            highlight()
        } else {
            unHighlight()
        }
    }
}

class SliderView: UIView {
    let viewPosition: SliderPosition

    init(viewPosition: SliderPosition) {
        self.viewPosition = viewPosition
        super.init(frame: .zero)
        backgroundColor = UIColor(red: 0, green: 0.227, blue: 0.392, alpha: 1)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setPosition(sliderPosition: SliderPosition) {
        if sliderPosition.position > viewPosition.position {
            highlight()
        } else {
            unHighlight()
        }
    }

    func highlight() {
        backgroundColor = UIColor(red: 0, green: 0.227, blue: 0.392, alpha: 1)
    }

    func unHighlight() {
        backgroundColor = UIColor(red: 0.849, green: 0.849, blue: 0.849, alpha: 1)
    }
}

class SliderBall: UIView {
    private lazy var label: UILabel = {
        let label = UILabel()
        label.textColor = Colors.PrimaryBlue.uicolor
        label.font = Fonts.SFProMedium.uifont(with: 16)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .white
        layer.cornerRadius = 18
        layer.borderWidth = 2
        layer.borderColor = Colors.PrimaryBlue.uicolor.cgColor

        addSubview(label)
        label.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setPosition(sliderPosition: SliderPosition) {
        label.text = "\(sliderPosition.rawValue) mi"
    }
}
