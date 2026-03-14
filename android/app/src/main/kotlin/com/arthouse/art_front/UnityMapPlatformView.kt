package com.arthouse.art_front

import android.content.Context
import android.graphics.Color
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import io.flutter.plugin.platform.PlatformView

class UnityMapPlatformView(
    context: Context,
    private val bridgeStore: UnityMapBridgeStore,
) : PlatformView {
    private val roomLabel = TextView(context)
    private val statusLabel = TextView(context)
    private val snapshotLabel = TextView(context)
    private val rootView = FrameLayout(context)
    private val unityHost = UnityPlayerHost(context)

    private val observer = UnityBridgeObserver { snapshot ->
        roomLabel.text = if (snapshot.roomId.isBlank()) {
            "Активная комната: не выбрана"
        } else {
            "Активная комната: ${snapshot.roomId}"
        }

        snapshotLabel.text = if (snapshot.mapJson.isBlank()) {
            "Snapshot пока не загружен"
        } else {
            "Snapshot получен. Длина JSON: ${snapshot.mapJson.length}"
        }
    }

    init {
        if (unityHost.isAvailable) {
            bridgeStore.attachDispatcher(unityHost)
            rootView.addView(
                unityHost.getView(),
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT,
                ),
            )
        } else {
            rootView.addView(
                createPlaceholderView(context),
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT,
                ),
            )
        }

        bridgeStore.addObserver(observer)
    }

    override fun getView(): View = rootView

    override fun dispose() {
        bridgeStore.removeObserver(observer)
        bridgeStore.attachDispatcher(null)
        unityHost.dispose()
    }

    private fun createPlaceholderView(context: Context): View {
        val container = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(48, 48, 48, 48)
            setBackgroundColor(Color.parseColor("#F5F1EA"))
        }

        statusLabel.apply {
            text = "Unity export еще не подключен в android/app как unityLibrary. После экспорта из Unity этот контейнер автоматически переключится на реальный Unity Player."
            setTextColor(Color.parseColor("#2F2A24"))
            textSize = 16f
        }

        roomLabel.apply {
            setTextColor(Color.parseColor("#9A6330"))
            textSize = 15f
            setPadding(0, 24, 0, 16)
        }

        snapshotLabel.apply {
            setTextColor(Color.parseColor("#6B6259"))
            textSize = 13f
            gravity = Gravity.CENTER
        }

        container.addView(statusLabel)
        container.addView(roomLabel)
        container.addView(snapshotLabel)
        return container
    }
}