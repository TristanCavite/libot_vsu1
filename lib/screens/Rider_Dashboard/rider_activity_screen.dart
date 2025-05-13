import 'package:flutter/material.dart';

class RiderActivityScreen extends StatefulWidget {
  const RiderActivityScreen({super.key});

  @override
  State<RiderActivityScreen> createState() => _RiderActivityScreenState();
}

class _RiderActivityScreenState extends State<RiderActivityScreen> {
  final List<Map<String, dynamic>> _acceptedRequests = [
    {
      'name': 'Alex Carter',
      'requestType': 'Delivery',
      'pickup': 'Library',
      'destination': 'DLABS',
      'item': 'Book',
      'fare': 50.0,
      'avatar': 'assets/images/default_profile.png',
      'online': true,
      'status': 'Pending',
    },
    {
      'name': 'Mia Rodriguez',
      'requestType': 'Passenger',
      'pickup': 'Upper Utod',
      'destination': 'DCST',
      'fare': 30.0,
      'avatar': 'assets/images/default_profile.png',
      'online': false,
      'status': 'Pending',
    },
    {
      'name': 'Jordan Blake',
      'requestType': 'Delivery',
      'pickup': 'RDE',
      'destination': 'Market',
      'item': 'Household Essentials',
      'fare': 60.0,
      'avatar': 'assets/images/default_profile.png',
      'online': false,
      'status': 'Pending',
    },
    {
      'name': 'John Carter',
      'requestType': 'Passenger',
      'pickup': 'VSU Beach',
      'destination': 'Lower Utod',
      'fare': 50.0,
      'avatar': 'assets/images/default_profile.png',
      'online': true,
      'status': 'Pending',
    },
  ];

  final List<Map<String, dynamic>> _completedRequests = [];

  void _showRequestDetails(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text('Request Type: ${request['requestType']}'),
                  Text('Pickup: ${request['pickup']}'),
                  Text('Destination: ${request['destination']}'),
                  Text('Item: ${request['item']}'),
                  Text('Fare: \$${request['fare']}'),
                  Text(
                    'Status: Pending',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // Radius of the button
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () {
                      _completeRequest(request);
                    },
                    child: Text('Complete Request'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _completeRequest(Map<String, dynamic> request) {
    setState(() {
      request['status'] = 'Completed'; // <-- Update status
      _acceptedRequests.remove(request);
      _completedRequests.add(request);
    });
    Navigator.pop(context);
  }

  void _showCompletedRequestDetails(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text('Request Type: ${request['requestType']}'),
                  Text('Pickup: ${request['pickup']}'),
                  Text('Destination: ${request['destination']}'),
                  Text('Item: ${request['item']}'),
                  Text('Fare: \$${request['fare']}'),
                  Text(
                    'Status: Completed',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // Radius of the button
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () {
                      _deleteCompletedRequest(request);
                    },
                    child: Text('Delete Request'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteCompletedRequest(Map<String, dynamic> request) {
    setState(() {
      _completedRequests.remove(request);
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Accepted Requests'),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: ListView.builder(
                itemCount: _acceptedRequests.length,
                padding: const EdgeInsets.symmetric(horizontal: 0),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _showRequestDetails(_acceptedRequests[index]);
                    },
                    child: _buildRequestTile(_acceptedRequests[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionHeader('Completed Requests'),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: ListView.builder(
                itemCount: _completedRequests.length,
                padding: const EdgeInsets.symmetric(horizontal: 0),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _showCompletedRequestDetails(_completedRequests[index]);
                    },
                    child: _buildRequestTile(_completedRequests[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildRequestTile(Map<String, dynamic> request) {
    String subtitleText;

    if (request['requestType'] == 'Passenger') {
      subtitleText = '${request['pickup']} to ${request['destination']}';
    } else if (request['requestType'] == 'Delivery') {
      subtitleText =
          '${request['item']} - ${request['pickup']} to ${request['destination']}';
    } else {
      subtitleText = '${request['pickup']} to ${request['destination']}';
    }

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: const Color(0xFFF5F5F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: AssetImage(request['avatar']),
          radius: 24,
        ),
        title: Text(request['name']),
        subtitle: Text(subtitleText),
        trailing:
            request['online']
                ? const Icon(Icons.circle, color: Colors.green, size: 12)
                : null,
      ),
    );
  }
}
