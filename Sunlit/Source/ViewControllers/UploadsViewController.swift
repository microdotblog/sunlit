//
//  UploadsViewController.swift
//  Sunlit
//
//  Created by Jonathan Hays on 10/3/20.
//  Copyright © 2020 Micro.blog, LLC. All rights reserved.
//

import UIKit

class UploadsViewController: UIViewController {

    @IBOutlet var collectionView : UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

}

extension UploadsViewController : UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoEntryCollectionViewCell", for: indexPath)

        return cell
    }


}
