package com.arthouse.art_front

interface UnityCommandDispatcher {
    fun initialize(json: String)
    fun focusRoom(roomId: String)
    fun undo()
    fun redo()
    fun requestSnapshot()
}

data class UnityBridgeSnapshot(
    val roomId: String,
    val mapJson: String,
)

fun interface UnityBridgeObserver {
    fun onBridgeStateChanged(snapshot: UnityBridgeSnapshot)
}

class UnityMapBridgeStore {
    private val undoStack = mutableListOf<String>()
    private val redoStack = mutableListOf<String>()
    private val observers = linkedSetOf<UnityBridgeObserver>()
    private var commandDispatcher: UnityCommandDispatcher? = null

    private var currentRoomId: String = ""
    private var currentJson: String = ""

    fun attachDispatcher(dispatcher: UnityCommandDispatcher?) {
        commandDispatcher = dispatcher
    }

    fun initialize(json: String?) {
        currentJson = json.orEmpty()
        undoStack.clear()
        redoStack.clear()
        if (currentJson.isNotEmpty()) {
            undoStack.add(currentJson)
        }
        if (currentJson.isNotEmpty()) {
            commandDispatcher?.initialize(currentJson)
        }
        notifyObservers()
    }

    fun focusRoom(roomId: String?) {
        currentRoomId = roomId.orEmpty()
        if (currentRoomId.isNotEmpty()) {
            commandDispatcher?.focusRoom(currentRoomId)
        }
        notifyObservers()
    }

    fun undo() {
        commandDispatcher?.undo()
        if (undoStack.size <= 1) {
            return
        }

        val current = undoStack.removeLast()
        redoStack.add(current)
        currentJson = undoStack.last()
        notifyObservers()
    }

    fun redo() {
        commandDispatcher?.redo()
        if (redoStack.isEmpty()) {
            return
        }

        val restored = redoStack.removeLast()
        undoStack.add(restored)
        currentJson = restored
        notifyObservers()
    }

    fun requestSnapshot(): String {
        commandDispatcher?.requestSnapshot()
        return currentJson
    }

    fun updateFromUnity(roomId: String?, json: String?) {
        if (!roomId.isNullOrBlank()) {
            currentRoomId = roomId
        }

        if (!json.isNullOrBlank()) {
            currentJson = json
            if (undoStack.isEmpty() || undoStack.last() != json) {
                undoStack.add(json)
            }
            redoStack.clear()
        }

        notifyObservers()
    }

    fun addObserver(observer: UnityBridgeObserver) {
        observers.add(observer)
        observer.onBridgeStateChanged(UnityBridgeSnapshot(currentRoomId, currentJson))
    }

    fun removeObserver(observer: UnityBridgeObserver) {
        observers.remove(observer)
    }

    private fun notifyObservers() {
        val snapshot = UnityBridgeSnapshot(currentRoomId, currentJson)
        observers.forEach { observer -> observer.onBridgeStateChanged(snapshot) }
    }
}