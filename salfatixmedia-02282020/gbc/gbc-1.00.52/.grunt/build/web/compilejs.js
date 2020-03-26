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
  var includes = [];
  includes = includes.concat(
    grunt.__gbc.pathes.libraries,
    path.join(grunt.__gbc.pathes.distWeb, "js/compiledLocales.js"),
    path.join(grunt.__gbc.pathes.distWeb, "js/compiledTemplates.js")
  );

  if (grunt.__gbc.config.compileMode === "dev") {
    includes = includes.concat(Object.values(grunt.__gbc.pathes.platformBootstrap)
      .map(p => path.join(grunt.__gbc.pathes.distWeb, p)));
    grunt.config.merge({
      copy: {
        jsdevbootstrap: {
          src: Object.values(grunt.__gbc.pathes.platformBootstrap),
          dest: grunt.__gbc.pathes.distWeb
        }
      }
    });

    includes = includes.concat(grunt.__gbc.pathes.sources.map(p => path.join(grunt.__gbc.pathes.distWeb, p)));
    grunt.config.merge({
      copy: {
        jsdev: {
          src: grunt.__gbc.pathes.sources,
          dest: grunt.__gbc.pathes.distWeb
        }
      }
    });

    grunt.loadNpmTasks("grunt-contrib-copy");
    grunt.registerTask("__compilejs", ["copy:jsdevbootstrap", "copy:jsdev"]);
  } else if (grunt.__gbc.config.compileMode === "cdev") {
    includes = includes.concat(Object.keys(grunt.__gbc.pathes.platformBootstrap)
      .map(p => path.join(grunt.__gbc.pathes.distWeb, "js/", p)));
    grunt.config.merge({
      copy: {
        jsbootstrap: {
          files: Object.keys(grunt.__gbc.pathes.platformBootstrap)
            .map(p => ({
              src: grunt.__gbc.pathes.platformBootstrap[p],
              dest: path.join(grunt.__gbc.pathes.distWeb, "js/", p)
            }))
        }
      }
    });
    includes = includes.concat(path.join(grunt.__gbc.pathes.distWeb, "js/gbc.js"));

    grunt.config.merge({
      concat: {
        cdevgbc: {
          options: {
            separator: ";",
            sourceMap: false
          },
          files: [{
            src: grunt.__gbc.pathes.sources,
            dest: path.join(grunt.__gbc.pathes.distWeb, "js/gbc.js")

          }]
        }
      }
    });

    grunt.loadNpmTasks("grunt-contrib-concat");
    grunt.registerTask("__compilejs", ["copy:jsbootstrap", "concat:cdevgbc"]);

  } else if (grunt.__gbc.config.compileMode === "prod") {
    includes = includes.concat(Object.keys(grunt.__gbc.pathes.platformBootstrap)
      .map(p => path.join(grunt.__gbc.pathes.distWeb, "js/", p)));
    grunt.config.merge({
      copy: {
        jsbootstrap: {
          files: Object.keys(grunt.__gbc.pathes.platformBootstrap)
            .map(p => ({
              src: grunt.__gbc.pathes.platformBootstrap[p],
              dest: path.join(grunt.__gbc.pathes.distWeb, "js/", p)
            }))
        }
      }
    });
    includes = includes.concat(path.join(grunt.__gbc.pathes.distWeb, "js/gbc.js"));

    var banner =
      `/// FOURJS_START_COPYRIGHT(D,2014)
/// Property of Four Js*
/// (c) Copyright Four Js 2014, 2019. All Rights Reserved.
/// * Trademark of Four Js Development Tools Europe Ltd
///   in the United States and elsewhere
///
/// This file can be modified by licensees according to the
/// product manual.
/// FOURJS_END_COPYRIGHT\n\n`;

    grunt.config.merge({
      uglify: {
        prod: {
          options: {
            banner: banner
          },
          files: [{
            src: grunt.__gbc.pathes.sources,
            dest: path.join(grunt.__gbc.pathes.distWeb, "js/gbc.js")
          }]
        },
        "prod_templates": {
          options: {
            banner: banner
          },
          files: [{
            src: path.join(grunt.__gbc.pathes.distWeb, "js/compiledTemplates.js"),
            dest: path.join(grunt.__gbc.pathes.distWeb, "js/compiledTemplates.js")
          }]
        },
        "prod_locales": {
          options: {
            banner: banner
          },
          files: [{
            src: path.join(grunt.__gbc.pathes.distWeb, "js/compiledLocales.js"),
            dest: path.join(grunt.__gbc.pathes.distWeb, "js/compiledLocales.js")
          }]
        }
      }
    });

    grunt.loadNpmTasks("grunt-contrib-uglify");
    grunt.registerTask("__compilejs", ["copy:jsbootstrap", "uglify:prod", "uglify:prod_templates", "uglify:prod_locales"]);
  }
  grunt.__gbc.pathes.indexIncludes = includes;
};
