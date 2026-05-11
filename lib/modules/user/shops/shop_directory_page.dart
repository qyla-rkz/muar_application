import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShopDirectoryPage extends StatelessWidget {
  const ShopDirectoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kedai Pedagang"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('shops')
            .where('status', isEqualTo: 'approved')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
                child: Text("Tiada kedai yang disahkan dijumpai."));
          }

          return RefreshIndicator(
              onRefresh: () async {
                // Trigger rebuild to re-subscribe stream
                (context as Element).markNeedsBuild();
                // Or better, just convert to StatefulWidget if needed, but setState logic requires StatefulWidget.
                // Wait, this is a StatelessWidget. I cannot use setState.
                // I should convert to StatefulWidget first? Or just let it be?
                // Actually, looking at the code, it is a StatelessWidget.
                // I CANNOT use setState in StatelessWidget.
                // I will leave it as is for now and note it?
                // No, the user wants me to implement it.
                // I MUST convert to StatefulWidget.
                // Or I can use a ValueNotifier? No, simpler to convert.
              },
              // WAIT. I cannot change to StatefulWidget comfortably in one replace call if it changes the whole file structure.
              // But actually, I can just not implement logic?
              // No, that's bad.
              // I will Convert ShopDirectoryPage to StatefulWidget.
              // This requires changing the class definition.
              // I will start by converting the class to StatefulWidget.
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>? ?? {};

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: data['status'] == 'approved'
                            ? Colors.blue.shade50
                            : Colors.grey.shade100,
                        child: Icon(
                          data['status'] == 'approved'
                              ? Icons.verified
                              : Icons.store,
                          color: data['status'] == 'approved'
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                              child: Text(data['shopName'] ?? 'Unnamed Shop')),
                          if (data['status'] == 'approved') ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified,
                                color: Colors.blue, size: 16),
                          ],
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Text(data['category'] ?? 'Retail'),
                          const Spacer(),
                          const Icon(Icons.card_giftcard,
                              color: Colors.orange, size: 14),
                          const SizedBox(width: 4),
                          const Text("App Exclusives",
                              style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/shopDetail',
                          arguments: doc.id,
                        );
                      },
                    ),
                  );
                },
              ));
        },
      ),
    );
  }
}
