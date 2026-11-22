//
//  ActivityShareSheet.swift
//  PrimePickApp
//

import SwiftUI
import UIKit

/// 共有シート（`UIActivityViewController`）を出す窓口
///
/// シェアボタンの `background` に置く。iPad ではこのビューの位置からポップオーバーを出すので、ボタンを指して開く。
/// `items` に値が入ると共有シートを出し、閉じたら nil に戻す。
struct ActivityShareSheet: UIViewControllerRepresentable {
    /// 共有シートに渡す項目。それぞれを別々の項目として渡す
    @Binding var items: [Any]?
    /// 共有シートを閉じたとき。`completed` は送り終えたかどうか（閉じただけなら false）
    var onComplete: (_ activityType: UIActivity.ActivityType?, _ completed: Bool) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        viewController.view.isUserInteractionEnabled = false
        return viewController
    }

    func updateUIViewController(_ viewController: UIViewController, context: Context) {
        let coordinator = context.coordinator
        guard let items, !coordinator.isPresenting else { return }
        coordinator.isPresenting = true

        let itemsBinding = $items
        let onComplete = onComplete
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = viewController.view.bounds
        }
        activityViewController.completionWithItemsHandler = { activityType, completed, _, _ in
            coordinator.isPresenting = false
            itemsBinding.wrappedValue = nil
            onComplete(activityType, completed)
        }
        // SwiftUI の更新の途中で表示を始めないよう、次の周回で出す
        DispatchQueue.main.async {
            guard viewController.view.window != nil, viewController.presentedViewController == nil else {
                coordinator.isPresenting = false
                itemsBinding.wrappedValue = nil
                return
            }
            viewController.present(activityViewController, animated: true)
        }
    }

    final class Coordinator {
        /// 共有シートを出している間は、もう一度出さない
        var isPresenting = false
    }
}
