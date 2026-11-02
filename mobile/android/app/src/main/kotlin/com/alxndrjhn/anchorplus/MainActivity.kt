package com.alxndrjhn.anchorplus

import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.os.Bundle
import com.alxndrjhn.anchorplus.debug.DebugVideoPlugin
import com.alxndrjhn.anchorplus.files.DeviceFilesPlugin
import com.alxndrjhn.anchorplus.lock.ScreenOffPlugin
import com.alxndrjhn.anchorplus.photos.PhotoConverterPlugin
import com.alxndrjhn.anchorplus.share.ShareFolderPlugin
import com.alxndrjhn.anchorplus.update.UpdateInstallerPlugin
import com.alxndrjhn.anchorplus.widget.NotesWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import io.flutter.embedding.android.FlutterFragment
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.android.TransparencyMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterShellArgs
import io.flutter.plugin.common.MethodChannel

// A FragmentActivity so local_auth can show the fingerprint prompt (locked
// notes).
class MainActivity : FlutterFragmentActivity() {

    private var magicLinkChannel: MethodChannel? = null

    /** The magic link the app was opened with, until Flutter takes it. */
    private var pendingMagicLink: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        attachWidgetNoteUri(intent)
        // Not again when Android brings back the screen it was opened with.
        if (savedInstanceState == null) pendingMagicLink = magicLinkOf(intent)
        super.onCreate(savedInstanceState)
        preferFastestRefreshRate()
        // Talks to the launcher, which takes a moment: not while starting up.
        Thread(::publishShortcuts).start()
    }

    /**
     * The launcher's long-press menu: New note and New checklist. They are
     * dynamic so they target whichever package this is (the fork's id
     * differs), and launch like the widget's buttons, which home_widget
     * hands to the Flutter side on both cold and warm starts.
     */
    private fun publishShortcuts() {
        if (Build.VERSION.SDK_INT < 25) return
        try {
            val manager = getSystemService(ShortcutManager::class.java) ?: return
            fun shortcut(id: String, label: String, uri: String, icon: Int) =
                ShortcutInfo.Builder(this, id)
                    .setShortLabel(label)
                    .setLongLabel(label)
                    .setIcon(Icon.createWithResource(this, icon))
                    .setIntent(
                        Intent(this, MainActivity::class.java)
                            .setAction(HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION)
                            .setData(Uri.parse(uri))
                            .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP),
                    )
                    .build()
            val scheme = NotesWidgetProvider.URI_SCHEME
            manager.setDynamicShortcuts(listOf(
                shortcut("new_note", getString(R.string.shortcut_new_note), "$scheme://note/new", R.drawable.ic_shortcut_note),
                shortcut("new_checklist", getString(R.string.shortcut_new_checklist), "$scheme://note/new?checklist=1", R.drawable.ic_shortcut_checklist),
            ))
        } catch (e: Exception) {
            android.util.Log.w("AnchorShortcuts", "Couldn't publish app shortcuts", e)
        }
    }

    override fun onNewIntent(intent: Intent) {
        attachWidgetNoteUri(intent)
        super.onNewIntent(intent)
        magicLinkOf(intent)?.let {
            pendingMagicLink = it
            magicLinkChannel?.invokeMethod("link", null)
        }
    }

    private fun magicLinkOf(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_VIEW) return null
        if ((intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0) return null
        val data = intent.data ?: return null
        if (data.scheme != MAGIC_LINK_SCHEME || data.host != MAGIC_LINK_HOST) return null
        return data.toString()
    }

    /**
     * FlutterFragmentActivity's own fragment, built the same way (this app
     * never uses a cached engine), but one whose SystemNavigator.pop moves
     * the app to the background, as FlutterActivity's popSystemNavigator did.
     */
    override fun createFlutterFragment(): FlutterFragment {
        val builder = FlutterFragment.NewEngineFragmentBuilder(BackgroundingFlutterFragment::class.java)
            .dartEntrypoint(dartEntrypointFunctionName)
            .dartEntrypointArgs(dartEntrypointArgs ?: emptyList())
            .appBundlePath(appBundlePath)
            .flutterShellArgs(FlutterShellArgs.fromIntent(intent))
            .handleDeeplinking(shouldHandleDeeplinking())
            .renderMode(renderMode)
            .transparencyMode(TransparencyMode.opaque)
            .shouldAttachEngineToActivity(shouldAttachEngineToActivity())
            .shouldDelayFirstAndroidViewDraw(renderMode == RenderMode.surface)
            .shouldAutomaticallyHandleOnBackPressed(true)
        dartEntrypointLibraryUri?.let { builder.dartLibraryUri(it) }
        getInitialRoute()?.let { builder.initialRoute(it) }
        return builder.build()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(PhotoConverterPlugin())
        flutterEngine.plugins.add(ShareFolderPlugin(listens = true))
        flutterEngine.plugins.add(UpdateInstallerPlugin())
        flutterEngine.plugins.add(ScreenOffPlugin())
        flutterEngine.plugins.add(DeviceFilesPlugin())
        flutterEngine.plugins.add(DebugVideoPlugin())
        magicLinkChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MAGIC_LINK_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                if (call.method != "takeLink") return@setMethodCallHandler result.notImplemented()
                result.success(pendingMagicLink)
                pendingMagicLink = null
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        magicLinkChannel?.setMethodCallHandler(null)
        magicLinkChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
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

private const val MAGIC_LINK_CHANNEL = "anchor/magic_link"
private const val MAGIC_LINK_SCHEME = "anchorplus"
private const val MAGIC_LINK_HOST = "magic-login"

/** SystemNavigator.pop moves the app to the background instead of closing it. */
class BackgroundingFlutterFragment : FlutterFragment() {
    override fun popSystemNavigator(): Boolean = activity?.moveTaskToBack(true) ?: false
}
