import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutterflow_ui/flutterflow_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';

class YourRidePage extends StatefulWidget {
  const YourRidePage({Key? key}) : super(key: key);

  @override
  _YourRidePageState createState() => _YourRidePageState();
}

class _YourRidePageState extends State<YourRidePage>
    with TickerProviderStateMixin {
  late YourRidePageModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => YourRidePageModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<String>(
        future: _model.getUserName(
            FirebaseAuth.instance.currentUser?.uid ?? ''),
        builder: (context, userNameSnapshot) {
          if (userNameSnapshot.connectionState ==
              ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!userNameSnapshot.hasData) {
            return Center(child: Text('User name not available'));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('trips')
                .where('status', isEqualTo: 'accepted')
                .where('userName', isEqualTo: userNameSnapshot.data)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text('empty'),
                );
              }

              return ListView(
                children: snapshot.data!.docs
                    .map((DocumentSnapshot document) {
                  Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;

                  return buildRideDetailsCard(
                      data, document.reference);
                }).toList(),
              );
            },
          );
        },
      ),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          title: Text('Your Rides'),
          backgroundColor: Color(0xFF19DB8A),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('HomePage');
            },
          ),
        ),
      ),
    );
  }

  Widget buildRideDetailsCard(
      Map<String, dynamic> data, DocumentReference documentReference) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.all(16),
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver: ${data['driverName']}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('From: ${data['from']}'),
                        Text('To: ${data['to']}'),
                        Text('Date: ${data['date']}'),
                        Text('Time: ${data['time']}'),
                        Text('Price: ${data['price']}'),
                        Text('Driver phone: ${data['phoneNumber']}'),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      // Handle deletion here
                      removeRideCard(documentReference);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> removeRideCard(DocumentReference documentReference) async {
    try {
      await documentReference.delete();
    } catch (e) {
      print('Error deleting ride card: $e');
    }
  }
}

class YourRidePageModel extends FlutterFlowModel<YourRidePage> {
  final unfocusNode = FocusNode();

  Future<String> getUserName(String uid) async {
    DocumentSnapshot snapshot =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (snapshot.exists) {
      return snapshot['name'] ?? '';
    } else {
      return ''; // Handle the case where the document doesn't exist
    }
  }

  void initState(BuildContext context) {}

  void dispose() {
    unfocusNode.dispose();
  }
}
