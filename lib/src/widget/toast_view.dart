import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class ToastView extends StatefulWidget {
  final Function() removeAllCallback;
  final Function()? firstCallAfterBuild;

  final double horizontalMargin;
  final double verticalMargin;

  final double downsizePercent;

  final double topItemSpace;

  final int maxShowingItem;

  final Alignment alignment = Alignment.bottomCenter;
  final TextDirection dismissDirection;

  final BoxShadow boxShadow;
  final BorderRadius borderRadius;

  final Color backgroundColor;

  final Duration animationDuration;
  final Duration showingItemDuration;

  ToastView(this.removeAllCallback,
      {this.firstCallAfterBuild,
      this.backgroundColor = Colors.white,
      this.borderRadius = const BorderRadius.all(Radius.circular(12.0)),
      this.animationDuration = const Duration(milliseconds: 300),
      this.showingItemDuration = const Duration(seconds: 3),
      this.boxShadow = const BoxShadow(
        color: Colors.black12,
        spreadRadius: 5,
        blurRadius: 7,
        offset: Offset(0, 1),
      ),
      this.horizontalMargin = 10,
      this.verticalMargin = 10,
      this.downsizePercent = 5,
      this.topItemSpace = 10,
      this.dismissDirection = TextDirection.ltr,
      this.maxShowingItem = 5,
      super.key});

  @override
  State<ToastView> createState() => ToastViewState();
}

class ToastViewState extends State<ToastView> with TickerProviderStateMixin {
  late final AnimationController _insertAnimationController = AnimationController(
    duration: widget.animationDuration,
    vsync: this,
  );

  late final AnimationController _deleteAnimationController = AnimationController(
    duration: widget.animationDuration,
    vsync: this,
  );

  late final AnimationController _dismissAllAnimationController = AnimationController(
    duration: widget.animationDuration,
    vsync: this,
  );

  late final AnimationController _dismissAnimationController = AnimationController(
    duration: widget.animationDuration,
    vsync: this,
  );

  final List<Widget> _widgetList = [];

  Timer? _dismissTimer;

