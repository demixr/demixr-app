import CarPlay
import Flutter
import UIKit

final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var channel: FlutterMethodChannel?
    private weak var controller: CPInterfaceController?
    private let library = CPListTemplate(title: "Library", sections: [])
    private var songs: [[String: String]] = []
    private var page = 0

    func templateApplicationScene(
        _ scene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }

        controller = interfaceController
        channel = app.carPlayChannel
        library.emptyViewTitleVariants = ["Loading library…"]
        interfaceController.setRootTemplate(library, animated: false, completion: nil)
        channel?.setMethodCallHandler { [weak self] call, reply in
            guard call.method == "libraryChanged" else {
                reply(FlutterMethodNotImplemented)
                return
            }
            self?.reloadLibrary()
            reply(nil)
        }
        reloadLibrary()
    }

    func templateApplicationScene(
        _ scene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        channel?.setMethodCallHandler(nil)
        channel = nil
        controller = nil
    }

    private func reloadLibrary() {
        channel?.invokeMethod("getLibrary", arguments: nil) { [weak self] result in
            // On cold launch Flutter sends libraryChanged once it is ready.
            guard let self, self.controller != nil,
                  let songs = result as? [[String: String]] else { return }
            self.songs = songs
            self.page = 0
            self.library.emptyViewTitleVariants = ["No saved songs"]
            self.showPage()
        }
    }

    private func showPage() {
        let limit = CPListTemplate.maximumItemCount
        let pageSize = songs.count <= limit ? limit : max(1, limit - 2)
        let start = page * pageSize
        let end = min(start + pageSize, songs.count)
        var items: [CPListItem] = []

        if page > 0 {
            items.append(pageButton(title: "Previous Songs", page: page - 1))
        }
        for song in songs[start..<end] {
            guard let id = song["id"], let title = song["title"] else { continue }
            let item = CPListItem(text: title, detailText: song["artist"])
            item.handler = { [weak self] _, completion in
                guard let self, let channel = self.channel else {
                    completion()
                    return
                }
                channel.invokeMethod("playSong", arguments: id) { [weak self] result in
                    completion()
                    let nowPlaying = CPNowPlayingTemplate.shared
                    if result as? Bool == true, let controller = self?.controller,
                       controller.topTemplate !== nowPlaying {
                        controller.pushTemplate(nowPlaying, animated: true, completion: nil)
                    }
                }
            }
            items.append(item)
        }
        if end < songs.count {
            items.append(pageButton(title: "More Songs", page: page + 1))
        }
        library.updateSections(items.isEmpty ? [] : [CPListSection(items: items)])
    }

    private func pageButton(title: String, page: Int) -> CPListItem {
        let item = CPListItem(text: title, detailText: nil)
        item.handler = { [weak self] _, completion in
            self?.page = page
            self?.showPage()
            completion()
        }
        return item
    }
}
