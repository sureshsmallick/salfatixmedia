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

modulum('BrowserForwardSpecialAction', ['ActionApplicationService'],
  function(context, cls) {
    /**
     * @class BrowserForwardSpecialAction
     * @memberOf classes
     */
    cls.BrowserForwardSpecialAction = context.oo.Class(function() {
      return /** @lends classes.BrowserForwardSpecialAction.prototype */ {
        __name: "BrowserForwardSpecialAction",
        /** @type {classes.ActionApplicationService} */
        _actionService: null,
        _listener: null,
        constructor: function(actionService) {
          this._actionService = actionService;
          this._listener = this._onBrowserForward.bind(this);
          if (history.pushState) {
            history.replaceState("back", "");
            history.pushState("", "");
            history.pushState("forward", "");
            history.back();
          }
          window.addEventListener("popstate", this._listener);
        },

        destroy: function() {
          window.removeEventListener("popstate", this._listener);
          this._actionService = null;
        },
        _onBrowserForward: function(event) {
          if (this._actionService && this._actionService.hasAction("browser_forward")) {
            if (event.state && event.state === "forward") { //back or forward
              this._actionService.executeByName("browser_forward");
              history.back();
            }
          }
        }
      };
    });
    cls.ActionApplicationService.registerSpecialAction("browser_forward", cls.BrowserForwardSpecialAction);
  });
