// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * These are not quite unit tests, since we build on top of the analyzer and the
 * html5parser to build the input for each test.
 */
library emitter_test;

import 'package:html5lib/dom.dart';
import 'package:unittest/unittest.dart';
import 'package:web_ui/src/analyzer.dart';
import 'package:web_ui/src/emitters.dart';
import 'package:web_ui/src/html5_utils.dart';
import 'package:web_ui/src/info.dart';
import 'package:web_ui/src/file_system/path.dart' show Path;
import 'testing.dart';
import 'compact_vm_config.dart';


main() {
  useCompactVMConfiguration();
  useMockMessages();
  group('emit element field', () {
    group('declaration', () {
      test('no data binding', () {
        var elem = parseSubtree('<div></div>');
        var code = _declarationsRecursive(analyzeElement(elem));
        expect(code, equals(''));
      });

      test('id only, no data binding', () {
        var elem = parseSubtree('<div id="one"></div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_declarations(emitter),
            equals('autogenerated_html.DivElement __one;'));
      });

      test('action with no id', () {
        var elem = parseSubtree('<div data-action="foo:bar"></div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_declarations(emitter),
            equals('autogenerated_html.DivElement __e0;'));
      });

      test('action with id', () {
        var elem = parseSubtree('<div id="my-id" data-action="foo:bar"></div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_declarations(emitter),
            equals('autogenerated_html.DivElement __myId;'));
      });

      test('1 way binding with no id', () {
        var elem = parseSubtree('<div class="{{bar}}"></div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_declarations(emitter),
            equals('autogenerated_html.DivElement __e0;'));
      });

      test('1 way binding with id', () {
        var elem = parseSubtree('<div id="my-id" class="{{bar}}"></div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_declarations(emitter),
            equals('autogenerated_html.DivElement __myId;'));
      });

      test('2 way binding with no id', () {
        var elem = parseSubtree('<input data-bind="value:bar"></input>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_declarations(emitter),
            equals('autogenerated_html.InputElement __e0;'));
      });

      test('2 way binding with id', () {
        var elem = parseSubtree(
          '<input id="my-id" data-bind="value:bar"></input>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_declarations(emitter),
            equals('autogenerated_html.InputElement __myId;'));
      });

      test('1 way binding in content with no id', () {
        var elem = parseSubtree('<div>{{bar}}</div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_declarations(emitter), 'autogenerated_html.DivElement __e1;');
      });

      test('1 way binding in content with id', () {
        var elem = parseSubtree('<div id="my-id">{{bar}}</div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_declarations(emitter), 'autogenerated_html.DivElement __myId;');
      });
    });

    group('created', () {
      test('no data binding', () {
        var elem = parseSubtree('<div></div>');
        var code = _createdRecursive(analyzeElement(elem));
        expect(code, equals(''));
      });

      test('id only, no data binding', () {
        var elem = parseSubtree('<div id="one"></div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_created(emitter), equals("__one = _root.query('#one');"));
      });

      test('action with no id', () {
        var elem = parseSubtree('<div data-action="foo:bar"></div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_created(emitter), equals("__e0 = _root.query('#__e-0');"));
      });

      test('action with id', () {
        var elem = parseSubtree('<div id="my-id" data-action="foo:bar"></div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_created(emitter), equals("__myId = _root.query('#my-id');"));
      });

      test('1 way binding with no id', () {
        var elem = parseSubtree('<div class="{{bar}}"></div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_created(emitter), equals("__e0 = _root.query('#__e-0');"));
      });

      test('1 way binding with id', () {
        var elem = parseSubtree('<div id="my-id" class="{{bar}}"></div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_created(emitter), equals("__myId = _root.query('#my-id');"));
      });

      test('2 way binding with no id', () {
        var elem = parseSubtree('<input data-bind="value:bar"></input>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_created(emitter), equals("__e0 = _root.query('#__e-0');"));
      });

      test('2 way binding with id', () {
        var elem = parseSubtree(
          '<input id="my-id" data-bind="value:bar"></input>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_created(emitter), equals("__myId = _root.query('#my-id');"));
      });

      test('sibling of a data-bound text node, with id and children', () {
        var elem = parseSubtree('<div id="a1">{{x}}<div id="a2">a</div></div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem).children[1]);
        expect(_created(emitter),
            "__a2 = new autogenerated_html.Element.html("
            "'<div id=\"a2\">a</div>');");
      });
    });

    group('type', () {
      htmlElementNames.forEach((tag, className) {
        // Skip script and body tags, we don't create fields for them.
        if (tag == 'script' || tag == 'body') return;

        test('$tag -> $className', () {
          var elem = new Element(tag)..attributes['class'] = "{{bar}}";
          var emitter = new ElementFieldEmitter(analyzeElement(elem));
          expect(_declarations(emitter),
              equals('autogenerated_$className __e0;'));
        });
      });
    });
  });

  group('emit text node field', () {
    test('declaration', () {
      var elem = parseSubtree('<div>{{bar}}</div>');
      var emitter = new ContentFieldEmitter(analyzeElement(elem).children[0]);
      expect(_declarations(emitter), 'var __binding0;');
    });

    test('created', () {
      var elem = parseSubtree('<div>{{bar}}</div>');
      var emitter = new ContentFieldEmitter(analyzeElement(elem).children[0]);
      expect(_created(emitter),
          "__binding0 = new autogenerated_html.Text('');");
    });

    test('inserted', () {
      var elem = parseSubtree('<div>{{bar}}</div>');
      var emitter = new ContentFieldEmitter(analyzeElement(elem).children[0]);
      expect(_inserted(emitter), '');
    });

    test('removed', () {
      var elem = parseSubtree('<div>{{bar}}</div>');
      var emitter = new ContentFieldEmitter(analyzeElement(elem).children[0]);
      expect(_removed(emitter), '__binding0 = null;');
    });
  });

  group('emit event listeners', () {
    test('declaration for action', () {
      var elem = parseSubtree('<div data-action="foo:bar"></div>');
      var emitter = new EventListenerEmitter(analyzeElement(elem));
      expect(_declarations(emitter), equals(
          'autogenerated_html.EventListener __listener__e0_foo_1;'));
    });

    test('declaration for input value data-bind', () {
      var elem = parseSubtree('<input data-bind="value:bar"></input>');
      var emitter = new EventListenerEmitter(analyzeElement(elem));
      expect(_declarations(emitter),
        equals('autogenerated_html.EventListener __listener__e0_input_1;'));
    });

    test('created', () {
      var elem = parseSubtree('<div data-action="foo:bar"></div>');
      var emitter = new EventListenerEmitter(analyzeElement(elem));
      expect(_created(emitter), equals(''));
    });

    test('inserted', () {
      var elem = parseSubtree('<div data-action="foo:bar"></div>');
      var emitter = new EventListenerEmitter(analyzeElement(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          '__listener__e0_foo_1 = '
          r'  ($event) { bar($event); autogenerated.dispatch(); }; '
          '__e0.on.foo.add(__listener__e0_foo_1);'));
    });

    test('inserted for input value data bind', () {
      var elem = parseSubtree('<input data-bind="value:bar"></input>');
      var emitter = new EventListenerEmitter(analyzeElement(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          r'__listener__e0_input_1 = ($event) { bar = __e0.value; '
          'autogenerated.dispatch(); }; '
          '__e0.on.input.add(__listener__e0_input_1);'));
    });

    test('removed', () {
      var elem = parseSubtree('<div data-action="foo:bar"></div>');
      var emitter = new EventListenerEmitter(analyzeElement(elem));
      expect(_removed(emitter), equalsIgnoringWhitespace(
          '__e0.on.foo.remove(__listener__e0_foo_1); '
          '__listener__e0_foo_1 = null;'));
    });
  });

  group('emit data binding watchers for attributes', () {
    test('declaration', () {
      var elem = parseSubtree('<div foo="{{bar}}"></div>');
      var emitter = new AttributeEmitter(analyzeElement(elem));
      expect(_declarations(emitter),
        equals('List<autogenerated.WatcherDisposer> __stoppers1;'));
    });

    test('created', () {
      var elem = parseSubtree('<div foo="{{bar}}"></div>');
      var emitter = new AttributeEmitter(analyzeElement(elem));
      expect(_created(emitter), equals('__stoppers1 = [];'));
    });

    test('inserted', () {
      var elem = parseSubtree('<div foo="{{bar}}"></div>');
      var emitter = new AttributeEmitter(analyzeElement(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          '__stoppers1.add(autogenerated.watchAndInvoke(() => '
          "bar, (__e) { __e0.attributes['foo'] = __e.newValue; }));"));
    });

    test('inserted for 1-way binding with dom accessor', () {
      var elem = parseSubtree('<input value="{{bar}}">');
      var emitter = new AttributeEmitter(analyzeElement(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          '__stoppers1.add(autogenerated.watchAndInvoke(() => bar, (__e) { '
          '__e0.value = __e.newValue; }));'));
    });

    test('inserted for 2-way binding with dom accessor', () {
      var elem = parseSubtree('<input data-bind="value:bar">');
      var emitter = new AttributeEmitter(analyzeElement(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          '__stoppers1.add(autogenerated.watchAndInvoke(() => bar, (__e) { '
          '__e0.value = __e.newValue; }));'));
    });

    test('inserted for data attribute', () {
      var elem = parseSubtree('<div data-foo="{{bar}}"></div>');
      var emitter = new AttributeEmitter(analyzeElement(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          '__stoppers1.add(autogenerated.watchAndInvoke(() => bar, (__e) { '
          "__e0.attributes['data-foo'] = __e.newValue; }));"));
    });

    test('inserted for class', () {
      var elem = parseSubtree('<div class="{{bar}} {{foo}}" />');
      var emitter = new AttributeEmitter(analyzeElement(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace('''
          __stoppers1.add(autogenerated.bindCssClasses(__e0, () => bar));
          __stoppers1.add(autogenerated.bindCssClasses(__e0, () => foo));
          '''));
    });

    test('inserted for style', () {
      var elem = parseSubtree('<div data-style="bar"></div>');
      var emitter = new AttributeEmitter(analyzeElement(elem));
      expect(_inserted(emitter),
          '__stoppers1.add(autogenerated.bindStyle(__e0, () => bar));');
    });

    test('removed', () {
      var elem = parseSubtree('<div foo="{{bar}}"></div>');
      var emitter = new AttributeEmitter(analyzeElement(elem));
      expect(_removed(emitter), equalsIgnoringWhitespace(
          '(__stoppers1..forEach((s) => s())).clear();'));
    });
  });

  group('emit data binding watchers for content', () {
    test('declaration', () {
      var elem = parseSubtree('<div>fo{{bar}}o</div>');
      var emitter = new ContentDataBindingEmitter(
          analyzeElement(elem).children[1]);
      expect(_declarations(emitter),
        equals('List<autogenerated.WatcherDisposer> __stoppers1;'));
    });

    test('inserted', () {
      var elem = parseSubtree('<div>fo{{bar}}o</div>');
      var emitter = new ContentDataBindingEmitter(
          analyzeElement(elem).children[1]);
      expect(_inserted(emitter), equalsIgnoringWhitespace(r'''
          __stoppers1.add(autogenerated.watchAndInvoke(() => '${bar}', (__e) {
            __binding0 = autogenerated.updateBinding(bar,
                __binding0, __e.newValue);
          }));'''));
    });

    test('removed', () {
      var elem = parseSubtree('<div>fo{{bar}}o</div>');
      var emitter = new ContentDataBindingEmitter(
          analyzeElement(elem).children[1]);
      expect(_removed(emitter), equalsIgnoringWhitespace(
          '(__stoppers1..forEach((s) => s())).clear();'));
    });
  });

  group('emit main page class', () {
    test('external resource URLs', () {
      var html =
          '<html><head>'
          '<script src="http://ex.com/a.js" type="text/javascript"></script>'
          '<script src="//example.com/a.js" type="text/javascript"></script>'
          '<script src="/a.js" type="text/javascript"></script>'
          '<link href="http://example.com/a.css" rel="stylesheet">'
          '<link href="//example.com/a.css" rel="stylesheet">'
          '<link href="/a.css" rel="stylesheet">'
          '</head><body></body></html>';
      var doc = parseDocument(html);
      var fileInfo = analyzeNodeForTesting(doc);
      fileInfo.userCode = new DartCodeInfo('main', null, [], '');
      var pathInfo = new PathInfo(new Path('a'), new Path('b'), true);

      var emitter = new MainPageEmitter(fileInfo);
      emitter.run(doc, pathInfo);
      expect(doc.outerHTML, equals(html));
    });

    group('transform css urls', () {
      var html = '<html><head>'
          '<link href="a.css" rel="stylesheet">'
          '</head><body></body></html>';

      test('html at the top level', () {
        var doc = parseDocument(html);
        var fileInfo = analyzeNodeForTesting(doc, filepath: 'a.html');
        fileInfo.userCode = new DartCodeInfo('main', null, [], '');
        // Issue #207 happened because we used to mistakenly take the path of
        // the external file when transforming the urls in the html file.
        fileInfo.externalFile = new Path('dir/a.dart');
        var pathInfo = new PathInfo(new Path(''), new Path('out'), true);
        var emitter = new MainPageEmitter(fileInfo);
        emitter.run(doc, pathInfo);
        expect(doc.outerHTML, html.replaceAll('a.css', '../a.css'));
      });

      test('file within dir -- base dir match input file dir', () {
        var doc = parseDocument(html);
        var fileInfo = analyzeNodeForTesting(doc, filepath: 'dir/a.html');
        fileInfo.userCode = new DartCodeInfo('main', null, [], '');
        // Issue #207 happened because we used to mistakenly take the path of
        // the external file when transforming the urls in the html file.
        fileInfo.externalFile = new Path('dir/a.dart');
        var pathInfo = new PathInfo(new Path('dir/'), new Path('out'), true);
        var emitter = new MainPageEmitter(fileInfo);
        emitter.run(doc, pathInfo);
        expect(doc.outerHTML, html.replaceAll('a.css', '../dir/a.css'));
      });

      test('file within dir, base dir at top-level', () {
        var doc = parseDocument(html);
        var fileInfo = analyzeNodeForTesting(doc, filepath: 'dir/a.html');
        fileInfo.userCode = new DartCodeInfo('main', null, [], '');
        // Issue #207 happened because we used to mistakenly take the path of
        // the external file when transforming the urls in the html file.
        fileInfo.externalFile = new Path('dir/a.dart');
        var pathInfo = new PathInfo(new Path(''), new Path('out'), true);
        var emitter = new MainPageEmitter(fileInfo);
        emitter.run(doc, pathInfo);
        expect(doc.outerHTML, html.replaceAll('a.css', '../../dir/a.css'));
      });
    });
  });
}

_declarations(Emitter emitter) {
  var context = new Context();
  emitter.emitDeclarations(context);
  return context.declarations.toString().trim();
}

_created(Emitter emitter) {
  var context = new Context();
  emitter.emitDeclarations(context);
  emitter.emitCreated(context);
  return context.createdMethod.toString().trim();
}

_inserted(Emitter emitter) {
  var context = new Context();
  emitter.emitDeclarations(context);
  emitter.emitInserted(context);
  return context.insertedMethod.toString().trim();
}

_removed(Emitter emitter) {
  var context = new Context();
  emitter.emitDeclarations(context);
  emitter.emitRemoved(context);
  return context.removedMethod.toString().trim();
}

_createdRecursive(ElementInfo info) {
  var context = new Context();
  new RecursiveEmitter(null, context).visit(info);
  return context.createdMethod.toString().trim();
}

_declarationsRecursive(ElementInfo info) {
  var context = new Context();
  new RecursiveEmitter(null, context).visit(info);
  return context.declarations.toString().trim();
}
