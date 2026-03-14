package com.arthouse.art_front

object UnityRuntimeAvailability {
    fun isUnityPlayerAvailable(): Boolean = runCatching {
        Class.forName("com.unity3d.player.UnityPlayer")
        true
    }.getOrDefault(false)
}