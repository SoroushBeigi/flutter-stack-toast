
## Features

1. Configurable toast view.
2. Slide to dismiss
3. Auto dismissible
4. Can show custom widget as toast
5. Stacking toast view.

## Getting started

Add this line into pubspec.yaml

```dart
    flutter_stack_toast: ^0.0.1
```

```dart
// add the import statement
import 'package:flutter_stack_toast/flutter_stack_toast.dart';

```

## Usage

For showing toast you have three method in "StackToast" class:

showToast:
With this method you only send your text and it will show.

```dart
 StackToast.showToast(buildContext, "desired text");
 ```

showTextToast:
With this method you can customize your text widget with your property.

```dart
 StackToast.showTextToast(buildContext, Text("desired text" , TextStyle(color: Colors.black, fontSize: 15)));
 ```

showCustomToast:
With this method you can show any widget you want into toast widget.

```dart
 StackToast.showCustomToast(buildContext, Text("desired text" , TextStyle(color: Colors.black, fontSize: 15)));
 ```

You can dismiss all toast widget with clear method:

```dart
 StackToast.clear(buildContext);
 ```

And also you can change all default configs:

```dart
StackToastConfig()
  .setHorizontalMargin(10)
  .setVerticalMargin(10)
  .setSimpleItemHeight(40)
  .setDownsizePercent(5)
  .setBetweenItemSpace(10)
  .setMaxShowingItem(5)
  .setDismissDirection(TextDirection.ltr)
  .setBoxShadow(BoxShadow(
    color: Colors.black12,
    spreadRadius: 5,
    blurRadius: 7,
    offset: Offset(0, 1),
    ))
  .setBorderRadius(BorderRadius.all(Radius.circular(12.0)))
  .setBackgroundColor(Colors.white)
  .setAnimationDuration(Duration(milliseconds: 300))
  .setAutoDismissItemDuration(Duration(seconds: 3))
  .setAutoDismissEnable(true);
 ```


