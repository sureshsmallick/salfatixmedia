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

module.exports = function(grunt) {
  const
    _ = require("lodash"),
    path = require("path");
  if (grunt.__gbc.config.compileMode === "prod") {
    let files = {
      "jsface.js": "node_modules/jsface/dist/jsface.min.js",
      "base64.js": "node_modules/js-base64/base64.min.js",
      "moment.js": "node_modules/moment/min/moment-with-locales.min.js",
      "pikaday.js": "node_modules/pikaday-time/pikaday.js",
      "state-machine.js": "node_modules/javascript-state-machine/state-machine.min.js",
      "i18next.js": "node_modules/i18next/i18next.min.js",
      "i18next-browser-languagedetector.js": "node_modules/i18next-browser-languagedetector/i18nextBrowserLanguageDetector.min.js",
      "stackframe.js": "node_modules/stackframe/dist/stackframe.min.js",
      "stacktrace.js": "node_modules/stacktrace-js/dist/stacktrace-with-promises-and-json-polyfills.min.js"
    };
    _.merge(files, grunt.__gbc.configFile.compile.libraries || {});
    grunt.config.merge({
      concat: {
        clientlibs: {
          files: [{
              src: Object.keys(files).map(key => files[key]),
              dest: path.join(grunt.__gbc.pathes.distWeb, "js/third-party/libraries.js")
            },
            {
              src: "port/license/thirdparty-english.txt",
              dest: path.join(grunt.__gbc.pathes.distWeb, "license/"),
              expand: true,
              flatten: true
            }
          ]
        }
      }
    });
    grunt.loadNpmTasks("grunt-contrib-concat");

    grunt.registerTask("__libraries", "Copy client libraries to the dist folder.", ["concat:clientlibs"]);

    grunt.__gbc.pathes.libraries = [path.join(grunt.__gbc.pathes.distWeb, "js/third-party/libraries.js")];
  } else {
    let files = {
      "jsface.js": "node_modules/jsface/dist/jsface.js",
      "base64.js": "node_modules/js-base64/base64.js",
      "moment.js": "node_modules/moment/min/moment-with-locales.js",
      "pikaday.js": "node_modules/pikaday-time/pikaday.js",
      "state-machine.js": "node_modules/javascript-state-machine/state-machine.js",
      "i18next.js": "node_modules/i18next/i18next.js",
      "i18next-browser-languagedetector.js": "node_modules/i18next-browser-languagedetector/i18nextBrowserLanguageDetector.js",
      "stackframe.js": "node_modules/stackframe/dist/stackframe.js",
      "stacktrace.js": "node_modules/stacktrace-js/dist/stacktrace-with-promises-and-json-polyfills.min.js"
    };
    _.merge(files, grunt.__gbc.configFile.compile.libraries || {});

    grunt.config.merge({
      copy: {
        clientlibs: {
          files: Object.keys(files).map(key => ({
            src: files[key],
            dest: path.join(grunt.__gbc.pathes.distWeb, "js/third-party/" + key)
          })).concat({
            src: "port/license/thirdparty-english.txt",
            dest: path.join(grunt.__gbc.pathes.distWeb, "license/"),
            expand: true,
            flatten: true
          })
        }
      }
    });
    grunt.loadNpmTasks("grunt-contrib-copy");
    grunt.registerTask("__libraries", "Copy client libraries to the dist folder.", ["copy:clientlibs"]);
    grunt.__gbc.pathes.libraries = Object.keys(files).map(key => path.join(grunt.__gbc.pathes.distWeb, "js/third-party/" + key));
  }
};
