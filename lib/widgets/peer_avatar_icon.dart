import 'package:flutter/material.dart';

class PeerAvatarIcon extends StatelessWidget {
  final String peerName;
  final String displayName;
  final bool isSelected;
  
  const PeerAvatarIcon({
    super.key,
    required this.displayName,
    required this.peerName,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 65,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 58, // selected border ring
            height: 58,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.blue, width: 2.5)
                  : null,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 5),
            child: Container(
              width: 50,
              height: 50,
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.green.shade400, Colors.green.shade700],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade300,
                    spreadRadius: 0.5,
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Center(child: Text(peerName)),
            ),
          ),
          SizedBox(height: 2),
          SizedBox(
            width: 55,
            child: Text(
              displayName,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
