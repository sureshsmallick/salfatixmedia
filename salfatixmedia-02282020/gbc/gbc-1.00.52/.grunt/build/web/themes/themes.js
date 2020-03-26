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

const fs = require("fs"),
  fse = require("fs-extra"),
  glob = require("glob"),
  path = require("path"),
  sass = require('node-sass'),
  postcss = require('postcss'),
  autoprefixer = require('autoprefixer'),
  postcssUrlMapper = require('postcss-url-mapper'),
  postcssDiscardComments = require('postcss-discard-comments'),
  b64 = require("js-base64").Base64;

const
  resourceUrlMatcher = /^\$\$RES\//,
  mainScssFile = "src/sass/main.scss",
  banner = postcss.plugin('postcss-banner', function(opts) {
    opts = opts || {};
    return function(css) {
      if ('banner' in opts) {
        css.insertAfter(css.nodes[0], postcss.comment({
          text: "\n * ".concat(opts.banner.split('\n').join('\n * ').concat("\n"))
        }));
        if (css.nodes[1]) {
          css.nodes[1].raws.before = '\n';
        }
      }
    };
  }),
  resourceList = postcss.plugin('postcss-resource-list', function(opts) {
    opts = opts || {};
    return function(css) {
      css.walkRules(rule => {
        if (rule.selector === "body:after") {
          rule.walkDecls((decl) => {
            if (decl.prop === 'content') {
              let themeData = {
                variables: JSON.parse(decl.value.replace(/\\'/g, "'").replace(/^"|"$/g, "").replace(/^'|'$/g, "")
                  .replace(/"/g, '\\\\"').replace(/'/g, '"')),
                pathes: opts.list || [],
                widgetFactory: opts.factory || {}
              };
              decl.value = decl.value.replace(/.*/, `"${b64.toBase64(JSON.stringify(themeData))}"`);
            }
          });
        }
      });
    };
  });

class ThemeBuilder {
  constructor(grunt, theme) {
    this._grunt = grunt;
    this._theme = theme;
    this.sassImporter = new(require("./sassImporter")(grunt))(theme.usePathes);
    this.sassFunctions = require("./sassFunctions")(grunt).functions;
    this._options = {
      precision: 10,
      outputStyle: "compact",
      importer: (url, file, done) => this.sassImporter.importer(url, file, done),
      functions: this.sassFunctions,
      file: path.join(this._grunt.__pwd, mainScssFile),
      outFile: theme.cacheCss
    };
  }
  async build() {
    this._grunt.log.writeln(`
    Building theme ${this._theme.name}`);
    let css = await new Promise((resolve, reject) => sass.render(this._options, (err, res) => {
      if (err) {
        this._grunt.log.error(err.formatted + '\n');
        reject(err);
      } else {
        this._grunt.file.write(this._theme.cacheCss, res.css);
        resolve(res.css);
      }
    }));
    await fse.mkdirs(this._theme.cacheResourcePath);

    for (let p of this._theme.usePathes) {
      try {
        this._grunt.log.write(`Copy resources from ${p} ... `);
        await fse.copy(path.join(p, "resources/"), this._theme.cacheResourcePath);
        this._grunt.log.writeln(`ok`);
      } catch (e) {
        this._grunt.log.writeln(`not found`);
      }
    }

    await fse.mkdirs(this._theme.outputPath);

    await fse.copy(this._theme.cachePath, this._theme.outputPath);

    this._grunt.__gbc.resources.themes[this._theme.name] = glob.sync("**/*", {
      cwd: path.join(this._theme.outputPath, "resources")
    });
    let mapper = (url) => {
      let result = url;
      if (resourceUrlMatcher.test(url)) {
        let relUrl = url.replace(resourceUrlMatcher, "").split("?")[0].split("#")[0];
        if (this._grunt.__gbc.resources.themes[this._theme.name].indexOf(relUrl) >= 0) {
          result = "./resources/" + relUrl;
        } else if (this._grunt.__gbc.resources.common.indexOf(relUrl) >= 0) {
          result = "../../resources/" + relUrl;
        } else {
          this._grunt.log.warn(`Resource '${relUrl}' used but not found in files.`);
        }
      }
      return result;
    };
    let resources = {
      common: this._grunt.__gbc.resources.common,
      themes: {}
    };
    resources.themes[this._theme.name] = this._grunt.__gbc.resources.themes[this._theme.name];
    await postcss([
        postcssUrlMapper(mapper, {
          atRules: true
        }),
        autoprefixer({
          browsers: ["last 1 version"]
        }),
        postcssDiscardComments({
          removeAll: true
        }),
        resourceList({
          list: resources,
          factory: this._theme.widgetFactory
        }),
        banner({
          banner: `FOURJS_START_COPYRIGHT(D,2014)
Property of Four Js*
(c) Copyright Four Js 2014, 2019. All Rights Reserved.
* Trademark of Four Js Development Tools Europe Ltd
  in the United States and elsewhere

This file can be modified by licensees according to the
product manual.
FOURJS_END_COPYRIGHT`
        })
      ])
      .process(css, {
        from: this._theme.cacheCss,
        to: this._theme.outputCss
      })
      .then(result => {
        this._grunt.log.write(`Writing ${this._theme.outputCss} ...`);
        if (!result.css) {
          this._grunt.log.writeln(" EMPTY.");
        }
        fs.writeFileSync(this._theme.outputCss, result.css);
        if (result.map) {
          fs.writeFileSync(this._theme.outputCss, result.map);
        }
        this._grunt.log.writeln(" ok.");
      });
  }
}

class ThemesBuilder {
  constructor(grunt, configuration) {
    this._grunt = grunt;
    this._config = configuration;
  }

  static _isReadableDirectory(dir) {
    try {
      fs.accessSync(dir, fs.R_OK | fs.X_OK);
      return fs.statSync(dir).isDirectory();
    } catch (e) {
      return false;
    }
  }

  _resolveThemePath(name) {
    let result = null,
      pathes = [];
    if (path.isAbsolute(name)) {
      pathes.push(name);
    }
    if (this._grunt.__gbc.pathes.customizationPath) {
      pathes.push(path.join(this._grunt.__gbc.pathes.customizationPath, "theme", name));
    }
    pathes.push(path.join(this._grunt.__pwd, "theme", name));
    pathes.push(path.join(this._grunt.__pwd, name));

    for (let p of pathes) {
      let readable = ThemesBuilder._isReadableDirectory(p, this._grunt);
      if (readable) {
        result = p;
        break;
      }
    }
    if (!result) {
      throw new Error(`theme '${name}' does not exist.`);
    }
    return result;
  }

  async prepare() {
    for (let theme of this._config) {
      if (!theme.name) {
        this._grunt.log.error("Theme has no name:", JSON.stringify(theme));
        throw new Error();
      }
      if (!/^[a-z0-9_][a-z0-9_-]*$/i.test(theme.name)) {
        this._grunt.log.error("malformed theme name:", theme.name);
        throw new Error();
      }
      theme.usePathes = theme.uses ? theme.uses.map(x => this._resolveThemePath(x)) : [];

      this._resolveThemeConfiguration(theme);
      theme.cachePath = theme.cachePath || path.join(".cache/", this._grunt.__gbc.pathes.distWebFlat, "/themes/", theme.name);
      theme.cacheResourcePath = path.join(theme.cachePath, "resources");
      theme.cacheCss = path.join(theme.cachePath, "main.css");
      theme.outputPath = theme.outputPath || path.join(this._grunt.__gbc.pathes.distWeb, `themes/${theme.name}/`);
      theme.outputCss = path.join(theme.outputPath, "main.css");
    }
  }

  async build() {
    for (let theme of this._config) {
      await this._buildTheme(theme);
    }
  }

  async _buildTheme(theme) {
    await new ThemeBuilder(this._grunt, theme).build();
  }

  _resolveThemeConfiguration(theme) {
    let conditions = [],
      widgetFactory = {};

    for (let themePartPath of theme.usePathes) {
      try {
        let partConfig = this._grunt.file.readJSON(path.join(themePartPath, "theme.config.json"));
        if (partConfig.conditions) {
          for (let condition of partConfig.conditions) {
            if (!conditions.includes(condition)) {
              conditions.push(condition);
            }
          }
        }
        if (partConfig.widgetFactory) {
          for (let key in partConfig.widgetFactory) {
            widgetFactory[key] = partConfig.widgetFactory[key];
          }
        }
      } catch (e) {}
    }
    try {
      for (let condition of theme.conditions) {
        if (!conditions.includes(condition)) {
          conditions.push(condition);
        }
      }
    } catch (e) {}
    try {
      for (let key in theme.widgetFactory) {
        widgetFactory[key] = theme.widgetFactory[key];
      }
    } catch (e) {}
    theme.conditions = conditions;
    theme.widgetFactory = widgetFactory;
  }
}

module.exports = function(grunt) {
  grunt.verbose.writeln('\n' + sass.info + '\n');
  grunt.registerMultiTask('themes', 'Compile Themes', function() {
    grunt.__gbc.resources = {
      common: glob.sync("**/*", {
        cwd: path.join(grunt.__gbc.pathes.distWeb, "resources")
      }),
      themes: {}
    };
    let builder = new ThemesBuilder(grunt, grunt.__gbc.config.themeConfiguration);
    (async () => {
      await builder.prepare();
      await builder.build();
    })().then(this.async()).catch(this.async());
  });

  grunt.config.merge({
    themes: {
      compile: {}
    }
  });

  grunt.registerTask("__themes", ["themes:compile"]);
};
