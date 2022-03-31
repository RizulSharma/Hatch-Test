//
//  CustomToast.swift
//  Hatch-Test
//
//  Created by Rizul Sharma on 31/03/22.
//

import LBTATools
//MARK:- IMPLEMENTATION.

/**
 * This class provides a custom pop up to show in UIViewController.
 * Following is the implementation for showing a  pop-up.
 * CustomToast.show(message: "This is an Awesome popup build by Rizul Sharma.", backGroundColor: .systemPurple, showIn: .bottom, textColor: .white, controller: self)
 */

class CustomToast {
    
    enum ShowAt {
        case top
        case bottom
    }
    
    static func show(message: String, backGroundColor: UIColor = UIColor.darkGray, position: ShowAt = .bottom, textColor: UIColor = .white, controller: UIViewController) {
        controller.view.endEditing(true)
        let toastContainer = UIView(backgroundColor: backGroundColor.withAlphaComponent(1.0))
        toastContainer.alpha = 0.0
        toastContainer.layer.cornerRadius = 10
        toastContainer.clipsToBounds = true

        let toastLabel = UILabel(text: message, font: UIFont.systemFont(ofSize: 15, weight: .semibold), textColor: textColor, textAlignment: .center, numberOfLines: 0)
        toastLabel.lineBreakMode = .byWordWrapping
        toastContainer.addSubview(toastLabel)
        
        toastLabel.anchor(top: toastContainer.topAnchor, leading: toastContainer.leadingAnchor, bottom: toastContainer.bottomAnchor, trailing: toastContainer.trailingAnchor, padding: .init(top: 10, left: 10, bottom: 10, right: 10))
        
        toastContainer.translatesAutoresizingMaskIntoConstraints = false
        controller.view.addSubview(toastContainer)
        
        let c1 = NSLayoutConstraint(item: toastContainer, attribute: .leading, relatedBy: .equal, toItem: controller.view, attribute: .leading, multiplier: 1, constant: 65)
        
        let c2 = NSLayoutConstraint(item: toastContainer, attribute: .trailing, relatedBy: .equal, toItem: controller.view, attribute: .trailing, multiplier: 1, constant: -65)
        
        let c3 = NSLayoutConstraint(item: toastContainer, attribute: (position == .top) ? .top: .bottom, relatedBy: .equal, toItem: controller.view, attribute: (position == .top) ? .top: .bottom, multiplier: 1, constant: (position == .top) ? 75: -75)
        controller.view.addConstraints([c1, c2, c3])

        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseIn, animations: {
            toastContainer.alpha = 1.0
        }, completion: { (_) in
            UIView.animate(withDuration: 8.0, delay: 1.5, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                toastContainer.alpha = 0.0
            }, completion: { (_) in
                toastContainer.removeFromSuperview()
            })
        })
    }
}
