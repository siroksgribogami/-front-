package com.arthouse.art_front

object UnityBridgeCallbacks {
    private var bridgeStore: UnityMapBridgeStore? = null

    fun bindStore(store: UnityMapBridgeStore) {
        bridgeStore = store
    }

    @JvmStatic
    fun updateSnapshot(roomId: String?, json: String?) {
        bridgeStore?.updateFromUnity(roomId, json)
    }
}