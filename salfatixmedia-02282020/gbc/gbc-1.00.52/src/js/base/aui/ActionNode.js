/// FOURJS_START_COPYRIGHT(D,2014)
/// Property of Four Js*
/// (c) Copyright Four Js 2014, 2019. All Rights Reserved.
/// * Trademark of Four Js Development Tools Europe Ltd
///   in the United States and elsewhere
/// 
/// This file can be modified by licensees according to the
/// product manual.
/// FOURJS_END_COPYRIGHT

"use strict";

modulum('ActionNode', ['StandardNode', 'NodeFactory'],
  function(context, cls) {
    /**
     * @class ActionNode
     * @memberOf classes
     * @extends classes.StandardNode
     */
    cls.ActionNode = context.oo.Class(cls.StandardNode, function($super) {
      return /** @lends classes.ActionNode.prototype */ {

        $static: /** @lends classes.ActionNode */ {
          /**
           * Return true if actionName correspond to a field navigation action
           * @returns {boolean}
           */
          isFieldNavigationAction: function(actionName) {

            return (['nextfield', 'prevfield'].indexOf(actionName) > -1);
          },

          /**
           * Return true if actionName correspond to a table/matrix navigation action
           * @returns {boolean}
           */
          isTableNavigationAction: function(actionName) {

            return (['nextrow', 'prevrow',
              'firstrow', 'lastrow',
              'nextpage', 'prevpage'
            ].indexOf(actionName) > -1);
          }
        },

        constructor: function(parent, tag, id, attributes, app) {
          $super.constructor.call(this, parent, tag, id, attributes, app);
        },

        /**
         * Send action event to VM.
         */
        execute: function() {
          var actionService = this.getApplication().getActionApplicationService();
          actionService.execute(this._id);
        }
      };
    });
    cls.NodeFactory.register("Action", cls.ActionNode);
  });
