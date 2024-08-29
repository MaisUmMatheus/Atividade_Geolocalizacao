import 'package:appgeolocalizacao/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng? _currentPosition;
  LatLng? _tappedPosition; // Armazena a posição onde o usuário tocou
  double?
      _distance; // Armazena a distância entre a posição atual e o ponto tocado
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await _locationService.getCurrentLocation();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('Erro ao obter a localização: $e');
    }
  }

  void _refreshLocation() {
    setState(() {
      _currentPosition = null;
      _tappedPosition = null;
      _distance = null;
    });
    _getCurrentLocation();
  }

  void _onMapTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _tappedPosition = latlng;
      _calculateDistance();
    });
  }

  // Método para calcular a distância entre a posição atual e o ponto clicado
  void _calculateDistance() {
    if (_currentPosition != null && _tappedPosition != null) {
      final distanceInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _tappedPosition!.latitude,
        _tappedPosition!.longitude,
      );

      setState(() {
        _distance = distanceInMeters;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _refreshLocation,
            ),
            Text('Minha Localização no Mapa'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _currentPosition == null
                ? Center(child: CircularProgressIndicator())
                : FlutterMap(
                    options: MapOptions(
                      center: _currentPosition,
                      zoom: 15,
                      onTap: _onMapTap, // Detecta toques no mapa
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: ['a', 'b', 'c'],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentPosition!,
                            width: 80,
                            height: 80,
                            builder: (ctx) => Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                      if (_tappedPosition != null)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [_currentPosition!, _tappedPosition!],
                              color: Colors.red,
                              strokeWidth: 4.0,
                            ),
                          ],
                        ),
                    ],
                  ),
          ),
          if (_currentPosition != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    'Latitude: ${_currentPosition!.latitude}, Longitude: ${_currentPosition!.longitude}',
                    style: TextStyle(fontSize: 16),
                  ),
                  if (_distance != null)
                    Text(
                      'Distância até o ponto tocado: ${_distance! < 1000 ? '${_distance!.toStringAsFixed(2)} metros' : '${(_distance! / 1000).toStringAsFixed(2)} quilômetros'}',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
