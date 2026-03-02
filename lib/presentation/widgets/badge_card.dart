import 'package:flutter/material.dart';
import 'package:kidpedia/data/models/badge_model.dart';

class BadgeCard extends StatelessWidget {
  final BadgeModel badge;

  const BadgeCard({
    super.key,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: badge.isUnlocked ? 4 : 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badge.isUnlocked
                        ? Colors.amber.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                  ),
                  child: ClipOval(
                    child: _buildBadgeImage(),
                  ),
                ),
                if (!badge.isUnlocked)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              badge.title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            if (!badge.isUnlocked)
              Column(
                children: [
                  Text(
                    '${badge.currentCount}/${badge.requiredCount}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            if (badge.isUnlocked && badge.unlockedAt != null)
              Text(
                'Unlocked!',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.amber[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeImage() {
    // Try to load the badge image, fallback to icon if not found
    if (badge.iconPath.isNotEmpty) {
      try {
        return Image.asset(
          'assets/${badge.iconPath}',
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              _getBadgeIcon(),
              size: 30,
              color: badge.isUnlocked ? Colors.amber : Colors.grey,
            );
          },
        );
      } catch (e) {
        return Icon(
          _getBadgeIcon(),
          size: 30,
          color: badge.isUnlocked ? Colors.amber : Colors.grey,
        );
      }
    }
    
    return Icon(
      _getBadgeIcon(),
      size: 30,
      color: badge.isUnlocked ? Colors.amber : Colors.grey,
    );
  }

  IconData _getBadgeIcon() {
    if (badge.category == 'reading') {
      return Icons.book;
    } else if (badge.category == 'gaming') {
      return Icons.videogame_asset;
    } else {
      return Icons.emoji_events;
    }
  }
}
