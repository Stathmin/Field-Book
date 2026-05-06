package com.fieldbook.tracker.utilities

import android.app.Activity
import android.content.pm.ActivityInfo
import androidx.preference.PreferenceManager
import com.fieldbook.tracker.preferences.PreferenceKeys

/**
 * Centralized orientation policy used by a few screens.
 *
 * Experimental toggle to allow app rotation on large screens.
 */
object RotationPolicy {
    /**
     * Use smallestScreenWidthDp as a stable, resource-like breakpoint.
     */
    const val ROTATION_MIN_SW_DP = 450

    private fun shouldAllowRotation(activity: Activity): Boolean {
        val prefs = PreferenceManager.getDefaultSharedPreferences(activity)
        if (!prefs.getBoolean(PreferenceKeys.ALLOW_ROTATION, false)) return false

        val swDp = activity.resources.configuration.smallestScreenWidthDp
        return swDp >= ROTATION_MIN_SW_DP
    }

    fun apply(activity: Activity) {
        activity.requestedOrientation =
            if (shouldAllowRotation(activity)) {
                ActivityInfo.SCREEN_ORIENTATION_USER
            } else {
                ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
            }
    }
}

