package com.example.siaheh

import android.Manifest
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.provider.Telephony
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    companion object {
        private const val SMS_READER_CHANNEL = "com.example.siaheh/sms_reader"
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var smsExecutor: ExecutorService? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        if (smsExecutor == null || smsExecutor!!.isShutdown) {
            smsExecutor = Executors.newSingleThreadExecutor()
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SMS_READER_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != "readInboxPage") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val sinceMs = call.argument<Number>("sinceMs")?.toLong()
            val beforeDateMs = call.argument<Number>("beforeDateMs")?.toLong()
            val beforeId = call.argument<Number>("beforeId")?.toLong()
            val limit = (call.argument<Number>("limit")?.toInt() ?: 300).coerceIn(1, 1000)

            val appContext = applicationContext
            val executor = smsExecutor
            if (executor == null || executor.isShutdown) {
                result.error("EXECUTOR_SHUTDOWN", "SMS executor is not available", null)
                return@setMethodCallHandler
            }

            executor.execute {
                try {
                    if (ContextCompat.checkSelfPermission(
                            appContext,
                            Manifest.permission.READ_SMS,
                        ) != PackageManager.PERMISSION_GRANTED
                    ) {
                        mainHandler.post {
                            result.error("PERMISSION_DENIED", "READ_SMS not granted", null)
                        }
                        return@execute
                    }

                    val projection = arrayOf(
                        Telephony.Sms._ID,
                        Telephony.Sms.ADDRESS,
                        Telephony.Sms.BODY,
                        Telephony.Sms.DATE,
                    )
                    val sortOrder = "${Telephony.Sms.DATE} DESC, ${Telephony.Sms._ID} DESC"

                    val (selection, selectionArgs) = when {
                        sinceMs != null && beforeDateMs != null && beforeId != null -> {
                            "${Telephony.Sms.DATE} >= ? AND (${Telephony.Sms.DATE} < ? OR (${Telephony.Sms.DATE} = ? AND ${Telephony.Sms._ID} < ?))" to
                                arrayOf(
                                    sinceMs.toString(),
                                    beforeDateMs.toString(),
                                    beforeDateMs.toString(),
                                    beforeId.toString(),
                                )
                        }
                        sinceMs != null -> {
                            "${Telephony.Sms.DATE} >= ?" to arrayOf(sinceMs.toString())
                        }
                        beforeDateMs != null && beforeId != null -> {
                            "${Telephony.Sms.DATE} < ? OR (${Telephony.Sms.DATE} = ? AND ${Telephony.Sms._ID} < ?)" to
                                arrayOf(
                                    beforeDateMs.toString(),
                                    beforeDateMs.toString(),
                                    beforeId.toString(),
                                )
                        }
                        else -> null to null
                    }

                    val items = ArrayList<HashMap<String, Any?>>(minOf(limit, 300))
                    var rowsRead = 0
                    var lastDate: Long? = null
                    var lastId: Long? = null
                    var hasMore = false

                    val cursor = appContext.contentResolver.query(
                        Telephony.Sms.Inbox.CONTENT_URI,
                        projection,
                        selection,
                        selectionArgs,
                        sortOrder,
                    )

                    cursor?.use { c ->
                        val idIdx = c.getColumnIndex(Telephony.Sms._ID)
                        val addrIdx = c.getColumnIndex(Telephony.Sms.ADDRESS)
                        val bodyIdx = c.getColumnIndex(Telephony.Sms.BODY)
                        val dateIdx = c.getColumnIndex(Telephony.Sms.DATE)

                        while (rowsRead < limit && c.moveToNext()) {
                            rowsRead++
                            val id = if (idIdx >= 0 && !c.isNull(idIdx)) c.getLong(idIdx) else null
                            val date = if (dateIdx >= 0 && !c.isNull(dateIdx)) c.getLong(dateIdx) else 0L
                            if (id != null) {
                                lastId = id
                                lastDate = date
                            }

                            val address = if (addrIdx >= 0 && !c.isNull(addrIdx)) c.getString(addrIdx) else null
                            val body = if (bodyIdx >= 0 && !c.isNull(bodyIdx)) c.getString(bodyIdx) else null
                            if (address != null && body != null) {
                                items.add(
                                    hashMapOf(
                                        "id" to id,
                                        "address" to address,
                                        "body" to body,
                                        "date" to date,
                                    ),
                                )
                            }
                        }

                        hasMore = rowsRead == limit && c.moveToNext()
                    }

                    val payload = hashMapOf<String, Any?>(
                        "messages" to items,
                        "hasMore" to hasMore,
                        "nextBeforeDate" to lastDate,
                        "nextBeforeId" to lastId,
                    )
                    mainHandler.post {
                        result.success(payload)
                    }
                } catch (t: Throwable) {
                    mainHandler.post {
                        result.error("SMS_READ_ERROR", t.message ?: "Failed to read SMS inbox", null)
                    }
                }
            }
        }
    }

    override fun onDestroy() {
        smsExecutor?.shutdownNow()
        smsExecutor = null
        super.onDestroy()
    }
}
