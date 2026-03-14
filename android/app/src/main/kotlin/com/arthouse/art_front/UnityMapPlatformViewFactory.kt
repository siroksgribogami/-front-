package com.arthouse.art_front

import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class UnityMapPlatformViewFactory(
    private val bridgeStore: UnityMapBridgeStore,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<*, *>
        val roomId = creationParams?.get("roomId") as? String
        if (!roomId.isNullOrBlank()) {
            bridgeStore.focusRoom(roomId)
        }
        return UnityMapPlatformView(context, bridgeStore)
    }
}