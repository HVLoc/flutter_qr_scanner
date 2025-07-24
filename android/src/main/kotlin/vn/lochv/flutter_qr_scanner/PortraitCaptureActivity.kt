package vn.lochv.flutter_qr_scanner

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import android.graphics.Color
import android.widget.LinearLayout
import android.widget.TextView
import android.view.Gravity
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import androidx.appcompat.app.AppCompatActivity
import com.journeyapps.barcodescanner.BarcodeCallback
import com.journeyapps.barcodescanner.BarcodeResult
import com.journeyapps.barcodescanner.CompoundBarcodeView
import com.journeyapps.barcodescanner.camera.CameraSettings
import java.io.File
import java.io.InputStream

class PortraitCaptureActivity : AppCompatActivity() {
    private lateinit var barcodeView: CompoundBarcodeView
    private var isTorchOn = false
    private val REQUEST_IMAGE_PICK = 1001

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val showGallery = intent?.getBooleanExtra("showGallery", false) == true

        barcodeView = CompoundBarcodeView(this).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            statusView.text = if (showGallery) "" else "Đưa mã QR vào khung để quét"
            cameraSettings.focusMode = CameraSettings.FocusMode.CONTINUOUS
        }

        val backButton = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_menu_close_clear_cancel)
            setPadding(50, 50, 50, 50)
            setOnClickListener {
                setResult(Activity.RESULT_CANCELED)
                finish()
            }
        }

        val flashButton = ImageView(this).apply {
            setImageResource(R.drawable.ic_flash_on)
            setPadding(50, 50, 50, 50)
            setOnClickListener {
                isTorchOn = !isTorchOn
                if (isTorchOn) {
                    barcodeView.setTorchOn()
                    setImageResource(R.drawable.ic_flash_off)
                } else {
                    barcodeView.setTorchOff()
                    setImageResource(R.drawable.ic_flash_on)
                }
            }
        }

        val pickImageButton = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(20, 20, 20, 40)

            val icon = ImageView(this@PortraitCaptureActivity).apply {
                setImageResource(android.R.drawable.ic_menu_gallery)
                setOnClickListener {
                    val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
                    startActivityForResult(intent, REQUEST_IMAGE_PICK)
                }
            }

            val label = TextView(this@PortraitCaptureActivity).apply {
                text = "Chọn từ ảnh trong máy"
                setTextColor(Color.WHITE)
                textSize = 16f
                gravity = Gravity.CENTER
            }

            addView(icon)
            addView(label)
            visibility = if (showGallery) LinearLayout.VISIBLE else LinearLayout.GONE
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
            ).apply { gravity = Gravity.START or Gravity.TOP })

            addView(flashButton, FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { gravity = Gravity.END or Gravity.TOP })

            addView(pickImageButton, FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
                bottomMargin = 60
            })
        }

        setContentView(layout)

        barcodeView.decodeContinuous(object : BarcodeCallback {
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

    private fun pickImageFromGallery() {
        val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
        intent.type = "image/*"
        startActivityForResult(intent, REQUEST_IMAGE_PICK)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQUEST_IMAGE_PICK && resultCode == Activity.RESULT_OK && data != null) {
            val uri: Uri? = data.data
            uri?.let {
                val imagePath = copyUriToTempFile(it)
                if (imagePath != null) {
                    val result = QrScanHelper.scanQRFromImagePath(imagePath)
                    if (result != null) {
                        val intent = Intent().apply {
                            putExtra("SCAN_RESULT", result["content"] as String)
                            putExtra("SCAN_EXTRA", HashMap(result))
                        }
                        setResult(Activity.RESULT_OK, intent)
                    } else {
                        setResult(Activity.RESULT_CANCELED)
                    }
                } else {
                    setResult(Activity.RESULT_CANCELED)
                }
                finish()
            }
        }
    }

    private fun copyUriToTempFile(uri: Uri): String? {
        return try {
            val inputStream: InputStream = contentResolver.openInputStream(uri) ?: return null
            val tempFile = File(cacheDir, "temp_qr_image_${System.currentTimeMillis()}.jpg")
            tempFile.outputStream().use { output ->
                inputStream.copyTo(output)
            }
            tempFile.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}
