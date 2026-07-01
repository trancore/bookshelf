package com.bookshelf.bookshelf

import android.content.Intent
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
    private var pendingPickDirectoryResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickDirectoryTree" -> pickDirectoryTree(result)
                "documentLength" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val treeRootPath = call.argument<String>("treeRootPath")
                    val treeUri = call.argument<String>("treeUri")
                    if (sourcePath.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "sourcePath is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        result.success(
                            documentLength(sourcePath, treeRootPath, treeUri).toInt(),
                        )
                    } catch (e: Exception) {
                        result.error("LENGTH_FAILED", e.message, null)
                    }
                }
                "copyPathToFile" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val treeRootPath = call.argument<String>("treeRootPath")
                    val treeUri = call.argument<String>("treeUri")
                    val destPath = call.argument<String>("destPath")
                    if (sourcePath.isNullOrBlank() || destPath.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "sourcePath and destPath are required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        copyPathToFile(sourcePath, treeRootPath, treeUri, destPath)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("COPY_FAILED", e.message, null)
                    }
                }
                "deleteDocument" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val treeRootPath = call.argument<String>("treeRootPath")
                    val treeUri = call.argument<String>("treeUri")
                    if (sourcePath.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "sourcePath is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        deleteDocument(sourcePath, treeRootPath, treeUri)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("DELETE_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun pickDirectoryTree(result: MethodChannel.Result) {
        if (pendingPickDirectoryResult != null) {
            result.error("IN_PROGRESS", "Directory picker is already open", null)
            return
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            result.error("UNSUPPORTED", "SAF requires API 21+", null)
            return
        }

        pendingPickDirectoryResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
            )
        }
        startActivityForResult(intent, PICK_DIRECTORY_TREE_CODE)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == PICK_DIRECTORY_TREE_CODE) {
            val pendingResult = pendingPickDirectoryResult
            pendingPickDirectoryResult = null
            if (pendingResult != null) {
                val uri = data?.data
                if (resultCode == RESULT_OK && uri != null) {
                    val flags =
                        Intent.FLAG_GRANT_READ_URI_PERMISSION or
                            Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                    contentResolver.takePersistableUriPermission(uri, flags)
                    pendingResult.success(uri.toString())
                } else {
                    pendingResult.success(null)
                }
            }
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun documentLength(
        sourcePath: String,
        treeRootPath: String?,
        treeUri: String?,
    ): Long {
        val uri = buildDocumentUri(sourcePath, treeRootPath, treeUri)
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

    private fun copyPathToFile(
        sourcePath: String,
        treeRootPath: String?,
        treeUri: String?,
        destPath: String,
    ) {
        val uri = buildDocumentUri(sourcePath, treeRootPath, treeUri)
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

    private fun deleteDocument(
        sourcePath: String,
        treeRootPath: String?,
        treeUri: String?,
    ) {
        val uri = buildDocumentUri(sourcePath, treeRootPath, treeUri)
        if (!DocumentsContract.isDocumentUri(this, uri)) {
            throw IllegalStateException("Not a document URI for $sourcePath")
        }
        if (!DocumentsContract.deleteDocument(contentResolver, uri)) {
            throw IllegalStateException("Cannot delete document for $sourcePath")
        }
    }

    private fun buildDocumentUri(
        sourcePath: String,
        treeRootPath: String?,
        treeUri: String?,
    ): Uri {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            throw IllegalStateException("SAF requires API 21+")
        }

        val fileRelative = normalizePrimaryRelative(sourcePath)
        val documentId = "primary:$fileRelative"

        val resolvedTreeUri = resolveTreeUri(treeRootPath, treeUri)
        if (resolvedTreeUri != null) {
            return DocumentsContract.buildDocumentUriUsingTree(resolvedTreeUri, documentId)
        }

        return DocumentsContract.buildDocumentUri(STORAGE_AUTHORITY, documentId)
    }

    private fun resolveTreeUri(treeRootPath: String?, treeUri: String?): Uri? {
        if (!treeUri.isNullOrBlank()) {
            val parsed = Uri.parse(treeUri)
            if (hasReadablePersistedPermission(parsed)) {
                return parsed
            }
        }

        if (!treeRootPath.isNullOrBlank()) {
            val resolved = findPersistedTreeUriForPath(treeRootPath)
            if (resolved != null) {
                return resolved
            }

            val treeDocumentId = "primary:${normalizePrimaryRelative(treeRootPath)}"
            return DocumentsContract.buildTreeDocumentUri(
                STORAGE_AUTHORITY,
                treeDocumentId,
            )
        }

        return null
    }

    private fun hasReadablePersistedPermission(uri: Uri): Boolean {
        return contentResolver.persistedUriPermissions.any { permission ->
            permission.uri == uri && permission.isReadPermission
        }
    }

    private fun findPersistedTreeUriForPath(treeRootPath: String): Uri? {
        val target = normalizePrimaryRelative(treeRootPath)
        for (permission in contentResolver.persistedUriPermissions) {
            if (!permission.isReadPermission) continue
            val uri = permission.uri
            if (!DocumentsContract.isTreeUri(uri)) continue
            val documentId = DocumentsContract.getTreeDocumentId(uri)
            val path = documentId.removePrefix("primary:")
            if (path == target) {
                return uri
            }
        }
        return null
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
        private const val PICK_DIRECTORY_TREE_CODE = 0xB001
    }
}
