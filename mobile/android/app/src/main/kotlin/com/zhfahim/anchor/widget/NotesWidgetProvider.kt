package com.zhfahim.anchor.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import com.zhfahim.anchor.MainActivity
import com.zhfahim.anchor.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject

class NotesWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            appWidgetManager.updateAppWidget(appWidgetId, buildViews(context, appWidgetId))
        }
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.widget_list)
    }

    private fun buildViews(context: Context, appWidgetId: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_notes)

        val serviceIntent = Intent(context, NotesWidgetService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
        }
        views.setRemoteAdapter(R.id.widget_list, serviceIntent)
        views.setEmptyView(R.id.widget_list, R.id.widget_empty)

        val loggedIn = isLoggedIn(context)
        views.setTextViewText(
            R.id.widget_empty,
            context.getString(if (loggedIn) R.string.widget_empty else R.string.widget_logged_out),
        )
        // Creating a note needs an account; the "+" can't act while logged out.
        views.setViewVisibility(R.id.widget_new_note, if (loggedIn) View.VISIBLE else View.GONE)

        views.setOnClickPendingIntent(
            R.id.widget_header,
            launchIntent(context, "$URI_SCHEME://open"),
        )
        views.setOnClickPendingIntent(
            R.id.widget_empty,
            launchIntent(context, "$URI_SCHEME://open"),
        )
        views.setOnClickPendingIntent(
            R.id.widget_new_note,
            launchIntent(context, "$URI_SCHEME://note/new"),
        )

        // List rows can't carry their own PendingIntent; they fill the note id
        // into this template as an extra, and MainActivity turns it into the
        // data URI home_widget expects.
        val templateIntent = Intent(context, MainActivity::class.java).apply {
            action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
        }
        views.setPendingIntentTemplate(
            R.id.widget_list,
            PendingIntent.getActivity(
                context,
                LIST_TEMPLATE_REQUEST_CODE,
                templateIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
            ),
        )

        return views
    }

    private fun launchIntent(context: Context, uri: String): PendingIntent =
        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse(uri))

    private fun isLoggedIn(context: Context): Boolean {
        val json = HomeWidgetPlugin.getData(context)
            .getString(NotesWidgetService.WIDGET_NOTES_KEY, null) ?: return false
        return try {
            JSONObject(json).optBoolean("loggedIn", false)
        } catch (_: Exception) {
            false
        }
    }

    companion object {
        const val URI_SCHEME = "anchorwidget"
        const val EXTRA_NOTE_ID = "com.zhfahim.anchor.widget.EXTRA_NOTE_ID"
        private const val LIST_TEMPLATE_REQUEST_CODE = 1
    }
}
