//
//  ToastManager.swift
//  BLEDemo
//
//  Created by admin on 2023/10/8.
//
import Foundation
import UIKit
@objcMembers class ToastManager: NSObject {
    static var share = ToastManager()
    private override init() {}
    var isLoading: Bool { indicatorV.loading }
    private let indicatorV = IndicatorView()
    private var indicatorWidthConstraint: NSLayoutConstraint?
    /// superView
    private var toastViewDict = [UIView: (list: [ToastView], toastDismissing: Bool)]()
}
extension ToastManager {
    func loading(in superV: UIView?, text: String = "Loading", width: CGFloat = 90) {
        guard let superV else { return }
        if indicatorV.isDescendant(of: superV) {
            superV.bringSubviewToFront(indicatorV)
        } else {
            stopLoading()
            superV.addSubview(indicatorV)
            indicatorV.translatesAutoresizingMaskIntoConstraints = false
            indicatorV.centerXAnchor.constraint(equalTo: superV.centerXAnchor).isActive = true
            indicatorV.centerYAnchor.constraint(equalTo: superV.centerYAnchor).isActive = true
        }
        indicatorWidthConstraint?.isActive = false
        indicatorWidthConstraint = indicatorV.widthAnchor.constraint(equalToConstant: width)
        indicatorWidthConstraint?.isActive = true
        indicatorV.textL.text = text
        indicatorV.loading = true
        superV.isUserInteractionEnabled = false
    }
    func stopLoading() {
        indicatorV.loading = false
        indicatorV.superview?.isUserInteractionEnabled = true
        indicatorV.removeFromSuperview()
    }
}
extension ToastManager {
    func showErr(in superV: UIView?, text: String?) {
        show(in: superV, text: text, isErr: true)
    }
    func show(in superV: UIView?, text: String?) {
        show(in: superV, text: text, isErr: false)
    }
    private func show(in superV: UIView?, text: String?, isErr: Bool) {
        guard let superV, let text, !text.isEmpty else { return }
        let tv = ToastView()
        tv.backgroundColor = isErr ? UIColor(red: 0.988, green: 0.247, blue: 0.349, alpha: 0.95) : .black.withAlphaComponent(0.8)
        tv.layer.cornerRadius = 12
        tv.textL.text = text
        tv.textL.textAlignment = .center
        superV.addSubview(tv)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.superConstraints.append(tv.centerYAnchor.constraint(equalTo: superV.centerYAnchor, constant: -70))
        tv.superConstraints.append(tv.centerXAnchor.constraint(equalTo: superV.centerXAnchor))
        tv.superConstraints.append(tv.heightAnchor.constraint(lessThanOrEqualToConstant: 200))
        tv.superConstraints.append(tv.widthAnchor.constraint(lessThanOrEqualTo: superV.widthAnchor, constant: -40))
        tv.superConstraints.forEach { $0.isActive = true }
        var (views, dismissing) = toastViewDict[superV] ?? ([], false)
        _ = views.reversed().reduce(tv) { nextV, v in
            v.superConstraints.filter { $0.firstAnchor == v.centerYAnchor || $0.firstAnchor == v.bottomAnchor } .forEach { $0.isActive = false }
            v.bottomAnchor.constraint(equalTo: nextV.topAnchor, constant: -5).isActive = true
            return v
        }
        if views.count > 3 {
            views.first?.removeFromSuperview()
            views.removeFirst()
        }
        views.append(tv)
        toastViewDict[superV] = (views, dismissing)
        tv.alpha = 0
        UIView.animate(withDuration: 0.25, animations: {
            tv.alpha = 1
        })
        dismiss(3, superView: superV)
    }
    private func dismiss(_ duration: Double, superView: UIView) {
        guard let (views, dismissing) = toastViewDict[superView], !views.isEmpty, !dismissing else { return }
        toastViewDict[superView]?.toastDismissing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard var (views, dismissing) = self?.toastViewDict[superView] else { return }
            UIView.animate(withDuration: 0.25, animations: {
                views.first?.alpha = 0
            }) { (_) in
                views.first?.removeFromSuperview()
                views.removeFirst()
                dismissing = false
                self?.toastViewDict[superView] = views.isEmpty ? nil : (views, dismissing)
                if views.isEmpty {
                    superView.subviews.forEach {
                        if $0 is ToastView {
                            $0.removeFromSuperview()
                        }
                    }
                }
                self?.dismiss(views.count < 2 ? 5 : 2, superView: superView)
            }
        }
    }
}
private class ToastView: UIView {
    var superConstraints = [NSLayoutConstraint]()
    let textL = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        textL.textColor = .white
        textL.font = .systemFont(ofSize: 16)
        textL.numberOfLines = 0
        addSubview(textL)
        textL.translatesAutoresizingMaskIntoConstraints = false
        textL.leftAnchor.constraint(equalTo: leftAnchor, constant: 10).isActive = true
        textL.rightAnchor.constraint(equalTo: rightAnchor, constant: -10).isActive = true
        textL.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
        textL.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
private class IndicatorView: UIView {
    fileprivate let imgV = UIActivityIndicatorView(style: .white), textL = UILabel()
    var loading = false {
        willSet {
            guard loading != newValue else { return }
            if newValue {
                imgV.startAnimating()
            } else {
                imgV.stopAnimating()
            }
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.1).cgColor
        addSubview(imgV)
        textL.textColor = .white
        textL.font = .systemFont(ofSize: 16, weight: .semibold)
        textL.numberOfLines = 0
        textL.textAlignment = .center
        addSubview(textL)
        imgV.translatesAutoresizingMaskIntoConstraints = false
        imgV.topAnchor.constraint(equalTo: topAnchor, constant: 12).isActive = true
        imgV.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        imgV.widthAnchor.constraint(equalToConstant: 16).isActive = true
        imgV.heightAnchor.constraint(equalTo: imgV.widthAnchor).isActive = true
        textL.translatesAutoresizingMaskIntoConstraints = false
        textL.topAnchor.constraint(equalTo: imgV.bottomAnchor, constant: 8).isActive = true
        textL.leftAnchor.constraint(equalTo: leftAnchor, constant: 12).isActive = true
        textL.rightAnchor.constraint(equalTo: rightAnchor, constant: -12).isActive = true
        textL.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12).isActive = true
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
