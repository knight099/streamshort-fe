import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/repositories/creator_repository.dart';
import '../../../../data/providers.dart';
import '../../../../../auth/presentation/providers/auth_providers.dart';
import 'package:dio/dio.dart';

class AddEpisodeDialog extends ConsumerStatefulWidget {
  final String seriesId;
  final String? manifestUrl;

  const AddEpisodeDialog({
    super.key,
    required this.seriesId,
    this.manifestUrl,
  });

  @override
  ConsumerState<AddEpisodeDialog> createState() => _AddEpisodeDialogState();
}

class _AddEpisodeDialogState extends ConsumerState<AddEpisodeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _episodeNumberController = TextEditingController();
  final _durationMinutesController = TextEditingController();
  final _durationSecondsController = TextEditingController();
  final _captionsUrlController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _selectedFilePath;
  int? _fileSize;
  String? _contentType;
  double _uploadProgress = 0.0;
  String? _manifestUrl;

  @override
  void dispose() {
    _titleController.dispose();
    _episodeNumberController.dispose();
    _durationMinutesController.dispose();
    _durationSecondsController.dispose();
    _captionsUrlController.dispose();
    super.dispose();
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
    if (_selectedFilePath == null || _fileSize == null || _contentType == null) {
      setState(() {
        _error = 'Please select a video file first';
      });
      return;
    }

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

      if (!mounted) return;

      // Extract manifest URL from response
      final manifestUrl = response['manifest_url'] as String?;
      if (manifestUrl == null || manifestUrl.isEmpty) {
        throw Exception('Server did not return a valid manifest URL.');
      }

      setState(() {
        _manifestUrl = manifestUrl;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video uploaded successfully!')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error uploading video: ${e.response?.data?['message'] ?? e.message}';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error uploading video: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSubmit() async {
      if (!_formKey.currentState!.validate()) return;
    if (_manifestUrl == null) {
      setState(() {
        _error = 'Please upload the video first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(creatorRepositoryProvider);
      final accessToken = ref.read(accessTokenProvider);
      
      // Parse episode number
      final episodeNumber = int.parse(_episodeNumberController.text.trim());
      
      // Parse duration
      final minutes = int.parse(_durationMinutesController.text.trim());
      final seconds = int.parse(_durationSecondsController.text.trim());
      final durationSeconds = (minutes * 60) + seconds;
      
      // Get captions URL if provided
      final captionsUrl = _captionsUrlController.text.trim().isNotEmpty 
          ? _captionsUrlController.text.trim() 
          : null;
      
      final episodeId = await repository.createEpisode(
        seriesId: widget.seriesId,
        title: _titleController.text.trim(),
        episodeNumber: episodeNumber,
        durationSeconds: durationSeconds,
        manifestUrl: _manifestUrl!,
        captionsUrl: captionsUrl,
        accessToken: accessToken,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Episode created successfully!'),
          ),
        );
        Navigator.pop(context, true);
        
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Episode'),
      content: Form(
        key: _formKey,
        child: Column(
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
            // Video Upload Section
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Video Upload (Required)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (_selectedFilePath != null) ...[
                    Text('File: ${_selectedFilePath!.split('/').last}'),
                    Text('Size: ${(_fileSize! / (1024 * 1024)).toStringAsFixed(2)} MB'),
                    Text('Type: $_contentType'),
                    const SizedBox(height: 8),
                    if (_isLoading && _uploadProgress > 0)
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _recordVideo,
                          icon: const Icon(Icons.videocam),
                          label: const Text('Record'),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedFilePath != null && _manifestUrl == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _uploadVideo,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Upload'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Episode Title',
                hintText: 'Enter episode title',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _episodeNumberController,
              decoration: const InputDecoration(
                labelText: 'Episode Number',
                hintText: 'e.g., 1, 2, 3...',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter episode number';
                }
                final number = int.tryParse(value.trim());
                if (number == null || number <= 0) {
                  return 'Please enter a valid episode number';
                }
                return null;
              },
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _durationMinutesController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (Minutes)',
                      hintText: 'e.g., 5',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final number = int.tryParse(value.trim());
                      if (number == null || number < 0) {
                        return 'Invalid';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _durationSecondsController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (Seconds)',
                      hintText: 'e.g., 30',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final number = int.tryParse(value.trim());
                      if (number == null || number < 0 || number >= 60) {
                        return '0-59';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _captionsUrlController,
              decoration: const InputDecoration(
                labelText: 'Captions URL (Optional)',
                hintText: 'Enter URL for captions file',
              ),
              enabled: !_isLoading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}