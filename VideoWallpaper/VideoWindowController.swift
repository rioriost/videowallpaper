//
//  VideoWindowController.swift
//  VideoWallpaper
//
//  Created by Rio Fujita on 2025/06/02.
//

import Cocoa
import AVFoundation
import os

/// 各スクリーンに透明ウィンドウ＋AVPlayerLayer で動画をループ再生するコントローラ
class VideoWindowController {
    var videoURL: URL
    private var windowItems: [VideoWindowItem] = []
    
    init(videoURL: URL) {
        self.videoURL = videoURL
    }
    
    /// すべてのスクリーンにウィンドウを作成し、動画をループ再生
    func showWindows() {
        // 既存ウィンドウを閉じる
        closeAllWindows()
        // フェイラブルイニシャライザで生成に失敗したものはスキップ
        let newItems = NSScreen.screens.compactMap { VideoWindowItem(screen: $0, videoURL: videoURL) }
        if newItems.isEmpty {
            os_log("VideoWindowItem を生成できませんでした: videoURL=%@", videoURL.path)
            return
        }
        newItems.forEach { item in
            windowItems.append(item)
            item.show()
        }
    }
    
    /// 動画URL を差し替えて各ウィンドウを再生成
    func updateVideoURL(_ newURL: URL) {
        DispatchQueue.main.async {
            // 1) 古いアイテムを安全に閉じる
            let oldItems = self.windowItems
            oldItems.forEach { $0.close() }
            self.windowItems.removeAll()

            // 2) 新しいアイテムを生成・表示
            let newItems = NSScreen.screens.compactMap { VideoWindowItem(screen: $0, videoURL: newURL) }
            newItems.forEach { $0.show() }
            self.windowItems = newItems
        }
    }
    
    /// すべてのウィンドウを閉じる
    private func closeAllWindows() {
        for item in windowItems {
            item.close()
        }
        windowItems.removeAll()
    }
    
    deinit {
        closeAllWindows()
    }
}


/// １スクリーン分のウィンドウを管理し、AVPlayerLayer でループ再生するクラス
private class VideoWindowItem {
    private let screen: NSScreen
    private let window: NSWindow
    private let player: AVPlayer
    private var playerLayer: AVPlayerLayer!
    private var observerToken: NSObjectProtocol?
    
    init?(screen: NSScreen, videoURL: URL) {
        self.screen = screen
        
        // ファイル存在チェック
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            os_log("動画ファイルが見つかりません: %@", videoURL.path)
            return nil
        }
        
        // 1. 各スクリーンのフレームを取得
        let frame = screen.frame
        
        // 2. ウィンドウを作成（フレーム座標をそのまま指定）
        window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // 3. ウィンドウの基本設定
        window.isOpaque = false               // 背景を透過
        window.backgroundColor = .clear       // 完全に透明
        window.hasShadow = false              // 影も不要
        window.ignoresMouseEvents = true      // クリック透過
        window.collectionBehavior = [
            .stationary,       // スペース切替で位置を維持
            .ignoresCycle,     // ⌘+Tab から切り替わらない
            .canJoinAllSpaces  // すべてのスペースに表示
        ]
        
        // 4. ウィンドウレベルを「デスクトップ (アイコンの後ろ)」に設定
        let desktopLevel = Int(CGWindowLevelForKey(.desktopWindow))
        window.level = NSWindow.Level(rawValue: desktopLevel)
        
        // 5. フレームを明示的にセットして表示を確実にする
        // window.setFrame(frame, display: true)
        
        let contentFrame = NSRect(origin: .zero, size: frame.size)

        // 6. AVAsset と AVPlayerItem を生成
        let asset = AVURLAsset(url: videoURL)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)

        // 7. AVPlayerLayer を貼り付け
        playerLayer = AVPlayerLayer(player: player)
        let contentView = NSView(frame: contentFrame)
        contentView.wantsLayer = true
        window.contentView = contentView

        playerLayer.frame = contentView.bounds
        contentView.layer?.addSublayer(playerLayer)
        
        // 8. 再生終了通知を監視し、動画をループ再生
        observerToken = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            // 再生完了後に先頭へシークして再生を再開
            guard let self = self else { return }
            self.player.seek(to: .zero)
            self.player.play()
        }
    }
    
    /// ウィンドウを前面に出し、再生開始
    func show() {
        // 強制的に最前面表示
        window.orderFrontRegardless()
        player.play()
    }
    
    /// ウィンドウを閉じて通知を解除
    func close() {
        NotificationCenter.default.removeObserver(observerToken as Any)
        player.pause()
        window.orderOut(nil)
    }
    
    deinit {
        if let token = observerToken {
            NotificationCenter.default.removeObserver(token)
        }
        player.pause()
    }
}
