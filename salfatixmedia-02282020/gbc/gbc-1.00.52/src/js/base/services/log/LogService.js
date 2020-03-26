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

modulum('LogService', ['InitService', 'ConsoleLogProvider', 'StoredSettingsService'],
  function(context, cls) {

    /**
     * @class gbc.LogService
     */
    context.LogService = context.oo.StaticClass( /** @lends gbc.LogService */ {
      __name: "LogService",
      /**
       * @type {string}
       */
      _currentLevel: "none",
      /**
       * @type {string[]}
       */
      levels: ["all", "debug", "log", "info", "warn", "error"],
      /**
       * @type {Object<string, classes.LogProviderBase>}
       */
      _providers: {
        _default: new cls.ConsoleLogProvider()
      },
      /**
       * @type {Array<string>}
       */
      _activeLoggers: null,
      /**
       * @type {Object<string, string>}
       */
      _labels: {},
      /**
       * initialize service
       */
      init: function() {
        this._currentLevel = context.StoredSettingsService.getLoglevel();
        this._activeLoggers = context.StoredSettingsService.getLogtypes();
        this.changeLevel(this._currentLevel, true);
      },
      /**
       *
       * @param {string} level
       * @return {number}
       * @private
       */
      _intLevel: function(level) {
        return this.levels.indexOf(level);
      },
      /**
       *
       * @return {string}
       */
      getCurrentLevel: function() {
        return this._currentLevel;
      },
      /**
       *
       * @param {string} newLevel
       * @param {boolean} force
       */
      changeLevel: function(newLevel, force) {
        var intlevel = this._intLevel(this._currentLevel);
        var intnewlevel = this._intLevel(newLevel);
        if (force || (intnewlevel !== intlevel)) {
          this._currentLevel = newLevel;
          var p = Object.keys(this._providers);
          for (var i = 0; i < p.length; i++) {
            this._prepareLogger(p[i], this._isActive(p[i] || "_default") ? intnewlevel : -1);
          }
        }
      },

      /**
       *
       * @param {classes.LogProviderBase} provider
       * @param {string|Array<string>} type
       * @param {string} [label]
       */
      registerLogProvider: function(provider, type, label) {
        var types = (Array.isArray(type) ? type : [type]);
        for (var i = 0; i < types.length; i++) {
          if (label) {
            this._labels[types[i] || "_default"] = label;
          }
          this._providers[types[i] || "_default"] = provider;
          this._prepareLogger(types[i] || "_default", this._isActive(types[i] || "_default") ? this._intLevel(this._currentLevel) :
            -1);
        }
      },
      /**
       *
       * @param {string} type
       * @param {number} intnewlevel
       * @private
       */
      _prepareLogger: function(type, intnewlevel) {
        var target = this;
        if (type !== "_default") {
          this[type] = {};
          target = this[type];
        }
        for (var i = 1; i < this.levels.length; i++) {
          var levelName = this.levels[i];
          if (intnewlevel < 0 || intnewlevel > i) {
            target[levelName] = Function.noop;
          } else {
            target[levelName] = this._getLogMethod(type, levelName);
          }
        }
      },
      /**
       *
       * @param {string} type
       * @return {boolean}
       * @private
       */
      _isActive: function(type) {
        return !this._activeLoggers || this._activeLoggers.indexOf(type) >= 0;
      },
      /**
       *
       * @param {string} logType
       * @param {string} level
       * @return {Function}
       * @private
       */
      _getLogMethod: function(logType, level) {
        var provider = this._providers[logType] || this._providers._default;
        return function() {
          provider.getLogger()[level].apply(provider.getLogger(), arguments);
        };
      },
      debug: function() {
        console.debug.apply(console, arguments);
      },
      log: function() {
        console.log.apply(console, arguments);
      },
      info: function() {
        console.info.apply(console, arguments);
      },
      warn: function() {
        console.warn.apply(console, arguments);
      },
      error: function() {
        console.error.apply(console, arguments);
      },

      /**
       *
       * @return {Array<{name:string, label:string}>}
       */
      getTypes: function() {
        return Object.keys(this._providers).map(function(k) {
          return {
            name: k,
            label: this._labels[k] || k
          };
        }.bind(this));
      },

      /**
       *
       * @return {Array<string>}
       */
      getActiveLogTypes: function() {
        return this._activeLoggers;
      },

      /**
       *
       * @param {string} type
       */
      toggleType: function(type) {
        if (!this._activeLoggers) {
          this._activeLoggers = Object.keys(this._providers);
        }
        if (this._activeLoggers.indexOf(type) >= 0) {
          this._activeLoggers.remove(type);
        } else {
          this._activeLoggers.push(type);
        }
        this._prepareLogger(type || "_default", this._isActive(type || "_default") ? this._intLevel(this._currentLevel) : -1);
      }
    });
    context.InitService.register(context.LogService);
  });
