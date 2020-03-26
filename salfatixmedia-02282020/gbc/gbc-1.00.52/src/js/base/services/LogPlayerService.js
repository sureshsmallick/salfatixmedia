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

modulum('LogPlayerService',
  function(context, cls) {

    /**
     * Log Player Service to centralize log playing logic used in LogPlayerWidget and in UR Log Player
     * @namespace gbc.LogPlayerService
     * @gbcService
     */
    context.LogPlayerService = context.oo.StaticClass( /** @lends gbc.LogPlayerService */ {
      __name: "LogPlayerService",

      /**
       * @type {Map<number, Map<number, classes.VMApplication>>}
       */
      _fakeSessions: null,

      /**
       * Get the mock application registered with a session id and an application id
       * @param {number} sessionId
       * @param {number} appId
       * @returns {classes.VMApplication}
       */
      getApplication: function(sessionId, appId) {
        if (!this._fakeSessions) {
          this._fakeSessions = new Map();
        }
        if (!this._fakeSessions.has(sessionId)) {
          this._fakeSessions.set(sessionId, new Map());
        }
        var fakeSession = this._fakeSessions.get(sessionId);
        if (!fakeSession.has(appId)) {
          var app = window.gbc.MockService.fakeApplication();
          app.setRunning(true);
          app.info().webComponent = window.location.origin +
            window.location.pathname.replace(/\/[^\/]+$/, "/") +
            context.ThemeService.getResource("webcomponents");
          fakeSession.set(appId, app);
        }
        return fakeSession.get(appId);
      },

      /**
       * Unregister a mock application
       * @param sessionId
       * @param appId
       */
      removeApplication: function(sessionId, appId) {
        if (!this._fakeSessions) {
          this._fakeSessions = new Map();
        }
        var session = this._fakeSessions.get(sessionId);
        if (session) {
          session.delete(appId);
          if (!session.size) {
            this._fakeSessions.delete(sessionId);
          }
        }
      },

      /**
       * Replace resource reference with mock ones
       * @param {string} order
       * @returns {string}
       */
      mockOrderResources: function(order) {
        var imgMock = context.ThemeService.getResource("img/logo.png"),
          ttfMock = context.ThemeService.getResource("fonts/materialdesignicons-webfont.ttf");
        return order.replace(/componentType "[^"]+"/g, "componentType \"empty\"")
          .replace(/"[^"]+\.png(\?[^"]+)?"/g, "\"" + imgMock + "\"")
          .replace(/"[^"]+\.jpg(\?[^"]+)?"/g, "\"" + imgMock + "\"")
          .replace(/"[^"]+\.gif(\?[^"]+)?"/g, "\"" + imgMock + "\"")
          .replace(/"[^"]+\.ttf\?[^"]+"/g, "\"" + ttfMock + "\"");
      }
    });
  });
