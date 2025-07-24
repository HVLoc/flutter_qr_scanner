package vn.lochv.flutter_qr_scanner

import android.app.Activity
import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec

class QrScannerViewFactory(
    private val messenger: BinaryMessenger,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {

        val methodChannel = MethodChannel(messenger, "flutter_qr_scanner_channel_$viewId")

        return QrScannerView(
            context = context,
            onScanResult = { result -> methodChannel.invokeMethod("onScanResult", result) },
        )
    }
}
