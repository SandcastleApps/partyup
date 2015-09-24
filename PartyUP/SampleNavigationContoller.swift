//
//  SampleNavigationContoller.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-22.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit

class SampleNavigationContoller: UIPageViewController, UIPageViewControllerDataSource {

	var samples: [Sample]?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
		return UIViewController()
	}

	func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
		return UIViewController()
	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
