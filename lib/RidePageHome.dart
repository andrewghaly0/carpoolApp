import 'package:carpool_project/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carpool_project/CardPage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RidePageHome extends StatefulWidget {
  const RidePageHome({Key? key}) : super(key: key);

  @override
  _RidePageHomeState createState() => _RidePageHomeState();
}

class _RidePageHomeState extends State<RidePageHome> with TickerProviderStateMixin {
  late RidePageHomeModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel();
    _model.initState(context);
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book your ride'),
        backgroundColor: Color(0xFF19DB8A),
        actions: [
          Switch(
            value: _model.isTimeConstraintActive,
            onChanged: (value) {
              setState(() {
                _model.isTimeConstraintActive = value;
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('trips')
            .where('time', isEqualTo: '5:30 PM').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No rides available at the moment'),
            );
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;

              return buildRideCard(data);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget buildRideCard(Map<String, dynamic> data) {
    // Extract the date from the document
    String tripDate = data['date'];

    // Check if the current time is within the allowed range for booking
    bool isBookingAllowed = _model.isBookingAllowed(data['date']);

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
                      ],
                    ),
                  ),
                  Image.network(
                    'https://platform.cstatic-images.com/large/in/v2/stock_photos/af7f32d6-41d2-4a67-bd6e-49e188d0a7fb/3de60623-b1df-44e7-9da6-53129a69039c.png',
                    width: 150,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: isBookingAllowed
                        ? () async {
                      await updateTripAndUser(data);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => HomePage()),
                      );
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blue,
                      onPrimary: Colors.white,
                    ),
                    child: Text('Cash'),
                  ),
                  ElevatedButton(
                    onPressed: isBookingAllowed
                        ? () async {
                      await updateTripAndUser(data);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => CardPage()),
                      );
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blue,
                      onPrimary: Colors.white,
                    ),
                    child: Text('Card'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> updateTripAndUser(Map<String, dynamic> data) async {
    try {
      // Get the currently logged-in user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Get user information from the "users" collection
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userSnapshot.exists) {
          // Extract user information
          String userName = userSnapshot['name'];
          String userPhone = userSnapshot['phone'];

          // Update the "trips" collection
          QuerySnapshot tripsSnapshot = await FirebaseFirestore.instance
              .collection('trips')
              .where('driverName', isEqualTo: data['driverName'])
              .where('time', isEqualTo: data['time'])
              .where('date', isEqualTo: data['date'])
              .where('price', isEqualTo: data['price'])
              .get();

          if (tripsSnapshot.docs.isNotEmpty) {
            // Assuming there's only one document with the given driverName and date
            DocumentReference tripReference = tripsSnapshot.docs[0].reference;

            await tripReference.update({
              'status': 'pending',
              'userName': userName,
              'userPhone': userPhone,
            });
          }
        }
      }
    } catch (e) {
      print('Error updating trip and user: $e');
    }
  }
}

class RidePageHomeModel extends ChangeNotifier {
  bool _isTimeConstraintActive = true;

  bool get isTimeConstraintActive => _isTimeConstraintActive;

  set isTimeConstraintActive(bool value) {
    _isTimeConstraintActive = value;
    notifyListeners();
  }

  bool isBookingAllowed(String tripDate) {
    try {
      if (!_isTimeConstraintActive) {
        return true;
      }

      DateTime now = DateTime.now();
      TimeOfDay startTime = TimeOfDay(hour: 17, minute: 30);
      TimeOfDay endTime = TimeOfDay(hour: 13, minute: 0);
      DateTime allowedStartTime = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);
      DateTime allowedEndTime = DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);

      DateTime parsedTripDate;
      try {
        List<String> dateParts = tripDate.split('-');
        int day = int.parse(dateParts[0]);
        int month = int.parse(dateParts[1]);
        int year = int.parse(dateParts[2]);
        parsedTripDate = DateTime(year, month, day);
      } catch (_) {
        List<String> dateParts = tripDate.split('/');
        int day = int.parse(dateParts[0]);
        int month = int.parse(dateParts[1]);
        int year = int.parse(dateParts[2]);
        parsedTripDate = DateTime(year, month, day);
      }

      bool isNotToday = parsedTripDate.day != now.day || parsedTripDate.month != now.month || parsedTripDate.year != now.year;

      return isNotToday || (now.isAfter(allowedStartTime) && now.isBefore(allowedEndTime));
    } catch (e) {
      print('Error parsing date: $e');
      return false;
    }
  }

  void initState(BuildContext context) {}

  void dispose() {}
}

RidePageHomeModel createModel() => RidePageHomeModel();
