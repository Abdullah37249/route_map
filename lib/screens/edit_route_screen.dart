import 'package:flutter/material.dart';
import '../viewmodels/edit_route_viewmodel.dart';
import 'multi_point_map_screen.dart';

class EditRouteScreen extends StatefulWidget {
  final Map<String, dynamic> route;
  final int routeId;

  EditRouteScreen({required this.route, required this.routeId});

  @override
  State<EditRouteScreen> createState() => _EditRouteScreenState();
}

class _EditRouteScreenState extends State<EditRouteScreen> {
  late EditRouteViewModel _viewModel;
  final _routeNameController = TextEditingController();
  final _provinceController = TextEditingController();
  final _cityController = TextEditingController();
  final _dateController = TextEditingController();

  final Map<int, TextEditingController> _startNameControllers = {};
  final Map<int, TextEditingController> _endNameControllers = {};
  final Map<int, TextEditingController> _distanceControllers = {};
  final Map<int, TextEditingController> _durationControllers = {};

  bool _isSendingToServer = false;

  @override
  void initState() {
    super.initState();
    _viewModel = EditRouteViewModel(route: widget.route, routeId: widget.routeId);
    _initializeControllers();
    _loadData();
    _setupListeners();
  }

  void _initializeControllers() {
    _routeNameController.text = _viewModel.routeName;
    _provinceController.text = _viewModel.province;
    _cityController.text = _viewModel.city;
    _dateController.text = _viewModel.date;
  }

  void _loadData() async {
    await _viewModel.loadSegments();
    await _viewModel.checkServerStatus();
  }

  void _setupListeners() {
    _viewModel.segmentsStream.listen((segments) {
      if (mounted) {
        setState(() {
          // Update UI when segments change
        });
      }
    });

    _viewModel.hasChangesStream.listen((hasChanges) {
      if (mounted) {
        setState(() {
          // Update UI when changes occur
        });
      }
    });

    _viewModel.serverStatusStream.listen((existsOnServer) {
      if (mounted) {
        setState(() {
          // Update UI when server status changes
        });
      }
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _routeNameController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _dateController.dispose();

    _startNameControllers.values.forEach((c) => c.dispose());
    _endNameControllers.values.forEach((c) => c.dispose());
    _distanceControllers.values.forEach((c) => c.dispose());
    _durationControllers.values.forEach((c) => c.dispose());

    super.dispose();
  }

  void _showEditSegmentDialog(Map<String, dynamic> segment) {
    final id = segment['id'] as int;
    final srNo = segment['sr_no'] as int;

    // Initialize controllers for this segment if not exists
    if (!_startNameControllers.containsKey(id)) {
      _startNameControllers[id] = TextEditingController(text: _viewModel.getStartName(id));
      _endNameControllers[id] = TextEditingController(text: _viewModel.getEndName(id));
      _distanceControllers[id] = TextEditingController(text: _viewModel.getDistance(id));
      _durationControllers[id] = TextEditingController(text: _viewModel.getDuration(id));
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Segment $srNo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _startNameControllers[id],
                decoration: InputDecoration(
                  labelText: 'Start Point Name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _viewModel.updateSegmentField(id, 'startName', value),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _endNameControllers[id],
                decoration: InputDecoration(
                  labelText: 'End Point Name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _viewModel.updateSegmentField(id, 'endName', value),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _distanceControllers[id],
                decoration: InputDecoration(
                  labelText: 'Distance (km)',
                  border: OutlineInputBorder(),
                  suffixText: 'km',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) => _viewModel.updateSegmentField(id, 'distance', value),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _durationControllers[id],
                decoration: InputDecoration(
                  labelText: 'Duration',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 2 h 30 min',
                ),
                onChanged: (value) => _viewModel.updateSegmentField(id, 'duration', value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await _viewModel.saveSegmentChanges(id);
              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Segment updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text('Save'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openMapForSegmentEdit(segment);
            },
            child: Text('Edit on Map'),
          ),
        ],
      ),
    );
  }

  void _openMapForSegmentEdit(Map<String, dynamic> segment) async {
    final routeId = widget.routeId;
    final srNo = segment['sr_no'] as int;

    final allSegments = await _viewModel.segments;

    List<Map<String, dynamic>> waypoints = [];
    for (final seg in allSegments) {
      waypoints.add({
        'name': seg['start_name']?.toString() ?? 'Start',
        'lat': seg['start_lat'] as double? ?? 0.0,
        'lng': seg['start_lng'] as double? ?? 0.0,
      });

      if (seg['sr_no'] == allSegments.length) {
        waypoints.add({
          'name': seg['end_name']?.toString() ?? 'End',
          'lat': seg['end_lat'] as double? ?? 0.0,
          'lng': seg['end_lng'] as double? ?? 0.0,
        });
      }
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiPointMapScreen.editMode(
          existingWaypoints: waypoints,
          routeId: routeId,
          segmentToEdit: srNo,
        ),
      ),
    );

    if (result == true) {
      await _viewModel.loadSegments();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Segment updated via map'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _saveAllChanges() async {
    final result = await _viewModel.saveAllChanges();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? Colors.green : Colors.orange,
      ),
    );
  }

