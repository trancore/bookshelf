package com.bookshelf.bookshelf

import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "documentLength" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val treeRootPath = call.argument<String>("treeRootPath")
                    if (sourcePath.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "sourcePath is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        result.success(
                            documentLength(sourcePath, treeRootPath).toInt(),
                        )
                    } catch (e: Exception) {
                        result.error("LENGTH_FAILED", e.message, null)
                    }
                }
                "copyPathToFile" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val treeRootPath = call.argument<String>("treeRootPath")
                    val destPath = call.argument<String>("destPath")
                    if (sourcePath.isNullOrBlank() || destPath.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "sourcePath and destPath are required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        copyPathToFile(sourcePath, treeRootPath, destPath)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("COPY_FAILED", e.message, null)
                    }
                }
                "deleteDocument" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val treeRootPath = call.argument<String>("treeRootPath")
                    if (sourcePath.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "sourcePath is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        deleteDocument(sourcePath, treeRootPath)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("DELETE_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun documentLength(sourcePath: String, treeRootPath: String?): Long {
        val uri = buildDocumentUri(sourcePath, treeRootPath)
        contentResolver.query(uri, arrayOf(OpenableColumns.SIZE), null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val index = cursor.getColumnIndex(OpenableColumns.SIZE)
                if (index >= 0) {
                    val size = cursor.getLong(index)
                    if (size >= 0) return size
                }
            }
        }

        contentResolver.openAssetFileDescriptor(uri, "r")?.use { afd ->
            if (afd.length >= 0) return afd.length
        }

        throw IllegalStateException("Cannot read document length for $sourcePath")
    }

    private fun copyPathToFile(sourcePath: String, treeRootPath: String?, destPath: String) {
        val uri = buildDocumentUri(sourcePath, treeRootPath)
        val input = contentResolver.openInputStream(uri)
            ?: throw IllegalStateException("Cannot open document for $sourcePath")
        val destFile = File(destPath)
        destFile.parentFile?.mkdirs()
        input.use { stream ->
            FileOutputStream(destFile).use { output ->
                stream.copyTo(output)
            }
        }
    }

    private fun deleteDocument(sourcePath: String, treeRootPath: String?) {
        val uri = buildDocumentUri(sourcePath, treeRootPath)
        if (!DocumentsContract.isDocumentUri(this, uri)) {
            throw IllegalStateException("Not a document URI for $sourcePath")
        }
        if (!DocumentsContract.deleteDocument(contentResolver, uri)) {
            throw IllegalStateException("Cannot delete document for $sourcePath")
        }
    }

    private fun buildDocumentUri(sourcePath: String, treeRootPath: String?): Uri {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            throw IllegalStateException("SAF requires API 21+")
        }

        val fileRelative = normalizePrimaryRelative(sourcePath)
        val documentId = "primary:$fileRelative"

        if (!treeRootPath.isNullOrBlank()) {
            val treeRelative = normalizePrimaryRelative(treeRootPath)
            val treeDocumentId = "primary:$treeRelative"
            val treeUri = DocumentsContract.buildTreeDocumentUri(
                STORAGE_AUTHORITY,
                treeDocumentId,
            )
            return DocumentsContract.buildDocumentUriUsingTree(treeUri, documentId)
        }

        return DocumentsContract.buildDocumentUri(STORAGE_AUTHORITY, documentId)
    }

    private fun normalizePrimaryRelative(path: String): String {
        var normalized = path.trim()
        val prefixes = listOf("/storage/emulated/0/", "/storage/emulated/0", "/sdcard/", "/sdcard")
        for (prefix in prefixes) {
            if (normalized.startsWith(prefix)) {
                normalized = normalized.removePrefix(prefix)
                break
            }
        }
        while (normalized.startsWith("/")) {
            normalized = normalized.removePrefix("/")
        }
        return normalized
    }

    companion object {
        private const val CHANNEL = "com.bookshelf.bookshelf/saf_io"
        private const val STORAGE_AUTHORITY = "com.android.externalstorage.documents"
    }
}
