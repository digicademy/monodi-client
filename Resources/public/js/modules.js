/*jshint multistr: true */
var monodi = angular.module('monodi', []).
    filter('formatPath', function() {
        return function(input) {
            if (input) {
                var paths = input.split('/');
                paths.pop();
                return paths.join(' - ');
            }
        };
    }).filter('formatName', function() {
        return function(input) {
            if (input) return input.split('/').pop();
        };
    }).directive('filelistRepeat', function($compile, $parse) {
        return {
            link: function(scope, elem, attr) {
                var data = $parse(attr.filelistRepeat)(scope);
                var list = '';
                var renderDocuments = function(data) {
                    angular.forEach(data, function(el) {
                        if (el.document_count > 0) {
                            var path = el.path;
                            angular.forEach(el.documents, function(el) {
                                list += '<tr data-id="' + el.id +'">\
    <td><input type="checkbox" name="' + el.id +'" id="list-document-' + el.id + '" /></td>\
    <td>' + path + '</td>\
    <td><label for="list-document-' + el.id + '">' + el.filename + '</label></td>\
    <td>\
        <div class="actions btn-group">\
            <button class="btn btn-danger"><i class="icon-trash icon-white"></i></button>\
            <button class="btn btn-inverse" ng-click="print(' + el.id +')"><i class="icon-print icon-white"></i></button>\
            <button class="btn btn-info"><i class="icon-arrow-down icon-white"></i></button>\
            <button class="btn btn-primary" ng-click="documentinfo(' + el.id +')" data-toggle="modal"><i class="icon-info-sign icon-white"></i></button>\
        </div>\
    </td>\
</tr>';
                            });
                        }

                        if (el.children_count > 0) {
                            renderDocuments(el.folders);
                        }
                    });
                };

                if (data) {
                    renderDocuments(data);
                    elem.append($compile(list)(scope));
                }
            }
        };
    }).directive('filetreeRepeat', function($compile, $parse) {
        return {
            link: function(scope, elem, attr) {
                var data = $parse(attr.filetreeRepeat)(scope);
                var tree = '';
                var renderDocuments = function(data) {
                    angular.forEach(data, function(el) {
                        tree += '<li><button class="btn btn-link"><i class="icon-folder-close"></i> ' + el.title + '</button>';
                        if (el.document_count > 0) {
                            tree += '<ul>';
                            angular.forEach(el.documents, function(el) {
                                tree += '<li>\
    <input type="checkbox" name="' + el.id +'" id="tree-document-' + el.id + '" /><label for="tree-document-' + el.id + '" class="btn btn-link">' + el.filename + '</label>\
    <div class="actions btn-group">\
        <button class="btn btn-danger"><i class="icon-trash icon-white"></i></button>\
        <button class="btn btn-inverse" ng-click="print(' + el.id +')"><i class="icon-print icon-white"></i></button>\
        <button class="btn btn-info"><i class="icon-arrow-down icon-white"></i></button>\
        <button class="btn btn-primary" ng-click="documentinfo(' + el.id +')" data-toggle="modal"><i class="icon-info-sign icon-white"></i></button>\
    </div>\
</li>';
                            });
                            tree += '</ul>';
                        }

                        if (el.children_count > 0) {
                            tree += '<ul>';
                            renderDocuments(el.folders);
                            tree += '</ul>';
                        }

                        tree += '</li>';
                    });
                };

                if (data) {
                    tree += '<ul>';
                    renderDocuments(data);
                    tree += '</ul>';
                    elem.append($compile(tree)(scope));
                }
            }
        };
    });