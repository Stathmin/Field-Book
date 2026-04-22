package com.fieldbook.tracker.utilities

import android.app.Activity
import android.content.pm.ActivityInfo
import android.content.res.Configuration

/**
 * Centralized orientation policy used by a few screens.
 *
 * - Phones: keep portrait-locked
 * - Tablets: respect the user's auto-rotate setting
 */
object RotationPolicy {
    /**
     * "Smallest width" is the most stable signal we have, but some large tablets with unusual
     * density / resolution can report a lower swDp than expected. Use sw600dp (Android's common
     * tablet breakpoint) and fall back to screenLayout size.
     */
    const val TABLET_ROTATION_MIN_SW_DP = 600

    private fun isTablet(activity: Activity): Boolean {
        val config = activity.resources.configuration
        val swDp = config.smallestScreenWidthDp
        if (swDp >= TABLET_ROTATION_MIN_SW_DP) return true

        return when (config.screenLayout and Configuration.SCREENLAYOUT_SIZE_MASK) {
            Configuration.SCREENLAYOUT_SIZE_LARGE,
            Configuration.SCREENLAYOUT_SIZE_XLARGE -> true
            else -> false
        }
    }

    fun apply(activity: Activity) {
        activity.requestedOrientation =
            if (isTablet(activity)) {
                ActivityInfo.SCREEN_ORIENTATION_USER
            } else {
                ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
            }
    }
}

