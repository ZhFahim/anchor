package com.zhfahim.anchor.backup

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Picks a folder through the document tree and keeps write access to it across
 * restarts, the way NotallyX does.
 */
class BackupFolderPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware,
    PluginRegistry.ActivityResultListener {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var binding: ActivityPluginBinding? = null
    private var pending: MethodChannel.Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.binding = binding
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        binding?.removeActivityResultListener(this)
        binding = null
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickFolder" -> pickFolder(result)
            "writeFile" -> writeFile(call, result)
            "listFiles" -> listFiles(call, result)
            "deleteFile" -> deleteFile(call, result)
            else -> result.notImplemented()
        }
    }

    private fun pickFolder(result: MethodChannel.Result) {
        val current = activity
        if (current == null) {
            result.error("no_activity", "The folder picker needs a screen.", null)
            return
        }
        if (pending != null) {
            result.error("busy", "A folder is already being picked.", null)
            return
        }
        pending = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
            )
        }
        current.startActivityForResult(intent, REQUEST_PICK)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_PICK) return false
        val result = pending ?: return false
        pending = null

        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return true
        }
        val flags = data.flags and
            (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        try {
            activity?.contentResolver?.takePersistableUriPermission(uri, flags)
        } catch (_: SecurityException) {
            // Some providers refuse; the folder still works for this session.
        }
        val current = activity
        val name = current
            ?.let { DocumentFile.fromTreeUri(it, uri)?.name }
            ?: uri.lastPathSegment
                ?.substringAfterLast(':')
                ?.let { Uri.decode(it) }
        result.success(mapOf("uri" to uri.toString(), "name" to name))
        return true
    }

    private fun writeFile(call: MethodCall, result: MethodChannel.Result) {
        val folder = folderOf(call)
        val name = call.argument<String>("name")
        val bytes = call.argument<ByteArray>("bytes")
        if (folder == null || name == null || bytes == null) {
            result.error("bad_args", "A folder, a name and bytes are required.", null)
            return
        }
        try {
            folder.findFile(name)?.delete()
            val file = folder.createFile("application/zip", name)
            if (file == null) {
                result.error("no_file", "The folder refused a new file.", null)
                return
            }
            activity?.contentResolver?.openOutputStream(file.uri)?.use { it.write(bytes) }
            result.success(null)
        } catch (error: Exception) {
            result.error("write_failed", error.message, null)
        }
    }

    private fun listFiles(call: MethodCall, result: MethodChannel.Result) {
        val folder = folderOf(call)
        if (folder == null) {
            result.error("bad_args", "A folder is required.", null)
            return
        }
        result.success(folder.listFiles().mapNotNull { it.name })
    }

    private fun deleteFile(call: MethodCall, result: MethodChannel.Result) {
        val folder = folderOf(call)
        val name = call.argument<String>("name")
        if (folder == null || name == null) {
            result.error("bad_args", "A folder and a name are required.", null)
            return
        }
        folder.findFile(name)?.delete()
        result.success(null)
    }

    private fun folderOf(call: MethodCall): DocumentFile? {
        val uri = call.argument<String>("folder") ?: return null
        return DocumentFile.fromTreeUri(activity ?: return null, Uri.parse(uri))
    }

    companion object {
        private const val CHANNEL = "anchor/backup"
        private const val REQUEST_PICK = 4711
    }
}
