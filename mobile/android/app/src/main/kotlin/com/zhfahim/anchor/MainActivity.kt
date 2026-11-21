package com.zhfahim.anchor

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import com.zhfahim.anchor.language.LanguageSettingsPlugin
import com.zhfahim.anchor.photos.PhotoConverterPlugin
import com.zhfahim.anchor.share.ShareFolderPlugin
import com.zhfahim.anchor.widget.NotesWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        attachWidgetNoteUri(intent)
        super.onCreate(savedInstanceState)
        preferFastestRefreshRate()
    }

    override fun onNewIntent(intent: Intent) {
        attachWidgetNoteUri(intent)
        super.onNewIntent(intent)
    }

    // SystemNavigator.pop moves the app to the background.
    override fun popSystemNavigator(): Boolean = moveTaskToBack(true)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(PhotoConverterPlugin())
        flutterEngine.plugins.add(LanguageSettingsPlugin())
        flutterEngine.plugins.add(ShareFolderPlugin(listens = true))
    }

    private fun preferFastestRefreshRate() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        @Suppress("DEPRECATION")
        val display = (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) display else windowManager.defaultDisplay)
            ?: return
        val current = display.mode
        val fastest = display.supportedModes
            .filter { it.physicalWidth == current.physicalWidth && it.physicalHeight == current.physicalHeight }
            .maxByOrNull { it.refreshRate } ?: return
        window.attributes = window.attributes.apply { preferredDisplayModeId = fastest.modeId }
    }

    // home_widget reads the launch target only from the intent's data URI.
    private fun attachWidgetNoteUri(intent: Intent?) {
        if (intent?.action != HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION) return
        if (intent.data != null) return
        val noteId = intent.getStringExtra(NotesWidgetProvider.EXTRA_NOTE_ID) ?: return
        intent.data = Uri.parse("${NotesWidgetProvider.URI_SCHEME}://note/$noteId")
    }
}
