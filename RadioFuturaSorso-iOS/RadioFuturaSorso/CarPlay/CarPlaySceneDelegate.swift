//
//  CarPlaySceneDelegate.swift
//  Radio Futura Sorso
//
//  Integrazione per Apple CarPlay nel cruscotto dell'auto.
//

import CarPlay
import UIKit

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController

        // Template principale con pulsante radio in primo piano
        let radioItem = CPListItem(
            text: "Radio Futura Sorso",
            detailText: "Solo online – Diretta Streaming",
            image: UIImage(named: "CarPlayIcon")
        )

        radioItem.handler = { [weak self] item, completion in
            RadioPlayerManager.shared.play()
            // Mostra la schermata "In riproduzione" di CarPlay
            self?.interfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
            completion()
        }

        let section = CPListSection(items: [radioItem])
        let listTemplate = CPListTemplate(title: "Radio Futura Sorso", sections: [section])

        interfaceController.setRootTemplate(listTemplate, animated: true, completion: nil)
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
    }
}
