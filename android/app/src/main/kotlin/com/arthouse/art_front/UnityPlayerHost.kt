package com.arthouse.art_front

import android.content.Context
import android.view.View

class UnityPlayerHost(
    context: Context,
) : UnityCommandDispatcher {
    companion object {
        private const val BRIDGE_OBJECT_NAME = "ARTHouseMapBridge"
    }

    private val unityPlayerClass: Class<*>? = runCatching {
        Class.forName("com.unity3d.player.UnityPlayer")
    }.getOrNull()

    private val unityPlayer: Any? = unityPlayerClass?.let { clazz ->
        runCatching {
            clazz.getConstructor(Context::class.java).newInstance(context)
        }.getOrNull()
    }

    val isAvailable: Boolean
        get() = unityPlayerClass != null && unityPlayer is View

    fun getView(): View = unityPlayer as View

    override fun initialize(json: String) {
        sendBridgeMessage("ReceiveInitialMapJson", json)
    }

    override fun focusRoom(roomId: String) {
        sendBridgeMessage("FocusRoom", roomId)
    }

    override fun undo() {
        sendBridgeMessage("HandleUndoCommand", "")
    }

    override fun redo() {
        sendBridgeMessage("HandleRedoCommand", "")
    }

    override fun requestSnapshot() {
        sendBridgeMessage("PushSnapshotToAndroid", "")
    }

    fun dispose() {
        unityPlayer?.let { instance ->
            runCatching {
                instance.javaClass.getMethod("pause").invoke(instance)
                instance.javaClass.getMethod("quit").invoke(instance)
            }
        }
    }

    private fun sendBridgeMessage(methodName: String, payload: String) {
        val clazz = unityPlayerClass ?: return
        runCatching {
            clazz.getMethod("UnitySendMessage", String::class.java, String::class.java, String::class.java)
                .invoke(null, BRIDGE_OBJECT_NAME, methodName, payload)
        }
    }
}