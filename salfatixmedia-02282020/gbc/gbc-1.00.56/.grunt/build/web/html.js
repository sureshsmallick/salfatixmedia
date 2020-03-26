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
  const path = require("path"),
    glob = require("glob").sync;
  const themesFn = () =>
    `<script>
  window.__gbcThemesInfo = ${
    JSON.stringify(grunt.__gbc.config.themeConfiguration.map(({name, title, conditions}) => ({name, title: title||name, conditions})))
  };
</script>`,
    distWeb = path.join(grunt.__gbc.pathes.distWeb, "/").replace(/\\/g, "/");
  grunt.config.merge({
    replace: {
      index: {
        src: "src/index.html",
        dest: path.join(grunt.__gbc.pathes.distWeb, "/index.html"),
        replacements: [{
          from: "<!-- Theme information -->",
          to: themesFn
        }, {
          from: "<!-- Bootstrap information -->",
          to: ""
        }, {
          from: "<!-- JS injection -->",
          to: () => Array
            .from(new Set(grunt.__gbc.pathes.indexIncludes.map(item => glob(item)).reduce((acc, val) => acc.concat(val), [])))
            .map(item => `<script src="${item.replace("../../", "").replace(distWeb, "") + "?$CACHE"}"></script>`)
            .join("\n")
        }, {
          from: "$CACHE",
          to: grunt.__gbc.config.htmlCacheQueryStringPart
        }]
      },
      bootstrap: {
        src: "src/index.html",
        dest: path.join(grunt.__gbc.pathes.distWeb, "/bootstrap.html"),
        replacements: [{
          from: "<!-- Theme information -->",
          to: themesFn
        }, {
          from: "<!-- Bootstrap information -->",
          to: () => grunt.file.read("src/bootstrapParams.tpl")
        }, {
          from: "<!-- JS injection -->",
          to: () => Array
            .from(new Set(grunt.__gbc.pathes.indexIncludes.map(item => glob(item)).reduce((acc, val) => acc.concat(val), [])))
            .map(item => `<script src="${item.replace("../../", "").replace(distWeb, "") + "?$CACHE"}"></script>`)
            .join("\n")
        }, {
          from: "$CACHE",
          to: grunt.__gbc.config.htmlCacheQueryStringPart
        }]
      }
    }
  });

  grunt.loadNpmTasks("grunt-text-replace");

  grunt.registerTask("__html", ["replace:index", "replace:bootstrap"]);
};
