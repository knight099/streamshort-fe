import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/models/creator_models.dart';
import '../../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../data/providers.dart';
import 'add_episode_dialog.dart';

class UploadVideoDialog extends ConsumerStatefulWidget {
  final String seriesId;

  const UploadVideoDialog({
    super.key,
    required this.seriesId,
  });

  @override
  ConsumerState<UploadVideoDialog> createState() => _UploadVideoDialogState();
}

class _UploadVideoDialogState extends ConsumerState<UploadVideoDialog> {
  bool _isLoading = false;
  String? _selectedFilePath;
  int? _fileSize;
  String? _contentType;
  double _uploadProgress = 0.0;
  String? _error;
  String? _manifestUrl;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Episode Video'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          const Text('Select a video file to upload for this episode.'),
          const SizedBox(height: 16),
          if (_selectedFilePath != null) ...[
            Text('File: ${_selectedFilePath!.split('/').last}'),
            Text('Size: ${(_fileSize! / (1024 * 1024)).toStringAsFixed(2)} MB'),
            Text('Type: $_contentType'),
            const SizedBox(height: 16),
            if (_isLoading)
              LinearProgressIndicator(value: _uploadProgress),
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
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error picking file: $e';
      });
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
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error recording video: $e';
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (_selectedFilePath == null || _fileSize == null || _contentType == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _uploadProgress = 0.0;
    });

    try {
      // Get upload URL
      final accessToken = ref.read(accessTokenProvider);
      final uploadUrlResponse = await ref.read(creatorRepositoryProvider).getUploadUrl(
        fileName: _selectedFilePath!.split('/').last,
        contentType: _contentType!,
        sizeBytes: _fileSize!,
        metadata: {
          'series_id': widget.seriesId,
        },
        accessToken: accessToken,
      );

      // Extract upload URL and upload ID
      final uploadUrl = uploadUrlResponse['presigned_url'] as String;
      final uploadId = uploadUrlResponse['upload_id'] as String;

      // TODO: Implement actual file upload to S3 using the presigned URL
      // For now, we'll just simulate upload progress
      for (var i = 0; i <= 100; i += 10) {
        if (!mounted) return;
        setState(() {
          _uploadProgress = i / 100;
        });
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // Notify upload complete
      final response = await ref.read(creatorRepositoryProvider).notifyUploadComplete(
        uploadId: uploadId,
        s3Path: 's3://streamshort-episodes/${widget.seriesId}_${DateTime.now().millisecondsSinceEpoch}.mp4',
        sizeBytes: _fileSize!,
        accessToken: accessToken,
      );

      // Extract manifest URL from response
      _manifestUrl = response['manifest_url'] as String;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video uploaded successfully!')),
        );
        Navigator.pop(context, {
          'manifest_url': _manifestUrl,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error uploading video: $e';
          _isLoading = false;
        });
      }
    }
  }
}
