
import 'package:flutter/material.dart';
import 'user_model.dart';
import 'user_service.dart';

void main() {
  runApp(const CrudApp());
}

const Color bgColor = Color(0xFF100D18);
const Color cardColor = Color(0xFF211A30);
const Color purpleColor = Color(0xFF9B72F2);
const Color lightPurple = Color(0xFFD1BFFF);

class CrudApp extends StatelessWidget {
  const CrudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Purple User API',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9C27B0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const UserPage(),
    );
  }
}

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final UserService service = UserService();
  late Future<List<UserModel>> usersFuture;

  // Perubahan lokal agar hasil edit/hapus langsung terlihat di aplikasi.
  // Reqres API demo tidak menyimpan perubahan secara permanen.
  final Map<int, UserModel> editedUsers = {};
  final Set<int> deletedUserIds = {};

  @override
  void initState() {
    super.initState();
    usersFuture = service.getUsers();
  }

  void refreshUsers() {
    setState(() {
      // Muat ulang data asli dari server; perubahan lokal akan direset.
      editedUsers.clear();
      deletedUserIds.clear();
      usersFuture = service.getUsers();
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: purpleColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<Map<String, String>?> showUserForm({
    String name = '',
    String job = '',
    String title = 'Tambah User',
  }) async {
    final nameController = TextEditingController(text: name);
    final jobController = TextEditingController(text: job);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(title),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama lengkap',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: jobController,
              decoration: const InputDecoration(
                labelText: 'Pekerjaan / Jabatan',
                prefixIcon: Icon(Icons.work_outline),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: purpleColor,
            ),
            onPressed: () {
              final enteredName = nameController.text.trim();
              final enteredJob = jobController.text.trim();

              if (enteredName.isEmpty || enteredJob.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nama dan pekerjaan wajib diisi.'),
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext, {
                'name': enteredName,
                'job': enteredJob,
              });
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    nameController.dispose();
    jobController.dispose();

    return result;
  }

  Future<void> addUser() async {
    final data = await showUserForm();
    if (data == null || !mounted) return;

    try {
      final result = await service.createUser(
        data['name']!,
        data['job']!,
      );

      if (!mounted) return;

      showMessage(
        'User berhasil dibuat! ID: ${result['id'] ?? '-'}',
      );
    } catch (e) {
      if (!mounted) return;
      showMessage('Gagal membuat user: $e');
    }
  }

  Future<void> editUser(UserModel user) async {
    final data = await showUserForm(
      name: '${user.firstName} ${user.lastName}'.trim(),
      job: 'Karyawan',
      title: 'Edit User #${user.id}',
    );

    if (data == null || !mounted) return;

    try {
      // Kirim permintaan PUT ke Reqres API.
      await service.updateUser(
        user.id,
        data['name']!,
        data['job']!,
      );

      if (!mounted) return;

      // Perbarui nama di tampilan lokal setelah API merespons berhasil.
      final nameParts = data['name']!.trim().split(RegExp(r'\s+'));
      final updatedUser = UserModel(
        id: user.id,
        email: user.email,
        firstName: nameParts.first,
        lastName: nameParts.length > 1
            ? nameParts.skip(1).join(' ')
            : '',
        avatar: user.avatar,
      );

      setState(() {
        editedUsers[user.id] = updatedUser;
      });

      showMessage('User berhasil diperbarui!');
    } catch (e) {
      if (!mounted) return;
      showMessage('Gagal mengubah user: $e');
    }
  }

  Future<void> deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text('Hapus User?'),
        content: Text(
          'Apakah kamu yakin ingin menghapus '
              '${user.firstName} ${user.lastName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Kirim permintaan DELETE ke Reqres API.
      await service.deleteUser(user.id);

      if (!mounted) return;

      // Sembunyikan user dari daftar lokal; jangan GET ulang karena
      // Reqres demo tidak benar-benar menghapus data contoh di server.
      setState(() {
        deletedUserIds.add(user.id);
        editedUsers.remove(user.id);
      });

      showMessage('User berhasil dihapus dari daftar!');
    } catch (e) {
      if (!mounted) return;
      showMessage('Gagal menghapus user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgColor,
        title: const Row(
          children: [
            Icon(Icons.bubble_chart, color: purpleColor, size: 30),
            SizedBox(width: 10),
            Text(
              'Purple Users',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: refreshUsers,
            icon: const Icon(Icons.refresh, color: lightPurple),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addUser,
        backgroundColor: purpleColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Tambah User'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF52328B),
                      Color(0xFF291D45),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REST API DASHBOARD',
                      style: TextStyle(
                        color: lightPurple,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Kelola Pengguna',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Data pengguna dari Reqres API',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'DAFTAR PENGGUNA',
                style: TextStyle(
                  color: lightPurple,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<UserModel>>(
                future: usersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: purpleColor,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_off,
                              color: lightPurple,
                              size: 55,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Data gagal dimuat',
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white60,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: refreshUsers,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final users = (snapshot.data ?? [])
                      .where((user) => !deletedUserIds.contains(user.id))
                      .map((user) => editedUsers[user.id] ?? user)
                      .toList();

                  if (users.isEmpty) {
                    return const Center(
                      child: Text('Belum ada data pengguna.'),
                    );
                  }

                  return RefreshIndicator(
                    color: purpleColor,
                    onRefresh: () async {
                      refreshUsers();
                      try {
                        await usersFuture;
                      } catch (_) {
                        // Error ditampilkan oleh FutureBuilder.
                      }
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        16, 0, 16, 100,
                      ),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: purpleColor.withValues(
                                alpha: 0.20,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: purpleColor,
                                backgroundImage:
                                user.avatar.isNotEmpty
                                    ? NetworkImage(user.avatar)
                                    : null,
                                child: user.avatar.isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${user.firstName} ${user.lastName}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      user.email,
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Text(
                                      'ID: ${user.id}',
                                      style: const TextStyle(
                                        color: lightPurple,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                color: cardColor,
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    editUser(user);
                                  } else if (value == 'delete') {
                                    deleteUser(user);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined),
                                        SizedBox(width: 10),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                        ),
                                        SizedBox(width: 10),
                                        Text('Hapus'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
