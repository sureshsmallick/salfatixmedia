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

modulum('LogPlayerWidget', ['WidgetGroupBase', 'WidgetFactory'],
  function(context, cls) {

    /**
     * @class LogPlayerWidget
     * @memberOf classes
     * @extends classes.WidgetGroupBase
     */
    cls.LogPlayerWidget = context.oo.Class(cls.WidgetGroupBase, function($super) {
      return /** @lends classes.LogPlayerWidget.prototype */ {
        __name: "LogPlayerWidget",

        _fileInput: null,
        _delayInput: null,
        _resetButton: null,
        _nextStepButton: null,
        _playAllButton: null,
        _forwardInput: null,
        _forwardButton: null,
        _domCountCheckWidget: null,
        _domCountCheckElement: null,
        _log: null,
        _currentLogLine: 0,
        _currentDvmOrder: 0,
        _numberOfDvmOrdersToProcess: 0,
        _processedDvmOrders: 0,
        _startTime: null,
        _maxNumberOfElements: null,

        /**
         * @inheritDoc
         */
        constructor: function(opts) {
          $super.constructor.call(this, opts);

          window._logplayer = this;

          var root = this.getElement();

          this._fileInput = root.querySelector(".logplayer-fileinput");
          this._delayInput = root.querySelector(".logplayer-delay");
          this._resetButton = root.querySelector(".logplayer-reset");
          this._nextStepButton = root.querySelector(".logplayer-step");
          this._playAllButton = root.querySelector(".logplayer-play");
          this._forwardInput = root.querySelector(".logplayer-forward-count");
          this._forwardButton = root.querySelector(".logplayer-forward");
          this._domCountCheckElement = root.querySelector(".logplayer-domCount");

          this._delayInput.value = 500;

          this._fileInput.on('change.LogPlayerWidget', this.loadFile.bind(this));

          this.setButtonEnabled(this._resetButton, false);
          this.setButtonEnabled(this._nextStepButton, false);
          this.setButtonEnabled(this._playAllButton, false);
          this.setButtonEnabled(this._forwardButton, false);

          this._domCountCheckWidget = cls.WidgetFactory.createWidget("ToggleCheckBox", this.getBuildParameters());
          this._domCountCheckWidget.setEnabled(true);
          this._domCountCheckWidget.setText("Count DOM elements");
          this._domCountCheckWidget.setValue(false);

          this._domCountCheckElement.appendChild(this._domCountCheckWidget.getElement());
        },

        /**
         * @inheritDoc
         */
        destroy: function() {

          if (this._domCountCheckWidget) {
            this._domCountCheckWidget.destroy();
            this._domCountCheckWidget = null;
          }
          this._domCountCheckElement = null;

          // TODO ...

          $super.destroy.call(this);
        },

        /**
         * @inheritDoc
         */
        _initLayout: function() {
          // no layout
        },

        /**
         * @inheritDoc
         */
        manageMouseClick: function(domEvent) {
          var target = domEvent.target;
          if (target.isElementOrChildOf(this._resetButton)) {
            this.reset();
          } else if (target.isElementOrChildOf(this._nextStepButton)) {
            this.nextStep();
          } else if (target.isElementOrChildOf(this._playAllButton)) {
            this.play();
          } else if (target.isElementOrChildOf(this._forwardButton)) {
            this.forward();
          }

          return true;
        },

        setDelayInputValue: function(value) {
          this._delayInput.value = value;
        },

        setForwardInputValue: function(value) {
          this._forwardInput.value = value;
        },

        loadContent: function(content) {
          this._nextStepButton.removeAttribute('disabled');
          this._playAllButton.removeAttribute('disabled');
          this._log = null;
          this.reset();

          content = content.split('\n').map(function(line) {
            return line.trim();
          });
          if (content.length > 0) {
            var firstLine = content[0];
            if (firstLine === 'LOGVERSION=2') {
              this.parseGdcLog(content);
            } else if (firstLine.substr(0, 5) === 'om 0 ') {
              this.parseFglLog(content);
            } else if (firstLine === 'guilog v2') {
              this.parseFglLogV2(content);
            } else if (firstLine === '#Version: 1.0') {
              this.parseUaproxyLog(content);
            }
            this.setButtonEnabled(this._resetButton, true);
            this.setButtonEnabled(this._nextStepButton, true);
            this.setButtonEnabled(this._playAllButton, true);
            this.setButtonEnabled(this._forwardButton, true);
            this._fileInput.removeAttribute("disabled");
          }
        },

        loadFile: function(event) {
          if (event.target.files.length > 0) {
            var reader = new FileReader();
            reader.onload = function(fEvent) {
              this.loadContent(fEvent.target.result);
            }.bind(this);
            reader.readAsText(event.target.files[0]);
          }
        },

        reset: function() {
          this.setButtonEnabled(this._resetButton, true);
          this.setButtonEnabled(this._nextStepButton, true);
          this.setButtonEnabled(this._playAllButton, true);
          this.setButtonEnabled(this._forwardButton, true);
          this._fileInput.removeAttribute("disabled");

          this._currentLogLine = 0;
          this._currentDvmOrder = 0;
          this._numberOfDvmOrdersToProcess = 0;
          this._processedDvmOrders = 0;
        },

        parseGdcLog: function(log) {
          this._log = [];
          for (var i = 0; i < log.length; ++i) {
            if (i !== 0) {
              var line = log[i];
              if (line.length > 0) {
                var appEnd = line.indexOf(':');
                var senderEnd = line.indexOf(':', appEnd + 1);
                var delayEnd = line.indexOf(':', senderEnd + 1);

                var entry = {};
                entry.app = line.substring(0, appEnd);
                entry.sender = line.substring(appEnd + 1, senderEnd);
                entry.delay = line.substring(senderEnd + 1, delayEnd);
                entry.content = context.LogPlayerService.mockOrderResources(line.substring(delayEnd + 1));

                this._log.push(entry);
              }
            }
          }
        },

        parseFglLog: function(log) {
          this._log = [];
          for (var i = 0; i < log.length; ++i) {
            var line = log[i];
            if (line.length > 0) {
              var entry = {};
              entry.app = "0";
              entry.delay = 1000;
              if (line[0] === '#') {
                if (line.substr(0, 7) === '#event ') {
                  entry.sender = "FE";
                } else {
                  entry.sender = "COMMENT";
                }
                entry.content = context.LogPlayerService.mockOrderResources(line.substring(1));
              } else {
                entry.sender = "DVM";
                entry.content = context.LogPlayerService.mockOrderResources(line);
              }
              this._log.push(entry);
            }
          }
        },

        parseFglLogV2: function(log) {
          this._log = [];
          var lastOrderTime = 0;
          for (var i = 1; i < log.length; ++i) {
            var line = log[i];
            if (line.length > 0) {
              var colonIndex = line.indexOf(':');
              var info = line.substr(0, colonIndex).split(' ');
              var entry = {};
              entry.app = info[0];
              var timestamp = parseInt(info[1]);
              entry.delay = timestamp - lastOrderTime;
              lastOrderTime = timestamp;
              entry.sender = info[2] === 'i' ? "FE" : "DVM";
              entry.content = context.LogPlayerService.mockOrderResources(line.substr(colonIndex + 1));
              this._log.push(entry);
            }
          }
        },

        parseUaproxyLog: function(log) {
          this._log = [];
          var fieldsCount = null;
          var relativeTimeFieldIndex = null;
          var contextsFieldIndex = null;
          var eventTypeFieldIndex = null;
          var eventParamsFieldIndex = null;
          var timeSinceLastDvmOrder = 0;

          for (var i = 0; i < log.length; ++i) {
            var line = log[i];
            if (line.length !== 0) {
              if (line[0] === '#') {
                if (line.substr(0, 9) === '#Fields: ') {
                  var fields = line.substr(9).split(' ');
                  fieldsCount = fields.length;
                  relativeTimeFieldIndex = fields.indexOf('relative-time');
                  contextsFieldIndex = fields.indexOf('contexts');
                  eventTypeFieldIndex = fields.indexOf('event-type');
                  eventParamsFieldIndex = fields.indexOf('event-params');
                  if (relativeTimeFieldIndex === -1 || contextsFieldIndex === -1 || eventTypeFieldIndex === -1 ||
                    eventParamsFieldIndex === -1) {
                    this.addLog(" ", '<b>Log fields missing. Enable "ALL DEBUG" categories</b>');
                    return;
                  }
                }
              } else {
                var sectionStart = -1;
                var sections = [];
                for (var j = 0; j < line.length; ++j) {
                  var c = line[j];
                  if (c === ' ') {
                    sections.push(line.substring(sectionStart + 1, j));
                    sectionStart = j;
                  } else if (c === '"') {
                    j = line.indexOf('"', j + 1);
                  }
                  if (sections.length === fieldsCount - 1) {
                    sections.push(line.substr(j + 1));
                    break;
                  }
                }
                timeSinceLastDvmOrder += parseFloat(sections[relativeTimeFieldIndex]);
                var contexts = sections[contextsFieldIndex];
                var eventType = sections[eventTypeFieldIndex];
                var eventParams = sections[eventParamsFieldIndex];
                var vmIdIndex = contexts.indexOf('VM=');
                var vmId = null;
                if (vmIdIndex !== -1) {
                  var semiColonIndex = contexts.indexOf(';', vmIdIndex);
                  if (semiColonIndex === -1) {
                    semiColonIndex = undefined;
                  }
                  vmId = contexts.substring(vmIdIndex + 3, semiColonIndex);
                }
                if (vmId !== null) {
                  if (eventType === '"Sending VM"' || eventType === '"Sending UA"') {
                    if ((eventParams.indexOf("meta Connection") === 0 || eventParams.indexOf("om") === 0 || eventParams.indexOf(
                        "event _om") === 0)) {
                      var sender = eventType === '"Sending UA"' ? "DVM" : "FE";
                      var orders = eventParams;
                      var crIndex = -1;
                      do {
                        crIndex = orders.indexOf('\\n', crIndex + 1);
                        if (crIndex > 1 && orders[crIndex - 1] !== '\\') {
                          orders = orders.substr(0, crIndex) + '\n' + orders.substr(crIndex + 2);
                        }
                      } while (crIndex !== -1);
                      var order = this.detachString(orders);
                      order = order.replace(/([^\\])\\t/g, '$1\t');
                      order = order.replace(/\\\\n/g, '\\n');
                      order = order.replace(/\\\\\\\\/g, '//');
                      order = order.replace(/\\\\"/g, '\\"');
                      order = order.replace(/\\r/g, '');
                      order = order.replace(/%/g, "%25");
                      order = decodeURIComponent(order.replace(/\\x/g, "%"));
                      order = context.LogPlayerService.mockOrderResources(order);

                      if (order !== '-') { // '-' marks the DVM deconection
                        var entry = {};
                        entry.app = this.detachString(vmId);
                        entry.sender = sender;
                        entry.content = order;
                        entry.delay = sender === 'DVM' ? Math.round(timeSinceLastDvmOrder * 1000) : 0;
                        timeSinceLastDvmOrder = 0;
                        this._log.push(entry);
                      }
                      orders = orders.substring(crIndex + 2);
                    } else if (/X-FourJs-Closed: true/.test(line)) {
                      var closeEntry = {};
                      closeEntry.app = this.detachString(vmId);
                      closeEntry.sender = "";
                      closeEntry.content = "";
                      closeEntry.close = true;
                      closeEntry.delay = 0;
                      timeSinceLastDvmOrder = 0;
                      this._log.push(closeEntry);

                    }
                  }
                }
              }
            }
          }
        },

        nextStep: function() {
          if (this._log) {
            this._processedDvmOrders = 0;
            this._numberOfDvmOrdersToProcess = 1;
            this.run();
          }
        },

        play: function() {
          if (this._log) {
            this._startTime = performance.now();
            this._processedDvmOrders = 0;
            this._numberOfDvmOrdersToProcess = this._log.length;
            this.run();
          }
        },

        forward: function() {
          if (this._log) {
            this._processedDvmOrders = 0;
            this._numberOfDvmOrdersToProcess = this._forwardInput.value;
            this.run();
          }
        },

        run: function() {
          this.setButtonEnabled(this._resetButton, false);
          this.setButtonEnabled(this._nextStepButton, false);
          this.setButtonEnabled(this._playAllButton, false);
          this.setButtonEnabled(this._forwardButton, false);
          this._fileInput.setAttribute("disabled", "disabled");

          while (this._currentLogLine < this._log.length) {
            var entry = this._log[this._currentLogLine];
            ++this._currentLogLine;
            var isDvm = entry.sender === 'DVM' && entry.content.substr(0, 5) !== 'meta ';
            this.addLog(entry.app + ':' + entry.sender, entry.content, isDvm);
            if (isDvm) {
              ++this._processedDvmOrders;
              ++this._currentDvmOrder;
              var app = context.LogPlayerService.getApplication(0, entry.app);
              var callback = null;
              if (this._processedDvmOrders < this._numberOfDvmOrdersToProcess && this._currentLogLine < this._log.length) {
                callback = this._delayRunner();
              } else {
                callback = this._setPlayerEnabled.bind(this);
                this.emit(context.constants.widgetEvents.logForwardDone);
              }
              app.dvm.manageAuiOrders(entry.content, callback);
              this.emit(context.constants.widgetEvents.logStepDone, this._processedDvmOrders);
              break;
            } else if (entry.close) {
              var closeApp = context.LogPlayerService.getApplication(0, entry.app);
              if (closeApp) {
                closeApp.setEnding();
                closeApp.stop();
                context.LogPlayerService.removeApplication(0, entry.app);
              }
            }
          }
          if (this._domCountCheckWidget.getValue()) {
            var elementNumber = document.getElementsByTagName('*').length;
            if (this._maxNumberOfElements === null || elementNumber > this._maxNumberOfElements) {
              this._maxNumberOfElements = elementNumber;
            }
          }

          if (this._currentLogLine >= this._log.length) {

            var reportTime = "";
            if (this._startTime !== null) {
              var t1 = performance.now();
              reportTime = "Duration: " + (t1 - this._startTime) + " milliseconds.";
              this.addLog(" ", reportTime);
              this._startTime = null;
            }
            var reportDOM = "";
            if (this._maxNumberOfElements !== null) {
              reportDOM = "Max number of DOM elements: " + this._maxNumberOfElements;
              this.addLog(" ", reportDOM);
            }

            if (!gbc.qaMode && (reportDOM !== "" || reportTime !== "")) {
              gbc.alert(reportTime + "\n" + reportDOM, "LogPlayer");
            }

            this.setButtonEnabled(this._resetButton, true);
            this.setButtonEnabled(this._nextStepButton, false);
            this.setButtonEnabled(this._playAllButton, false);
            this.setButtonEnabled(this._forwardButton, false);
            this._fileInput.removeAttribute("disabled");
            this.log = [];

            context.SessionService.getCurrent().closeSession();
            this.addLog(" ", '<b>== LOG FINISHED ==</b>');
            this.emit(context.constants.widgetEvents.ready);
          }
        },

        _delayRunner: function() {
          return function() {
            this._registerTimeout(function() {
              this.run();
            }.bind(this), this._delayInput.value);
          }.bind(this);
        },

        _setPlayerEnabled: function() {
          this.setButtonEnabled(this._resetButton, true);
          this.setButtonEnabled(this._nextStepButton, true);
          this.setButtonEnabled(this._playAllButton, true);
          this.setButtonEnabled(this._forwardButton, true);
          this._fileInput.removeAttribute("disabled");
        },

        addLog: function(context, content, withOrderNumber) {
          var orderNr = withOrderNumber ? this._currentDvmOrder : ' ';
          console.log("LOGPLAYER", orderNr, context, content);
        },

        setButtonEnabled: function(button, enabled) {
          if (enabled) {
            button.removeClass("disabled");
            button.removeAttribute("disabled");
          } else {
            button.addClass("disabled");
            button.setAttribute("disabled", "disabled");
          }
        },

        detachString: function(s) {
          return (' ' + s).slice(1);
        }
      };
    });
    cls.WidgetFactory.registerBuilder('LogPlayer', cls.LogPlayerWidget);
  });
