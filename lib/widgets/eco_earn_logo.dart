import 'package:flutter/material.dart';

class EcoEarnLogo extends StatelessWidget {
  final double height;
  
  const EcoEarnLogo({
    super.key,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'EC',
            style: TextStyle(
              color: const Color(0xFF34A853),
              fontSize: height * 0.8,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: height * 0.8,
                height: height * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF34A853),
                    width: 2,
                  ),
                ),
              ),
              Transform.rotate(
                angle: -0.5, // Slightly rotate the arrows
                child: Icon(
                  Icons.sync,
                  color: const Color(0xFF34A853),
                  size: height * 0.6,
                ),
              ),
            ],
          ),
          Text(
            'EARN',
            style: TextStyle(
              color: const Color(0xFF34A853),
              fontSize: height * 0.8,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
} 