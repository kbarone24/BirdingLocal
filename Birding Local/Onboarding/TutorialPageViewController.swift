//
//  PageViewController.swift
//  Birding Local
//
//  Created by Kenny Barone on 2/18/24.
//

import Foundation
import UIKit

class TutorialPageViewController: UIPageViewController {
    private var pages: [UIViewController]
    private lazy var gradientView = UIView()
    private lazy var pageControl = UIPageControl()

    init() {
        let page0 = OnboardingPage0()
        let page1 = OnboardingPage1()
        let page2 = OnboardingPage2()
        pages = [page0, page1, page2]

        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)

        page2.delegate = self
        dataSource = self
        delegate = self

        if let firstPage = pages.first {
            setViewControllers(
                [firstPage],
                direction: .forward,
                animated: true,
                completion: nil
            )
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(color: .PrimaryBlue)

        view.insertSubview(gradientView, at: 0)
        gradientView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        gradientView.layoutIfNeeded()
        gradientView.backgroundColor = UIColor(patternImage: UIImage.gradientImage(
            bounds: gradientView.bounds,
            colors: [
                UIColor(red: 1, green: 0.797, blue: 0.275, alpha: 1.0),
               UIColor(red: 0.36, green: 0.561, blue: 0.706, alpha: 1),
               UIColor(red: 0, green: 0.227, blue: 0.392, alpha: 1)
            ],
            startPoint: CGPoint(x: 0.75, y: -0.15),
            endPoint: CGPoint(x: 1.0, y: 1.0),
            locations: [0, 0.26, 1.0]
        ))
    }
}

extension TutorialPageViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else {
            return nil
        }

        let previousIndex = index - 1
        guard previousIndex >= 0,
              pages.count > previousIndex else {
            return nil
        }

        return pages[previousIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else {
            return nil
        }

        let nextIndex = index + 1
        guard nextIndex >= 0,
              pages.count > nextIndex else {
            return nil
        }

        return pages[nextIndex]
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return pages.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return pageControl.currentPage
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed,
           let visibleViewController = pageViewController.viewControllers?.first,
           let index = pages.firstIndex(of: visibleViewController) {
            pageControl.currentPage = index
        }
    }
}

extension TutorialPageViewController: OnboardingDelegate {
    func closeOnboarding() {
        DispatchQueue.main.async {
            self.dismiss(animated: true)
        }
    }
}
