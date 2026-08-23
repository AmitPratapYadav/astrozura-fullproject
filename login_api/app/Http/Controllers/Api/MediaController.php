<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\MediaStorage;
use Illuminate\Http\Request;

class MediaController extends Controller
{
    public function uploadChatImage(Request $request)
    {
        $validated = $request->validate([
            'image' => 'required|image|max:10240',
        ]);

        $path = MediaStorage::store($validated['image'], 'chat-attachments');

        return response()->json([
            'success' => true,
            'message' => 'Chat image uploaded successfully.',
            'path' => $path,
            'url' => $path,
        ]);
    }

    public function uploadChatAttachment(Request $request)
    {
        $validated = $request->validate([
            'attachment' => 'required|file|mimes:jpg,jpeg,png,webp,gif,pdf,mp4,webm,mov,mp3,m4a,wav,ogg|max:51200',
        ]);

        $file = $validated['attachment'];
        $path = MediaStorage::store($file, 'chat-attachments');
        $mime = $file->getClientMimeType() ?: $file->getMimeType();

        return response()->json([
            'success' => true,
            'message' => 'Chat attachment uploaded successfully.',
            'path' => $path,
            'url' => $path,
            'name' => $file->getClientOriginalName(),
            'mime' => $mime,
            'size' => $file->getSize(),
            'message_type' => $this->messageTypeForMime((string) $mime),
        ]);
    }

    private function messageTypeForMime(string $mime): string
    {
        if (str_starts_with($mime, 'image/')) {
            return 'image';
        }

        if ($mime === 'application/pdf') {
            return 'pdf';
        }

        if (str_starts_with($mime, 'video/')) {
            return 'video';
        }

        if (str_starts_with($mime, 'audio/')) {
            return 'audio';
        }

        return 'file';
    }
}
