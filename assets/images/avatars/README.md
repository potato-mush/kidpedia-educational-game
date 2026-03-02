# Avatar Images

## Required Avatar Files (PNG format with transparency)

Place your avatar image files here with the exact filenames:

### Animal Avatars:
1. **avatar_cat.png** - Cute cat illustration
2. **avatar_dog.png** - Cute dog illustration
3. **avatar_bear.png** - Cute bear illustration
4. **avatar_fox.png** - Cute fox illustration
5. **avatar_rabbit.png** - Cute rabbit illustration
6. **avatar_panda.png** - Cute panda illustration
7. **avatar_lion.png** - Cute lion illustration
8. **avatar_tiger.png** - Cute tiger illustration
9. **avatar_elephant.png** - Cute elephant illustration
10. **avatar_giraffe.png** - Cute giraffe illustration

### Default Avatar:
- **avatar_default.png** - Generic user avatar

## Image Specifications:
- **Format**: PNG with transparency (alpha channel)
- **Size**: 512x512 pixels (square)
- **Style**: Cute, kid-friendly, cartoon or flat design
- **File Size**: < 200KB per image
- **Background**: Transparent

## Current State:
Currently using placeholder icons. Replace with actual images when ready.

## Where to Find/Create Avatars:
- **Flaticon** (https://flaticon.com/) - Free and premium icons
- **Freepik** (https://freepik.com/) - Illustrations
- **Canva** (https://canva.com/) - Create custom avatars
- **Custom commission** - Hire an artist for unique designs

## Implementation:
Once you add the images, update the `_getAvatarWidget` method in:
- `lib/presentation/screens/profile_screen.dart`
- `lib/presentation/screens/leaderboard_screen.dart`

Replace the Icon widgets with:
```dart
Image.asset(
  'assets/images/avatars/$avatarId.png',
  width: size,
  height: size,
  errorBuilder: (context, error, stackTrace) {
    return Icon(Icons.person, size: size * 0.6);
  },
)
```
