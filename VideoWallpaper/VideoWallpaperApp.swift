//
//  VideoWallpaperApp.swift
//  VideoWallpaper
//
//  Created by Rio Fujita on 2025/06/02.
//

import SwiftUI
import AVFoundation
import ServiceManagement
import UniformTypeIdentifiers
import os

@main
struct VideoWallpaperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // メニューバーアイテム（macOS 13+）
        MenuBarExtra("Video Wallpaper", systemImage: "film") {
            Button("動画を変更…") {
                appDelegate.changeVideo()
            }
            Divider()
            Button("終了") {
                NSApp.terminate(nil)
            }
        }
        // メニューバーアイテムがクリックされたときにウィンドウを隠さない
        .menuBarExtraStyle(.window)
    }

// 既存の AppDelegate のロジックをそのまま流用
class AppDelegate: NSObject, NSApplicationDelegate {
    var videoWindowController: VideoWindowController!
    private let favoriteVideoKey = "FavoriteVideoURL"

    func applicationDidFinishLaunching(_ notification: Notification) {
        // ログイン時起動登録など、従来のセットアップを実行
        registerLoginItem()
        launchVideoWindow()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenConfigurationChange(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    private func launchVideoWindow() {
        // 動画URLの取得およびキャンセル時のハンドリング
        let videoURL: URL
        if let saved = UserDefaults.standard.url(forKey: favoriteVideoKey) {
            videoURL = saved
        } else if let chosen = promptForVideo() {
            videoURL = chosen
            UserDefaults.standard.set(chosen, forKey: favoriteVideoKey)
        } else {
            os_log("動画ファイルの選択がキャンセルされました")
            showAlert(message: "動画ファイルが選択されませんでした。アプリを終了します。")
            NSApp.terminate(nil)
            return
        }
        // VideoWindowController の生成と動画再生開始
        videoWindowController = VideoWindowController(videoURL: videoURL)
        videoWindowController.showWindows()
    }

    func changeVideo() {
        // 動画変更ダイアログで選択されたURLを取得
        guard let newURL = promptForVideo() else {
            os_log("動画変更ダイアログがキャンセルされました")
            return
        }
        UserDefaults.standard.set(newURL, forKey: favoriteVideoKey)
        // コントローラ未初期化時のハンドリング
        guard let controller = videoWindowController else {
            os_log("VideoWindowController が未初期化のため URL 更新できません")
            showAlert(message: "動画ウィンドウがまだ初期化されていません。")
            return
        }
        controller.updateVideoURL(newURL)
    }

    private func promptForVideo() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "動画ファイルを選択してください"
        if #available(macOS 12.0, *) {
            panel.allowedContentTypes = [.movie]
        } else {
            panel.allowedFileTypes = ["mp4","mov","m4v","avi","mpg","mpeg"]
        }
        panel.allowsMultipleSelection = false
        return panel.runModal() == .OK ? panel.url : nil
    }

    // macOS ログイン時にアプリを自動起動する設定
    private func registerLoginItem() {
        do {
            try SMAppService.mainApp.register()
        } catch {
            print("⚠️ ログイン時起動の登録に失敗: \(error)")
        }
    }

    /// ユーザー向けの簡易アラート表示
    private func showAlert(message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = message
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    @objc private func handleScreenConfigurationChange(_ n: Notification) {
        os_log("画面構成変更を受信、最新の動画を再読み込みします")
        // UserDefaults から最新の動画 URL を取得
        guard let url = UserDefaults.standard.url(forKey: favoriteVideoKey) else {
            os_log("⚠️ 保存された動画URLが見つかりません")
            return
        }
        videoWindowController.updateVideoURL(url)
    }
}
}
