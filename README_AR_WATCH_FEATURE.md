# AR Watch Try-On Feature

This feature allows users to virtually try on watches using AR technology. The implementation is similar to existing AR try-on features for sunglasses, ornaments and t-shirts in the app.

## Implementation Details

### Key Components

1. **AssetWatchesPainter**

   - Custom painter class that renders watch images on the user's wrist
   - Uses face detection to position watches based on face size and position
   - Implements position stabilization to reduce jitter
   - Supports both left and right wrist placement

2. **ARWatchesScreen**

   - Camera screen that handles face detection using Google ML Kit
   - Loads appropriate watch images based on product data
   - Provides UI controls to adjust watch size and position
   - Includes options to switch between left and right wrist
   - Supports image capture and saving to gallery

3. **Product Detail Integration**
   - Updated ProductDetailScreen to route to AR watch try-on for watch products
   - Detects watch products by category name or product title

## Watch Assets

Watch images are stored in `assets/effects/watches/` and include:

- Diesel Mega Chief.png
- Guess Letterm.png

## Features

- **Real-time Tracking**: The watch follows the user's wrist as they move
- **Adjustable Size**: Users can resize the watch to fit their wrist
- **Position Adjustment**: Watch distance from the face can be adjusted
- **Wrist Selection**: Users can switch between left and right wrist
- **Image Capture**: Users can take photos with the virtual watch and save to gallery
- **Stabilization**: Sophisticated position smoothing reduces jitter for a better experience

## Usage

When viewing a product in the "watches" category, users can tap "Try On" to launch the AR experience. The appropriate watch model will be automatically selected based on the product title.

## Future Improvements

- Add more watch models and styles
- Implement wrist detection for more accurate positioning
- Add watch animation (ticking second hand)
- Support for smart watch faces with customizable displays
