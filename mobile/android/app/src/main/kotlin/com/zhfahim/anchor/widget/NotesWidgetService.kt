package com.zhfahim.anchor.widget

import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import com.zhfahim.anchor.R
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject

class NotesWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        NotesRemoteViewsFactory(applicationContext)

    companion object {
        /** Must match `homeWidgetNotesKey` in lib/core/home_widget/home_widget_payload.dart. */
        const val WIDGET_NOTES_KEY = "widget_notes"
    }
}

private class NotesRemoteViewsFactory(
    private val context: Context,
) : RemoteViewsService.RemoteViewsFactory {

    private data class WidgetNote(
        val id: String,
        val title: String,
        val snippet: String,
        val pinned: Boolean,
    )

    private var notes: List<WidgetNote> = emptyList()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        notes = loadNotes()
    }

    private fun loadNotes(): List<WidgetNote> {
        val json = HomeWidgetPlugin.getData(context)
            .getString(NotesWidgetService.WIDGET_NOTES_KEY, null) ?: return emptyList()
        return try {
            val array = JSONObject(json).optJSONArray("notes") ?: return emptyList()
            (0 until array.length()).mapNotNull { i ->
                val item = array.optJSONObject(i) ?: return@mapNotNull null
                val id = item.optString("id")
                if (id.isEmpty()) return@mapNotNull null
                WidgetNote(
                    id = id,
                    title = item.optString("title"),
                    snippet = item.optString("snippet"),
                    pinned = item.optBoolean("pinned"),
                )
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_note_item)
        val note = notes.getOrNull(position) ?: return views

        views.setTextViewText(
            R.id.item_title,
            note.title.ifBlank { context.getString(R.string.widget_untitled) },
        )
        views.setTextViewText(R.id.item_snippet, note.snippet)
        views.setViewVisibility(
            R.id.item_snippet,
            if (note.snippet.isBlank()) View.GONE else View.VISIBLE,
        )
        views.setViewVisibility(R.id.item_pin, if (note.pinned) View.VISIBLE else View.GONE)

        views.setOnClickFillInIntent(
            R.id.item_root,
            Intent().putExtra(NotesWidgetProvider.EXTRA_NOTE_ID, note.id),
        )
        return views
    }

    override fun getCount(): Int = notes.size

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = false

    override fun onDestroy() {}
}
