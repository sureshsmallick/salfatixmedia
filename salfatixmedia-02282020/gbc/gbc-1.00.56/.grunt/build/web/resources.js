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

module.exports = grunt => {
  const path = require("path");

  let resourcePath = path.join(grunt.__gbc.pathes.distWeb, "resources"),
    fontPath = path.join(resourcePath, "fonts/");

  grunt.config.merge({
    copy: {
      version: {
        expand: true,
        cwd: "",
        src: "VERSION",
        dest: grunt.__gbc.pathes.distWeb,
        options: {
          process: contents => require("./injectVersion")(grunt, contents)
        }
      },
      productinfo: {
        expand: true,
        cwd: "",
        src: "PRODUCTINFO",
        dest: grunt.__gbc.pathes.distWeb
      },
      droidFonts: {
        options: {
          processContent: false
        },
        files: [{
          expand: true,
          cwd: "node_modules/connect-fonts-droidsans/fonts/default",
          src: ["*.*"],
          dest: fontPath
        }, {
          expand: true,
          cwd: "node_modules/connect-fonts-droidsansmono/fonts/default",
          src: ["*.*"],
          dest: fontPath
        }]
      },
      materialIcons: {
        expand: true,
        options: {
          processContent: false
        },
        cwd: "node_modules/@mdi/font/fonts/",
        src: ["*.*"],
        dest: fontPath
      },
      resources: {
        expand: true,
        cwd: "src/resources",
        src: "**/*",
        dest: resourcePath
      },
      customizationResources: {
        expand: true,
        cwd: grunt.__gbc.pathes.customizationPath + "/resources",
        src: "**/*",
        dest: resourcePath
      }
    }
  });

  grunt.loadNpmTasks("grunt-contrib-copy");
  grunt.registerTask("__resources", ["copy:version", "copy:productinfo", "copy:droidFonts",
    "copy:materialIcons", "copy:resources", "copy:customizationResources"
  ]);

};
