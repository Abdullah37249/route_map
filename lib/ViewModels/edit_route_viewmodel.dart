import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path/path.dart';

import '../Database/db_service.dart';
import '../models/segment_model.dart';

class EditRouteViewModel {
  final int routeId;
  final Map<String, dynamic> route;

  List<Map<String, dynamic>> _segments = [];
  bool _isLoading = false;
  bool _hasChanges = false;
  bool _existsOnServer = false;

  // Form controllers
  String province = 'Punjab';
  String city = 'Sialkot';
  String date = '';

  // Segment editing state
  final Map<int, String> _startNames = {};
  final Map<int, String> _endNames = {};
  final Map<int, String> _distances = {};
  final Map<int, String> _durations = {};

  final StreamController<bool> _loadingController = StreamController<bool>.broadcast();
  final StreamController<bool> _changesController = StreamController<bool>.broadcast();
  final StreamController<bool> _serverStatusController = StreamController<bool>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _segmentsController =
  StreamController<List<Map<String, dynamic>>>.broadcast();

  Stream<bool> get isLoadingStream => _loadingController.stream;
  Stream<bool> get hasChangesStream => _changesController.stream;
  Stream<bool> get serverStatusStream => _serverStatusController.stream;
  Stream<List<Map<String, dynamic>>> get segmentsStream => _segmentsController.stream;

  List<Map<String, dynamic>> get segments => _segments;
  bool get isLoading => _isLoading;
  bool get hasChanges => _hasChanges;
  bool get existsOnServer => _existsOnServer;

  EditRouteViewModel({required this.route, required this.routeId}) {
    date = route['date']?.toString() ?? DateTime.now().toIso8601String().split('T')[0];
    province = route['province']?.toString() ?? 'Punjab';
    city = route['city']?.toString() ?? 'Sialkot';
  }

