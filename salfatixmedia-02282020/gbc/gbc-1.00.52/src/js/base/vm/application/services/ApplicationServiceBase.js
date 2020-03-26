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

modulum('ApplicationServiceBase', ['EventListener'],
  function(context, cls) {
    /**
     * Base class of application scoped services
     * @class ApplicationServiceBase
     * @memberOf classes
     * @extends classes.EventListener
     */
    cls.ApplicationServiceBase = context.oo.Class(cls.EventListener, function($super) {
      return /** @lends classes.ApplicationServiceBase.prototype */ {
        __name: "ApplicationServiceBase",
        /**
         * owner
         * @protected
         * @type classes.VMApplication
         */
        _application: null,
        /**
         *
         * @param {classes.VMApplication} app owner
         */
        constructor: function(app) {
          $super.constructor.call(this);
          this._application = app;
        },
        /**
         * frees memory hooks of this service (typically when application is destroyed)
         */
        destroy: function() {
          this._application = null;
          $super.destroy.call(this);
        },
        /**
         * Get owning application
         * @publicdoc
         * @return {classes.VMApplication} the owning application
         */
        getApplication: function() {
          return this._application;
        }
      };
    });
  });
