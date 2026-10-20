import 'package:flutter/material.dart';

class ChultMapWidget extends StatelessWidget {
  final List<dynamic> locations;
  final dynamic selectedLocation;
  final Function(dynamic) onSelectLocation;

  const ChultMapWidget({
    super.key,
    required this.locations,
    required this.selectedLocation,
    required this.onSelectLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      child: InteractiveViewer(
        maxScale: 5.0,
        minScale: 0.8,
        boundaryMargin: const EdgeInsets.all(300),
        child: Center(
          child: Stack(
            children: [
              Image.asset(
                'assets/images/chult_map.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 1000,
                    height: 800,
                    color: Colors.grey.shade900,
                    child: const Center(
                      child: Text(
                        'Покладіть карту у assets/images/chult_map.png',
                        style: TextStyle(color: Colors.white54, fontSize: 18),
                      ),
                    ),
                  );
                },
              ),
              ...locations.map((loc) {
                final double posX = (loc['x'] ?? 0.5) * 1000;
                final double posY = (loc['y'] ?? 0.5) * 800;
                final isSelected =
                    selectedLocation != null &&
                    selectedLocation['id'] == loc['id'];

                return Positioned(
                  left: posX,
                  top: posY,
                  child: GestureDetector(
                    onTap: () => onSelectLocation(loc),
                    child: Tooltip(
                      message: loc['name'],
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.amber : Colors.redAccent,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isSelected ? Colors.amber : Colors.redAccent)
                                      .withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.location_on,
                          size: isSelected ? 22 : 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
