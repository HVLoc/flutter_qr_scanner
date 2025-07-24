package vn.lochv.flutter_qr_scanner

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import androidx.appcompat.app.AppCompatActivity
import com.journeyapps.barcodescanner.BarcodeCallback
import com.journeyapps.barcodescanner.BarcodeResult
import com.journeyapps.barcodescanner.CompoundBarcodeView
import com.journeyapps.barcodescanner.camera.CameraSettings

class PortraitCaptureActivity : AppCompatActivity() {
    private lateinit var barcodeView: CompoundBarcodeView
    private var isTorchOn = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        barcodeView = CompoundBarcodeView(this).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            statusView.text = "Đưa mã QR vào khung để quét"
            cameraSettings.focusMode = CameraSettings.FocusMode.CONTINUOUS
        }

        // Nút back
        val backButton = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_menu_close_clear_cancel)
            setPadding(50, 50, 50, 50)
            setOnClickListener {
                setResult(Activity.RESULT_CANCELED)
                finish()
            }
        }

        // Nút bật/tắt đèn flash
        val flashButton = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_menu_manage)
            setPadding(50, 50, 50, 50)
            setOnClickListener {
                isTorchOn = !isTorchOn
                if (isTorchOn) {
                    barcodeView.setTorchOn()
                } else {
                    barcodeView.setTorchOff()
                }
            }
        }

        val layout = FrameLayout(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            addView(barcodeView)

            addView(backButton, FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.START or Gravity.TOP
            })

            addView(flashButton, FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.END or Gravity.TOP
            })
        }

        setContentView(layout)

        // Bắt mã QR
        barcodeView.decodeSingle(object : BarcodeCallback {
            override fun barcodeResult(result: BarcodeResult) {
                val intent = Intent()
                intent.putExtra("SCAN_RESULT", result.text)
                setResult(Activity.RESULT_OK, intent)
                finish()
            }

            override fun possibleResultPoints(resultPoints: MutableList<com.google.zxing.ResultPoint>?) {}
        })
    }

    override fun onResume() {
        super.onResume()
        barcodeView.resume()
    }

    override fun onPause() {
        super.onPause()
        barcodeView.pause()
    }
}
