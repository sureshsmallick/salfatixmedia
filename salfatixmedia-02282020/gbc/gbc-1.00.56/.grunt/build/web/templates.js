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
  var path = require("path");
  grunt.config.merge({
    templates2js: {
      compile: {
        options: {
          module: "gbcTemplates",
          rename: function(item) {
            return item.replace(".tpl.html", "").replace(/(?:.*\/)?([^\/]+)/, "$1");
          },
          process: function(contents) {
            return contents.replace(/<!--[^>]*-->/g, "").replace(/^\s*/, "").replace(/\s*$/, "");
          }
        },
        files: [{
          dest: path.join(grunt.__gbc.pathes.distWeb, "js/compiledTemplates.js"),
          src: grunt.__gbc.pathes.templates
        }]
      }
    }
  });
  grunt.loadNpmTasks("grunt-templates2js");
  grunt.registerTask("__templates", ["templates2js:compile"]);
};
