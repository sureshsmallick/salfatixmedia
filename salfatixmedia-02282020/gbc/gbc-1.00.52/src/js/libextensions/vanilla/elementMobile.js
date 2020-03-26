/// FOURJS_START_COPYRIGHT(D,2015)
/// Property of Four Js*
/// (c) Copyright Four Js 2015, 2019. All Rights Reserved.
/// * Trademark of Four Js Development Tools Europe Ltd
///   in the United States and elsewhere
/// 
/// This file can be modified by licensees according to the
/// product manual.
/// FOURJS_END_COPYRIGHT

"use strict";
(function() {

  /**
   * Handle double tap events
   * @param {string} context gives a namespace to the event
   * @param {Function=} callback
   */
  Element.prototype.onDoubleTap = function(context, callback) {
    if (window.isTouchDevice()) {
      var lastTap = 0;
      this.on('touchstart.doubleTap_' + context, function(eventstart) {
        this.off('touchend.doubleTap_' + context);
        if (eventstart.touches.length <= 1) {
          this.on('touchend.doubleTap_' + context, function(event) {
            var currentTime = new Date().getTime();
            var tapLength = currentTime - lastTap;
            if (tapLength < 500 && tapLength > 0) {
              // Double Tapped
              callback(event);
              event.preventCancelableDefault();
            }
            lastTap = currentTime;
          });
        }
      });
    }
    return this;
  };

  /**
   * Unregister doubleTap event
   * @param {string} context : namespace of the event to unregister
   */
  Element.prototype.offDoubleTap = function(context) {
    if (window.isTouchDevice()) {
      this.off("touchend.doubleTap_" + context);
    }
  };

  /**
   * Handle swipe events
   * @param {string} context gives a namespace to the event
   * @param {Function=} callback with swiped direction and distance as arguments
   * @param {Object} options
   *    direction : gives a direction to listen to: [left, right, up, down, all]
   *    debounce : true/false to limit the touchmove call
   *    swipeEnd : true/false to call callback once touch end. default is true.
   *    velocity : minimum velocity (px/ms) that gesture has to obtain to execute callback. default is 0.2
   */
  Element.prototype.onSwipe = function(context, callback, options) {
    options = (typeof options === "object") ? options : {};
    if (options.swipeEnd !== false) {
      options.swipeEnd = true;
    }

    var direction = options.direction ? options.direction : "all";

    var watchDirection = {
      left: direction === "left" || direction === "all",
      right: direction === "right" || direction === "all",
      up: direction === "up" || direction === "all",
      down: direction === "down" || direction === "all"
    };

    var _touchStartX = null;
    var _touchStartY = null;
    var _touchStartTime = null;

    var _applyCallback = function(evt) {
      if (!_touchStartX || !_touchStartY || !evt) {
        return;
      }
      var xUp = evt.changedTouches ? evt.changedTouches[0].clientX : evt.clientX;
      var yUp = evt.changedTouches ? evt.changedTouches[0].clientY : evt.clientY;
      var xDiff = _touchStartX - xUp;
      var yDiff = _touchStartY - yUp;

      // Get most significant direction
      var absXMove = Math.abs(xDiff);
      var absYMove = Math.abs(yDiff);
      var swiped = false;

      var maxMove = Math.max(absXMove, absYMove);
      var duration = new Date().getTime() - _touchStartTime;
      var velocity = options.velocity ? options.velocity : 0.2;

      if (maxMove / duration >= velocity) { // only swipe if minimum velocity of gesture (distance/duration of swipe)
        if (absXMove > absYMove) {
          if (xDiff > 0) {
            /* left swipe */
            if (watchDirection.left) {
              swiped = callback("left", xDiff);
            }
          } else {
            if (watchDirection.right) {
              swiped = callback("right", xDiff);
            }
          }
        } else {
          if (yDiff > 0) {
            if (watchDirection.up) {
              swiped = callback("up", yDiff);
            }
          } else {
            if (watchDirection.down) {
              swiped = callback("down", yDiff);
            }
          }
        }
      }
      if (swiped) { // if we swiped a container, stop propagation
        evt.stopPropagation();
      }
      /* reset values */
      _touchStartX = null;
      _touchStartY = null;
      _touchStartTime = null;
    };

    var _onTouchStart = function(evt) {
      _touchStartX = evt.changedTouches ? evt.changedTouches[0].clientX : evt.clientX;
      _touchStartY = evt.changedTouches ? evt.changedTouches[0].clientY : evt.clientY;
      _touchStartTime = new Date().getTime();
    };

    this.offSwipe(context, direction);
    if (options.debounce) {
      var onSwipeStartDebouncedHandler = _onTouchStart.debounce().bind(this);
      var onSwipeEndDebouncedHandler = _applyCallback.debounce().bind(this);

      this.on('mousedown.swipe_' + direction + '_' + context, onSwipeStartDebouncedHandler);
      this.on('touchstart.swipe_' + direction + '_' + context, onSwipeStartDebouncedHandler);
      if (options.swipeEnd) {
        this.on('mouseup.swipe_' + direction + '_' + context, onSwipeEndDebouncedHandler);
        this.on('touchend.swipe_' + direction + '_' + context, onSwipeEndDebouncedHandler);
      } else {
        this.on('mousemove.swipe_' + direction + '_' + context, onSwipeEndDebouncedHandler);
        this.on('touchmove.swipe_' + direction + '_' + context, onSwipeEndDebouncedHandler);
      }
    } else {
      var onSwipeStartHandler = _onTouchStart.bind(this);
      var onSwipeEndHandler = _applyCallback.bind(this);

      this.on('mousedown.swipe_' + direction + '_' + context, onSwipeStartHandler);
      this.on('touchstart.swipe_' + direction + '_' + context, onSwipeStartHandler);
      if (options.swipeEnd) {
        this.on('mouseup.swipe_' + direction + '_' + context, onSwipeEndHandler);
        this.on('touchend.swipe_' + direction + '_' + context, onSwipeEndHandler);
      } else {
        this.on('mousemove.swipe_' + direction + '_' + context, onSwipeEndHandler);
        this.on('touchmove.swipe_' + direction + '_' + context, onSwipeEndHandler);
      }
    }
  };

  /**
   * Unregister swipe event
   * @param {string} context : namespace of the event to unregister
   * @param {string} direction : remove swipe direction
   */
  Element.prototype.offSwipe = function(context, direction) {
    if (window.isTouchDevice()) {
      direction = direction ? direction : "all";
      this.off('mousedown.swipe_' + direction + '_' + context);
      this.off('mousemove.swipe_' + direction + '_' + context);
      this.off('mouseup.swipe_' + direction + '_' + context);
      this.off('touchstart.swipe_' + direction + '_' + context);
      this.off('touchend.swipe_' + direction + '_' + context);
      this.off('touchmove.swipe_' + direction + '_' + context);
    }
  };

  /**
   * Handle long touch events
   * @param {string} context gives a namespace to the event
   * @param {Function=} callback
   * @param {Object} options
   *    touchDuration : define the duration before triggering the callback
   */
  Element.prototype.onLongTouch = function(context, callback, options) {
    if (window.isTouchDevice()) {
      var touchDuration = (options && options.touchDuration) || 500;
      var preventDefault = (options && options.preventDefault) || true; // TODO Wrong it is always true
      var timer = null;

      this.on('touchstart.longTouch_' + context, function(event) {
        if (preventDefault) {
          event.preventCancelableDefault();
        }
        timer = setTimeout(function() {
          callback(event);
        }.bind(this), touchDuration);
      });

      this.on('touchend.longTouch_' + context, function() {
        if (timer) {
          clearTimeout(timer);
        }
      });
    }
    return this;
  };

  /**
   * Unregister longTouch event
   * @param {string} context : namespace of the event to unregister
   */
  Element.prototype.offLongTouch = function(context) {
    if (window.isTouchDevice()) {
      this.off("touchstart.longTouch_" + context);
      this.off("touchend.longTouch_" + context);
    }
  };

})();
