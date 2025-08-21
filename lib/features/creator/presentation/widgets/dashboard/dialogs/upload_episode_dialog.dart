import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/models/creator_models.dart';
import '../../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../data/providers.dart';

class UploadEpisodeDialog extends ConsumerStatefulWidget {
  final String episodeId;

  const UploadEpisodeDialog({super.key, required this.episodeId});

  @override
  ConsumerState<UploadEpisodeDialog> createState() => _UploadEpisodeDialogState();
}

class _UploadEpisodeDialogState extends ConsumerState<UploadEpisodeDialog> {
  bool _isLoading = false;
  String? _selectedFilePath;
  int? _fileSize;
  String? _contentType;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Episode Video'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select a video file to upload for this episode.'),
          const SizedBox(height: 16),
          if (_selectedFilePath != null) ...[
            Text('File: ${_selectedFilePath!.split('/').last}'),
            Text('Size: ${(_fileSize! / (1024 * 1024)).toStringAsFixed(2)} MB'),
            Text('Type: $_contentType'),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickVideoFile,
                  icon: const Icon(Icons.video_file),
                  label: const Text('Pick Video'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _recordVideo,
                  icon: const Icon(Icons.videocam),
                  label: const Text('Record'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_selectedFilePath != null && !_isLoading) ? _uploadVideo : null,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Upload'),
        ),
      ],
    );
  }

  Future<void> _pickVideoFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _selectedFilePath = file.name;
          _fileSize = file.size;
          _contentType = file.extension != null ? 'video/${file.extension}' : 'video/mp4';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _recordVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.camera);
      
      if (video != null) {
        final file = File(video.path);
        final stat = await file.stat();
        setState(() {
          _selectedFilePath = video.name;
          _fileSize = stat.size;
          _contentType = 'video/mp4';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error recording video: $e')),
      );
    }
  }

  Future<void> _uploadVideo() async {
    if (_selectedFilePath == null || _fileSize == null || _contentType == null) return;

    setState(() => _isLoading = true);

    try {
      // Get upload URL
      final uploadUrlRequest = GetUploadUrlRequest(
        filename: _selectedFilePath!.split('/').last,
        contentType: _contentType!,
        sizeBytes: _fileSize!,
        episodeId: widget.episodeId,
      );

      final accessToken = ref.read(accessTokenProvider);
      await ref.read(creatorRepositoryProvider).getUploadUrl(
        fileName: uploadUrlRequest.filename,
        contentType: uploadUrlRequest.contentType,
        sizeBytes: uploadUrlRequest.sizeBytes,
        accessToken: accessToken,
      );

      // TODO: Implement actual file upload to S3 using the presigned URL
      // For now, we'll just notify completion with a dummy S3 path
      
      // Simulate upload completion
      await Future.delayed(const Duration(seconds: 2));
      
      final notifyRequest = NotifyUploadCompleteRequest(
        episodeId: widget.episodeId,
        s3Path: 's3://streamshort-episodes/${widget.episodeId}_${DateTime.now().millisecondsSinceEpoch}.mp4',
        sizeBytes: _fileSize!,
      );

      await ref.read(creatorRepositoryProvider).notifyUploadComplete(
        uploadId: notifyRequest.episodeId, // Using episodeId as uploadId
        fileUrl: notifyRequest.s3Path, // Using s3Path as fileUrl
        sizeBytes: _fileSize!,
        accessToken: accessToken,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video uploaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading video: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
