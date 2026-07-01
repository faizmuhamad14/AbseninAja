import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/attendance_model.dart';

class MapDetailScreen extends StatefulWidget {
  final AttendanceModel attendance;
  const MapDetailScreen({super.key, required this.attendance});

  @override
  State<MapDetailScreen> createState() => _MapDetailScreenState();
}

class _MapDetailScreenState extends State<MapDetailScreen> {
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initMarkers();
  }

  void _initMarkers() {
    final att = widget.attendance;
    if (att.checkInLat != null && att.checkInLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('check_in'),
          position: LatLng(att.checkInLat!, att.checkInLng!),
          infoWindow: InfoWindow(
            title: 'Check-In Location',
            snippet: (att.checkInAddress != null && att.checkInAddress!.trim().isNotEmpty)
                ? att.checkInAddress
                : 'Lat: ${att.checkInLat}, Lng: ${att.checkInLng}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    if (att.checkOutLat != null && att.checkOutLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('check_out'),
          position: LatLng(att.checkOutLat!, att.checkOutLng!),
          infoWindow: InfoWindow(
            title: 'Check-Out Location',
            snippet: (att.checkOutAddress != null && att.checkOutAddress!.trim().isNotEmpty)
                ? att.checkOutAddress
                : 'Lat: ${att.checkOutLat}, Lng: ${att.checkOutLng}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  Widget _buildLocationItem({
    required BuildContext context,
    required String title,
    required String? time,
    required double? lat,
    required double? lng,
    required String? address,
    required Color color,
    required IconData icon,
  }) {
    final bool hasCoordinates = lat != null && lng != null;
    final String cleanAddress = (address != null && address.trim().isNotEmpty)
        ? address.trim()
        : (hasCoordinates ? 'Lat: $lat, Lng: $lng' : 'Detail alamat tidak tersedia');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      time ?? '--:--',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: time != null ? color : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (hasCoordinates && time != null) ...[
                  Text(
                    'Koordinat GPS: $lat, $lng',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  time != null ? cleanAddress : 'Belum melakukan absensi $title',
                  style: TextStyle(
                    fontSize: 13,
                    color: time != null ? Theme.of(context).textTheme.bodyMedium?.color : Colors.grey[500],
                    fontStyle: time != null ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final att = widget.attendance;
    final LatLng initialPos = att.checkInLat != null && att.checkInLng != null
        ? LatLng(att.checkInLat!, att.checkInLng!)
        : (att.checkOutLat != null && att.checkOutLng != null
            ? LatLng(att.checkOutLat!, att.checkOutLng!)
            : const LatLng(-6.200000, 106.816666)); // Default Jakarta

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Lokasi Absen',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Top Part: Map
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: initialPos,
                    zoom: 15.0,
                  ),
                  markers: _markers,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: true,
                ),
                if (att.checkInLat == null && att.checkOutLat == null)
                  Container(
                    color: Colors.black.withValues(alpha: 0.05),
                    child: const Center(
                      child: Text(
                        'Koordinat GPS tidak tersedia',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Bottom Part: Detail Panel
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Riwayat Lokasi Absensi',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            att.attendanceDate,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    // Timeline Details
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildLocationItem(
                              context: context,
                              title: 'Masuk (Check-In)',
                              time: att.checkInTime,
                              lat: att.checkInLat,
                              lng: att.checkInLng,
                              address: att.checkInAddress,
                              color: Colors.green,
                              icon: Icons.login_rounded,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 2,
                                  height: 20,
                                  color: Colors.grey.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                            _buildLocationItem(
                              context: context,
                              title: 'Pulang (Check-Out)',
                              time: att.checkOutTime,
                              lat: att.checkOutLat,
                              lng: att.checkOutLng,
                              address: att.checkOutAddress,
                              color: Colors.redAccent,
                              icon: Icons.logout_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
