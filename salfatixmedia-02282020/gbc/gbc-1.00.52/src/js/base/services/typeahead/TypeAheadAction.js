/// FOURJS_START_COPYRIGHT(D,2018)
/// Property of Four Js*
/// (c) Copyright Four Js 2018, 2019. All Rights Reserved.
/// * Trademark of Four Js Development Tools Europe Ltd
///   in the United States and elsewhere
/// 
/// This file can be modified by licensees according to the
/// product manual.
/// FOURJS_END_COPYRIGHT

"use strict";

modulum('TypeAheadAction', ['TypeAheadCommand'],
  /**
   * @param {gbc} context
   * @param {classes} cls
   */
  function(context, cls) {
    /**
     * TypeAhead action event.
     * @class TypeAheadAction
     * @memberOf classes
     * @extends classes.TypeAheadCommand
     */
    cls.TypeAheadAction = context.oo.Class(cls.TypeAheadCommand, function($super) {
      return /** @lends classes.TypeAheadAction.prototype */ {
        __name: "TypeAheadAction",

        /** @type boolean */
        _noUserActivity: false,

        /** @type boolean */
        _dialogTouched: false,

        /**
         * @param {classes.VMApplication} app owner
         * @param {classes.NodeBase} node action
         * @param {boolean} [noUserActivity] - true if action is not from a user interaction
         */
        constructor: function(app, node, noUserActivity) {
          $super.constructor.call(this, app, node);
          this._noUserActivity = !!noUserActivity;
          this._dialogTouched = (node.attribute('name') === 'dialogtouched');
        },

        /**
         * @inheritDoc
         */
        canBeExecuted: function() {
          var sendActionEvent = false;

          switch (this._node.getTag()) {
            case "StartMenuCommand":
              sendActionEvent = (this._node.attribute('disabled') !== 1);
              break;
            case "IdleAction":
              sendActionEvent = true;
              break;
            default:
              var parentNode = this._node.getParentNode();
              if (parentNode.getTag() === "TableColumn") {
                parentNode = parentNode.getParentNode(); // we want the table node
              }
              // Check if action is active
              var hasActionActiveAttr = this._node.isAttributeSetByVM('actionActive');
              var hasActiveAttr = this._node.isAttributeSetByVM('active');
              var hasParentActiveAttr = parentNode && parentNode.isAttributeSetByVM('active');

              var active = false;
              if (hasActionActiveAttr) {
                active = this._node.attribute('actionActive');
              } else if (hasActiveAttr) {
                active = this._node.attribute('active');
              }

              if (hasParentActiveAttr && parentNode.attribute('active')) {
                active = active && parentNode.attribute('active');
              }

              sendActionEvent = active;
          }

          return sendActionEvent;
        },

        /**
         * @inheritDoc
         */
        execute: function() {

          if (this.canBeExecuted()) {
            var event = new cls.VMActionEvent(this._node.getId());
            event.noUserActivity = this._noUserActivity;
            return {
              processed: true,
              vmEvents: [event]
            };
          }

          return {
            processed: false,
            vmEvents: []
          };
        },

        /**
         * @inheritDoc
         */
        isPredictable: function() {
          // when action is dialog touched consider that we stay in the same edit
          // we say that action is predictable to not activate bufferedKey mode in typeahead
          return this._dialogTouched;
        },

        /**
         * @inheritDoc
         */
        needsVmSync: function() {
          return true;
        }
      };
    });
  }
);