  late double downsizePercent;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.firstCallAfterBuild != null && _widgetList.isEmpty) {
        widget.firstCallAfterBuild!.call();
      }
    });

    downsizePercent = widget.downsizePercent / 100;

    _insertAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _insertAnimationController.reset();
        });
      }
    });

    _deleteAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _deleteAnimationController.reset();
        });
      }
    });

    _dismissAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _dismissAnimationController.reset();
        removeLast();
      }
    });

    _dismissAllAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _dismissAllAnimationController.reset();
          _dismissTimer?.cancel();
          _widgetList.clear();
          widget.removeAllCallback.call();
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _insertAnimationController.dispose();
    _deleteAnimationController.dispose();
    _dismissAnimationController.dispose();
    _dismissAllAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var stack = Padding(
      padding: EdgeInsets.only(bottom: widget.horizontalMargin),
      child: Stack(
        alignment: widget.alignment,
        children: listItems(),
      ),
    );

    return stack;
  }

  List<Widget> listItems() {
    List<Widget> list = [];
    int startPosition = max(0, _widgetList.length - 1 - widget.maxShowingItem);
    for (int index = startPosition; index < _widgetList.length; index++) {
      var item = _widgetList[index];
      var itemIndex = _widgetList.length - 1 - index;
      list.add(_listItem(item, itemIndex));
    }
    return list;
  }

  Widget _listItem(Widget widget, int index) {
    var itemView = index == 0
        ? Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.horizontal,
            onDismissed: (DismissDirection direction) {
              removeLast();
            },
            onUpdate: (details) {
              _dismissTimer?.cancel();
            },
            child: widget,
          )
        : widget;

    var runningAnimation = getRunningAnimation();

    if (runningAnimation != null) {
      return _itemDuringAnimation(
          runningAnimation == _insertAnimationController, itemView, runningAnimation, index);
    } else {
      return Transform(
        alignment: FractionalOffset.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..translate(0.0, _animateY(true, _insertAnimationController, index), 0)
          ..scale(_itemScale(false, _insertAnimationController, index)),
        child: itemView,
      );
    }
  }

  AnimationController? getRunningAnimation() {
    if (_insertAnimationController.isAnimating) {
      return _insertAnimationController;
    } else if (_deleteAnimationController.isAnimating) {
      return _deleteAnimationController;
    } else if (_dismissAnimationController.isAnimating) {
      return _dismissAnimationController;
    } else if (_dismissAllAnimationController.isAnimating) {
      return _dismissAllAnimationController;
    } else {
      return null;
    }
  }

  Widget _itemDuringAnimation(
      bool insert, Widget child, AnimationController controller, int index) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (BuildContext context, Widget? child) {
        return Transform(
          alignment: FractionalOffset.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..translate(_animateX(controller, index), _animateY(insert, controller, index), 0)
            ..scale(_itemScale(insert, controller, index)),
          child: child,
        );
      },
    );
  }

  double _animateX(AnimationController controller, int index) {
    if (controller == _dismissAllAnimationController) {
      double startPos = 0.07 * index;
      if (controller.value < startPos) return 0.0;
      return -((controller.value - startPos) * MediaQuery.of(context).size.width) *
          (widget.dismissDirection == TextDirection.ltr ? 1.0 : -1.0);
    } else if (index == 0 && controller == _dismissAnimationController) {
      return -(controller.value * MediaQuery.of(context).size.width) *
          (widget.dismissDirection == TextDirection.ltr ? 1 : -1);
    } else {
      return 0;
    }
  }

  double _animateY(bool insert, AnimationController controller, int index) {
    if (controller == _dismissAllAnimationController || controller == _dismissAnimationController) {
      return _itemExit(1, index);
    } else {
      return insert ? _itemEnter(controller.value, index) : _itemExit(controller.value, index);
    }
  }

  double _itemEnter(double animation, int index) {
    if (index == 0) {
      double itemHeight = 40;
      double animationDistance = itemHeight + widget.verticalMargin;
      var result = _insertAnimationController.isAnimating
          ? itemHeight - (animationDistance * animation)
          : -widget.verticalMargin;
      return result;
    } else {
      double startPosition = -widget.verticalMargin -
          ((index - (_insertAnimationController.isAnimating ? 1 : 0)) * widget.topItemSpace);
      var result = startPosition - (animation * widget.topItemSpace);
      return result;
    }
  }

  double _itemExit(double animation, int index) {
    double startPosition = -widget.verticalMargin - ((index + 1) * widget.topItemSpace);
    var result = startPosition + (animation * widget.topItemSpace);
    return result;
  }

  double _itemScale(bool insert, AnimationController controller, int index) {
    if (controller == _dismissAnimationController) {
      return _itemScaleDown(0, index);
    } else {
      return insert
          ? _itemScaleDown(controller.isAnimating ? controller.value : 1, index)
          : _itemScaleUp(controller.isAnimating ? controller.value : 1, index);
    }
  }

  double _itemScaleDown(double animation, int index) {
    if (index == 0) {
      return 1;
    }
    return (1 - ((index - (_insertAnimationController.isAnimating ? 1 : 0)) * downsizePercent)) -
        (animation * downsizePercent);
  }

  double _itemScaleUp(double animation, int index) {
    return (1 - ((index + 1) * downsizePercent)) + (animation * downsizePercent);
  }

  Widget _getSimpleView(Text text) {
    return Container(
      width: MediaQuery.of(context).size.width - (widget.horizontalMargin * 2),
      decoration: BoxDecoration(
          boxShadow: [widget.boxShadow],
          color: widget.backgroundColor,
          borderRadius: widget.borderRadius),
      child: text,
    );
  }

  bool isEmpty() {
    return _widgetList.isEmpty;
  }

  void addWidget({Widget? view, Text? text}) {
    if (view == null && text == null) {
      return;
    }
    setState(() {
      _setTimer();
      _widgetList.add(view ?? _getSimpleView(text!));
      _insertAnimationController.reset();
      _insertAnimationController.forward();
    });
  }

  bool removeLast() {
    if (_widgetList.isNotEmpty) {
      setState(() {
        _setTimer();
        _widgetList.removeLast();
        _deleteAnimationController.reset();
        _deleteAnimationController.forward();
      });
    } else {
      widget.removeAllCallback.call();
    }
    return _widgetList.isNotEmpty;
  }

  void _setTimer() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer.periodic(widget.showingItemDuration, (timer) {
      setState(() {
        _dismissAnimationController.forward();
      });
    });
  }

  void clear() {
    setState(() {
      _dismissAllAnimationController.forward();
    });
  }
}
