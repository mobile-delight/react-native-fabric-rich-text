package io.michaelfay.fabricrichtext

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.text.Layout
import android.util.Log

/**
 * Provides debug visualization for text layout bounds.
 * Only active in debug builds when DEBUG_ENABLED is true.
 *
 * Single Responsibility: Debug drawing and logging
 */
class DebugDrawingHelper {

    companion object {
        private const val TAG = "DebugDrawingHelper"

        // Debug flags: only enabled in debug builds
        // To enable debug visualization, set DEBUG_DRAW_LINE_BOUNDS = true AND build in debug mode
        val DEBUG_DRAW_LINE_BOUNDS = BuildConfig.DEBUG && false

        // To enable debug logging, set DEBUG_LOG = true AND build in debug mode
        val DEBUG_LOG = BuildConfig.DEBUG && false
    }

    // Debug drawing paints - only initialized when debug is enabled
    private val debugFillPaints = if (DEBUG_DRAW_LINE_BOUNDS) {
        arrayOf(
            Paint().apply { color = Color.argb(51, 255, 0, 0) },     // Red 20%
            Paint().apply { color = Color.argb(51, 0, 0, 255) },     // Blue 20%
            Paint().apply { color = Color.argb(51, 0, 204, 0) },     // Green 20%
            Paint().apply { color = Color.argb(51, 255, 128, 0) }    // Orange 20%
        )
    } else null

    private val debugStrokePaint = if (DEBUG_DRAW_LINE_BOUNDS) {
        Paint().apply {
            color = Color.argb(128, 0, 0, 0)
            style = Paint.Style.STROKE
            strokeWidth = 1f
        }
    } else null

    private val debugBaselinePaint = if (DEBUG_DRAW_LINE_BOUNDS) {
        Paint().apply {
            color = Color.RED
            style = Paint.Style.STROKE
            strokeWidth = 2f
        }
    } else null

    private val layoutBoundsPaint = if (DEBUG_DRAW_LINE_BOUNDS) {
        Paint().apply {
            color = Color.rgb(200, 80, 0)  // Dark orange for better visibility
            style = Paint.Style.STROKE
            strokeWidth = 4f
        }
    } else null

    /**
     * Check if debug drawing is enabled.
     */
    fun isDrawingEnabled(): Boolean = DEBUG_DRAW_LINE_BOUNDS

    /**
     * Check if debug logging is enabled.
     */
    fun isLoggingEnabled(): Boolean = DEBUG_LOG

    /**
     * Log a debug message.
     */
    fun log(message: String) {
        if (DEBUG_LOG) {
            Log.d(TAG, message)
        }
    }

    /**
     * Draws debug line bounds for a custom layout.
     *
     * @param canvas The canvas to draw on
     * @param textLayout The text layout
     * @param paddingLeft Left padding offset
     * @param paddingTop Top padding offset
     * @param viewHeight View's total height
     */
    fun drawDebugLineBoundsForLayout(
        canvas: Canvas,
        textLayout: Layout,
        paddingLeft: Int,
        paddingTop: Int,
        viewHeight: Int
    ) {
        if (!DEBUG_DRAW_LINE_BOUNDS) return

        val lineCount = textLayout.lineCount
        if (lineCount == 0) return

        Log.d(TAG, "[DEBUG] Custom Layout - Total lines: $lineCount, view height: $viewHeight, layout height: ${textLayout.height}, layoutWidth: ${textLayout.width}")

        canvas.save()
        canvas.translate(paddingLeft.toFloat(), paddingTop.toFloat())

        // Draw full layout bounds as dark orange outline
        layoutBoundsPaint?.let { paint ->
            canvas.drawRect(0f, 0f, textLayout.width.toFloat(), textLayout.height.toFloat(), paint)
        }

        for (i in 0 until lineCount) {
            val lineTop = textLayout.getLineTop(i).toFloat()
            val lineBottom = textLayout.getLineBottom(i).toFloat()
            val lineBaseline = textLayout.getLineBaseline(i).toFloat()
            val lineLeft = textLayout.getLineLeft(i)
            val lineRight = textLayout.getLineRight(i)

            Log.d(TAG, "[DEBUG] Line $i: top=$lineTop bottom=$lineBottom baseline=$lineBaseline left=$lineLeft right=$lineRight layoutWidth=${textLayout.width}")

            debugFillPaints?.get(i % 4)?.let { paint ->
                canvas.drawRect(lineLeft, lineTop, lineRight, lineBottom, paint)
            }

            debugStrokePaint?.let { paint ->
                canvas.drawRect(lineLeft, lineTop, lineRight, lineBottom, paint)
            }

            debugBaselinePaint?.let { paint ->
                canvas.drawLine(lineLeft, lineBaseline, lineRight, lineBaseline, paint)
            }
        }

        canvas.restore()
    }

    /**
     * Draws debug line bounds for a standard TextView layout.
     *
     * @param canvas The canvas to draw on
     * @param textLayout The text layout
     * @param text The text content (for logging)
     * @param viewHeight View's total height
     */
    fun drawDebugLineBounds(
        canvas: Canvas,
        textLayout: Layout,
        text: CharSequence?,
        viewHeight: Int
    ) {
        if (!DEBUG_DRAW_LINE_BOUNDS) return

        val lineCount = textLayout.lineCount
        if (lineCount == 0) return

        Log.d(TAG, "[DEBUG] Total lines: $lineCount, view height: $viewHeight")

        for (i in 0 until lineCount) {
            val lineTop = textLayout.getLineTop(i).toFloat()
            val lineBottom = textLayout.getLineBottom(i).toFloat()
            val lineBaseline = textLayout.getLineBaseline(i).toFloat()
            val lineLeft = textLayout.getLineLeft(i)
            val lineRight = textLayout.getLineRight(i)

            val lineStart = textLayout.getLineStart(i)
            val lineEnd = textLayout.getLineEnd(i)
            val lineText = text?.subSequence(lineStart, lineEnd)?.toString()
                ?.replace("\n", "\\n") ?: ""

            val ascent = textLayout.getLineAscent(i).toFloat()
            val descent = textLayout.getLineDescent(i).toFloat()

            Log.d(TAG, "[DEBUG] Line $i: top=$lineTop bottom=$lineBottom baseline=$lineBaseline " +
                "ascent=$ascent descent=$descent height=${lineBottom - lineTop} " +
                "text='$lineText'")

            // Draw filled rect for line bounds
            debugFillPaints?.get(i % 4)?.let { paint ->
                canvas.drawRect(lineLeft, lineTop, lineRight, lineBottom, paint)
            }

            // Draw stroke around line bounds
            debugStrokePaint?.let { paint ->
                canvas.drawRect(lineLeft, lineTop, lineRight, lineBottom, paint)
            }

            // Draw baseline
            debugBaselinePaint?.let { paint ->
                canvas.drawLine(lineLeft, lineBaseline, lineRight, lineBaseline, paint)
            }
        }
    }
}
