//
//  Syphon.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 03.10.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class Syphon {
//    static func start(description: [AnyHashable: Any], context: CGLContextObj, handler: @escaping (SyphonClient?) -> Void) -> SyphonClient {
//        return SyphonClient(serverDescription: description, context: context, options: nil, newFrameHandler: handler)
//    }
//
//    static func start(on view: RFOpenGLView, description: [AnyHashable: Any]) -> SyphonClient {
//        return start(description: description, context: view.openGLContext!.cglContextObj!, handler: { client in
//            guard let client = client, let frame = client.newFrameImage() else {
//                return
//            }
//            
//            DispatchQueue.main.async {
//                view.texture = TextureInfo(size: frame.textureSize, textureID: frame.textureName)
//                view.drawFrame()
//            }
//        })
//    }
    
    static func offer(view: RFOpenGLView, as name: String) -> LiveSyphonServer? {
        let options: [AnyHashable: Any] =  [
            SyphonServerOptionDepthBufferResolution: 16
        ]
        guard let server = SyphonServer(name: name, context: view.openGLContext!.cglContextObj!, options: options) else {
            return nil
        }
        
        view.overrideTextureID = -1 // Don't draw yet
        
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { _ in
            view.animate()
            
            server.bind(toDrawFrameOf: view.bounds.size)
            view.drawFrame()
            server.unbindAndPublish()
            RFOpenGLView.checkGLError("Syphon Draw")

            let drawnFrame = server.newFrameImage()!
            view.overrideTextureID = GLint(drawnFrame.textureName)
            DispatchQueue.main.async {
                view.needsDisplay = true
            }
        }
        
        return LiveSyphonServer(server: server, timer: timer)
    }
}

class LiveSyphonServer {
    let server: SyphonServer
    let timer: Timer
    
    init(server: SyphonServer, timer: Timer) {
        self.server = server
        self.timer = timer
    }
    
    deinit {
        server.stop()
        timer.invalidate()
    }
}