  Future<void> loadSegments() async {
    _setLoading(true);

    try {
      _segments = await DBHelper.getSegmentsByRouteId(routeId);

      for (final segment in _segments) {
        final id = segment['id'] as int;
        _startNames[id] = segment['start_name']?.toString() ?? '';
        _endNames[id] = segment['end_name']?.toString() ?? '';
        _distances[id] = (segment['segment_distance'] as double?)?.toStringAsFixed(2) ?? '0.00';
        _durations[id] = segment['segment_duration']?.toString() ?? '0 min';
      }

      _segmentsController.add(_segments);
    } catch (e) {
      print('Error loading segments: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> checkServerStatus() async {
    final exists = await DBHelper.doesRouteExistOnServer(routeId);
    _existsOnServer = exists;
    _serverStatusController.add(exists);
  }

  void updateSegmentField(int segmentId, String field, String value) {
    switch (field) {
      case 'startName':
        _startNames[segmentId] = value;
        break;
      case 'endName':
        _endNames[segmentId] = value;
        break;
      case 'distance':
        _distances[segmentId] = value;
        break;
      case 'duration':
        _durations[segmentId] = value;
        break;
    }
    _setChangesMade(true);
  }

  void updateRouteInfo(String newProvince, String newCity, String newDate) {
    province = newProvince;
    city = newCity;
    date = newDate;
    _setChangesMade(true);
  }

  Future<bool> saveSegmentChanges(int segmentId) async {
    try {
      final startName = _startNames[segmentId] ?? '';
      final endName = _endNames[segmentId] ?? '';
      final distance = double.tryParse(_distances[segmentId] ?? '0') ?? 0.0;
      final duration = _durations[segmentId] ?? '0 min';

      final segment = _segments.firstWhere((s) => s['id'] == segmentId);

      final success = await DBHelper.updateSegment(
        id: segmentId,
        startName: startName,
        endName: endName,
        segmentDistance: distance,
        segmentDuration: duration,
        totalDistance: segment['total_distance'] as double?,
        totalDuration: segment['total_duration'] as String?,
        province: province,
        city: city,
        date: date,
      );

      if (success) {
        // Update local segment
        final index = _segments.indexWhere((s) => s['id'] == segmentId);
        if (index != -1) {
          _segments[index] = {
            ..._segments[index],
            'start_name': startName,
            'end_name': endName,
            'segment_distance': distance,
            'segment_duration': duration,
          };
          _segmentsController.add(_segments);
        }
        _setChangesMade(false);
        return true;
      }
      return false;
    } catch (e) {
      print('Error saving segment: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> saveAllChanges() async {
    _setLoading(true);

    try {
      bool allSuccessful = true;

      for (final segment in _segments) {
        final id = segment['id'] as int;
        final success = await DBHelper.updateSegment(
          id: id,
          startName: _startNames[id],
          endName: _endNames[id],
          segmentDistance: double.tryParse(_distances[id] ?? '0') ?? 0.0,
          segmentDuration: _durations[id],
          province: province,
          city: city,
          date: date,
        );

        if (!success) {
          allSuccessful = false;
        }
      }

      _setChangesMade(!allSuccessful);
      return {
        'success': allSuccessful,
        'message': allSuccessful ? 'All changes saved locally!' : 'Some segments failed to update',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error saving changes: $e',
      };
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> updateToServer() async {
    _setLoading(true);

    try {
      // Check if route exists on server
      final existsOnServer = await DBHelper.doesRouteExistOnServer(routeId);

      if (existsOnServer) {
        // Show confirmation dialog before deleting from server
        bool shouldDelete = await showDialog(
          context: context as BuildContext,
          builder: (context) => AlertDialog(
            title: const Text('Route Already on Server'),
            content: Text(
              'Route $routeId already exists on server. Do you want to delete it and upload the updated version?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete & Update'),
              ),
            ],
          ),
        ) ?? false;

        if (!shouldDelete) {
          _setLoading(false);
          return {
            'success': false,
            'message': 'Update cancelled by user',
            'action': 'showError',
          };
        }

        // Delete from server first
        final deleteSuccess = await DBHelper.deleteRouteFromServer(routeId);

        if (!deleteSuccess) {
          return {
            'success': false,
            'message': 'Failed to delete route from server. Cannot update.',
            'action': 'showError',
          };
        }

        await Future.delayed(const Duration(seconds: 1));
      }

      // Save any pending changes first
      if (_hasChanges) {
        await saveAllChanges();
      }

      // Send to server with the same route ID
      final result = await DBHelper.saveRouteSegmentsToServer(routeId);

      if (result['success'] == true) {
        final sent = result['sent_segments'] ?? 0;
        final failed = result['failed_segments'] ?? 0;

        if (failed == 0) {
          _existsOnServer = true;
          _serverStatusController.add(true);
          return {
            'success': true,
            'message': 'Route $routeId updated on server! $sent segments sent.',
            'action': 'showSuccess',
          };
        } else {
          return {
            'success': false,
            'message': 'Updated $sent segments, $failed failed.',
            'details': result['failed_segment_numbers']?.join(', ') ?? '',
            'action': 'showWarning',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to update route on server',
          'action': 'showError',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
        'action': 'showError',
      };
    } finally {
      _setLoading(false);
    }
  }

  String getStartName(int segmentId) => _startNames[segmentId] ?? '';
  String getEndName(int segmentId) => _endNames[segmentId] ?? '';
  String getDistance(int segmentId) => _distances[segmentId] ?? '0.00';
  String getDuration(int segmentId) => _durations[segmentId] ?? '0 min';

  void _setLoading(bool loading) {
    _isLoading = loading;
    _loadingController.add(loading);
  }

  void _setChangesMade(bool hasChanges) {
    _hasChanges = hasChanges;
    _changesController.add(hasChanges);
  }

  void dispose() {
    _loadingController.close();
    _changesController.close();
    _serverStatusController.close();
    _segmentsController.close();
  }
}