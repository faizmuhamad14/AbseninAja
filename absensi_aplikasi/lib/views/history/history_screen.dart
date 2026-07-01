import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/theme_provider.dart';
import '../dashboard/map_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (mounted) {
        Provider.of<AttendanceProvider>(context, listen: false).fetchHistoryAndStats();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final history = attendanceProvider.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Absensi', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: attendanceProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off, size: 64, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada riwayat absensi.',
                        style: TextStyle(fontSize: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await attendanceProvider.fetchHistoryAndStats();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: history.length,
                    itemBuilder: (ctx, index) {
                      final item = history[index];
                      return Dismissible(
                        key: Key(item.id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 30),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              title: const Text('Hapus Absensi'),
                              content: const Text('Apakah Anda yakin ingin menghapus data absensi ini?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(dialogCtx).pop(true),
                                  child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          attendanceProvider.deleteAttendanceItem(context, item.id);
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.attendanceDate,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: item.status == 'masuk' ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.status.toUpperCase(),
                                    style: TextStyle(
                                      color: item.status == 'masuk' ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.login_rounded, size: 16, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text('Masuk: ${item.checkInTime ?? '--:--'}'),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.logout_rounded, size: 16, color: Colors.redAccent),
                                    const SizedBox(width: 4),
                                    Text('Pulang: ${item.checkOutTime ?? '--:--'}'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        (item.checkInAddress != null && item.checkInAddress!.trim().isNotEmpty)
                                            ? item.checkInAddress!
                                            : (item.checkOutAddress != null && item.checkOutAddress!.trim().isNotEmpty)
                                                ? item.checkOutAddress!
                                                : (item.checkInLat != null && item.checkInLng != null)
                                                    ? 'Lat: ${item.checkInLat}, Lng: ${item.checkInLng}'
                                                    : 'Lokasi tidak tersedia',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => MapDetailScreen(attendance: item)),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
