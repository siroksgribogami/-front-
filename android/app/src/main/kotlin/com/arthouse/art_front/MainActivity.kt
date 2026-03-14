package com.arthouse.art_front

import com.arthouse.art_front.UnityBridgeCallbacks
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
	private val bridgeStore = UnityMapBridgeStore()

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		UnityBridgeCallbacks.bindStore(bridgeStore)

		flutterEngine
			.platformViewsController
			.registry
			.registerViewFactory(UnityMapBridgePlugin.VIEW_TYPE, UnityMapPlatformViewFactory(bridgeStore))

		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			UnityMapBridgePlugin.CHANNEL,
		).setMethodCallHandler { call, result ->
			handleUnityBridgeCall(call, result)
		}
	}

	private fun handleUnityBridgeCall(call: MethodCall, result: MethodChannel.Result) {
		when (call.method) {
			"isAvailable" -> result.success(UnityRuntimeAvailability.isUnityPlayerAvailable())
			"initializeEditor" -> {
				bridgeStore.initialize(call.arguments as? String)
				result.success(null)
			}
			"focusRoom" -> {
				bridgeStore.focusRoom(call.arguments as? String)
				result.success(null)
			}
			"undo" -> {
				bridgeStore.undo()
				result.success(null)
			}
			"redo" -> {
				bridgeStore.redo()
				result.success(null)
			}
			"requestSnapshot" -> result.success(bridgeStore.requestSnapshot())
			else -> result.notImplemented()
		}
	}
}