  Future<void> _updateToServer() async {
    if (_isSendingToServer) return; // Prevent multiple clicks

    setState(() {
      _isSendingToServer = true;
    });

    try {
      // First, save all local changes
      if (_viewModel.hasChanges) {
        final localSaveResult = await _viewModel.saveAllChanges();
        if (!localSaveResult['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save local changes: ${localSaveResult['message']}'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Local changes saved successfully'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      // Then send to server
      final result = await _viewModel.updateToServer();

      switch (result['action']) {
        case 'showSuccess':
          _showSuccessDialog(result['message']);
          break;
        case 'showWarning':
          _showWarningDialog(result['message'], result['details'] ?? '');
          break;
        case 'showError':
          _showErrorDialog(result['message']);
          break;
      }

      // Refresh server status
      await _viewModel.checkServerStatus();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending to server: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingToServer = false;
        });
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success!'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showWarningDialog(String title, String details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: details.isNotEmpty ? Text('Failed segments: $details') : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openMapForCompleteEdit() async {
    final allSegments = _viewModel.segments;

    List<Map<String, dynamic>> waypoints = [];
    for (final seg in allSegments) {
      waypoints.add({
        'name': seg['start_name']?.toString() ?? 'Start',
        'lat': seg['start_lat'] as double? ?? 0.0,
        'lng': seg['start_lng'] as double? ?? 0.0,
      });

      if (seg['sr_no'] == allSegments.length) {
        waypoints.add({
          'name': seg['end_name']?.toString() ?? 'End',
          'lat': seg['end_lat'] as double? ?? 0.0,
          'lng': seg['end_lng'] as double? ?? 0.0,
        });
      }
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiPointMapScreen.editMode(
          existingWaypoints: waypoints,
          routeId: widget.routeId,
        ),
      ),
    );

    if (result == true) {
      await _viewModel.loadSegments();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Route updated via map'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Route ${widget.routeId}'),
        actions: [
          if (_viewModel.hasChanges && !_isSendingToServer)
            IconButton(
              icon: Icon(Icons.save, color: Colors.blue),
              onPressed: _saveAllChanges,
              tooltip: 'Save Changes Locally',
            ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'save_local') {
                _saveAllChanges();
              } else if (value == 'update_server') {
                _updateToServer();
              } else if (value == 'check_server') {
                _viewModel.checkServerStatus();
              } else if (value == 'edit_on_map') {
                _openMapForCompleteEdit();
              }
            },
            itemBuilder: (context) => [
              if (_viewModel.hasChanges && !_isSendingToServer)
                PopupMenuItem(
                  value: 'save_local',
                  child: Row(
                    children: [
                      Icon(Icons.save, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Save Changes Locally'),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'edit_on_map',
                child: Row(
                  children: [
                    Icon(Icons.map, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Edit on Map'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'update_server',
                child: Row(
                  children: [
                    if (_isSendingToServer)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        Icons.cloud_upload,
                        color: _viewModel.existsOnServer ? Colors.orange : Colors.green,
                      ),
                    SizedBox(width: 8),
                    Text(
                      _isSendingToServer
                          ? 'Sending...'
                          : (_viewModel.existsOnServer ? 'Update on Server' : 'Send to Server'),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'check_server',
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud,
                      color: _viewModel.existsOnServer ? Colors.green : Colors.grey,
                    ),
                    SizedBox(width: 8),
                    Text('Check Server Status'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<bool>(
        stream: _viewModel.isLoadingStream,
        initialData: _viewModel.isLoading,
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Card(
                margin: EdgeInsets.all(12),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Route Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _viewModel.existsOnServer
                                  ? Colors.green.shade100
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _viewModel.existsOnServer
                                    ? Colors.green
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _viewModel.existsOnServer
                                      ? Icons.cloud_done
                                      : Icons.cloud_off,
                                  size: 14,
                                  color: _viewModel.existsOnServer
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  _viewModel.existsOnServer ? 'On Server' : 'Local Only',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _viewModel.existsOnServer
                                        ? Colors.green.shade800
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      // Route Name Field
                      TextField(
                        controller: _routeNameController,
                        decoration: InputDecoration(
                          labelText: 'Route Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.route),
                        ),
                        onChanged: (value) => _viewModel.updateRouteInfo(
                          value,
                          _provinceController.text,
                          _cityController.text,
                          _dateController.text,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _provinceController,
                              decoration: InputDecoration(
                                labelText: 'Province',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) => _viewModel.updateRouteInfo(
                                _routeNameController.text,
                                value,
                                _cityController.text,
                                _dateController.text,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _cityController,
                              decoration: InputDecoration(
                                labelText: 'City',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) => _viewModel.updateRouteInfo(
                                _routeNameController.text,
                                _provinceController.text,
                                value,
                                _dateController.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _dateController,
                        decoration: InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            _dateController.text = picked.toIso8601String().split('T')[0];
                            _viewModel.updateRouteInfo(
                              _routeNameController.text,
                              _provinceController.text,
                              _cityController.text,
                              _dateController.text,
                            );
                          }
                        },
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Segments: ${_viewModel.segments.length}',
                            style: TextStyle(color: Colors.grey),
                          ),
                          StreamBuilder<bool>(
                            stream: _viewModel.hasChangesStream,
                            initialData: _viewModel.hasChanges,
                            builder: (context, snapshot) {
                              if (snapshot.data == true) {
                                return Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit,
                                        size: 12,
                                        color: Colors.orange.shade800,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Unsaved Changes',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return SizedBox();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _viewModel.segmentsStream,
                  initialData: _viewModel.segments,
                  builder: (context, snapshot) {
                    final segments = snapshot.data ?? [];

                    if (segments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.route, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No segments found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: segments.length,
                      itemBuilder: (context, index) {
                        final segment = segments[index];
                        final id = segment['id'] as int;
                        final srNo = segment['sr_no'] as int;

                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$srNo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _viewModel.getStartName(id),
                                  style: TextStyle(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.arrow_right_alt, size: 16, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _viewModel.getEndName(id),
                                        style: TextStyle(fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.straighten, size: 14, color: Colors.blue),
                                    SizedBox(width: 4),
                                    Text('${_viewModel.getDistance(id)} km'),
                                  ],
                                ),
                                SizedBox(width: 16),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 14, color: Colors.orange),
                                    SizedBox(width: 4),
                                    Text(_viewModel.getDuration(id)),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, size: 20),
                                  onPressed: () => _showEditSegmentDialog(segment),
                                  tooltip: 'Edit Segment',
                                ),
                                IconButton(
                                  icon: Icon(Icons.map, size: 20, color: Colors.green),
                                  onPressed: () => _openMapForSegmentEdit(segment),
                                  tooltip: 'Edit on Map',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSendingToServer)
            Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Sending to server...'),
                ],
              ),
            ),
          FloatingActionButton.extended(
            onPressed: _isSendingToServer ? null : _updateToServer,
            icon: _isSendingToServer
                ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Icon(_viewModel.existsOnServer ? Icons.cloud_sync : Icons.cloud_upload),
            label: _isSendingToServer
                ? Text('Sending...')
                : Text(_viewModel.existsOnServer ? 'Update Server' : 'Send to Server'),
            backgroundColor: _isSendingToServer
                ? Colors.blue.shade300
                : (_viewModel.existsOnServer ? Colors.orange : Colors.green),
            foregroundColor: Colors.white,
            heroTag: 'server_button',
          ),
          SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: _isSendingToServer ? null : _openMapForCompleteEdit,
            icon: Icon(Icons.map),
            label: Text('Edit on Map'),
            backgroundColor: _isSendingToServer ? Colors.grey : Colors.purple,
            foregroundColor: Colors.white,
            heroTag: 'map_button',
          ),
          SizedBox(height: 12),
          StreamBuilder<bool>(
            stream: _viewModel.hasChangesStream,
            initialData: _viewModel.hasChanges,
            builder: (context, snapshot) {
              if (snapshot.data == true && !_isSendingToServer) {
                return FloatingActionButton.extended(
                  onPressed: _saveAllChanges,
                  icon: Icon(Icons.save),
                  label: Text('Save Locally'),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  heroTag: 'save_button',
                );
              }
              return SizedBox();
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _isSendingToServer ? null : () {
                  if (_viewModel.hasChanges) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Unsaved Changes'),
                        content: Text(
                          'You have unsaved changes. Are you sure you want to leave?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: Text('Leave'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    Navigator.pop(context);
                  }
                },
                icon: Icon(Icons.arrow_back),
                label: Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}